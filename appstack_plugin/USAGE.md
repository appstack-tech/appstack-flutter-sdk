# Appstack Flutter Plugin - Usage Guide

Track events and revenue with Apple Search Ads attribution in your Flutter app.

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
    AppstackPlugin.sendEvent(EventType.purchase, revenue: 29.99);
  }

  @override
  Widget build(BuildContext context) {
    // ... your app
  }
}
```

## iOS Configuration (Required)

Add to your `ios/Runner/Info.plist`:

```xml
<key>NSAdvertisingAttributionReportEndpoint</key>
<string>https://ios-appstack.com/</string>
```

Then run:

```bash
cd ios && pod install
```

**Note:** The iOS AppstackSDK is automatically fetched from the [official GitHub repository](https://github.com/appstack-tech/ios-appstack-sdk) via Swift Package Manager during the build process.

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
await AppstackPlugin.sendEvent(EventType.addToCart, revenue: 15.99);

// User initiates checkout
await AppstackPlugin.sendEvent(EventType.initiateCheckout, revenue: 89.97);

// User completes purchase
await AppstackPlugin.sendEvent(EventType.purchase, revenue: 89.97);
```

### Gaming Events

```dart
// User starts a level
await AppstackPlugin.sendEvent(EventType.levelStart);

// User completes a level
await AppstackPlugin.sendEvent(EventType.levelComplete);

// In-app purchase
await AppstackPlugin.sendEvent(EventType.purchase, revenue: 4.99);
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

// Custom event with revenue
await AppstackPlugin.sendEvent(
  EventType.custom, 
  eventName: 'premium_feature_used',
  revenue: 9.99,
);
```

---

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
await AppstackPlugin.sendEvent(EventType.purchase, revenue: 29.99);

// ✅ Convert cents to dollars  
final cents = 2999;
await AppstackPlugin.sendEvent(EventType.purchase, revenue: cents / 100);
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
