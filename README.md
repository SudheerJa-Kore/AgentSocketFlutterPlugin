# Artemis Flutter SDK

A production-ready Flutter plugin for integrating Artemis's AI agent capabilities into iOS and Android applications.

## Features

- ✅ **Text Chat**: Real-time messaging with AI agents
- ✅ **Configuration-First**: All settings loaded from YAML configuration
- ✅ **Event Streaming**: Listen to SDK and chat events
- ✅ **Message History**: Full conversation management
- ✅ **Environment Support**: Dev/staging/prod configurations
- ✅ **Type-Safe**: Strongly typed Dart API
- ✅ **Platform Native**: Supports iOS and Android

## Installation

Add this to your package's `pubspec.yaml`:

```yaml
dependencies:
  artemis_flutter_socket_sdk:
    path: ../path/to/artemis_flutter_socket_sdk  # or from pub.dev when published
```

Then run:

```bash
flutter pub get
```

## Quick Start

### 1. Create Configuration File

Create `assets/sdk_configurations.yaml` in your Flutter app:

```yaml
artemis_sdk:
  environment: dev
  connection:
    project_id: "your-project-id"
    api_key: "pk_your_api_key"
    endpoint: "https://runtime.example.com"
  # ... see example/assets/sdk_configurations.yaml for all options
```

### 2. Add Assets to pubspec.yaml

```yaml
flutter:
  assets:
    - assets/sdk_configurations.yaml
```

### 3. Initialize SDK

```dart
import 'package:artemis_flutter_socket_sdk/artemis_flutter_socket_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SDK with configuration from assets
  final sdk = await AgentSDK.initialize();
  
  // Connect to platform
  await sdk.connect();
  
  runApp(MyApp(sdk: sdk));
}
```

### 4. Use SDK in Your App

```dart
class ChatScreen extends StatefulWidget {
  final AgentSDK sdk;
  
  const ChatScreen({required this.sdk});
  
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  void initState() {
    super.initState();
    
    // Listen to chat events
    widget.sdk.chatEvents.listen((event) {
      if (event is MessageReceivedEvent) {
        setState(() {
          // Update UI with new message
        });
      }
    });
  }
  
  Future<void> _sendMessage(String text) async {
    await widget.sdk.sendMessage(text);
  }
  
  @override
  Widget build(BuildContext context) {
    final messages = widget.sdk.getMessages();
    // Build your UI with messages
  }
}
```

## Configuration

The SDK uses a YAML configuration file to control all behavior. This makes it easy to switch between environments without code changes.

### Required Fields

```yaml
artemis_sdk:
  connection:
    project_id: "your-project-id"      # REQUIRED
    api_key: "pk_your_api_key"         # REQUIRED (or bootstrap_token)
    endpoint: "https://runtime.example.com"  # REQUIRED
```

### Environment-Specific Overrides

Create environment-specific files that override base configuration:

```
assets/
  ├── sdk_configurations.yaml         # Base configuration
  ├── sdk_configurations.dev.yaml     # Development overrides
  ├── sdk_configurations.staging.yaml # Staging overrides
  └── sdk_configurations.prod.yaml    # Production overrides
```

Load specific environment:

```dart
final sdk = await AgentSDK.initialize(
  environment: 'prod',  // Loads sdk_configurations.prod.yaml
);
```

### Configuration Sections

| Section | Description |
|---------|-------------|
| `connection` | Project ID, API key, endpoint |
| `websocket` | Reconnection settings, idle disconnect |
| `voice` | Voice mode, barge-in, sample rate |
| `chat` | File upload, typing indicators, history |
| `storage` | Message cache, offline queue |
| `theme` | Colors, fonts, border radius |
| `debug` | Logging levels, request logging |
| `features` | Feature flags for all capabilities |
| `security` | TLS enforcement, certificate pinning |

See [example/assets/sdk_configurations.yaml](example/assets/sdk_configurations.yaml) for complete configuration.

## API Reference

### AgentSDK

Main SDK entry point.

