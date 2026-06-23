/// Artemis Flutter UI SDK
///
/// UI and configuration on top of
/// [artemis_flutter_socket_sdk](https://github.com/SudheerJa-Kore/AgentSocketFlutterPlugin)
/// for WebSocket chat connectivity.
library;

import 'artemis_flutter_ui_sdk_platform_interface.dart';

// Socket / connection layer (AgentSocketFlutterPlugin)
export 'package:artemis_flutter_socket_sdk/artemis_flutter_socket_sdk.dart'
    hide SDKConfigurationLoader;

// Artemis UI configuration helpers (supports channelId + artemis_flutter_ui_sdk YAML key)
export 'src/config/sdk_configuration_loader.dart';

// Built-in chat UI
export 'src/ui/agent_chat_ui.dart';
export 'src/ui/agent_chat_screen.dart';
export 'src/ui/connection_status.dart';

class ArtemisFlutterUiSdk {
  Future<String?> getPlatformVersion() {
    return ArtemisFlutterUiSdkPlatform.instance.getPlatformVersion();
  }
}
