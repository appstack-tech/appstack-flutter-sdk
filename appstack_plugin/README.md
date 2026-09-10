# Appstack Flutter Plugin

Track events and revenue with Apple Search Ads attribution in your Flutter app.

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

## **pub.dev** **repository**

Here, you will find the [pub.dev appstack_plugin documentation](https://pub.dev/packages/appstack_plugin). Please use the latest available version of the SDK.

## **Requirements**

### **iOS**

- **iOS version:** 15.0+
- **Xcode:** 14.0+

### **Android**

- **Minimum SDK:** Android 5.0 (API level 21)
- **Target SDK:** 34+

### **General**

- **Flutter:** 3.3.0+
- **Dart:** 2.18.0+

## **Initial setup**

<Steps>
  <Step title="Installation">
    Add to your `pubspec.yaml`:

    ```
    dependencies:
      appstack_plugin: ^2.2.2
    ```

    Then run:

    ```
    flutter pub get
    ```

    **iOS - Configuring the SKAdNetwork attribution endpoint (optional)**

    Add to `ios/YourApp/Info.plist`:

    ```dart
    <key>NSAdvertisingAttributionReportEndpoint</key>
    <string>https://ios-appstack.com/</string>
    ```

    **iOS Configuration**

    How the native iOS SDK is resolved depends on your Flutter version:

    - **Flutter 3.44+ (recommended):** Swift Package Manager is the default and is enabled automatically — the AppstackSDK is fetched from GitHub during the build. No manual setup is required; just run your app.
    - **Flutter < 3.44:** The plugin falls back to CocoaPods using a bundled `AppstackSDK.xcframework`, so no additional dependencies are needed. Run:

      ```
      cd ios && pod install
      ```

      To use Swift Package Manager on pre-3.44 Flutter, see the [SPM Setup Guide](SPM_SETUP_GUIDE.md).

    > **Note:** CocoaPods is in maintenance mode and its package registry becomes read-only on **December 2, 2026**. Upgrading to Flutter 3.44+ (SwiftPM by default) is the recommended long-term path.

    **Android Configuration**

    Add the repository to your `android/build.gradle`:

    ```dart
    allprojects {
        repositories {
            google()
            mavenCentral()
            maven { url 'https://jitpack.io' }
        }
    }
    ```

    No additional configuration is needed for Android; the SDK will work automatically after installation.
  </Step>
  <Step title="Quickstart">
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
      
      // Enable Apple Ads attribution on iOS
      if (Platform.isIOS) {
        await AppstackPlugin.enableAppleAdsAttribution();
      }
      
      runApp(MyApp());
    }
    
    class MyApp extends StatelessWidget {
      void trackPurchase() {
        AppstackPlugin.sendEvent(
          EventType.purchase, 
          parameters: {'revenue': 29.99, 'currency': 'USD'}
        );
      }
    
      @override
      Widget build(BuildContext context) {
        // ... your app
      }
    }
    ```
  </Step>
  <Step stepNumber={3} title="Configuration parameters">
    Initializes the SDK with your API key. Must be called before any other SDK methods.

    **Parameters:**

    - `apiKey` - Your platform-specific API key from the Appstack dashboard
    - `isDebug` - Optional debug mode flag (default: false)
    - `endpointBaseUrl` - Optional custom endpoint
    - `logLevel` - Optional log level: 0=DEBUG, 1=INFO, 2=WARN, 3=ERROR (default: 1)
    - `customerUserId` - Optional customer user ID passed through to the native SDKs. If it is only known after `configure()` (usually after a login), use [`setCustomerUserId()`](#setting-the-customer-user-id) instead — a repeat `configure()` is a no-op and ignores this parameter.

    Returns: A `Future<void>` that completes when configuration is done. It throws on failure (e.g. an empty API key or an invalid `logLevel`). To check whether the SDK was actually enabled after configuring, call `isSdkDisabled()`.

    **Example:**

    ```dart
    await AppstackPlugin.configure('your-api-key-here');

    // Verify the SDK is enabled (e.g. the API key is valid)
    if (await AppstackPlugin.isSdkDisabled()) {
      print('SDK is disabled - check your API key');
    }
    
    // With all parameters
    await AppstackPlugin.configure(
      'your-api-key-here',
      isDebug: true,
      logLevel: 0, // DEBUG
      customerUserId: 'your-customer-user-id',
    );
    ```
  </Step>
  <Step stepNumber={4} title="Sending events">
    Track user actions and revenue in your activities:

    ```dart
    // Track events without parameters
    await AppstackPlugin.sendEvent(EventType.signUp);
    await AppstackPlugin.sendEvent(EventType.levelComplete);
    
    // Track events with parameters (including revenue)
    await AppstackPlugin.sendEvent(
      EventType.purchase, 
      parameters: {'revenue': 29.99, 'currency': 'USD'}
    );
    await AppstackPlugin.sendEvent(
      EventType.subscribe, 
      parameters: {'revenue': 9.99, 'plan': 'monthly'}
    );
    
    // Custom events
    await AppstackPlugin.sendEvent(
      EventType.custom,
      eventName: 'user_attributes',
      parameters: {
        'email': 'test@example.com',
        'name': 'John Doe',
        'phone_number': '+33060000000',
        'date_of_birth': '2026-02-01',
      },
    );
    ```

    **Available EventType values**

    It is recommended to use standard events for a smoother experience.

    - `EventType.install` - App installation (tracked automatically)
    - `EventType.login`, `EventType.signUp`, `EventType.register` - Authentication
    - `EventType.purchase`, `EventType.addToCart`, `EventType.addToWishlist`, `EventType.initiateCheckout`, `EventType.startTrial`, `EventType.subscribe` - Monetization
    - `EventType.levelStart`, `EventType.levelComplete` - Game progression
    - `EventType.tutorialComplete`, `EventType.search`, `EventType.viewItem`, `EventType.viewContent`, `EventType.share` - Engagement
    - `EventType.custom` - For application-specific events

    Tracks custom events with optional parameters:

    - `eventType` - Event type from the EventType enum (required)
    - `eventName` - Event name for custom events (optional, required when eventType is custom)
    - `parameters` - Optional map of parameters (e.g., `{'revenue': 29.99, 'currency': 'USD'}`)

    Returns: A future that resolves to `true` if event was sent successfully.

    **Enhanced app campaigns**

    <Tip>
      When running enhanced app campaigns (EACs), it is highly recommended to send multiple parameters with the in-app event to improve matching quality.
    </Tip>
    For any event that represents revenue, we recommend sending:

    1. `revenue` or `price` (number)
    2. `currency`(string, e.g. `EUR`, `USD`)

    ```dart
    await AppstackPlugin.sendEvent(
      EventType.purchase,
      parameters: {'revenue': 4.99, 'currency': 'EUR'},
    );
    ```

    To improve matching quality on Meta, send events including the following parameters if you can fulfill them:

    1. `email`
    2. `name` (first + last name in the same field)
    3. `phone_number`
    4. `date_of_birth` (recommended format: `YYYY-MM-DD`)
  </Step>
</Steps>

## **Advanced usage**

### **Universal Links and Android App Links**

Pass the initial URI and subsequent URI events from your existing Flutter
Router or link plugin to `AppstackPlugin.handleUniversalLink`. Only branded
standard links with one path segment are supported; see
[USAGE.md](USAGE.md#universal-links-and-android-app-links) for platform setup and
an example.

### **Attribution parameters**

Two methods are available to retrieve attribution parameters:

| Method | Mechanism | When to use |
|---|---|---|
| `getAttributionParams()` | `Future` — request/response over method channel | Simple use cases where timing is predictable |
| `getAttributionParamsWithCallback()` | `Stream` — native background thread pushes result | When retrieval time may vary; frees the platform thread immediately |

**`getAttributionParams()`**

```dart
final params = await AppstackPlugin.getAttributionParams();
if (params != null) {
  print('Attribution params: $params');
}
```

**`getAttributionParamsWithCallback()`**

Spawns a native background thread (Swift `Task.detached` on iOS, `Thread` on Android). The stream emits exactly one value then closes.

```dart
AppstackPlugin.getAttributionParamsWithCallback().listen(
  (params) {
    if (params != null) {
      print('Attribution params: $params');
    }
  },
  onError: (e) => print('Error: $e'),
);
```

### **Checking SDK status**

After calling `configure()`, you can verify the SDK was enabled (for example, that the API key is valid). `isSdkDisabled()` returns `true` when the SDK is disabled.

```dart
await AppstackPlugin.configure('your-api-key');
if (await AppstackPlugin.isSdkDisabled()) {
  print('SDK is disabled - check your API key');
}
```

### **Setting the customer user ID**

The customer user ID is your own identifier for the signed-in user. Appstack attaches it to events so server-to-server events — which identify the user by this ID rather than by the install — can be joined back to the install that produced them.

If you already know the ID at startup, pass it to `configure()`. More often a login reveals it afterwards, so set it whenever it becomes known:

```dart
// On login
await AppstackPlugin.setCustomerUserId('user-123');

