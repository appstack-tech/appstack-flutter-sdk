import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'android_platform_interface.dart';

/// An implementation of [AndroidPlatform] that uses method channels.
class MethodChannelAndroid extends AndroidPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('android');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
