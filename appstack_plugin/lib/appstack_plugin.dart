import 'appstack_plugin_platform_interface.dart';
import 'event_type.dart';

export 'event_type.dart';

/// Main Appstack SDK class for Flutter
///
/// Usage example:
/// ```dart
/// import 'package:appstack_plugin/appstack_plugin.dart';
///
/// // Configure the SDK
/// await AppstackPlugin.configure('your-api-key');
///
/// // Send events
/// await AppstackPlugin.sendEvent(EventType.purchase, revenue: 29.99);
///
/// // Enable Apple Ads Attribution (iOS only)
/// await AppstackPlugin.enableAppleAdsAttribution();
/// ```
class AppstackPlugin {
  /// Configure Appstack SDK with your API key and optional parameters
  ///
  /// Parameters:
  /// - [apiKey]: Your Appstack API key obtained from the dashboard
  /// - [isDebug]: Enable debug mode (optional, default false)
  /// - [endpointBaseUrl]: Custom endpoint base URL (optional)
  /// - [logLevel]: Log level: 0=DEBUG, 1=INFO, 2=WARN, 3=ERROR (optional, default 1)
  ///
  /// Returns: Future that resolves to true if configuration was successful
  static Future<bool> configure(
    String apiKey, {
    bool isDebug = false,
    String? endpointBaseUrl,
    int logLevel = 1,
  }) async {
    if (apiKey.isEmpty) {
      throw ArgumentError('API key must be a non-empty string');
    }

    if (logLevel < 0 || logLevel > 3) {
      throw ArgumentError('logLevel must be a number between 0 and 3');
    }

    try {
      final result = await AppstackPluginPlatform.instance.configure(
        apiKey,
        isDebug,
        endpointBaseUrl,
        logLevel,
      );
      return result;
    } catch (error) {
      throw Exception('Failed to configure Appstack SDK: $error');
    }
  }

  /// Send an event with optional revenue parameter
  ///
  /// Parameters:
  /// - [eventType]: Event type from EventType enum (required)
  /// - [eventName]: Event name for custom events (optional)
  /// - [revenue]: Optional revenue value (can be double or int)
  ///
  /// Returns: Future that resolves to true if event was sent successfully
  static Future<bool> sendEvent(
    EventType eventType, {
    String? eventName,
    double? revenue,
  }) async {
    try {
      return await AppstackPluginPlatform.instance.sendEvent(
        eventType.name,
        eventName,
        revenue ?? 0.0,
      );
    } catch (error) {
      throw Exception(
        'Failed to send event (eventType: ${eventType.name}): $error',
      );
    }
  }

  /// Enable Apple Search Ads Attribution tracking (iOS only)
  ///
  /// Requires iOS 14.3+
  ///
  /// Returns: Future that resolves to true if attribution was enabled successfully
  static Future<bool> enableAppleAdsAttribution() async {
    try {
      return await AppstackPluginPlatform.instance.enableAppleAdsAttribution();
    } catch (error) {
      throw Exception('Failed to enable Apple Ads Attribution: $error');
    }
  }

  /// Get the Appstack ID for the current user
  ///
  /// Returns: Future that resolves to the Appstack ID string, or null if not available
  static Future<String?> getAppstackId() async {
    try {
      return await AppstackPluginPlatform.instance.getAppstackId();
    } catch (error) {
      throw Exception('Failed to get Appstack ID: $error');
    }
  }
}
