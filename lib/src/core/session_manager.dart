import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

import '../config/sdk_configuration.dart';
import '../utils/logger.dart';
import 'endpoint.dart';
import 'sdk_session_scope.dart';
import 'token_manager.dart';
import 'websocket_auth.dart';
import '../transport/transport_types.dart';

const _sessionReadyTimeoutMs = 10000;
const _endSessionCloseFallbackMs = 5000;

/// WebSocket connection and session handling.
class SessionManager {
  final SDKConfiguration _config;
  final TokenManager _tokenManager;
  final String _httpEndpoint;
  final String _wsEndpoint;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;

  String? _sessionId;
  String? _resolvedProjectId;
  String? _resolvedChannelId;
  bool _isSessionReady = false;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  Future<void>? _connectPromise;
  Completer<void>? _pendingConnectCompleter;
  Timer? _pendingConnectTimeout;
  Timer? _endSessionCloseTimeout;
  bool _shouldReconnect = true;
  bool _disposed = false;

  final StreamController<TransportServerMessage> _messageController =
      StreamController<TransportServerMessage>.broadcast();
  final StreamController<void> _connectedController =
      StreamController<void>.broadcast();
  final StreamController<String?> _disconnectedController =
      StreamController<String?>.broadcast();
  final StreamController<Object> _errorController =
      StreamController<Object>.broadcast();
  final StreamController<ConnectionState> _connectionStateController =
      StreamController<ConnectionState>.broadcast();

  SessionManager({
    required SDKConfiguration config,
    required TokenManager tokenManager,
  })  : _config = config,
        _tokenManager = tokenManager,
        _httpEndpoint = normalizeHttpEndpoint(config.connection.endpoint),
        _wsEndpoint = normalizeWebSocketEndpoint(config.connection.endpoint);

  Stream<TransportServerMessage> get messages => _messageController.stream;

  Stream<void> get connected => _connectedController.stream;

  Stream<String?> get disconnected => _disconnectedController.stream;

  Stream<Object> get errors => _errorController.stream;

  Stream<ConnectionState> get connectionState =>
      _connectionStateController.stream;

  Future<void> connect() async {
    if (isConnected()) {
      return;
    }

    if (_connectPromise != null) {
      return _connectPromise!;
    }

    _shouldReconnect = true;
    _connectPromise = _openConnection().whenComplete(() {
      _connectPromise = null;
    });

    return _connectPromise!;
  }

  void disconnect() {
    _shouldReconnect = false;
    _clearEndSessionCloseTimeout();
    _rejectPendingConnect(StateError('Client disconnected before session_start'));
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _closeChannel(ws_status.normalClosure, 'Client disconnect');
    _resetSessionState();
    _setConnectionState(ConnectionState.disconnected);
  }

  void endSession() {
    _shouldReconnect = false;
    if (!isConnected() || _channel == null) {
      disconnect();
      return;
    }

    try {
      send(EndSessionTransport(sessionId: _sessionId));
      _armEndSessionCloseFallback();
    } catch (error, stackTrace) {
      ABLLogger.error('Failed to send end_session frame; disconnecting', error, stackTrace);
      disconnect();
    }
  }

  void send(TransportClientMessage message) {
    if (!isConnected() || _channel == null) {
      throw StateError('Not connected');
    }

    final payload = jsonEncode(message.toJson());
    if (_config.debug.logWebsocketMessages) {
      ABLLogger.debug('WebSocket send', payload);
    }
    _channel!.sink.add(payload);
  }

  bool isConnected() => _channel != null && _isSessionReady;

  String? getSessionId() => _sessionId;

  String getProjectId() => _resolvedProjectId ?? _config.connection.projectId;

  String? getChannelId() => _resolvedChannelId;

  SDKSessionScope? getScope() => _tokenManager.getScope();

  Future<String> getAuthToken() => _tokenManager.getToken();

  String getEndpoint() => _httpEndpoint;

  Future<void> dispose() async {
    _disposed = true;
    disconnect();
    await _messageController.close();
    await _connectedController.close();
    await _disconnectedController.close();
    await _errorController.close();
    await _connectionStateController.close();
  }

