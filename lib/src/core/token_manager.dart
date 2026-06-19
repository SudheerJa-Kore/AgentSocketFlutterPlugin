import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/sdk_configuration.dart';
import '../events/sdk_events.dart';
import '../models/widget_config.dart';
import '../utils/logger.dart';
import 'endpoint.dart';
import 'sdk_error.dart';
import 'sdk_session_scope.dart';

const _refreshLeewayMs = 60 * 1000;

class TokenRequestException implements Exception {
  final int status;
  final String message;

  TokenRequestException(this.status, this.message);

  @override
  String toString() => 'TokenRequestException($status): $message';
}

class TokenResponseValidationException implements Exception {
  final String message;

  TokenResponseValidationException(this.message);

  @override
  String toString() => 'TokenResponseValidationException: $message';
}

/// Bootstrap and refresh short-lived SDK session tokens.
class TokenManager {
  final SDKConfiguration _config;
  final String _httpEndpoint;

  String? _token;
  int? _expiresAtMs;
  SDKSessionScope? _scope;
  WidgetConfig? _widgetConfig;
  Future<String>? _inflight;

  TokenManager(this._config) : _httpEndpoint = normalizeHttpEndpoint(_config.connection.endpoint);

  Future<String> getToken() async {
    if (_inflight != null) {
      return _inflight!;
    }

    if (_token != null && !_shouldRefresh()) {
      return _token!;
    }

    _inflight = _refreshOrInit().whenComplete(() {
      _inflight = null;
    });

    return _inflight!;
  }

  SDKSessionScope? getScope() => _scope;

  /// Server-provided widget configuration from the most recent init/refresh
  /// response, or null if none was returned yet.
  WidgetConfig? getWidgetConfig() => _widgetConfig;

  void invalidateToken() => _clearToken();

  Future<String> _refreshOrInit() async {
    if (_token == null) {
      return _initToken();
    }

    final currentToken = _token!;

    try {
      return await _refreshToken(currentToken);
    } catch (error, stackTrace) {
      if (error is TokenResponseValidationException) {
        _clearToken();
        throw SdkStageException(SDKErrorCode.tokenRefresh, error, stackTrace);
      }

      if (!_isExpired() && !_isUnauthorizedError(error)) {
        return currentToken;
      }

      _clearToken();
      return _initToken();
    }
  }

  Future<String> _initToken() async {
    try {
      return await _initTokenImpl();
    } on SdkStageException {
      rethrow;
    } catch (error, stackTrace) {
      throw SdkStageException(SDKErrorCode.tokenInit, error, stackTrace);
    }
  }

  Future<String> _initTokenImpl() async {
    final body = <String, dynamic>{};
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    final bootstrapToken = _config.connection.bootstrapToken;
    if (bootstrapToken != null && bootstrapToken.isNotEmpty) {
      body['bootstrapToken'] = bootstrapToken;
    } else {
      final channel = _config.channel;
      if (channel != null) {
        final channelId = channel.channelId;
        final channelName = channel.channelName;
        if (channelId != null && channelId.isNotEmpty) {
          body['channelId'] = channelId;
        } else if (channelName != null && channelName.isNotEmpty) {
          body['channelName'] = channelName;
        }

        final deploymentSlug = channel.deploymentSlug;
        if (deploymentSlug != null && deploymentSlug.isNotEmpty) {
          body['deploymentSlug'] = deploymentSlug;
        }
      }

      final userContext = _config.userContext;
      if (userContext != null) {
        final contextBody = <String, dynamic>{};
        if (userContext.userId != null && userContext.userId!.isNotEmpty) {
          contextBody['userId'] = userContext.userId;
        }
        if (userContext.customAttributes != null &&
            userContext.customAttributes!.isNotEmpty) {
          contextBody['customAttributes'] = userContext.customAttributes;
        }
        if (contextBody.isNotEmpty) {
          body['userContext'] = contextBody;
        }
      }

      final apiKey = _config.connection.apiKey;
      if (apiKey == null || apiKey.isEmpty) {
        throw TokenRequestException(0, 'connection.api_key is required');
      }
      headers['X-Public-Key'] = apiKey;
    }

    final url = '$_httpEndpoint/api/v1/sdk/init';
    final encodedBody = jsonEncode(body);
    ArtemisLogger.debug('SDK init request', {
      'method': 'POST',
      'url': url,
      'headers': headers,
      'body': encodedBody,
    });

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: encodedBody,
    );

    ArtemisLogger.debug('SDK init response', {
      'status': response.statusCode,
      'body': response.body,
    });

