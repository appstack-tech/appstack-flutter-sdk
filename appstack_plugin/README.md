# Appstack Flutter Plugin

Track events and revenue with Apple Search Ads attribution in your Flutter app.

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  appstack_plugin: ^0.0.1
```

Then run:

```bash
flutter pub get
```

### iOS Setup Options

The plugin supports two iOS integration methods:

#### Option 1: CocoaPods (Not Recommended)

**WARNING** : This feature will be removed as soon as this ticket will be completed and we will go back to SPM usage to have a much cleaner repository ([deprecation on flutter's side of cocoapods](https://github.com/flutter/flutter/issues/168015))

This is the default method that works out of the box. The XCFramework is bundled with the plugin but that is not recommanded anymore.

Simply run `pod install` in your `ios` directory (see Platform Configuration below).

#### Option 2: Swift Package Manager

If you need to use SPM instead, enable it with:

```bash
flutter config --enable-swift-package-manager
```

After enabling SPM, clean and regenerate your project:

```bash
flutter clean
flutter pub get
```

> **Note:** SPM support requires additional configuration. See [SPM_SETUP_GUIDE.md](./SPM_SETUP_GUIDE.md) for detailed instructions.

### Platform Configuration

**iOS Configuration:**

- **iOS version** 13.0+ minimum (14.3+ recommended for Apple Search Ads)
- The plugin includes the AppstackSDK XCFramework for CocoaPods users
- SPM users can reference the SDK from GitHub (requires `flutter config --enable-swift-package-manager`)

Add to `ios/Runner/Info.plist`:
```xml
<key>NSAdvertisingAttributionReportEndpoint</key>
<string>https://ios-appstack.com/</string>
```

Run `pod install` in the `ios` directory:
```bash
cd ios && pod install
```

**Note:** For CocoaPods users, the AppstackSDK XCFramework is bundled with the plugin. For SPM users, see [SPM_SETUP_GUIDE.md](./SPM_SETUP_GUIDE.md).

**Android Configuration:**

- **Minimum SDK:** Android 5.0 (API level 21)
- **Target SDK:** 34+

Add the Appstack SDK repository to your `android/build.gradle`:
```gradle
allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url 'https://jitpack.io' }
    }
}
```

No additional configuration needed for Android - the SDK will work automatically after installation.

## Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:appstack_plugin/appstack_plugin.dart';
import 'dart:io' show Platform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure the SDK
  final apiKey = Platform.isIOS 
      ? 'your-ios-api-key' 
      : 'your-android-api-key';
  
  await AppstackPlugin.configure(apiKey);
  
  // Enable Apple Search Ads attribution on iOS
  if (Platform.isIOS) {
    await AppstackPlugin.enableAppleAdsAttribution();
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  void trackPurchase() {
    AppstackPlugin.sendEvent(EventType.purchase, parameters: {'revenue': 29.99, 'currency': 'USD'});
  }

  @override
  Widget build(BuildContext context) {
    // ... your app
  }
}
```

## API

### `configure(String apiKey, {bool isDebug, String? endpointBaseUrl, int logLevel}): Future<void>`
Initializes the SDK with your API key. Must be called before any other SDK methods.

**Parameters:**
- `apiKey` - Your platform-specific API key from the Appstack dashboard
- `isDebug` - Enable debug mode (optional, default false)
- `endpointBaseUrl` - Custom endpoint base URL (optional)
- `logLevel` - Log level: 0=DEBUG, 1=INFO, 2=WARN, 3=ERROR (optional, default 1)

**Returns:** Future that completes when configuration is done

**Logging:** The SDK automatically checks its status after configuration and prints to console:
- ✅ "The SDK is enabled and ready to track events."
- ⚠️  "The SDK is disabled. Please check your API key and ensure it is valid."

**Example:**
```dart
await AppstackPlugin.configure('your-api-key-here');

// With all parameters
await AppstackPlugin.configure(
  'your-api-key-here',
  isDebug: true,
  logLevel: 0, // DEBUG
);
```

### `sendEvent(EventType eventType, {String? eventName, Map<String, dynamic>? parameters}): Future<bool>`
Tracks custom events with optional parameters. Use this for all user actions you want to measure.

**Parameters:**
- `eventType` - Event type from the EventType enum (required)
- `eventName` - Event name for custom events (optional)
- `parameters` - Optional map of parameters to include with the event (e.g., `{'revenue': 29.99, 'currency': 'USD'}`)

