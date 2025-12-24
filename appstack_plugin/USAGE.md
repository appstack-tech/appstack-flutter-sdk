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
  appstack_plugin: ^1.2.0
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

## Installation ID + attribution parameters

```dart
final appstackId = await AppstackPlugin.getAppstackId();
final attributionParams = await AppstackPlugin.getAttributionParams();
print('Appstack ID: $appstackId');
print('Attribution params: $attributionParams');
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
