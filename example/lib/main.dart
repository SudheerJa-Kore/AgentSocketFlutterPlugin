import 'package:artemis_flutter_ui_sdk/artemis_flutter_ui_sdk.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => AgentChatUI.open(
            context,
            configuration: SDKConfigurationLoader.createDefault(
              // projectId: '019ebab0-737a-7661-9c02-d8d416320a1c',
              // endpoint: 'https://agents-dev.kore.ai',
              // apiKey: 'pk_3721dc52d9b95534fa402c680387afee04b9c9b569a9c508',
              // channelId: '019eee30-53a9-7961-afb1-e9303a8c989f',
              projectId: '019ddd5e-4a24-769b-ac26-4d55bc99fdb8',
              endpoint: 'https://agents-dev.kore.ai',
              apiKey: 'pk_29fd5cb101a5d1323b8f0e2b811a9f926b4bac3bdaf21f99',
              channelId: '019eef69-1b31-7111-a6ee-2122763cabc7',
            ),
            title: 'Agent Chat',
          ),
          child: const Text('Connect to Kore AI Agent'),
        ),
      ),
    );
  }
}
