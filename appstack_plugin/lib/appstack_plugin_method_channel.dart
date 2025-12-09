import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'appstack_plugin_platform_interface.dart';

/// An implementation of [AppstackPluginPlatform] that uses method channels.
class MethodChannelAppstackPlugin extends AppstackPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('appstack_plugin');

  @override
  Future<void> configure(
    String apiKey,
    bool isDebug,
    String? endpointBaseUrl,
    int logLevel,
  ) async {
    await methodChannel.invokeMethod<void>('configure', {
      'apiKey': apiKey,
      'isDebug': isDebug,
      'endpointBaseUrl': endpointBaseUrl,
      'logLevel': logLevel,
    });
  }

  @override
  Future<bool> sendEvent(
    String eventType,
    String? eventName,
    Map<String, dynamic>? parameters,
  ) async {
    final result = await methodChannel.invokeMethod<bool>('sendEvent', {
      'eventType': eventType,
      'eventName': eventName,
      'parameters': parameters,
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

  @override
  Future<bool> isSdkDisabled() async {
    final result = await methodChannel.invokeMethod<bool>('isSdkDisabled');
    if (result == null) {
      throw Exception(
        'Native platform did not return a value for isSdkDisabled check',
      );
    }
    return result;
  }

  @override
  Future<Map<String, dynamic>?> getAttributionParams() async {
    final result = await methodChannel.invokeMethod<Map<dynamic, dynamic>?>(
      'getAttributionParams',
    );
    if (result == null) {
      return null;
    }
    return Map<String, dynamic>.from(result);
  }
}
