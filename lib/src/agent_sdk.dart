import 'dart:async';

import 'chat/chat_client.dart';
import 'config/sdk_configuration.dart';
import 'config/sdk_configuration_loader.dart';
import 'core/sdk_error.dart';
import 'core/session_manager.dart';
import 'core/token_manager.dart';
import 'events/chat_events.dart';
import 'events/sdk_events.dart';
import 'models/message.dart';
import 'models/widget_config.dart';
import 'transport/transport_types.dart';
import 'utils/logger.dart';

/// Main Artemis Flutter SDK entry point
///
/// The SDK loads configuration from the host app's assets/sdk_configurations.yaml file.
/// All behavior is controlled by this configuration.
///
/// Example:
/// ```dart
/// final sdk = await AgentSDK.initialize();
/// await sdk.connect();
/// ```
class AgentSDK {
  SDKConfiguration? _config;
  TokenManager? _tokenManager;
  SessionManager? _sessionManager;
  ChatClient? _chatClient;

  StreamSubscription<void>? _connectedSubscription;
  StreamSubscription<String?>? _disconnectedSubscription;
  StreamSubscription<Object>? _errorSubscription;
  StreamSubscription<ConnectionState>? _connectionStateSubscription;
  StreamSubscription<ChatEvent>? _chatSubscription;

  final StreamController<SDKEvent> _eventController =
      StreamController<SDKEvent>.broadcast();
  final StreamController<ChatEvent> _chatEventController =
      StreamController<ChatEvent>.broadcast();

  AgentSDK._();

  /// Initialize SDK by loading configuration from host app
  ///
  /// [environment] - Optional environment override (dev, staging, prod)
  /// [customConfigPath] - Optional custom config file path
  /// [runtimeUserContext] - Optional user context to override config
  ///
  /// Returns initialized [AgentSDK] instance
  static Future<AgentSDK> initialize({
    String? environment,
    String? customConfigPath,
    SDKUserContext? runtimeUserContext,
  }) async {
    final sdk = AgentSDK._();

    try {
      sdk._config = await SDKConfigurationLoader.load(
        environment: environment,
        customPath: customConfigPath,
      );

      if (runtimeUserContext != null) {
        sdk._config = sdk._config!.copyWithUserContext(runtimeUserContext);
      }

      sdk._initializeClients();

      ArtemisLogger.configure(
        enabled: sdk._config!.debug.enabled,
        logLevel: sdk._config!.debug.logLevel,
        printToConsole: sdk._config!.debug.printLogs,
      );

      ArtemisLogger.info('AgentSDK initialized successfully', {
        'environment': sdk._config!.environment,
        'endpoint': sdk._config!.connection.endpoint,
        'project_id': sdk._config!.connection.projectId,
        'channel_id': sdk._config!.channel?.channelId,
      });

      return sdk;
    } catch (e, st) {
      ArtemisLogger.error('Failed to initialize AgentSDK', e, st);
      rethrow;
    }
  }

  /// Create SDK with explicit configuration (for testing)
  static AgentSDK createWithConfig(SDKConfiguration config) {
    final sdk = AgentSDK._();
    sdk._config = config;
    sdk._initializeClients();

    ArtemisLogger.configure(
      enabled: config.debug.enabled,
      logLevel: config.debug.logLevel,
      printToConsole: config.debug.printLogs,
    );

    return sdk;
  }

  void _initializeClients() {
    final config = _config!;
    _tokenManager = TokenManager(config);
    _sessionManager = SessionManager(
      config: config,
      tokenManager: _tokenManager!,
    );
    _chatClient = ChatClient(
      sessionManager: _sessionManager!,
      config: config,
      onHistoryError: (error, stackTrace) {
        _eventController.add(
          SDKErrorEvent(
            error,
            stackTrace: stackTrace,
            code: SDKErrorCode.historyFetch,
          ),
        );
      },
    );

    _connectedSubscription = _sessionManager!.connected.listen((_) {
      final sessionId = _sessionManager!.getSessionId();
      if (sessionId != null) {
        _eventController.add(SDKConnectedEvent(sessionId));
      }
      // Retransmit any messages that were left unanswered by a prior drop.
      _chatClient!.resendPending();
      // Hydrate persisted history first thing on every (re)connect.
      unawaited(_chatClient!.hydratePersistedHistory());
    });

    _disconnectedSubscription = _sessionManager!.disconnected.listen((reason) {
      _eventController.add(SDKDisconnectedEvent(reason: reason));
    });

    _errorSubscription = _sessionManager!.errors.listen((error) {
      _eventController.add(_toSdkErrorEvent(error));
    });

    _connectionStateSubscription =
        _sessionManager!.connectionState.listen((state) {
      if (state == ConnectionState.reconnecting) {
        final attempts = _config!.websocket.reconnection.maxAttempts;
        _eventController.add(SDKReconnectingEvent(1, attempts));
      }
    });

    _chatSubscription = _chatClient!.events.listen(_chatEventController.add);
  }

  /// Get loaded configuration (read-only)
  SDKConfiguration get config {
    if (_config == null) {
      throw StateError('SDK not initialized. Call AgentSDK.initialize() first.');
    }
    return _config!;
  }

