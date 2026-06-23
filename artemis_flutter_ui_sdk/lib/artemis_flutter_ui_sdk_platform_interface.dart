import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'artemis_flutter_ui_sdk_method_channel.dart';

abstract class ArtemisFlutterUiSdkPlatform extends PlatformInterface {
  /// Constructs a ArtemisFlutterUiSdkPlatform.
  ArtemisFlutterUiSdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static ArtemisFlutterUiSdkPlatform _instance =
      MethodChannelArtemisFlutterUiSdk();

  /// The default instance of [ArtemisFlutterUiSdkPlatform] to use.
  ///
  /// Defaults to [MethodChannelArtemisFlutterUiSdk].
  static ArtemisFlutterUiSdkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ArtemisFlutterUiSdkPlatform] when
  /// they register themselves.
  static set instance(ArtemisFlutterUiSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
