/// SDK Configuration Models
///
/// Complete configuration model for ABL Platform Flutter SDK.
/// Configuration is loaded from host application's assets/sdk_configurations.yaml
library;

import '../models/message.dart';

/// Main SDK configuration
class SDKConfiguration {
  final String environment;
  final ConnectionConfig connection;
  final ChannelConfig? channel;
  final UserContextConfig? userContext;
  final WebSocketConfig websocket;
  final VoiceConfig voice;
  final ChatConfig chat;
  final StorageConfig storage;
  final PerformanceConfig performance;
  final AccessibilityConfig accessibility;
  final ThemeConfig theme;
  final DebugConfig debug;
  final FeaturesConfig features;
  final LocalizationConfig localization;
  final SecurityConfig security;
  final AnalyticsConfig? analytics;

  const SDKConfiguration({
    required this.environment,
    required this.connection,
    this.channel,
    this.userContext,
    required this.websocket,
    required this.voice,
    required this.chat,
    required this.storage,
    required this.performance,
    required this.accessibility,
    required this.theme,
    required this.debug,
    required this.features,
    required this.localization,
    required this.security,
    this.analytics,
  });

  factory SDKConfiguration.fromMap(Map<String, dynamic> map) {
    return SDKConfiguration(
      environment: map['environment'] ?? 'dev',
      connection: ConnectionConfig.fromMap(map['connection'] ?? {}),
      channel: map['channel'] != null
          ? ChannelConfig.fromMap(map['channel'])
          : null,
      userContext: map['user_context'] != null
          ? UserContextConfig.fromMap(map['user_context'])
          : null,
      websocket: WebSocketConfig.fromMap(map['websocket'] ?? {}),
      voice: VoiceConfig.fromMap(map['voice'] ?? {}),
      chat: ChatConfig.fromMap(map['chat'] ?? {}),
      storage: StorageConfig.fromMap(map['storage'] ?? {}),
      performance: PerformanceConfig.fromMap(map['performance'] ?? {}),
      accessibility: AccessibilityConfig.fromMap(map['accessibility'] ?? {}),
      theme: ThemeConfig.fromMap(map['theme'] ?? {}),
      debug: DebugConfig.fromMap(map['debug'] ?? {}),
      features: FeaturesConfig.fromMap(map['features'] ?? {}),
      localization: LocalizationConfig.fromMap(map['localization'] ?? {}),
      security: SecurityConfig.fromMap(map['security'] ?? {}),
      analytics: map['analytics'] != null
          ? AnalyticsConfig.fromMap(map['analytics'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'environment': environment,
      'connection': connection.toMap(),
      'channel': channel?.toMap(),
      'user_context': userContext?.toMap(),
      'websocket': websocket.toMap(),
      'voice': voice.toMap(),
      'chat': chat.toMap(),
      'storage': storage.toMap(),
      'performance': performance.toMap(),
      'accessibility': accessibility.toMap(),
      'theme': theme.toMap(),
      'debug': debug.toMap(),
      'features': features.toMap(),
      'localization': localization.toMap(),
      'security': security.toMap(),
      'analytics': analytics?.toMap(),
    };
  }

  SDKConfiguration copyWithUserContext(SDKUserContext userContext) {
    return SDKConfiguration(
      environment: environment,
      connection: connection,
      channel: channel,
      userContext: UserContextConfig(
        userId: userContext.userId,
        customAttributes: userContext.customAttributes,
      ),
      websocket: websocket,
      voice: voice,
      chat: chat,
      storage: storage,
      performance: performance,
      accessibility: accessibility,
      theme: theme,
      debug: debug,
      features: features,
      localization: localization,
      security: security,
      analytics: analytics,
    );
  }
}

/// Connection configuration
class ConnectionConfig {
  final String projectId;
  final String endpoint;
  final String? apiKey;
  final String? bootstrapToken;

  const ConnectionConfig({
    required this.projectId,
    required this.endpoint,
    this.apiKey,
    this.bootstrapToken,
  });

  factory ConnectionConfig.fromMap(Map<String, dynamic> map) {
    return ConnectionConfig(
      projectId: map['project_id'] ?? '',
      endpoint: map['endpoint'] ?? '',
      apiKey: map['api_key'],
      bootstrapToken: map['bootstrap_token'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'project_id': projectId,
      'endpoint': endpoint,
      'api_key': apiKey,
      'bootstrap_token': bootstrapToken,
    };
  }
}

/// Channel configuration
class ChannelConfig {
  final String? channelId;
  final String? channelName;
  final String? deploymentSlug;

  const ChannelConfig({
    this.channelId,
    this.channelName,
    this.deploymentSlug,
  });

  factory ChannelConfig.fromMap(Map<String, dynamic> map) {
    return ChannelConfig(
      channelId: map['channel_id'],
      channelName: map['channel_name'],
      deploymentSlug: map['deployment_slug'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'channel_id': channelId,
      'channel_name': channelName,
      'deployment_slug': deploymentSlug,
    };
  }
}

/// User context configuration
class UserContextConfig {
  final String? userId;
  final Map<String, dynamic>? customAttributes;

  const UserContextConfig({
    this.userId,
    this.customAttributes,
  });

  factory UserContextConfig.fromMap(Map<String, dynamic> map) {
    return UserContextConfig(
      userId: map['user_id'],
      customAttributes: map['custom_attributes'] != null
          ? Map<String, dynamic>.from(map['custom_attributes'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'custom_attributes': customAttributes,
    };
  }
}

/// WebSocket configuration
class WebSocketConfig {
  final ReconnectionConfig reconnection;
  final IdleDisconnectConfig idleDisconnect;

  const WebSocketConfig({
    required this.reconnection,
    required this.idleDisconnect,
  });

  factory WebSocketConfig.fromMap(Map<String, dynamic> map) {
    return WebSocketConfig(
      reconnection: ReconnectionConfig.fromMap(map['reconnection'] ?? {}),
      idleDisconnect: IdleDisconnectConfig.fromMap(map['idle_disconnect'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reconnection': reconnection.toMap(),
      'idle_disconnect': idleDisconnect.toMap(),
    };
  }
}

/// Reconnection configuration
class ReconnectionConfig {
  final bool enabled;
  final int maxAttempts;
  final int baseDelayMs;
  final int maxDelayMs;
  final bool exponentialBackoff;

  const ReconnectionConfig({
    this.enabled = true,
    this.maxAttempts = 5,
    this.baseDelayMs = 1000,
    this.maxDelayMs = 30000,
    this.exponentialBackoff = true,
  });

  factory ReconnectionConfig.fromMap(Map<String, dynamic> map) {
    return ReconnectionConfig(
      enabled: map['enabled'] ?? true,
      maxAttempts: map['max_attempts'] ?? 5,
      baseDelayMs: map['base_delay_ms'] ?? 1000,
      maxDelayMs: map['max_delay_ms'] ?? 30000,
      exponentialBackoff: map['exponential_backoff'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'max_attempts': maxAttempts,
      'base_delay_ms': baseDelayMs,
      'max_delay_ms': maxDelayMs,
      'exponential_backoff': exponentialBackoff,
    };
  }
}

/// Idle disconnect configuration
class IdleDisconnectConfig {
  final bool enabled;
  final int timeoutMs;
  final String behavior;

  const IdleDisconnectConfig({
    this.enabled = false,
    this.timeoutMs = 900000,
    this.behavior = 'disconnect',
  });

  factory IdleDisconnectConfig.fromMap(Map<String, dynamic> map) {
    return IdleDisconnectConfig(
      enabled: map['enabled'] ?? false,
      timeoutMs: map['timeout_ms'] ?? 900000,
      behavior: map['behavior'] ?? 'disconnect',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'timeout_ms': timeoutMs,
      'behavior': behavior,
    };
  }
}

/// Voice configuration
class VoiceConfig {
  final bool enabled;
  final String mode;
  final bool enableBargeIn;
  final bool enableVad;
  final int sampleRate;
  final int channels;

  const VoiceConfig({
    this.enabled = true,
    this.mode = 'pipeline',
    this.enableBargeIn = true,
    this.enableVad = true,
    this.sampleRate = 16000,
    this.channels = 1,
  });

  factory VoiceConfig.fromMap(Map<String, dynamic> map) {
    return VoiceConfig(
      enabled: map['enabled'] ?? true,
      mode: map['mode'] ?? 'pipeline',
      enableBargeIn: map['enable_barge_in'] ?? true,
      enableVad: map['enable_vad'] ?? true,
      sampleRate: map['sample_rate'] ?? 16000,
      channels: map['channels'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'mode': mode,
      'enable_barge_in': enableBargeIn,
      'enable_vad': enableVad,
      'sample_rate': sampleRate,
      'channels': channels,
    };
  }
}

/// Chat configuration
class ChatConfig {
  final int maxMessagesLocal;
  final int historyPageSize;
  final int maxHistoryPages;
  final bool enableTypingIndicator;
  final bool enableThoughts;
  final bool enableFileUpload;
  final int maxFileSizeMb;
  final List<String> allowedFileTypes;

  const ChatConfig({
    this.maxMessagesLocal = 10000,
    this.historyPageSize = 200,
    this.maxHistoryPages = 20,
    this.enableTypingIndicator = true,
    this.enableThoughts = false,
    this.enableFileUpload = true,
    this.maxFileSizeMb = 10,
    this.allowedFileTypes = const ['image/jpeg', 'image/png', 'application/pdf'],
  });

  factory ChatConfig.fromMap(Map<String, dynamic> map) {
    return ChatConfig(
      maxMessagesLocal: map['max_messages_local'] ?? 10000,
      historyPageSize: map['history_page_size'] ?? 200,
      maxHistoryPages: map['max_history_pages'] ?? 20,
      enableTypingIndicator: map['enable_typing_indicator'] ?? true,
      enableThoughts: map['enable_thoughts'] ?? false,
      enableFileUpload: map['enable_file_upload'] ?? true,
      maxFileSizeMb: map['max_file_size_mb'] ?? 10,
      allowedFileTypes: map['allowed_file_types'] != null
          ? List<String>.from(map['allowed_file_types'])
          : const ['image/jpeg', 'image/png', 'application/pdf'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'max_messages_local': maxMessagesLocal,
      'history_page_size': historyPageSize,
      'max_history_pages': maxHistoryPages,
      'enable_typing_indicator': enableTypingIndicator,
      'enable_thoughts': enableThoughts,
      'enable_file_upload': enableFileUpload,
      'max_file_size_mb': maxFileSizeMb,
      'allowed_file_types': allowedFileTypes,
    };
  }
}

/// Storage configuration
class StorageConfig {
  final bool enableMessageCache;
  final bool enableOfflineQueue;
  final String secureStorageKeyPrefix;
  final int cacheTtlDays;

  const StorageConfig({
    this.enableMessageCache = true,
    this.enableOfflineQueue = true,
    this.secureStorageKeyPrefix = 'artemis_sdk',
    this.cacheTtlDays = 30,
  });

  factory StorageConfig.fromMap(Map<String, dynamic> map) {
    return StorageConfig(
      enableMessageCache: map['enable_message_cache'] ?? true,
      enableOfflineQueue: map['enable_offline_queue'] ?? true,
      secureStorageKeyPrefix: map['secure_storage_key_prefix'] ?? 'artemis_sdk',
      cacheTtlDays: map['cache_ttl_days'] ?? 30,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enable_message_cache': enableMessageCache,
      'enable_offline_queue': enableOfflineQueue,
      'secure_storage_key_prefix': secureStorageKeyPrefix,
      'cache_ttl_days': cacheTtlDays,
    };
  }
}

/// Performance configuration
class PerformanceConfig {
  final bool lowPowerMode;
  final bool reducedAnimations;
  final double imageQuality;
  final bool enablePagination;
  final bool prefetchAvatars;

  const PerformanceConfig({
    this.lowPowerMode = false,
    this.reducedAnimations = false,
    this.imageQuality = 0.8,
    this.enablePagination = true,
    this.prefetchAvatars = true,
  });

  factory PerformanceConfig.fromMap(Map<String, dynamic> map) {
    return PerformanceConfig(
      lowPowerMode: map['low_power_mode'] ?? false,
      reducedAnimations: map['reduced_animations'] ?? false,
      imageQuality: (map['image_quality'] ?? 0.8).toDouble(),
      enablePagination: map['enable_pagination'] ?? true,
      prefetchAvatars: map['prefetch_avatars'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'low_power_mode': lowPowerMode,
      'reduced_animations': reducedAnimations,
      'image_quality': imageQuality,
      'enable_pagination': enablePagination,
      'prefetch_avatars': prefetchAvatars,
    };
  }
}

/// Accessibility configuration
class AccessibilityConfig {
  final bool screenReaderEnabled;
  final double minTouchTargetSize;
  final bool highContrastMode;
  final bool hapticFeedback;

  const AccessibilityConfig({
    this.screenReaderEnabled = true,
    this.minTouchTargetSize = 44.0,
    this.highContrastMode = false,
    this.hapticFeedback = true,
  });

  factory AccessibilityConfig.fromMap(Map<String, dynamic> map) {
    return AccessibilityConfig(
      screenReaderEnabled: map['screen_reader_enabled'] ?? true,
      minTouchTargetSize: (map['min_touch_target_size'] ?? 44.0).toDouble(),
      highContrastMode: map['high_contrast_mode'] ?? false,
      hapticFeedback: map['haptic_feedback'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'screen_reader_enabled': screenReaderEnabled,
      'min_touch_target_size': minTouchTargetSize,
      'high_contrast_mode': highContrastMode,
      'haptic_feedback': hapticFeedback,
    };
  }
}

/// Theme configuration
class ThemeConfig {
  final String primaryColor;
  final String textColor;
  final String backgroundColor;
  final String surfaceColor;
  final double borderRadius;
  final String fontFamily;
  final bool darkMode;

  const ThemeConfig({
    this.primaryColor = '#0066FF',
    this.textColor = '#1A1A1A',
    this.backgroundColor = '#FFFFFF',
    this.surfaceColor = '#F5F5F5',
    this.borderRadius = 12.0,
    this.fontFamily = 'System',
    this.darkMode = false,
  });

  factory ThemeConfig.fromMap(Map<String, dynamic> map) {
    return ThemeConfig(
      primaryColor: map['primary_color'] ?? '#0066FF',
      textColor: map['text_color'] ?? '#1A1A1A',
      backgroundColor: map['background_color'] ?? '#FFFFFF',
      surfaceColor: map['surface_color'] ?? '#F5F5F5',
      borderRadius: (map['border_radius'] ?? 12.0).toDouble(),
      fontFamily: map['font_family'] ?? 'System',
      darkMode: map['dark_mode'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'primary_color': primaryColor,
      'text_color': textColor,
      'background_color': backgroundColor,
      'surface_color': surfaceColor,
      'border_radius': borderRadius,
      'font_family': fontFamily,
      'dark_mode': darkMode,
    };
  }
}

/// Debug configuration
class DebugConfig {
  final bool enabled;
  final String logLevel;
  final bool logNetworkRequests;
  final bool logWebsocketMessages;

  const DebugConfig({
    this.enabled = false,
    this.logLevel = 'info',
    this.logNetworkRequests = false,
    this.logWebsocketMessages = false,
  });

  factory DebugConfig.fromMap(Map<String, dynamic> map) {
    return DebugConfig(
      enabled: map['enabled'] ?? false,
      logLevel: map['log_level'] ?? 'info',
      logNetworkRequests: map['log_network_requests'] ?? false,
      logWebsocketMessages: map['log_websocket_messages'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'log_level': logLevel,
      'log_network_requests': logNetworkRequests,
      'log_websocket_messages': logWebsocketMessages,
    };
  }
}

/// Feature flags configuration
class FeaturesConfig {
  final bool enableRichContent;
  final bool enableMarkdown;
  final bool enableCarousel;
  final bool enableKpiCards;
  final bool enableForms;
  final bool enableQuickReplies;
  final bool enableVoice;
  final bool enableFileUpload;
  final bool enableFeedback;
  final bool enableActivityUpdates;

  const FeaturesConfig({
    this.enableRichContent = true,
    this.enableMarkdown = true,
    this.enableCarousel = true,
    this.enableKpiCards = true,
    this.enableForms = true,
    this.enableQuickReplies = true,
    this.enableVoice = true,
    this.enableFileUpload = true,
    this.enableFeedback = true,
    this.enableActivityUpdates = false,
  });

  factory FeaturesConfig.fromMap(Map<String, dynamic> map) {
    return FeaturesConfig(
      enableRichContent: map['enable_rich_content'] ?? true,
      enableMarkdown: map['enable_markdown'] ?? true,
      enableCarousel: map['enable_carousel'] ?? true,
      enableKpiCards: map['enable_kpi_cards'] ?? true,
      enableForms: map['enable_forms'] ?? true,
      enableQuickReplies: map['enable_quick_replies'] ?? true,
      enableVoice: map['enable_voice'] ?? true,
      enableFileUpload: map['enable_file_upload'] ?? true,
      enableFeedback: map['enable_feedback'] ?? true,
      enableActivityUpdates: map['enable_activity_updates'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enable_rich_content': enableRichContent,
      'enable_markdown': enableMarkdown,
      'enable_carousel': enableCarousel,
      'enable_kpi_cards': enableKpiCards,
      'enable_forms': enableForms,
      'enable_quick_replies': enableQuickReplies,
      'enable_voice': enableVoice,
      'enable_file_upload': enableFileUpload,
      'enable_feedback': enableFeedback,
      'enable_activity_updates': enableActivityUpdates,
    };
  }
}

/// Localization configuration
class LocalizationConfig {
  final String defaultLocale;
  final List<String> supportedLocales;
  final String fallbackLocale;

  const LocalizationConfig({
    this.defaultLocale = 'en',
    this.supportedLocales = const ['en', 'es', 'fr'],
    this.fallbackLocale = 'en',
  });

  factory LocalizationConfig.fromMap(Map<String, dynamic> map) {
    return LocalizationConfig(
      defaultLocale: map['default_locale'] ?? 'en',
      supportedLocales: map['supported_locales'] != null
          ? List<String>.from(map['supported_locales'])
          : const ['en', 'es', 'fr'],
      fallbackLocale: map['fallback_locale'] ?? 'en',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'default_locale': defaultLocale,
      'supported_locales': supportedLocales,
      'fallback_locale': fallbackLocale,
    };
  }
}

/// Security configuration
class SecurityConfig {
  final bool enforceTls;
  final bool validateCertificates;
  final bool enableCertificatePinning;
  final List<String> certificatePins;

  const SecurityConfig({
    this.enforceTls = true,
    this.validateCertificates = true,
    this.enableCertificatePinning = false,
    this.certificatePins = const [],
  });

  factory SecurityConfig.fromMap(Map<String, dynamic> map) {
    return SecurityConfig(
      enforceTls: map['enforce_tls'] ?? true,
      validateCertificates: map['validate_certificates'] ?? true,
      enableCertificatePinning: map['enable_certificate_pinning'] ?? false,
      certificatePins: map['certificate_pins'] != null
          ? List<String>.from(map['certificate_pins'])
          : const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enforce_tls': enforceTls,
      'validate_certificates': validateCertificates,
      'enable_certificate_pinning': enableCertificatePinning,
      'certificate_pins': certificatePins,
    };
  }
}

/// Analytics configuration
class AnalyticsConfig {
  final bool enabled;
  final String? provider;
  final List<String> trackEvents;

  const AnalyticsConfig({
    this.enabled = false,
    this.provider,
    this.trackEvents = const [],
  });

  factory AnalyticsConfig.fromMap(Map<String, dynamic> map) {
    return AnalyticsConfig(
      enabled: map['enabled'] ?? false,
      provider: map['provider'],
      trackEvents: map['track_events'] != null
          ? List<String>.from(map['track_events'])
          : const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'provider': provider,
      'track_events': trackEvents,
    };
  }
}
