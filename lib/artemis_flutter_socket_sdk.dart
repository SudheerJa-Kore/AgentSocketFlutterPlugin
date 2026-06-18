/// Artemis Flutter SDK
///
/// A production-ready Flutter SDK for integrating Artemis's AI agent
/// capabilities into iOS and Android applications.
///
/// Features:
/// - Text chat with streaming support
/// - Voice interactions (WebRTC)
/// - Rich content rendering
/// - File uploads
/// - Offline support
/// - Configurable via YAML
library;

import 'artemis_flutter_socket_sdk_platform_interface.dart';

// Core SDK
export 'src/agent_sdk.dart';

// Configuration
export 'src/config/sdk_configuration.dart';
export 'src/config/sdk_configuration_loader.dart';

// Models
export 'src/models/message.dart';

// Events
export 'src/events/sdk_events.dart';
export 'src/events/chat_events.dart';

// Utils
export 'src/utils/logger.dart';

class ArtemisFlutterSocketSdk {
  Future<String?> getPlatformVersion() {
    return ArtemisFlutterSocketSdkPlatform.instance.getPlatformVersion();
  }
}
