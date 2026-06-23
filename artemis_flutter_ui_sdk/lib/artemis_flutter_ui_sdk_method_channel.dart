import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'artemis_flutter_ui_sdk_platform_interface.dart';

/// An implementation of [ArtemisFlutterUiSdkPlatform] that uses method channels.
class MethodChannelArtemisFlutterUiSdk
    extends ArtemisFlutterUiSdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('artemis_flutter_ui_sdk');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
