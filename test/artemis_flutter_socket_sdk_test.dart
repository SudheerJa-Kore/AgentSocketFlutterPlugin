import 'package:flutter_test/flutter_test.dart';
import 'package:artemis_flutter_socket_sdk/artemis_flutter_socket_sdk.dart';
import 'package:artemis_flutter_socket_sdk/artemis_flutter_socket_sdk_platform_interface.dart';
import 'package:artemis_flutter_socket_sdk/artemis_flutter_socket_sdk_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockArtemisFlutterSocketSdkPlatform
    with MockPlatformInterfaceMixin
    implements ArtemisFlutterSocketSdkPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final ArtemisFlutterSocketSdkPlatform initialPlatform =
      ArtemisFlutterSocketSdkPlatform.instance;

  test('$MethodChannelArtemisFlutterSocketSdk is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelArtemisFlutterSocketSdk>());
  });

  test('getPlatformVersion', () async {
    ArtemisFlutterSocketSdk plugin = ArtemisFlutterSocketSdk();
    MockArtemisFlutterSocketSdkPlatform fakePlatform =
        MockArtemisFlutterSocketSdkPlatform();
    ArtemisFlutterSocketSdkPlatform.instance = fakePlatform;

    expect(await plugin.getPlatformVersion(), '42');
  });
}
