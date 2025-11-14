# Appstack Flutter Plugin - Sample App

This is a sample Flutter application demonstrating the usage of the Appstack Flutter Plugin.

## Setup

1. **Install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Configure API Keys:**
   
   Edit `lib/main.dart` and replace the placeholder API keys with your actual keys:
   ```dart
   final apiKey = Platform.isIOS 
       ? 'your-ios-api-key-here'  // Replace with your iOS API key
       : 'your-android-api-key-here';  // Replace with your Android API key
   ```

3. **iOS Setup:**
   
   Add to `ios/Runner/Info.plist`:
   ```xml
   <key>NSAdvertisingAttributionReportEndpoint</key>
   <string>https://ios-appstack.com/</string>
   ```
   
   Then run:
   ```bash
   cd ios && pod install
   ```

4. **Android Setup:**
   
   Ensure `android/build.gradle` has the required repositories:
   ```gradle
   allprojects {
       repositories {
           google()
           mavenCentral()
           maven { url 'https://jitpack.io' }
       }
   }
   ```

## Running the App

```bash
# Run on iOS
flutter run -d ios

# Run on Android
flutter run -d android
```

## Features Demonstrated

The sample app shows how to:

- Configure the Appstack SDK on app startup
- Enable Apple Search Ads attribution (iOS only)
- Retrieve and display the Appstack ID
- Refresh the Appstack ID on demand
- Track various event types with different parameters:
  - Sign Up (no parameters)
  - Login (no parameters)
  - Purchase (with revenue and currency parameters)
  - Add to Cart (with revenue and currency parameters)
  - View Item (no parameters)
  - Custom events (no parameters)
  - Level Start (with level and difficulty parameters)
  - Search (with query and results count parameters)
  - User Engagement (with multiple custom parameters)
- Handle errors gracefully
- Display tracked events in the UI
- Demonstrate the new parameters-based event tracking API

## Code Structure

- `main.dart` - Main application with SDK initialization and event tracking examples
- SDK is configured in `main()` before the app runs
- Appstack ID is loaded automatically when the app starts
- Events are tracked through button presses in the UI
- Last tracked event is displayed in the UI
- Appstack ID can be refreshed with a button press

## Event Parameters

The sample app demonstrates the new parameters-based event tracking API introduced in version 0.0.15:

```dart
// Simple event without parameters
await AppstackPlugin.sendEvent(EventType.login);

// Event with revenue parameters
await AppstackPlugin.sendEvent(EventType.purchase, parameters: {
  'revenue': 29.99,
  'currency': 'USD'
});

// Event with custom parameters
await AppstackPlugin.sendEvent(EventType.search, parameters: {
  'query': 'flutter tutorial',
  'results_count': 25
});

// Complex custom event
await AppstackPlugin.sendEvent(EventType.custom,
  eventName: 'user_engagement',
  parameters: {
    'time_spent': 120,
    'feature': 'dashboard',
    'interaction_type': 'scroll'
  }
);
```

Parameters can include any data relevant to your analytics needs, such as revenue, currency, product IDs, categories, user segments, etc.

## Troubleshooting

**iOS:**
- Make sure you've run `pod install` in the `ios` directory
- Check that Info.plist has the attribution endpoint configured
- Verify your iOS API key is correct

**Android:**
- Ensure the Maven repository is configured in `build.gradle`
- Verify your Android API key is correct
- Check that minimum SDK is set to 21 or higher

**Both Platforms:**
- Check console logs for any error messages
- Ensure you have network connectivity
- Verify API keys are correct and active