    return _storeResponse(response, 'SDK init failed');
  }

  Future<String> _refreshToken(String currentToken) async {
    final url = '$_httpEndpoint/api/v1/sdk/refresh';
    ArtemisLogger.debug('SDK refresh request', {
      'method': 'POST',
      'url': url,
    });

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'X-SDK-Token': currentToken,
      },
      body: '{}',
    );

    ArtemisLogger.debug('SDK refresh response', {
      'status': response.statusCode,
    });

    return _storeResponse(response, 'SDK token refresh failed');
  }

  Future<String> _storeResponse(http.Response response, String fallbackMessage) async {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = response.body.isNotEmpty ? response.body : fallbackMessage;
      throw TokenRequestException(response.statusCode, message);
    }

    final payload = jsonDecode(response.body);
    final parsed = _parseTokenResponse(payload, fallbackMessage);
    _token = parsed.token;
    _expiresAtMs = DateTime.now().millisecondsSinceEpoch + parsed.expiresIn * 1000;
    _scope = _resolveScope(parsed);
    _widgetConfig = parsed.widgetConfig;
    return parsed.token;
  }

  _TokenResponse _parseTokenResponse(Object? payload, String fallbackMessage) {
    if (payload is! Map<String, dynamic>) {
      throw TokenResponseValidationException(
        '$fallbackMessage: invalid JSON payload.',
      );
    }

    final token = (payload['token'] as String?)?.trim() ?? '';
    if (token.isEmpty) {
      throw TokenResponseValidationException(
        '$fallbackMessage: missing token in SDK session response.',
      );
    }

    final expiresIn = payload['expiresIn'];
    if (expiresIn is! num || expiresIn <= 0) {
      throw TokenResponseValidationException(
        '$fallbackMessage: invalid expiresIn in SDK session response.',
      );
    }

    final tenantId = (payload['tenantId'] as String?)?.trim() ?? '';
    final projectId = (payload['projectId'] as String?)?.trim() ?? '';
    final channelId = (payload['channelId'] as String?)?.trim() ?? '';
    if (tenantId.isEmpty || projectId.isEmpty || channelId.isEmpty) {
      throw TokenResponseValidationException(
        '$fallbackMessage: Runtime must return tenantId, projectId, and channelId.',
      );
    }

    final permissions = (payload['permissions'] as List<dynamic>?)
            ?.whereType<String>()
            .where((permission) => permission.isNotEmpty)
            .toList() ??
        <String>[];
    if (permissions.isEmpty) {
      throw TokenResponseValidationException(
        '$fallbackMessage: Runtime must return a non-empty permissions array.',
      );
    }

    final showActivityUpdates = payload['showActivityUpdates'];
    if (showActivityUpdates is! bool) {
      throw TokenResponseValidationException(
        '$fallbackMessage: Runtime must return showActivityUpdates.',
      );
    }

    final deploymentId = (payload['deploymentId'] as String?)?.trim();

    final widgetConfigRaw = payload['widgetConfig'];
    final widgetConfig = widgetConfigRaw is Map<String, dynamic>
        ? WidgetConfig.fromMap(widgetConfigRaw)
        : null;

    return _TokenResponse(
      token: token,
      expiresIn: expiresIn.toInt(),
      tenantId: tenantId,
      projectId: projectId,
      channelId: channelId,
      deploymentId: deploymentId?.isNotEmpty == true ? deploymentId : null,
      permissions: permissions,
      showActivityUpdates: showActivityUpdates,
      widgetConfig: widgetConfig,
    );
  }

  SDKSessionScope _resolveScope(_TokenResponse payload) {
    final nextScope = SDKSessionScope(
      tenantId: payload.tenantId,
      projectId: payload.projectId,
      channelId: payload.channelId,
      deploymentId: payload.deploymentId,
      permissions: List<String>.from(payload.permissions),
      showActivityUpdates: payload.showActivityUpdates,
    );

    if (nextScope.projectId != _config.connection.projectId) {
      throw TokenResponseValidationException(
        'Runtime returned an SDK session for a different project than the SDK config.',
      );
    }

    if (_scope != null) {
      final previous = _scope!;
      final permissionsMatch = previous.permissions.length == nextScope.permissions.length &&
          List.generate(previous.permissions.length, (index) {
            return previous.permissions[index] == nextScope.permissions[index];
          }).every((match) => match);

      if (previous.tenantId != nextScope.tenantId ||
          previous.projectId != nextScope.projectId ||
          previous.channelId != nextScope.channelId ||
          previous.deploymentId != nextScope.deploymentId ||
          previous.showActivityUpdates != nextScope.showActivityUpdates ||
          !permissionsMatch) {
        throw TokenResponseValidationException(
          'Runtime changed SDK session scope during refresh. Re-initialize the SDK session.',
        );
      }
    }

    ArtemisLogger.debug('SDK token acquired', {
      'project_id': nextScope.projectId,
      'channel_id': nextScope.channelId,
    });

    return nextScope;
  }

  bool _shouldRefresh() {
    if (_token == null || _expiresAtMs == null) {
      return true;
    }
    return _expiresAtMs! - DateTime.now().millisecondsSinceEpoch <= _refreshLeewayMs;
  }

  bool _isExpired() {
    return _expiresAtMs != null &&
        _expiresAtMs! <= DateTime.now().millisecondsSinceEpoch;
  }

  bool _isUnauthorizedError(Object error) {
    return error is TokenRequestException &&
        (error.status == 401 || error.status == 403);
  }

  void _clearToken() {
    _token = null;
    _expiresAtMs = null;
    _scope = null;
    _widgetConfig = null;
  }
}

class _TokenResponse {
  final String token;
  final int expiresIn;
  final String tenantId;
  final String projectId;
  final String channelId;
  final String? deploymentId;
  final List<String> permissions;
  final bool showActivityUpdates;
  final WidgetConfig? widgetConfig;

  const _TokenResponse({
    required this.token,
    required this.expiresIn,
    required this.tenantId,
    required this.projectId,
    required this.channelId,
    this.deploymentId,
    required this.permissions,
    required this.showActivityUpdates,
    this.widgetConfig,
  });
}
