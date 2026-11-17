import 'package:flutter/foundation.dart';

import 'appstack_plugin_platform_interface.dart';
import 'event_type.dart';

export 'event_type.dart';

class AppstackLinkResult {
  const AppstackLinkResult({
    required this.deeplinkId,
    required this.queryParams,
    required this.url,
  });

  /// The link's single path segment. Optional in both native SDKs, so it is
  /// nullable here rather than collapsed to an empty string.
  final String? deeplinkId;
  final Map<String, String> queryParams;
  final Uri url;

  factory AppstackLinkResult.fromMap(Map<dynamic, dynamic> value) {
    return AppstackLinkResult(
      deeplinkId: value['deeplinkId'] as String?,
      queryParams: Map<String, String>.from(value['queryParams'] as Map),
      url: Uri.parse(value['url'] as String),
    );
  }
}

/// Main Appstack SDK class for Flutter
///
/// Usage example:
/// ```dart
/// import 'package:appstack_plugin/appstack_plugin.dart';
///
/// // Configure the SDK
/// await AppstackPlugin.configure('your-api-key');
///
/// // Set the customer user id later (e.g. on login), or clear it on logout
/// await AppstackPlugin.setCustomerUserId('user-123');
/// await AppstackPlugin.setCustomerUserId(null);
///
/// // Permanently delete this user's Appstack data for a privacy request
/// await AppstackPlugin.deleteUserData();
///
/// // Send events
/// await AppstackPlugin.sendEvent(EventType.purchase, parameters: {'revenue': 29.99, 'currency': 'USD'});
///
/// // Enable Apple Ads Attribution (iOS only)
/// await AppstackPlugin.enableAppleAdsAttribution();
/// ```
class AppstackPlugin {
  // Static-only API: not meant to be instantiated or subclassed.
  AppstackPlugin._();

  /// Configure Appstack SDK with your API key and optional parameters
  ///
  /// Parameters:
  /// - [apiKey]: Your Appstack API key obtained from the dashboard
  /// - [logLevel]: Log level: 0=DEBUG, 1=INFO, 2=WARN, 3=ERROR (optional, default 1)
  /// - [customerUserId]: Optional customer user ID to pass to the native SDKs
  ///
  /// Returns: Future that completes when configuration is done
  static Future<void> configure(
    String apiKey, {
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

  /// Set — or clear — the customer user id after [configure], e.g. once a login
  /// reveals it. A repeat [configure] is a no-op, so it cannot be used to change the id.
  ///
  /// Parameters:
  /// - [customerUserId]: Your identifier for the signed-in user; `null` or a blank
  ///   string clears it (do this on logout). Safe to call at any time; last write wins.
  ///
  /// Returns: Future that completes once native has stored (or cleared) the id
  static Future<void> setCustomerUserId(String? customerUserId) async {
    try {
      await AppstackPluginPlatform.instance.setCustomerUserId(customerUserId);
    } catch (error) {
      throw Exception('Failed to set customer user ID: $error');
    }
  }

  /// Permanently delete the current user's Appstack data for a GDPR or other
  /// privacy deletion request. Available on both iOS and Android.
  static Future<void> deleteUserData() async {
    try {
      await AppstackPluginPlatform.instance.deleteUserData();
    } catch (error) {
      throw Exception('Failed to delete Appstack user data: $error');
    }
  }

  /// Send an event with optional parameters
  ///
  /// Parameters:
  /// - [eventType]: Event type from EventType enum (required)
  /// - [eventName]: Event name for custom events (optional)
  /// - [parameters]: Optional map of parameters to include with the event (e.g., {'revenue': 29.99, 'currency': 'USD'})
  ///
  /// Use strings, finite numbers, booleans, lists, and nested string-keyed maps
  /// as parameter values. A `DateTime`, `Uri`, `Set` or arbitrary object cannot
  /// cross the platform channel and throws an `ArgumentError` before reaching
  /// the native SDK — convert those yourself (e.g. `date.toIso8601String()`).
  ///
  /// A `null` value is omitted from the payload and the event still sends;
  /// nulls nested inside a list are preserved. A value the native SDK cannot
  /// serialize — `double.nan`, `double.infinity`, or a typed-data list such as
  /// `Uint8List` — has its key dropped individually and logged natively, and
  /// the event still sends with the remaining parameters.
  ///
  /// Custom parameter values may be encrypted on the device before they are
  /// sent, so avoid relying on them being readable in raw payload inspection.
  /// This is driven entirely by remote config — nothing to set here — and keys
  /// the backend needs in the clear (`currency`, `revenue`, campaign fields)
  /// are excluded. Revenue reporting is unaffected.
  ///
  /// The future completes once the event has been handed to the native SDK.
  /// That doesn't mean it was delivered: the native SDK queues events, and may
  /// still drop one (for example a manual [EventType.install], or while the SDK
  /// is disabled). Delivery is not observable from Dart.
  static Future<void> sendEvent(
    EventType eventType, {
    String? eventName,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await AppstackPluginPlatform.instance.sendEvent(
        eventType.rawValue,
        eventName,
        parameters,
      );
    } catch (error) {
      throw Exception(
        'Failed to send event (eventType: ${eventType.rawValue}): $error',
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

  /// Get attribution parameters from the SDK.
  ///
  /// Request-response call over the method channel. On both platforms the
  /// returned future completes once the native attribution match has finished,
  /// so it is safe to call right after [configure].
  ///
  /// Never null: when there is nothing to report the map is empty.
  ///
  /// On iOS the map always contains `appstack_match_status`, describing the
  /// attribution outcome: `matched`, `matched_no_params`, `organic`, `skipped`,
  /// `failed` or `not_configured`. Only `failed` is worth retrying. Android does
  /// not send that key yet, so treat an empty map as "no attribution".
  ///
  /// Example:
  /// ```dart
  /// final params = await AppstackPlugin.getAttributionParams();
  /// print('Attribution params: $params');
  /// ```
  static Future<Map<String, dynamic>> getAttributionParams() async {
    try {
      return await AppstackPluginPlatform.instance.getAttributionParams();
    } catch (error) {
      throw Exception('Failed to get attribution params: $error');
    }
  }

  /// Parse an Appstack standard Universal/App Link delivered by the app's link handler.
  /// Safe before [configure]. Returns null for unsupported links.
  static Future<AppstackLinkResult?> handleUniversalLink(
    Uri url, {
    Set<String>? allowedHosts,
  }) async {
    if (allowedHosts != null &&
        allowedHosts.any((host) => host.trim().isEmpty)) {
      throw ArgumentError(
        'allowedHosts must contain only non-empty hostnames',
      );
    }
    final value = await AppstackPluginPlatform.instance.handleUniversalLink(
      url.toString(),
      allowedHosts?.map((host) => host.trim()).toList(),
    );
    return value == null ? null : AppstackLinkResult.fromMap(value);
  }
}
