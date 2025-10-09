# Appstack Plugin Example

This example demonstrates how to use the `appstack_plugin` package in a Flutter application.

## Features Demonstrated

- **SDK Configuration**: Configure the Appstack SDK with your API key
- **Event Tracking**: Send various types of events including:
  - Lifecycle events (install, login, sign up)
  - Monetization events (purchase, subscription, add to cart)
  - Engagement events (tutorial complete, view item, search)
  - Custom events
- **Apple Ads Attribution**: Enable Apple Search Ads Attribution tracking (iOS only)

## Getting Started

1. **Get your API key**: Sign up at [Appstack Dashboard](https://dashboard.appstack.com) to get your API key.

2. **Run the example**:
   ```bash
   cd example
   flutter pub get
   flutter run
   ```

3. **Configure the SDK**:
   - Enter your API key in the text field
   - Tap "Configure SDK" to initialize the plugin

4. **Send events**:
   - Once configured, you can tap any of the event buttons to send different types of events
   - The status will show whether the event was sent successfully

## Code Examples

### Basic Configuration

```dart
import 'package:appstack_plugin/appstack_plugin.dart';

// Configure the SDK
await AppstackPlugin.configure('your-api-key');
```

### Sending Events

```dart
// Send a purchase event with revenue
await AppstackPlugin.sendEvent(
  EventType.purchase, 
  revenue: 29.99
);

// Send a custom event
await AppstackPlugin.sendEvent(
  EventType.custom, 
  eventName: 'Custom Event Name'
);

// Send a login event
await AppstackPlugin.sendEvent(EventType.login);
```

### Apple Ads Attribution (iOS only)

```dart
// Enable Apple Search Ads Attribution
await AppstackPlugin.enableAppleAdsAttribution();
```

## Available Event Types

The plugin supports the following event types:

- **Lifecycle**: `install`, `login`, `signUp`, `register`
- **Monetization**: `purchase`, `addToCart`, `addToWishlist`, `initiateCheckout`, `startTrial`, `subscribe`
- **Games/Progression**: `levelStart`, `levelComplete`
- **Engagement**: `tutorialComplete`, `search`, `viewItem`, `viewContent`, `share`
- **Custom**: `custom` (for application-specific events)

## Platform Support

- ✅ iOS (with Apple Ads Attribution support)
- ✅ Android
- ✅ Web (basic functionality)

## Debug Mode

The example enables debug mode by default. In production, you should set `isDebug: false` when configuring the SDK.

## Error Handling

The plugin methods return `Future<bool>` indicating success/failure. Always wrap calls in try-catch blocks to handle potential exceptions:

```dart
try {
  final success = await AppstackPlugin.sendEvent(EventType.purchase);
  if (success) {
    print('Event sent successfully');
  } else {
    print('Failed to send event');
  }
} catch (e) {
  print('Error: $e');
}
```

## Learn More

- [Appstack Documentation](https://docs.appstack.com)
- [Flutter Plugin Development](https://flutter.dev/docs/development/packages-and-plugins/developing-packages)
