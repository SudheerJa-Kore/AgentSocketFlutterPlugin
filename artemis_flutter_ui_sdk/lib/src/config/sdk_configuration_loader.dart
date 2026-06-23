import 'dart:convert';

import 'package:artemis_flutter_socket_sdk/artemis_flutter_socket_sdk.dart';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

/// Configuration loader for Artemis UI SDK.
///
/// Socket/connection types come from [artemis_flutter_socket_sdk](https://github.com/SudheerJa-Kore/AgentSocketFlutterPlugin).
///
/// Loads configuration from host application assets:
/// - `assets/sdk_configurations.yaml` (base config)
/// - `assets/sdk_configurations.{env}.yaml` (environment overrides)
class SDKConfigurationLoader {
  static const String _defaultConfigPath = 'assets/sdk_configurations.yaml';
  static const String _configRootKey = 'artemis_flutter_ui_sdk';

  /// Load configuration from assets.
  static Future<SDKConfiguration> load({
    String? environment,
    String? customPath,
  }) async {
    try {
      final baseConfig = await _loadConfigFile(customPath ?? _defaultConfigPath);

      final env = environment ??
          baseConfig[_configRootKey]?['environment'] ??
          baseConfig['artemis_sdk']?['environment'] ??
          'dev';

      final envConfigPath = 'assets/sdk_configurations.$env.yaml';
      Map<String, dynamic>? envConfig;

      try {
        envConfig = await _loadConfigFile(envConfigPath);
        ArtemisLogger.debug('Loaded environment-specific config for $env');
      } catch (e) {
        ArtemisLogger.debug('No environment-specific config found for $env');
      }

      final mergedConfig = _mergeConfigs(baseConfig, envConfig);
      final sdkConfig = mergedConfig[_configRootKey] ?? mergedConfig['artemis_sdk'];
      if (sdkConfig == null) {
        throw SDKConfigurationException(
          'Configuration must have "$_configRootKey" or "artemis_sdk" root key',
        );
      }

      final config = SDKConfiguration.fromMap(
        Map<String, dynamic>.from(sdkConfig as Map),
      );

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

  static Future<Map<String, dynamic>> _loadConfigFile(String path) async {
    final content = await rootBundle.loadString(path);

    if (path.endsWith('.yaml') || path.endsWith('.yml')) {
      return _yamlToMap(loadYaml(content)) as Map<String, dynamic>;
    }
    if (path.endsWith('.json')) {
      return json.decode(content) as Map<String, dynamic>;
    }
    throw SDKConfigurationException('Unsupported config file format: $path');
  }

  static dynamic _yamlToMap(dynamic yamlDoc) {
    if (yamlDoc is YamlMap) {
      final map = <String, dynamic>{};
      yamlDoc.forEach((key, value) {
        map[key.toString()] = _yamlToMap(value);
      });
      return map;
    }
    if (yamlDoc is YamlList) {
      return yamlDoc.map(_yamlToMap).toList();
    }
    return yamlDoc;
  }

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
          Map<String, dynamic>.from(value),
        );
      } else {
        result[key] = value;
      }
    });
    return result;
  }

  static void _validateConfiguration(SDKConfiguration config) {
    final errors = <String>[];

    if (config.connection.projectId.isEmpty) {
      errors.add('connection.project_id is required and cannot be empty');
    }
    if (config.connection.endpoint.isEmpty) {
      errors.add('connection.endpoint is required and cannot be empty');
    }
    if (!config.connection.endpoint.startsWith('http://') &&
        !config.connection.endpoint.startsWith('https://')) {
      errors.add('connection.endpoint must start with http:// or https://');
    }
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
    if (config.environment == 'prod' &&
        config.connection.endpoint.startsWith('http://')) {
      errors.add('Production environment must use HTTPS endpoint');
    }

    if (errors.isNotEmpty) {
      throw SDKConfigurationException(
        'Configuration validation failed:\n${errors.map((e) => '  - $e').join('\n')}',
      );
    }
  }

  /// Create a default configuration for development and inline setup.
  static SDKConfiguration createDefault({
    required String projectId,
    required String endpoint,
    String? apiKey,
    String? channelId,
    String? channelName,
  }) {
    return SDKConfiguration(
      environment: 'dev',
      connection: ConnectionConfig(
        projectId: projectId,
        endpoint: endpoint,
        apiKey: apiKey,
      ),
      channel: channelId != null || channelName != null
          ? ChannelConfig(
              channelId: channelId,
              channelName: channelName,
            )
          : null,
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
