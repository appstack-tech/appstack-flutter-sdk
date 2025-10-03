import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'appstack_plugin_method_channel.dart';

abstract class AppstackPluginPlatform extends PlatformInterface {
  /// Constructs a AppstackPluginPlatform.
  AppstackPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static AppstackPluginPlatform _instance = MethodChannelAppstackPlugin();

  /// The default instance of [AppstackPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelAppstackPlugin].
  static AppstackPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AppstackPluginPlatform] when
  /// they register themselves.
  static set instance(AppstackPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
