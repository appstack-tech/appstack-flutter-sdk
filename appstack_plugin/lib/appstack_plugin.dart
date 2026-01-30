import 'package:flutter/foundation.dart';

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
/// await AppstackPlugin.sendEvent(EventType.purchase, parameters: {'revenue': 29.99, 'currency': 'USD'});
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
  /// - [customerUserId]: Optional customer user ID to pass to the native SDKs
  ///
  /// Returns: Future that completes when configuration is done
  static Future<void> configure(
    String apiKey, {
    bool isDebug = false,
    String? endpointBaseUrl,
    int logLevel = 1,
    String? customerUserId,
  }) async {
    if (apiKey.isEmpty) {
      throw ArgumentError('API key must be a non-empty string');
    }

    if (logLevel < 0 || logLevel > 3) {
      throw ArgumentError('logLevel must be a number between 0 and 3');
    }

    try {
      await AppstackPluginPlatform.instance.configure(
        apiKey,
        isDebug,
        endpointBaseUrl,
        logLevel,
        customerUserId,
      );

      // Check if SDK is disabled after configuration and log status
      try {
        final result = await AppstackPluginPlatform.instance.isSdkDisabled();
        debugPrint('[AppstackPlugin] isSdkDisabled: $result');
        if (result) {
          debugPrint(
            '[AppstackPlugin] ⚠️  WARNING: The SDK is disabled. Please check your API key and ensure it is valid.',
          );
        } else {
          debugPrint(
            '[AppstackPlugin] ✅ SUCCESS: The SDK is enabled and ready to track events.',
          );
        }
      } catch (e) {
        // Silently ignore errors when checking isSdkDisabled to prevent crashes
        debugPrint(
          '[AppstackPlugin] ❌ ERROR: Could not check SDK disabled status: $e',
        );
      }
    } catch (error) {
      throw Exception('Failed to configure Appstack SDK: $error');
    }
  }

  /// Send an event with optional parameters
  ///
  /// Parameters:
  /// - [eventType]: Event type from EventType enum (required)
  /// - [eventName]: Event name for custom events (optional)
  /// - [parameters]: Optional map of parameters to include with the event (e.g., {'revenue': 29.99, 'currency': 'USD'})
  ///
  /// Returns: Future that resolves to true if event was sent successfully
  static Future<bool> sendEvent(
    EventType eventType, {
    String? eventName,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      return await AppstackPluginPlatform.instance.sendEvent(
        eventType.name,
        eventName,
        parameters,
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

  /// Check if the SDK is disabled
  ///
  /// This method can be called after [configure] to verify that the SDK
  /// was configured successfully. Returns true if the SDK is disabled
  /// (e.g., due to invalid API key), false otherwise.
  ///
  /// Example:
  /// ```dart
  /// await AppstackPlugin.configure('your-api-key');
  /// final isSdkDisabled = await AppstackPlugin.isSdkDisabled();
  /// if (isSdkDisabled) {
  ///   print('SDK is disabled - check your API key');
  /// }
  /// ```
  ///
  /// Returns: Future that resolves to true if SDK is disabled, false otherwise
  static Future<bool> isSdkDisabled() async {
    try {
      return await AppstackPluginPlatform.instance.isSdkDisabled();
    } catch (error) {
      throw Exception('Failed to check SDK disabled status: $error');
    }
  }

  /// Get attribution parameters from the SDK
  ///
  /// Returns a map containing attribution parameters collected by the SDK.
  /// These parameters include information about the attribution source and other metadata.
  ///
  /// Example:
  /// ```dart
  /// final params = await AppstackPlugin.getAttributionParams();
  /// if (params != null) {
  ///   print('Attribution params: $params');
  /// }
  /// ```
  ///
  /// Returns: Future that resolves to a map of attribution parameters, or null if not available
  static Future<Map<String, dynamic>?> getAttributionParams() async {
    try {
      return await AppstackPluginPlatform.instance.getAttributionParams();
    } catch (error) {
      throw Exception('Failed to get attribution params: $error');
    }
  }
}
