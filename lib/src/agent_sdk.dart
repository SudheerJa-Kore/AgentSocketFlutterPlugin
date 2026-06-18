import 'dart:async';

import 'chat/chat_client.dart';
import 'config/sdk_configuration.dart';
import 'config/sdk_configuration_loader.dart';
import 'core/session_manager.dart';
import 'core/token_manager.dart';
import 'events/chat_events.dart';
import 'events/sdk_events.dart';
import 'models/message.dart';
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
    );

    _connectedSubscription = _sessionManager!.connected.listen((_) {
      final sessionId = _sessionManager!.getSessionId();
      if (sessionId != null) {
        _eventController.add(SDKConnectedEvent(sessionId));
      }
      // Hydrate persisted history first thing on every (re)connect.
      unawaited(_chatClient!.hydratePersistedHistory());
    });

    _disconnectedSubscription = _sessionManager!.disconnected.listen((reason) {
      _eventController.add(SDKDisconnectedEvent(reason: reason));
    });

    _errorSubscription = _sessionManager!.errors.listen((error) {
      _eventController.add(
        SDKErrorEvent(
          error is Exception ? error : Exception(error.toString()),
        ),
      );
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
      _eventController.add(SDKErrorEvent(e, st));
      rethrow;
    }
  }

  /// Disconnect from platform
  void disconnect() {
    if (_sessionManager == null) return;
    ArtemisLogger.info('Disconnecting from platform');
    _sessionManager!.disconnect();
  }

  /// End the current server session and disconnect.
  void endSession() {
    _sessionManager?.endSession();
  }

  /// Check if connected
  bool isConnected() => _sessionManager?.isConnected() ?? false;

  /// Get current session ID
  String? getSessionId() => _sessionManager?.getSessionId();

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
      throw StateError('SDK not connected. Call connect() first.');
    }

    return _chatClient!.send(
      text,
      metadata: metadata,
      attachmentIds: attachmentIds,
    );
  }

  /// Get all messages
  List<Message> getMessages() => _chatClient?.getMessages() ?? const [];

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

  void _ensureInitialized() {
    if (_config == null ||
        _tokenManager == null ||
        _sessionManager == null ||
        _chatClient == null) {
      throw StateError('SDK not initialized. Call AgentSDK.initialize() first.');
    }
  }
}
