import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'appstack_plugin_platform_interface.dart';

/// An implementation of [AppstackPluginPlatform] that uses method channels.
class MethodChannelAppstackPlugin extends AppstackPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('appstack_plugin');

  @override
  Future<bool> configure(
    String apiKey,
    bool isDebug,
    String? endpointBaseUrl,
    int logLevel,
  ) async {
    final result = await methodChannel.invokeMethod<bool>('configure', {
      'apiKey': apiKey,
      'isDebug': isDebug,
      'endpointBaseUrl': endpointBaseUrl,
      'logLevel': logLevel,
    });
    return result ?? false;
  }

  @override
  Future<bool> sendEvent(
    String eventType,
    String? eventName,
    double revenue,
  ) async {
    final result = await methodChannel.invokeMethod<bool>('sendEvent', {
      'eventType': eventType,
      'eventName': eventName,
      'revenue': revenue,
    });
    return result ?? false;
  }

  @override
  Future<bool> enableAppleAdsAttribution() async {
    final result = await methodChannel.invokeMethod<bool>(
      'enableAppleAdsAttribution',
    );
    return result ?? false;
  }

  @override
  Future<String?> getAppstackId() async {
    final result = await methodChannel.invokeMethod<String>('getAppstackId');
    return result;
  }
}
