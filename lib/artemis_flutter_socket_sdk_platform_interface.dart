import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'artemis_flutter_socket_sdk_method_channel.dart';

abstract class ArtemisFlutterSocketSdkPlatform extends PlatformInterface {
  /// Constructs a ArtemisFlutterSocketSdkPlatform.
  ArtemisFlutterSocketSdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static ArtemisFlutterSocketSdkPlatform _instance =
      MethodChannelArtemisFlutterSocketSdk();

  /// The default instance of [ArtemisFlutterSocketSdkPlatform] to use.
  ///
  /// Defaults to [MethodChannelArtemisFlutterSocketSdk].
  static ArtemisFlutterSocketSdkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ArtemisFlutterSocketSdkPlatform] when
  /// they register themselves.
  static set instance(ArtemisFlutterSocketSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