```dart
// Initialize
final sdk = await AgentSDK.initialize();

// Connect
await sdk.connect();

// Send message
await sdk.sendMessage('Hello!');

// Get messages
final messages = sdk.getMessages();

// Clear history
sdk.clearHistory();

// Check connection
final isConnected = sdk.isConnected();

// Get session ID
final sessionId = sdk.getSessionId();

// Disconnect
sdk.disconnect();

// Dispose
await sdk.dispose();
```

### Events

Listen to SDK and chat events:

```dart
// SDK events
sdk.events.listen((event) {
  if (event is SDKConnectedEvent) {
    print('Connected: ${event.sessionId}');
  } else if (event is SDKDisconnectedEvent) {
    print('Disconnected: ${event.reason}');
  } else if (event is SDKErrorEvent) {
    print('Error: ${event.error}');
  }
});

// Chat events
sdk.chatEvents.listen((event) {
  if (event is MessageReceivedEvent) {
    print('Message: ${event.message.content}');
  } else if (event is TypingIndicatorEvent) {
    print('Typing: ${event.isTyping}');
  }
});
```

### Configuration Access

Access loaded configuration:

```dart
final config = sdk.config;

print('Environment: ${config.environment}');
print('Endpoint: ${config.connection.endpoint}');
print('Voice enabled: ${config.features.enableVoice}');
print('Debug mode: ${config.debug.enabled}');
```

## Example App

Run the example app to see the SDK in action:

```bash
cd example
flutter run
```

The example demonstrates:
- SDK initialization and connection
- Sending and receiving messages
- Event handling
- Configuration display
- UI integration

## Architecture

The SDK follows a three-layer architecture:

```
┌─────────────────────────────────────┐
│  Host Application                    │
│  ├─ assets/sdk_configurations.yaml  │
│  └─ main.dart (SDK initialization)  │
└──────────────┬──────────────────────┘
               │
    ┌──────────┴──────────┐
    │ Artemis Flutter SDK  │
    │                      │
    │  Configuration Layer │
    │  ├─ sdk_configuration.dart
    │  └─ sdk_configuration_loader.dart
    │                      │
    │  Core SDK Layer      │
    │  ├─ agent_sdk.dart   │
    │  ├─ models/          │
    │  ├─ events/          │
    │  └─ utils/           │
    │                      │
    │  Platform Layer      │
    │  ├─ iOS (Swift)      │
    │  └─ Android (Kotlin) │
    └──────────────────────┘
```

## Development

### Setup

```bash
# Get dependencies
flutter pub get

# Run analysis
flutter analyze

# Run tests
flutter test

# Generate documentation
dart doc .
```

### Adding Features

1. Add configuration options to `sdk_configuration.dart`
2. Update `sdk_configuration_loader.dart` validation
3. Implement feature logic in appropriate module
4. Add events if needed
5. Update example app to demonstrate feature
6. Add tests

### Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run example app tests
cd example
flutter test
```

## Platform Support

| Platform | Version |
|----------|---------|
| iOS | 12.0+ |
| Android | API 21+ (Android 5.0) |

## Requirements

- Dart SDK: >=3.12.2
- Flutter: >=3.3.0

## Documentation

- [CLAUDE.md](CLAUDE.md) - Development guide for AI assistants
- [example/](example/) - Full working example
- [API Documentation](https://pub.dev/documentation/artemis_flutter_socket_sdk/latest/) - Generated docs

## Troubleshooting

### Configuration not loading

1. Verify file exists in `assets/` folder
2. Check it's added to `pubspec.yaml` under `flutter.assets`
3. Run `flutter clean` and rebuild
4. Validate YAML syntax

### Connection fails

1. Verify endpoint is reachable
2. Check project_id and api_key are correct
3. Enable debug logging: `debug.enabled: true`
4. Check SDK logs for detailed errors

### Build errors

1. Run `flutter clean`
2. Run `flutter pub get`
3. Check Flutter version matches requirements

## License

[Add your license here]

## Support

For issues and questions:
- GitHub Issues: [your-repo-url]
- Documentation: [your-docs-url]
- Email: [your-email]

## Roadmap

- [ ] Voice interaction support
- [ ] Rich content rendering
- [ ] File upload support
- [ ] Offline message queue
- [ ] Push notifications
- [ ] WebRTC audio
- [ ] Multi-session management

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## Acknowledgments

Built for the Artemis by [Your Team]
