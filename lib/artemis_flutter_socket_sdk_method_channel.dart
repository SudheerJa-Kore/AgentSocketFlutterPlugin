import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'artemis_flutter_socket_sdk_platform_interface.dart';

/// An implementation of [ArtemisFlutterSocketSdkPlatform] that uses method channels.
class MethodChannelArtemisFlutterSocketSdk
    extends ArtemisFlutterSocketSdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('artemis_flutter_socket_sdk');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
