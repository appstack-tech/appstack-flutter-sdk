import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'src/method_channel_appstack_plugin.dart';

/// The platform interface behind every [AppstackPlugin] call.
///
/// This is public on purpose, as the supported way to fake the plugin in an
/// app's unit tests. Extend it with `MockPlatformInterfaceMixin` (from
/// `package:plugin_platform_interface`) and set [instance]:
///
/// ```dart
/// class FakeAppstack extends AppstackPluginPlatform
///     with MockPlatformInterfaceMixin {
///   @override
///   Future<void> sendEvent(String eventType, String? eventName,
///       Map<String, dynamic>? parameters) async {}
/// }
///
/// setUp(() => AppstackPluginPlatform.instance = FakeAppstack());
/// ```
///
/// Methods a fake doesn't override throw [UnimplementedError].
abstract class AppstackPluginPlatform extends PlatformInterface {
  /// Constructs a AppstackPluginPlatform.
  AppstackPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static AppstackPluginPlatform _instance = MethodChannelAppstackPlugin();

  /// The default instance of [AppstackPluginPlatform] to use.
  ///
  /// Defaults to the method-channel implementation that talks to the native
  /// SDKs.
  static AppstackPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AppstackPluginPlatform] when
  /// they register themselves.
  static set instance(AppstackPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Configure Appstack SDK with your API key and optional parameters
  Future<void> configure(
    String apiKey,
    int logLevel,
    String? customerUserId,
  ) {
    throw UnimplementedError('configure() has not been implemented.');
  }

  /// Set — or clear — the customer user id after [configure]
  ///
  /// A null or blank id is an explicit clear here, not "not provided".
  Future<void> setCustomerUserId(String? customerUserId) {
    throw UnimplementedError('setCustomerUserId() has not been implemented.');
  }

  /// Permanently delete the current user's Appstack data.
  Future<void> deleteUserData() {
    throw UnimplementedError('deleteUserData() has not been implemented.');
  }

  /// Send an event with optional parameters
  Future<void> sendEvent(
    String eventType,
    String? eventName,
    Map<String, dynamic>? parameters,
  ) {
    throw UnimplementedError('sendEvent() has not been implemented.');
  }

  /// Enable Apple Search Ads Attribution tracking (iOS only)
  Future<bool> enableAppleAdsAttribution() {
    throw UnimplementedError(
      'enableAppleAdsAttribution() has not been implemented.',
    );
  }

  /// Get the Appstack ID for the current user
  Future<String?> getAppstackId() {
    throw UnimplementedError('getAppstackId() has not been implemented.');
  }

  /// Check if the SDK is disabled
  ///
  /// Returns true if the SDK is disabled (e.g., due to invalid API key),
  /// false otherwise. This can be called after configure() to verify
  /// that the configuration was successful.
  Future<bool> isSdkDisabled() {
    throw UnimplementedError('isSdkDisabled() has not been implemented.');
  }

  /// Get attribution parameters
  ///
  /// Returns a map containing attribution parameters from the SDK, empty when
  /// there are none.
  Future<Map<String, dynamic>> getAttributionParams() {
    throw UnimplementedError(
      'getAttributionParams() has not been implemented.',
    );
  }

  Future<Map<String, dynamic>?> handleUniversalLink(
    String url,
    List<String>? allowedHosts,
  ) {
    throw UnimplementedError('handleUniversalLink() has not been implemented.');
  }
}
