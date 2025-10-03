import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'android_method_channel.dart';

abstract class AndroidPlatform extends PlatformInterface {
  /// Constructs a AndroidPlatform.
  AndroidPlatform() : super(token: _token);

  static final Object _token = Object();

  static AndroidPlatform _instance = MethodChannelAndroid();

  /// The default instance of [AndroidPlatform] to use.
  ///
  /// Defaults to [MethodChannelAndroid].
  static AndroidPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AndroidPlatform] when
  /// they register themselves.
  static set instance(AndroidPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
