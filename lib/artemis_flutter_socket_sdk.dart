
import 'artemis_flutter_socket_sdk_platform_interface.dart';

class ArtemisFlutterSocketSdk {
  Future<String?> getPlatformVersion() {
    return ArtemisFlutterSocketSdkPlatform.instance.getPlatformVersion();
  }
}