// On logout — otherwise the previous user's ID stays attached to later events
await AppstackPlugin.setCustomerUserId(null);
```

- `null` (or a blank string) clears the stored ID. Unlike `configure()`, which never clears, a blank value here is an explicit clear rather than "not provided".
- Callable at any time, before or after `configure()`, as often as you like — the last call wins.
- Applies to every event sent from here on, including ones the native SDK has buffered but not yet flushed. Events already sent are not backfilled and do not need to be: Appstack maps the ID to the install using any event that carries it.
- The call itself sends nothing. Make sure at least one event follows, or no mapping is ever formed.
- Calling `configure()` again to change the ID does not work — a repeat `configure()` is a no-op and its `customerUserId` is ignored.

### **Getting the Appstack ID**

Retrieve the unique Appstack ID for the current user. Returns `null` if it is not available yet.

```dart
final appstackId = await AppstackPlugin.getAppstackId();
print('Appstack ID: $appstackId');
```

### **Environment-based configuration**

Set up different API keys for different environments:

```dart
// Use environment variables or configuration
final apiKey = Platform.isIOS 
    ? const String.fromEnvironment('APPSTACK_IOS_API_KEY')
    : const String.fromEnvironment('APPSTACK_ANDROID_API_KEY');

await AppstackPlugin.configure(apiKey);
```

## **Platform-specific considerations**

### **iOS**

**Apple Ads attribution:**

- Only works on iOS 14.3+
- Requires app installation from App Store or TestFlight
- Attribution data appears within 24-48 hours
- User consent may be required for detailed attribution (iOS 14.5+)

```
if (Platform.isIOS) {
  await AppstackPlugin.enableAppleAdsAttribution();
}
```

### **Android**

**Play Store Attribution**

- Install referrer data collected automatically
- Attribution available immediately for Play Store installs
- Works with Android 5.0+ (API level 21)

### **Cross-platform best practices**

```dart
Future<void> initializeSDK() async {
  final apiKey = Platform.isIOS 
      ? 'your-ios-api-key' 
      : 'your-android-api-key';

  await AppstackPlugin.configure(apiKey);

  if (Platform.isIOS) {
    await AppstackPlugin.enableAppleAdsAttribution();
  }
}
```

## **Limitations**

### **Attribution timing**

- **iOS:** Apple Ads attribution data appears within 24-48 hours after install
- **Android:** Install referrer data available immediately for Play Store installs
- Attribution only available for apps installed from official stores

### **Platform constraints**

- **iOS:** Requires iOS 15.0+
- **Android:** Minimum API level 21 (Android 5.0)
- **Flutter:** 3.3.0+
- Some Apple Ads features may not work in development/simulator environments

### **Event tracking**

- Event names are case-sensitive and standardized
- For revenue events, always pass a `revenue` (or `price`) and a `currency` parameter
- The SDK must be initialized before any tracking calls
- `enableAppleAdsAttribution()` only works on iOS and returns false on Android
- Network connectivity required for event transmission (events are queued offline)

## **Support**

For questions or issues:

1. Check the [GitHub Repository](https://github.com/appstack-tech/appstack-flutter-sdk)
2. Contact our support team at [support@appstack.tech](mailto:support@appstack.tech)
3. Open an issue in the repository