  Future<void> _openConnection() async {
    final authToken = await _tokenManager.getToken();
    final protocols = await _resolveWebSocketProtocols(authToken);
    final wsUrl = '$_wsEndpoint/ws/sdk';

    _setConnectionState(ConnectionState.connecting);
    _resetSessionState();
    _armPendingConnect();

    ABLLogger.info('Connecting WebSocket', {'url': wsUrl});

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse(wsUrl),
        protocols: protocols,
      );

      _subscription = _channel!.stream.listen(
        _handleSocketData,
        onError: (Object error) {
          ABLLogger.error('WebSocket error', error);
          _errorController.add(error);
          _rejectPendingConnect(
            error is Exception ? error : Exception(error.toString()),
          );
          _setConnectionState(ConnectionState.error);
        },
        onDone: () {
          final closeCode = _channel?.closeCode;
          final closeReason = _channel?.closeReason;
          _handleSocketClosed(closeCode, closeReason);
        },
        cancelOnError: false,
      );
    } catch (error, stackTrace) {
      ABLLogger.error('Failed to open WebSocket', error, stackTrace);
      _rejectPendingConnect(
        error is Exception ? error : Exception(error.toString()),
      );
      _setConnectionState(ConnectionState.error);
      rethrow;
    }

    return _pendingConnectCompleter!.future;
  }

  Future<List<String>> _resolveWebSocketProtocols(String authToken) async {
    try {
      final response = await http.post(
        Uri.parse('$_httpEndpoint/api/v1/sdk/ws-ticket'),
        headers: {
          'Content-Type': 'application/json',
          'X-SDK-Token': authToken,
        },
        body: '{}',
      );

      if (!response.statusCode.toString().startsWith('2')) {
        if (_shouldUseLegacyWebSocketAuth(response.statusCode)) {
          ABLLogger.warning(
            'WebSocket ticket endpoint unavailable; using deprecated session-token auth',
          );
          return buildSdkWSProtocols(authToken);
        }
        throw Exception(
          'WebSocket ticket request failed with status ${response.statusCode}',
        );
      }

      final payload = jsonDecode(response.body);
      if (payload is! Map<String, dynamic>) {
        throw Exception('WebSocket ticket response was invalid');
      }

      final ticket = (payload['ticket'] as String?)?.trim() ?? '';
      if (ticket.isEmpty) {
        throw Exception('WebSocket ticket response was missing ticket');
      }

      return buildSdkWSTicketProtocols(ticket);
    } catch (error, stackTrace) {
      ABLLogger.error('WebSocket ticket request failed', error, stackTrace);
      rethrow;
    }
  }

  bool _shouldUseLegacyWebSocketAuth(int status) {
    return status == 404 || status == 405 || status == 501;
  }

  void _handleSocketData(dynamic data) {
    try {
      final decoded = jsonDecode(data as String) as Map<String, dynamic>;
      if (_config.debug.logWebsocketMessages) {
        ABLLogger.debug('WebSocket receive', decoded);
      }

      final message = TransportServerMessage.fromJson(decoded);
      _handleMessage(message);
    } catch (error, stackTrace) {
      ABLLogger.error('Failed to parse WebSocket message', error, stackTrace);
    }
  }

  void _handleMessage(TransportServerMessage message) {
    if (message.type == 'session_start') {
      final tokenScope = _tokenManager.getScope();
      _sessionId = message.raw['sessionId'] as String?;
      _resolvedProjectId = message.raw['projectId'] as String? ?? tokenScope?.projectId;
      _resolvedChannelId = message.raw['channelId'] as String? ?? tokenScope?.channelId;

      if (!_isSessionReady) {
        _isSessionReady = true;
        _reconnectAttempts = 0;
        _connectedController.add(null);
        _resolvePendingConnect();
        _setConnectionState(ConnectionState.connected);
        ABLLogger.info('Connected', {'session_id': _sessionId});
      }

      ABLLogger.info('Session started', {'session_id': _sessionId});
    }

    _messageController.add(message);
  }

  void _handleSocketClosed(int? closeCode, String? closeReason) {
    _clearEndSessionCloseTimeout();
    _subscription?.cancel();
    _subscription = null;
    _channel = null;

    if (_shouldInvalidateTokenForClose(closeCode)) {
      _tokenManager.invalidateToken();
    }

    _resetSessionState();
    _rejectPendingConnect(StateError('WebSocket closed before session_start'));
    _disconnectedController.add(closeReason);
    _setConnectionState(ConnectionState.disconnected);
    ABLLogger.info('Disconnected', {
      'code': closeCode,
      'reason': closeReason,
    });

    if (_shouldReconnect && !_disposed) {
      _attemptReconnect();
    }
  }

  void _attemptReconnect() {
    final reconnection = _config.websocket.reconnection;
    if (!reconnection.enabled) {
      return;
    }

    if (_reconnectAttempts >= reconnection.maxAttempts) {
      ABLLogger.warning('Max reconnect attempts reached');
      return;
    }

    final delayMs = _getReconnectDelayMs(_reconnectAttempts, reconnection);
    _reconnectAttempts++;
    _setConnectionState(ConnectionState.reconnecting);

    ABLLogger.info('Reconnecting', {
      'delay_ms': delayMs,
      'attempt': _reconnectAttempts,
      'max_attempts': reconnection.maxAttempts,
    });

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: delayMs), () {
      connect().catchError((Object error, StackTrace stackTrace) {
        ABLLogger.error('Reconnect failed', error, stackTrace);
        _errorController.add(error);
      });
    });
  }

  int _getReconnectDelayMs(int attempt, ReconnectionConfig config) {
    if (!config.exponentialBackoff) {
      return config.baseDelayMs;
    }

    final delay = config.baseDelayMs * math.pow(2, attempt).toInt();
    return delay > config.maxDelayMs ? config.maxDelayMs : delay;
  }

  void _armPendingConnect() {
    _clearPendingConnect();
    _pendingConnectCompleter = Completer<void>();
    _pendingConnectTimeout = Timer(
      const Duration(milliseconds: _sessionReadyTimeoutMs),
      () {
        final timeoutError = StateError('Timed out waiting for session_start');
        _rejectPendingConnect(timeoutError);
        _closeChannel(ws_status.goingAway, 'Session start timeout');
      },
    );
  }

  void _resolvePendingConnect() {
    _clearPendingConnect();
    if (_pendingConnectCompleter != null && !_pendingConnectCompleter!.isCompleted) {
      _pendingConnectCompleter!.complete();
    }
    _pendingConnectCompleter = null;
  }

  void _rejectPendingConnect(Object error) {
    final completer = _pendingConnectCompleter;
    _clearPendingConnect();
    if (completer != null && !completer.isCompleted) {
      completer.completeError(error);
    }
  }

  void _clearPendingConnect() {
    _pendingConnectTimeout?.cancel();
    _pendingConnectTimeout = null;
  }

  void _armEndSessionCloseFallback() {
    _clearEndSessionCloseTimeout();
    _endSessionCloseTimeout = Timer(
      const Duration(milliseconds: _endSessionCloseFallbackMs),
      () {
        _closeChannel(ws_status.normalClosure, 'Session ended by client');
      },
    );
  }

  void _clearEndSessionCloseTimeout() {
    _endSessionCloseTimeout?.cancel();
    _endSessionCloseTimeout = null;
  }

  void _closeChannel(int code, String reason) {
    final channel = _channel;
    if (channel == null) {
      return;
    }

    try {
      channel.sink.close(code, reason);
    } catch (_) {
      // Channel may already be closed.
    }
  }

  void _resetSessionState() {
    _sessionId = null;
    _resolvedProjectId = null;
    _resolvedChannelId = null;
    _isSessionReady = false;
  }

  bool _shouldInvalidateTokenForClose(int? code) {
    return code == 4001 || code == 4003 || code == 4010;
  }

  void _setConnectionState(ConnectionState state) {
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(state);
    }
  }
}
