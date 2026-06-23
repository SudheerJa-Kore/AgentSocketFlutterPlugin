import 'package:artemis_flutter_socket_sdk/artemis_flutter_socket_sdk.dart';
import 'package:flutter/material.dart';
import 'agent_chat_screen.dart';
import 'theme/color_utils.dart';

/// High-level API to launch the built-in Agent Platform chat UI.
///
/// The SDK handles initialization, WebSocket connection, and the full chat
/// experience (status bar, message bubbles, input).
///
/// ```dart
/// // From YAML config in host app assets
/// ElevatedButton(
///   onPressed: () => AgentChatUI.open(context),
///   child: const Text('Open Chat'),
/// )
///
/// // Or with explicit configuration
/// AgentChatUI.open(
///   context,
///   configuration: SDKConfigurationLoader.createDefault(
///     projectId: 'xxx',
///     endpoint: 'https://runtime.example.com',
///     apiKey: 'pk_xxx',
///   ),
/// );
/// ```
class AgentChatUI {
  AgentChatUI._();

  /// Opens the full-screen chat UI.
  ///
  /// Provide [configuration] for programmatic setup, or omit it to load from
  /// `assets/sdk_configurations.yaml` in the host app.
  static Future<void> open(
    BuildContext context, {
    SDKConfiguration? configuration,
    String? environment,
    String? configAssetPath,
    SDKUserContext? runtimeUserContext,
    String title = 'Chat',
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => AgentChatScreen(
          configuration: configuration,
          environment: environment,
          configAssetPath: configAssetPath,
          runtimeUserContext: runtimeUserContext,
          title: title,
        ),
      ),
    );
  }

  /// Builds a [MaterialApp] themed from SDK configuration for quick demos.
  static Widget demoApp({
    required SDKConfiguration configuration,
    String title = 'Artemis UI SDK',
    String chatTitle = 'Chat',
  }) {
    return MaterialApp(
      title: title,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: colorFromHex(configuration.theme.primaryColor),
        ),
        useMaterial3: true,
      ),
      home: _DemoHome(
        configuration: configuration,
        chatTitle: chatTitle,
      ),
    );
  }
}

class _DemoHome extends StatelessWidget {
  final SDKConfiguration configuration;
  final String chatTitle;

  const _DemoHome({
    required this.configuration,
    required this.chatTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Artemis UI SDK')),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () => AgentChatUI.open(
            context,
            configuration: configuration,
            title: chatTitle,
          ),
          icon: const Icon(Icons.chat),
          label: const Text('Open Chat'),
        ),
      ),
    );
  }
}
