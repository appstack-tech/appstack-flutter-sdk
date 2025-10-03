import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'appstack_plugin_platform_interface.dart';

/// An implementation of [AppstackPluginPlatform] that uses method channels.
class MethodChannelAppstackPlugin extends AppstackPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('appstack_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
