# ABL Platform Flutter SDK - Quick Reference

## Installation

```yaml
# pubspec.yaml
dependencies:
  artemis_flutter_socket_sdk: ^0.0.1
  
flutter:
  assets:
    - assets/sdk_configurations.yaml
```

## Configuration

```yaml
# assets/sdk_configurations.yaml
artemis_sdk:
  connection:
    project_id: "your-project-id"
    api_key: "pk_your_key"
    endpoint: "https://runtime.example.com"
```

## Initialization

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sdk = await AgentSDK.initialize();
  await sdk.connect();
  runApp(MyApp(sdk: sdk));
}
```

## Core API

### Send Message

```dart
await sdk.sendMessage('Hello!');
```

### Get Messages

```dart
final messages = sdk.getMessages();
```

### Clear History

```dart
sdk.clearHistory();
```

### Check Connection

```dart
if (sdk.isConnected()) {
  // Connected
}
```

### Get Session ID

```dart
final sessionId = sdk.getSessionId();
```

### Disconnect

```dart
sdk.disconnect();
```

### Dispose

```dart
await sdk.dispose();
```

## Events

### Listen to SDK Events

```dart
sdk.events.listen((event) {
  if (event is SDKConnectedEvent) {
    print('Connected: ${event.sessionId}');
  } else if (event is SDKDisconnectedEvent) {
    print('Disconnected: ${event.reason}');
  } else if (event is SDKErrorEvent) {
    print('Error: ${event.error}');
  }
});
```

### Listen to Chat Events

```dart
sdk.chatEvents.listen((event) {
  if (event is MessageReceivedEvent) {
    print('Message: ${event.message.content}');
  } else if (event is TypingIndicatorEvent) {
    print('Typing: ${event.isTyping}');
  } else if (event is ThoughtEvent) {
    print('Thought: ${event.content}');
  }
});
```

## Configuration Access

```dart
// Get loaded configuration
final config = sdk.config;

// Connection settings
print(config.connection.projectId);
print(config.connection.endpoint);

// Feature flags
if (config.features.enableVoice) { }
if (config.features.enableFileUpload) { }

// Debug settings
if (config.debug.enabled) { }
print(config.debug.logLevel);

// Theme settings
print(config.theme.primaryColor);
print(config.theme.borderRadius);
```

## Models

### Message

```dart
class Message {
  final String id;
  final MessageRole role;  // user, assistant, system, thought
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final List<String>? attachmentIds;
}
```

### SDKUserContext

```dart
final context = SDKUserContext(
  userId: 'user_123',
  customAttributes: {
    'plan': 'premium',
    'region': 'us-east-1',
  },
);
```

## Environment Switching

```dart
// Development
final sdk = await AgentSDK.initialize(environment: 'dev');

// Staging
final sdk = await AgentSDK.initialize(environment: 'staging');

// Production
final sdk = await AgentSDK.initialize(environment: 'prod');
```

## Error Handling

```dart
try {
  await sdk.sendMessage('Hello');
} catch (e) {
  if (e is SDKConfigurationException) {
    // Configuration error
  } else {
    // Other error
  }
}
```

## Testing

### Create Test SDK

```dart
final testConfig = SDKConfigurationLoader.createDefault(
  projectId: 'test-project',
  endpoint: 'http://localhost:3112',
  apiKey: 'pk_test_key',
);

final sdk = AgentSDK.createWithConfig(testConfig);
```

## Configuration Sections

| Section | Key Fields |
|---------|-----------|
| `connection` | project_id, api_key, endpoint |
| `websocket` | reconnection, idle_disconnect |
| `voice` | enabled, mode, enable_barge_in |
| `chat` | enable_file_upload, max_file_size_mb |
| `storage` | enable_message_cache, enable_offline_queue |
| `theme` | primary_color, text_color, border_radius |
| `debug` | enabled, log_level |
| `features` | enable_voice, enable_rich_content |
| `security` | enforce_tls, validate_certificates |

## Common Patterns

### Basic Chat UI

```dart
class ChatScreen extends StatefulWidget {
  final AgentSDK sdk;
  const ChatScreen({required this.sdk});
}

class _ChatScreenState extends State<ChatScreen> {
  List<Message> _messages = [];
  
  @override
  void initState() {
    super.initState();
    _messages = widget.sdk.getMessages();
    
    widget.sdk.chatEvents.listen((event) {
      if (event is MessageReceivedEvent) {
        setState(() => _messages = widget.sdk.getMessages());
      }
    });
  }
  
  Future<void> _send(String text) async {
    await widget.sdk.sendMessage(text);
  }
}
```

### Connection Status Widget

```dart
Widget buildStatus(BuildContext context) {
  return StreamBuilder<SDKEvent>(
    stream: sdk.events,
    builder: (context, snapshot) {
      if (sdk.isConnected()) {
        return Icon(Icons.check_circle, color: Colors.green);
      }
      return Icon(Icons.warning, color: Colors.orange);
    },
  );
}
```

### Message List

```dart
ListView.builder(
  itemCount: messages.length,
  itemBuilder: (context, index) {
    final message = messages[index];
    final isUser = message.role == MessageRole.user;
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(message.content),
      ),
    );
  },
)
```

## Troubleshooting

### Config not loading
```bash
flutter clean
flutter pub get
# Verify assets/sdk_configurations.yaml exists
# Check pubspec.yaml has assets listed
```

### Connection fails
```yaml
# Enable debug mode
debug:
  enabled: true
  log_level: "debug"
```

### Import error
```dart
import 'package:artemis_flutter_socket_sdk/abl_flutter_sdk.dart';
```

## CLI Commands

```bash
# Development
flutter pub get
flutter analyze
flutter test
flutter run

# Example app
cd example
flutter run

# Build
flutter build apk --release
flutter build ios --release
```

## Links

- [README.md](README.md) - Full documentation
- [GETTING_STARTED.md](GETTING_STARTED.md) - Detailed setup guide
- [CLAUDE.md](CLAUDE.md) - Development guide
- [example/](example/) - Working example app
