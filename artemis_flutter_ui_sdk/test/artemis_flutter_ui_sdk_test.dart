import 'package:flutter_test/flutter_test.dart';
import 'package:artemis_flutter_ui_sdk/artemis_flutter_ui_sdk.dart';
import 'package:artemis_flutter_ui_sdk/artemis_flutter_ui_sdk_platform_interface.dart';
import 'package:artemis_flutter_ui_sdk/artemis_flutter_ui_sdk_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockArtemisFlutterUiSdkPlatform
    with MockPlatformInterfaceMixin
    implements ArtemisFlutterUiSdkPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final ArtemisFlutterUiSdkPlatform initialPlatform =
      ArtemisFlutterUiSdkPlatform.instance;

  test('$MethodChannelArtemisFlutterUiSdk is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelArtemisFlutterUiSdk>());
  });

  test('getPlatformVersion', () async {
    ArtemisFlutterUiSdk plugin = ArtemisFlutterUiSdk();
    MockArtemisFlutterUiSdkPlatform fakePlatform =
        MockArtemisFlutterUiSdkPlatform();
    ArtemisFlutterUiSdkPlatform.instance = fakePlatform;

    expect(await plugin.getPlatformVersion(), '42');
  });
}
