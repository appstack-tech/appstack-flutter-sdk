# Appstack Flutter Plugin - Usage Guide

Track events and revenue with Apple Search Ads attribution in your Flutter app.

## Overview

This guide follows the same structure across Appstack SDKs:

- Features (with examples)
- Installation & platform configuration
- Quick start
- EAC recommendations

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  appstack_plugin: ^2.2.2
```

Then run:

```bash
flutter pub get
```

## Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:appstack_plugin/appstack_plugin.dart';
import 'dart:io' show Platform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final apiKey = Platform.isIOS 
      ? 'your-ios-api-key' 
      : 'your-android-api-key';
  
  await AppstackPlugin.configure(apiKey);
  
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

## Universal Links and Android App Links

Appstack parses standard `https` links on your branded domain. The shared
`appstack.link` and `dev.appstack.link` hosts are intentionally ignored. A
supported link has exactly one path segment, for example
`https://links.example.com/abc123?screen=offer`. Links with a custom scheme,
with no path segment, or with more than one are not parsed.

Forward the `Uri` from your app's existing Router or link plugin:

```dart
Future<void> handleIncomingUri(Uri uri) async {
  final link = await AppstackPlugin.handleUniversalLink(
    uri,
    allowedHosts: {'links.example.com'},
  );
  if (link != null) {
    // Route using link.deeplinkId and link.queryParams.
    // deeplinkId is nullable, matching the native SDKs.
  }
}
```

`allowedHosts` is optional hardening, not a requirement. Omit it and every host
except the shared Appstack ones is parsed; pass it to restrict parsing to the
domains you own. Supply it when the `Uri` can come from somewhere you do not
control, such as a web view or a custom-scheme handler.

Call it for both the initial URI and later URI events. The method is safe before
`configure()`, and it does not register a second lifecycle listener, make a
network request, or track an event. If you use a plugin such as `app_links`,
follow Flutter's guidance for disabling Flutter's built-in deep-link handler so
the two handlers do not conflict. See Flutter's
[deep-linking guide](https://docs.flutter.dev/ui/navigation/deep-linking).

On iOS, add `applinks:links.example.com` to the Runner target's Associated
Domains entitlement. On Android, add a verified HTTPS intent filter for that
host. The branded domain must serve the matching AASA and `assetlinks.json`
files.

## Installation ID + attribution parameters

```dart
final appstackId = await AppstackPlugin.getAppstackId();
final attributionParams = await AppstackPlugin.getAttributionParams();
print('Appstack ID: $appstackId');
print('Attribution params: $attributionParams');
```

Alternatively, retrieve attribution parameters via a stream backed by a native background thread (emits one value then closes). Prefer this when attribution retrieval time may vary, as it frees the platform thread immediately:

```dart
AppstackPlugin.getAttributionParamsWithCallback().listen(
  (params) => print('Attribution params: $params'),
  onError: (e) => print('Error: $e'),
);
```

## iOS Configuration

Optionally configure the SKAdNetwork attribution report endpoint in `ios/Runner/Info.plist`:

```xml
<key>NSAdvertisingAttributionReportEndpoint</key>
<string>https://ios-appstack.com/</string>
```

**How the native iOS SDK is resolved:**

- **Flutter 3.44+ (recommended):** Swift Package Manager is the default and is enabled automatically. The AppstackSDK is fetched from the [official GitHub repository](https://github.com/appstack-tech/ios-appstack-sdk) via SPM during the build — no manual setup required.
- **Flutter < 3.44:** The plugin falls back to CocoaPods using a bundled `AppstackSDK.xcframework`. Run `cd ios && pod install`. To opt into SPM on pre-3.44 Flutter, see the [SPM Setup Guide](SPM_SETUP_GUIDE.md).

> **Note:** CocoaPods is in maintenance mode and its package registry becomes read-only on **December 2, 2026**. Upgrading to Flutter 3.44+ (SwiftPM by default) is the recommended long-term path.

## Android Configuration (Required)

Add the repository to your `android/build.gradle`:

```gradle
allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url 'https://jitpack.io' }
    }
}
```

---

## Event Examples

### E-commerce Events

```dart
// User views a product
await AppstackPlugin.sendEvent(EventType.viewItem);

// User adds item to cart
await AppstackPlugin.sendEvent(EventType.addToCart, parameters: {'revenue': 15.99, 'currency': 'USD'});

// User initiates checkout
await AppstackPlugin.sendEvent(EventType.initiateCheckout, parameters: {'revenue': 89.97, 'currency': 'USD'});

// User completes purchase
await AppstackPlugin.sendEvent(EventType.purchase, parameters: {'revenue': 89.97, 'currency': 'USD'});
```

### Gaming Events

```dart
// User starts a level
await AppstackPlugin.sendEvent(EventType.levelStart);

// User completes a level
await AppstackPlugin.sendEvent(EventType.levelComplete);

// In-app purchase
await AppstackPlugin.sendEvent(EventType.purchase, parameters: {'revenue': 4.99, 'currency': 'USD'});
```

### User Authentication

```dart
// User signs up
await AppstackPlugin.sendEvent(EventType.signUp);

// User logs in
await AppstackPlugin.sendEvent(EventType.login);
```

### Custom Events

```dart
// Custom event with name
await AppstackPlugin.sendEvent(
  EventType.custom, 
  eventName: 'user_completed_tutorial',
);

// Custom event with parameters
await AppstackPlugin.sendEvent(
  EventType.custom,
  eventName: 'premium_feature_used',
  parameters: {'revenue': 9.99, 'currency': 'USD'},
);
```

---

## EAC recommendations

### Revenue events (all ad networks)

For any event that represents revenue, we recommend sending:

- `revenue` **or** `price` (number)
- `currency` (string, e.g. `EUR`, `USD`)

```dart
await AppstackPlugin.sendEvent(
  EventType.purchase,
  parameters: {'revenue': 4.99, 'currency': 'EUR'},
);
```

### Meta matching (send once per installation, as early as possible)

For Meta, we recommend sending **one time** (because the information will then be associated to every event sent with the same **installation ID**), **as early as possible**, the following parameters (if you have them):

- `email`
- `name` (first name + last name in the same parameter)
- `phone_number`
- `date_of_birth`
```

### Troubleshooting

<details>
<summary>Common Issues</summary>

**iOS: Package not linked:**
```bash
cd ios && pod install
flutter clean
flutter pub get
```

**Events not tracking:**
- Check if `configure()` was called with correct API key
- Verify iOS Info.plist configuration
- Verify Android build.gradle has the correct repository

**Apple Search Ads not working:**
- Requires iOS 14.3+
- App must be from App Store/TestFlight
- Attribution data appears after 24-48 hours

**Wrong revenue values:**
```dart
// ✅ Use decimal dollars
await AppstackPlugin.sendEvent(EventType.purchase, parameters: {'revenue': 29.99, 'currency': 'USD'});

// ✅ Convert cents to dollars
final cents = 2999;
await AppstackPlugin.sendEvent(EventType.purchase, parameters: {'revenue': cents / 100, 'currency': 'USD'});
```

**Platform-specific code:**
```dart
import 'dart:io' show Platform;

// Only enable Apple Ads Attribution on iOS
if (Platform.isIOS) {
  await AppstackPlugin.enableAppleAdsAttribution();
}

// Use different API keys per platform
final apiKey = Platform.isIOS 
    ? 'ios-api-key' 
    : 'android-api-key';
await AppstackPlugin.configure(apiKey);
```
</details>

---

Need help? Check the [GitHub repository](https://github.com/appstack-tech/appstack-flutter-sdk) or contact support.
