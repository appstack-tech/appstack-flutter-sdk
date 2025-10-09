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

  /// Configure Appstack SDK with your API key and optional parameters
  Future<bool> configure(
    String apiKey,
    bool isDebug,
    String? endpointBaseUrl,
    int logLevel,
  ) {
    throw UnimplementedError('configure() has not been implemented.');
  }

  /// Send an event with optional revenue parameter
  Future<bool> sendEvent(String eventType, String? eventName, double revenue) {
    throw UnimplementedError('sendEvent() has not been implemented.');
  }

  /// Enable Apple Search Ads Attribution tracking (iOS only)
  Future<bool> enableAppleAdsAttribution() {
    throw UnimplementedError(
      'enableAppleAdsAttribution() has not been implemented.',
    );
  }
}
