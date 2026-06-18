import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';
import 'sdk_configuration.dart';
import '../utils/logger.dart';

/// Configuration loader for Artemis SDK
///
/// Loads configuration from host application's assets folder:
/// - assets/sdk_configurations.yaml (base config)
/// - assets/sdk_configurations.{env}.yaml (environment-specific overrides)
class SDKConfigurationLoader {
  static const String _defaultConfigPath = 'assets/sdk_configurations.yaml';

  /// Load configuration from assets
  ///
  /// [environment] - Optional environment override (dev, staging, prod)
  /// [customPath] - Optional custom config file path
  ///
  /// Returns validated [SDKConfiguration]
  /// Throws [SDKConfigurationException] on error
  static Future<SDKConfiguration> load({
    String? environment,
    String? customPath,
  }) async {
    try {
      // Load base configuration
      final baseConfig = await _loadConfigFile(customPath ?? _defaultConfigPath);

      // Determine environment
      final env = environment ??
                   baseConfig['artemis_sdk']?['environment'] ??
                   'dev';

      // Load environment-specific overrides if they exist
      final envConfigPath = 'assets/sdk_configurations.$env.yaml';
      Map<String, dynamic>? envConfig;

      try {
        envConfig = await _loadConfigFile(envConfigPath);
        ArtemisLogger.debug('Loaded environment-specific config for $env');
      } catch (e) {
        // Environment config is optional
        ArtemisLogger.debug('No environment-specific config found for $env');
      }

      // Merge configurations (env overrides base)
      final mergedConfig = _mergeConfigs(baseConfig, envConfig);

      // Parse and validate
      final artemisSdkConfig = mergedConfig['artemis_sdk'];
      if (artemisSdkConfig == null) {
        throw SDKConfigurationException(
          'Configuration must have "artemis_sdk" root key',
        );
      }

      final config = SDKConfiguration.fromMap(artemisSdkConfig);

      // Validate required fields
      _validateConfiguration(config);

      ArtemisLogger.info('SDK configuration loaded successfully', {
        'environment': config.environment,
        'endpoint': config.connection.endpoint,
      });

      return config;
    } catch (e, st) {
      if (e is SDKConfigurationException) {
        rethrow;
      }
      ArtemisLogger.error('Failed to load SDK configuration', e, st);
      throw SDKConfigurationException(
        'Failed to load SDK configuration: ${e.toString()}',
      );
    }
  }

  /// Load configuration file from assets
  static Future<Map<String, dynamic>> _loadConfigFile(String path) async {
    final content = await rootBundle.loadString(path);

    if (path.endsWith('.yaml') || path.endsWith('.yml')) {
      final yamlDoc = loadYaml(content);
      return _yamlToMap(yamlDoc);
    } else if (path.endsWith('.json')) {
      return json.decode(content) as Map<String, dynamic>;
    } else {
      throw SDKConfigurationException('Unsupported config file format: $path');
    }
  }

  /// Convert YAML document to Map or List
  static dynamic _yamlToMap(dynamic yamlDoc) {
    if (yamlDoc is YamlMap) {
      final map = <String, dynamic>{};
      yamlDoc.forEach((key, value) {
        map[key.toString()] = _yamlToMap(value);
      });
      return map;
    } else if (yamlDoc is YamlList) {
      return yamlDoc.map((item) => _yamlToMap(item)).toList();
    } else {
      return yamlDoc;
    }
  }

  /// Deep merge two configuration maps
  ///
  /// [base] - Base configuration
  /// [override] - Configuration to override base (nullable)
  ///
  /// Returns merged configuration
  static Map<String, dynamic> _mergeConfigs(
    Map<String, dynamic> base,
    Map<String, dynamic>? override,
  ) {
    if (override == null) return base;

    final result = Map<String, dynamic>.from(base);

    override.forEach((key, value) {
      if (value is Map && result[key] is Map) {
        result[key] = _mergeConfigs(
          result[key] as Map<String, dynamic>,
          value as Map<String, dynamic>,
        );
      } else {
        result[key] = value;
      }
    });

    return result;
  }

