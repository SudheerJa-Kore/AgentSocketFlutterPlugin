import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artemis_flutter_socket_sdk/artemis_flutter_socket_sdk_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelArtemisFlutterSocketSdk platform =
      MethodChannelArtemisFlutterSocketSdk();
  const MethodChannel channel = MethodChannel('artemis_flutter_socket_sdk');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return '42';
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
