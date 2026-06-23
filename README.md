# Artemis Flutter UI SDK

Flutter plugin for embedding AI agent chat in iOS and Android apps. Provides a **built-in chat UI** (status bar, bubbles, markdown, carousel, typing indicator, input) and a **one-line launch API**.

**WebSocket / session / messaging** is delegated to [AgentSocketFlutterPlugin](https://github.com/SudheerJa-Kore/AgentSocketFlutterPlugin) (`artemis_flutter_socket_sdk`). This package adds configuration helpers and the chat UI layer.

| Document | Description |
|----------|-------------|
| [HLD.md](./HLD.md) | High-level architecture, context, data flows |
| [LLD.md](./LLD.md) | Classes, sequences, module map, wire protocol |
| [example/](./example/) | Minimal host app (one button) |

---

## Features

- **One-button chat** — `AgentChatUI.open(context, …)`
- **Built-in UI** — status bar, message bubbles, markdown, carousel cards, typing indicator, input, reconnect
- **Inline or YAML config** — `createDefault()` or `assets/sdk_configurations.yaml`
- **WebSocket chat** — streaming, history, auto-reconnect (via socket plugin)
- **Channel support** — optional `channelId` in configuration
- **Rich content** — horizontal carousel cards with images and external links (`features.enable_carousel`)
- **iOS & Android** — Flutter 3.3+, Dart 3.12+

---

## Architecture (summary)

```
Host App (example)
       │
       ▼
artemis_flutter_ui_sdk     ← UI + SDKConfigurationLoader
       │
       ▼
artemis_flutter_socket_sdk       ← AgentSDK, SessionManager, ChatClient
       │
       ▼
Agent Platform Runtime (HTTPS + WSS)
```

See [HLD.md](./HLD.md) for diagrams and component detail.

---

## Installation

```yaml
# your_app/pubspec.yaml
dependencies:
  artemis_flutter_ui_sdk:
    path: ../artemis_flutter_ui_sdk
```

```bash
flutter pub get
```

> **iOS note:** The plugin folder must be named `artemis_flutter_ui_sdk` (same as the pubspec `name`) for Swift Package Manager. See [LLD §10](./LLD.md#10-build--spm-constraint).

---

## Quick Start

### Option A — Inline config (recommended)

```dart
import 'package:artemis_flutter_ui_sdk/artemis_flutter_ui_sdk.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(home: HomeScreen()));
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
              projectId: 'your-project-id',
              endpoint: 'https://your-runtime.example.com',
              apiKey: 'pk_your_public_key',
              channelId: 'your-channel-id', // optional
            ),
            title: 'Agent Chat',
          ),
          child: const Text('Open Chat'),
        ),
      ),
    );
  }
}
```

The SDK initializes `AgentSDK`, opens the WebSocket, and presents the full chat screen.

### Option B — YAML assets

1. Create `assets/sdk_configurations.yaml`:

```yaml
artemis_flutter_ui_sdk:
  environment: dev
  connection:
    project_id: "your-project-id"
    api_key: "pk_your_public_key"
    endpoint: "https://your-runtime.example.com"
  channel:
    channel_id: "your-channel-id"
```

2. Register the asset in your app `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/sdk_configurations.yaml
```

3. Open chat without inline config:

```dart
AgentChatUI.open(context, title: 'Agent Chat');
```

---

## Run the Example

```bash
cd example
flutter pub get
flutter run
```

The example app shows a single **Connect to Kore AI Agent** button that opens the SDK chat UI with inline configuration.

---

## API Reference

### `AgentChatUI`

| Method | Description |
|--------|-------------|
| `AgentChatUI.open(context, {configuration, environment, configAssetPath, runtimeUserContext, title})` | Push full-screen chat; handles init, connect, dispose |
| `AgentChatUI.demoApp({configuration, title, chatTitle})` | Wrap a minimal demo `MaterialApp` |

### `SDKConfigurationLoader`

| Method | Description |
|--------|-------------|
| `load({environment, customPath})` | Load and validate YAML from assets |
| `createDefault({projectId, endpoint, apiKey, channelId, channelName})` | Build inline dev configuration |

### `AgentSDK` (from socket plugin)

| Method | Description |
|--------|-------------|
| `AgentSDK.createWithConfig(config)` | Create SDK with explicit configuration |
| `connect()` | Bootstrap token, open WebSocket, return session ID |
| `sendMessage(text)` | Send user message |
| `getMessages()` | Local conversation history |
| `isConnected()` / `getSessionId()` | Connection state |
| `disconnect()` / `dispose()` | Teardown |

Use `AgentSDK` directly when building a **custom UI** instead of `AgentChatUI`.

### Events

```dart
sdk.events.listen((event) {
  if (event is SDKConnectedEvent) { /* connected */ }
  if (event is SDKDisconnectedEvent) { /* disconnected */ }
  if (event is SDKReconnectingEvent) { /* reconnecting */ }
  if (event is SDKErrorEvent) { /* error */ }
});

sdk.chatEvents.listen((event) {
  if (event is MessageReceivedEvent) { /* new message */ }
  if (event is MessageChunkEvent) { /* streaming chunk */ }
  if (event is TypingIndicatorEvent) { /* typing on/off */ }
});
```

Full event list: [LLD.md](./LLD.md) and [AgentSocketFlutterPlugin](https://github.com/SudheerJa-Kore/AgentSocketFlutterPlugin).

---

## Project Layout

```
artemis_flutter-ui-sdk/
├── artemis_flutter_ui_sdk/   # Plugin (pubspec name = folder name)
│   ├── lib/
│   │   ├── artemis_flutter_ui_sdk.dart
│   │   └── src/
│   │       ├── config/sdk_configuration_loader.dart
│   │       └── ui/               # Chat UI widgets
│   ├── android/
│   ├── ios/
│   └── test/
├── example/                      # Reference host app
├── HLD.md
├── LLD.md
└── README.md
```

---

## Configuration Sections

| Section | Description |
|---------|-------------|
| `connection` | `project_id`, `api_key`, `endpoint` |
| `channel` | `channel_id`, `channel_name` |
| `websocket` | Reconnection, idle disconnect |
| `chat` | History, typing, file upload limits |
| `theme` | Colors, border radius |
| `debug` | Logging levels |
| `features` | `enable_markdown`, `enable_carousel`, voice flags, etc. |
| `security` | TLS enforcement |

Complete sample: [example/assets/sdk_configurations.yaml](./example/assets/sdk_configurations.yaml)

---

## Requirements

| | Version |
|---|---------|
| Dart SDK | >= 3.12.2 |
| Flutter | >= 3.3.0 |
| iOS | 13.0+ |
| Android | API 21+ |

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Xcode SPM identity mismatch | Ensure plugin path folder is `artemis_flutter_ui_sdk` — [LLD §10](./LLD.md#10-build--spm-constraint) |
| Config not loading | Verify asset path in pubspec; YAML root key is `artemis_flutter_ui_sdk` |
| Connection fails | Check `project_id`, `api_key`, `endpoint`; enable `debug.enabled: true` |
| Build errors after pull | `flutter clean && flutter pub get` in `example/` |

---

## License

MIT