  /// Validate required configuration fields
  ///
  /// Throws [SDKConfigurationException] if validation fails
  static void _validateConfiguration(SDKConfiguration config) {
    final errors = <String>[];

    // Validate project ID
    if (config.connection.projectId.isEmpty) {
      errors.add('connection.project_id is required and cannot be empty');
    }

    // Validate endpoint
    if (config.connection.endpoint.isEmpty) {
      errors.add('connection.endpoint is required and cannot be empty');
    }

    // Validate endpoint format
    if (!config.connection.endpoint.startsWith('http://') &&
        !config.connection.endpoint.startsWith('https://')) {
      errors.add('connection.endpoint must start with http:// or https://');
    }

    // Validate authentication
    if (config.connection.apiKey == null &&
        config.connection.bootstrapToken == null) {
      errors.add(
        'Either connection.api_key or connection.bootstrap_token is required',
      );
    }

    if (config.connection.apiKey != null &&
        config.connection.bootstrapToken != null) {
      errors.add(
        'Cannot specify both connection.api_key and connection.bootstrap_token',
      );
    }

    // Enforce TLS in production
    if (config.environment == 'prod' &&
        config.connection.endpoint.startsWith('http://')) {
      errors.add(
        'Production environment must use HTTPS endpoint',
      );
    }

    // Validate security settings in production
    if (config.environment == 'prod') {
      if (!config.security.enforceTls) {
        ArtemisLogger.warning(
          'TLS enforcement is disabled in production environment',
        );
      }
      if (!config.security.validateCertificates) {
        ArtemisLogger.warning(
          'Certificate validation is disabled in production environment',
        );
      }
    }

    // Validate voice configuration
    if (config.voice.enabled) {
      if (config.voice.mode != 'pipeline' && config.voice.mode != 'realtime') {
        errors.add(
          'voice.mode must be either "pipeline" or "realtime"',
        );
      }
      if (config.voice.sampleRate <= 0) {
        errors.add('voice.sample_rate must be greater than 0');
      }
      if (config.voice.channels <= 0) {
        errors.add('voice.channels must be greater than 0');
      }
    }

    // Validate chat configuration
    if (config.chat.maxFileSizeMb <= 0) {
      errors.add('chat.max_file_size_mb must be greater than 0');
    }

    if (config.chat.allowedFileTypes.isEmpty) {
      ArtemisLogger.warning('chat.allowed_file_types is empty');
    }

    // Validate reconnection configuration
    if (config.websocket.reconnection.enabled) {
      if (config.websocket.reconnection.maxAttempts <= 0) {
        errors.add('websocket.reconnection.max_attempts must be greater than 0');
      }
      if (config.websocket.reconnection.baseDelayMs <= 0) {
        errors.add('websocket.reconnection.base_delay_ms must be greater than 0');
      }
      if (config.websocket.reconnection.maxDelayMs <
          config.websocket.reconnection.baseDelayMs) {
        errors.add(
          'websocket.reconnection.max_delay_ms must be >= base_delay_ms',
        );
      }
    }

    // Throw if there are any errors
    if (errors.isNotEmpty) {
      throw SDKConfigurationException(
        'Configuration validation failed:\n${errors.map((e) => '  - $e').join('\n')}',
      );
    }
  }

  /// Create a default configuration for testing/development
  static SDKConfiguration createDefault({
    required String projectId,
    required String endpoint,
    String? apiKey,
  }) {
    return SDKConfiguration(
      environment: 'dev',
      connection: ConnectionConfig(
        projectId: projectId,
        endpoint: endpoint,
        apiKey: apiKey,
      ),
      websocket: const WebSocketConfig(
        reconnection: ReconnectionConfig(),
        idleDisconnect: IdleDisconnectConfig(),
      ),
      voice: const VoiceConfig(),
      chat: const ChatConfig(),
      storage: const StorageConfig(),
      performance: const PerformanceConfig(),
      accessibility: const AccessibilityConfig(),
      theme: const ThemeConfig(),
      debug: const DebugConfig(enabled: true),
      features: const FeaturesConfig(),
      localization: const LocalizationConfig(),
      security: const SecurityConfig(
        enforceTls: false,
        validateCertificates: false,
      ),
    );
  }
}

/// SDK Configuration exception
class SDKConfigurationException implements Exception {
  final String message;

  SDKConfigurationException(this.message);

  @override
  String toString() => 'SDKConfigurationException: $message';
}
