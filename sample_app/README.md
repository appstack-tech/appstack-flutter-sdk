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
- Track various event types:
  - Sign Up
  - Login
  - Purchase (with revenue)
  - Add to Cart (with revenue)
  - View Item
  - Custom events
- Handle errors gracefully
- Display tracked events in the UI

## Code Structure

- `main.dart` - Main application with SDK initialization and event tracking examples
- SDK is configured in `main()` before the app runs
- Events are tracked through button presses in the UI
- Last tracked event is displayed in the UI

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