  /// Connect to the Artemis
  ///
  /// Returns session ID
  Future<String> connect() async {
    _ensureInitialized();

    try {
      ArtemisLogger.info('Connecting to Artemis...', {
        'endpoint': _config!.connection.endpoint,
      });

      await _sessionManager!.connect();

      final sessionId = _sessionManager!.getSessionId();
      if (sessionId == null || sessionId.isEmpty) {
        throw StateError('Connected but session ID was not returned');
      }

      ArtemisLogger.info('Connected successfully', {
        'session_id': sessionId,
      });

      return sessionId;
    } catch (e, st) {
      ArtemisLogger.error('Connection failed', e, st);
      _eventController.add(_toSdkErrorEvent(e, st));
      rethrow;
    }
  }

  /// Disconnect from platform
  void disconnect() {
    if (_sessionManager == null) return;
    ArtemisLogger.info('Disconnecting from platform');
    // Client-initiated teardown: drop unanswered messages so they are not
    // replayed if the host reconnects later.
    _chatClient?.clearPending();
    _sessionManager!.disconnect();
  }

  /// End the current server session and disconnect.
  void endSession() {
    _chatClient?.clearCustomData();
    _chatClient?.clearPending();
    _sessionManager?.endSession();
  }

  /// Check if connected
  bool isConnected() => _sessionManager?.isConnected() ?? false;

  /// Get current session ID
  String? getSessionId() => _sessionManager?.getSessionId();

  /// Get the server-provided widget configuration.
  ///
  /// Returned by the runtime in the init/refresh response and available after
  /// a successful [connect]. Returns null if the SDK is not connected yet or
  /// the runtime did not provide one.
  WidgetConfig? getWidgetConfig() => _sessionManager?.getWidgetConfig();

  /// Send a chat message
  ///
  /// [text] - Message text
  /// [metadata] - Optional metadata
  ///
  /// Returns message ID
  Future<String> sendMessage(
    String text, {
    Map<String, dynamic>? metadata,
    List<String>? attachmentIds,
  }) async {
    _ensureInitialized();

    if (!isConnected()) {
      final error = StateError('SDK not connected. Call connect() first.');
      _eventController.add(
        SDKErrorEvent(error, code: SDKErrorCode.sendFailed),
      );
      throw error;
    }

    try {
      return await _chatClient!.send(
        text,
        metadata: metadata,
        attachmentIds: attachmentIds,
      );
    } catch (e, st) {
      _eventController.add(
        SDKErrorEvent(e, stackTrace: st, code: SDKErrorCode.sendFailed),
      );
      rethrow;
    }
  }

  /// Submit an interactive action (button click, select change, form submit).
  Future<void> submitAction(
    String actionId, {
    String? value,
    Map<String, String>? formData,
    String? renderId,
  }) async {
    _ensureInitialized();

    if (!isConnected()) {
      final error = StateError('SDK not connected. Call connect() first.');
      _eventController.add(
        SDKErrorEvent(error, code: SDKErrorCode.sendFailed),
      );
      throw error;
    }

    try {
      _chatClient!.submitAction(
        actionId,
        value: value,
        formData: formData,
        renderId: renderId,
      );
    } catch (e, st) {
      _eventController.add(
        SDKErrorEvent(e, stackTrace: st, code: SDKErrorCode.sendFailed),
      );
      rethrow;
    }
  }

  /// Get all messages
  List<Message> getMessages() => _chatClient?.getMessages() ?? const [];

  /// Update session-scoped custom data.
  ///
  /// The provided [customData] is merged into any existing custom data and
  /// attached to every chat message sent afterwards, for the remainder of the
  /// conversation. It is cleared automatically on [endSession] (or manually via
  /// [clearCustomData]). Repeated calls accumulate; matching keys are
  /// overridden by the latest call.
  void updateCustomData(Map<String, dynamic> customData) {
    _ensureInitialized();
    _chatClient!.updateCustomData(customData);
  }

  /// Get the current session-scoped custom data.
  Map<String, dynamic> get customData => _chatClient?.customData ?? const {};

  /// Clear all session-scoped custom data.
  void clearCustomData() => _chatClient?.clearCustomData();

  /// Clear message history
  void clearHistory() {
    _chatClient?.clearMessages();
    ArtemisLogger.debug('Message history cleared');
  }

  /// SDK event stream
  Stream<SDKEvent> get events => _eventController.stream;

  /// Chat event stream
  Stream<ChatEvent> get chatEvents => _chatEventController.stream;

  /// Dispose and clean up resources
  Future<void> dispose() async {
    disconnect();
    await _connectedSubscription?.cancel();
    await _disconnectedSubscription?.cancel();
    await _errorSubscription?.cancel();
    await _connectionStateSubscription?.cancel();
    await _chatSubscription?.cancel();
    await _chatClient?.dispose();
    await _sessionManager?.dispose();
    await _eventController.close();
    await _chatEventController.close();
    ArtemisLogger.info('AgentSDK disposed');
  }

  /// Convert an internal error into a coded [SDKErrorEvent].
  ///
  /// [SdkStageException]s carry their originating stage so host apps can tell
  /// exactly where the failure happened; everything else is reported as
  /// [SDKErrorCode.unknown].
  SDKErrorEvent _toSdkErrorEvent(Object error, [StackTrace? stackTrace]) {
    if (error is SdkStageException) {
      return SDKErrorEvent(
        error.cause,
        stackTrace: error.stackTrace ?? stackTrace,
        code: error.code,
      );
    }
    return SDKErrorEvent(error, stackTrace: stackTrace);
  }

  void _ensureInitialized() {
    if (_config == null ||
        _tokenManager == null ||
        _sessionManager == null ||
        _chatClient == null) {
      throw StateError('SDK not initialized. Call AgentSDK.initialize() first.');
    }
  }
}