**Returns:** Future that resolves to `true` if event was sent successfully

**Examples:**
```dart
import 'package:appstack_plugin/appstack_plugin.dart';

// Using EventType enum (recommended)
await AppstackPlugin.sendEvent(EventType.purchase, parameters: {'revenue': 29.99, 'currency': 'USD'});
await AppstackPlugin.sendEvent(EventType.signUp);
await AppstackPlugin.sendEvent(EventType.addToCart);

// Custom events with custom names
await AppstackPlugin.sendEvent(
  EventType.custom,
  eventName: 'my_custom_event',
  parameters: {'revenue': 15.50, 'currency': 'USD', 'category': 'premium'}
);
```

**Available EventType values:**
- `install`, `login`, `signUp`, `register`
- `purchase`, `addToCart`, `addToWishlist`, `initiateCheckout`, `startTrial`, `subscribe`
- `levelStart`, `levelComplete`
- `tutorialComplete`, `search`, `viewItem`, `viewContent`, `share`
- `custom` (for application-specific events)

### `enableAppleAdsAttribution(): Future<bool>` (iOS only)
Enables Apple Search Ads attribution tracking. Call this after `configure()` on iOS to track App Store install sources.

**Returns:** Future that resolves to `true` if attribution was enabled successfully

**Requirements:**
- iOS 14.3+
- App installed from App Store or TestFlight
- Attribution data appears within 24-48 hours

**Example:**
```dart
import 'dart:io' show Platform;

if (Platform.isIOS) {
  await AppstackPlugin.enableAppleAdsAttribution();
}
```

### `getAppstackId(): Future<String?>`
Retrieves the unique Appstack ID for the current user. This ID is generated by the SDK and can be used for user identification and tracking across sessions.

**Returns:** Future that resolves to the Appstack ID string, or `null` if not available

**Example:**
```dart
final appstackId = await AppstackPlugin.getAppstackId();
if (appstackId != null) {
  print('Appstack ID: $appstackId');
  // Use the ID for your analytics or user tracking
} else {
  print('Appstack ID not available yet');
}
```

**Note:** The Appstack ID is generated after the SDK is configured. Make sure to call `configure()` before attempting to retrieve the ID.

### `isSdkDisabled(): Future<bool>`
Checks if the SDK is currently disabled. This can be useful for debugging or handling cases where the SDK configuration failed.

**Returns:** Future that resolves to `true` if the SDK is disabled (e.g., due to invalid API key), `false` otherwise

**Example:**
```dart
// After configuration, you can check if the SDK is working properly
await AppstackPlugin.configure('your-api-key');

// Check if SDK is disabled (e.g., invalid API key)
final isDisabled = await AppstackPlugin.isSdkDisabled();
if (isDisabled) {
  print('Warning: SDK is disabled - please check your API key');
  // Handle the error appropriately in your app
} else {
  print('SDK is enabled and ready');
}
```

**Note:** The SDK automatically logs warning messages when disabled, but this method allows you to programmatically check the status.

---

## Advanced

<details>
<summary>Security Considerations</summary>

**Data Privacy:**
- Event names and revenue data are transmitted securely over HTTPS
- No personally identifiable information (PII) should be included in event names
- The SDK does not collect device identifiers beyond what's required for attribution

**Network Security:**
- All API communications use TLS 1.2+ encryption
- Certificate pinning is implemented for additional security
- Requests are authenticated using your API key
</details>

<details>
<summary>Limitations</summary>

**Attribution Timing:**
- Apple Search Ads attribution data appears within 24-48 hours after install
- Attribution is only available for apps installed from App Store or TestFlight
- Attribution requires user consent on iOS 14.5+ (handled automatically)

**Platform Constraints:**
- **iOS:** Requires iOS 14.3+
- **Android:** Minimum API level 21 (Android 5.0)
- **Flutter:** 3.3.0+
- Some Apple Search Ads features may not work in development/simulator environments

**Event Tracking:**
- Event names are case-sensitive and standardized
- Revenue values need to be in USD
- SDK must be initialized before any tracking calls
- `enableAppleAdsAttribution` only works on iOS and will return false on Android
- Network connectivity required for event transmission (events are queued offline)
</details>

## Documentation

- [Complete Usage Guide](./USAGE.md)
- [GitHub Repository](https://github.com/appstack-tech/appstack-flutter-sdk)

## License

MIT License - see LICENSE file for details