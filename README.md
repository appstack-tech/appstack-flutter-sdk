# Appstack Flutter SDK

Flutter plugin for tracking events and revenue with Apple Search Ads attribution.

## Structure

This repository contains:

- **`appstack_plugin/`** - The Flutter plugin package
- **`sample_app/`** - Example Flutter app demonstrating the plugin usage

## Quick Start

See the [plugin README](./appstack_plugin/README.md) for installation and usage instructions.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  appstack_plugin: ^0.0.14 # or use pub.dev version when published
```

## Basic Usage

```dart
import 'package:appstack_plugin/appstack_plugin.dart';
import 'dart:io' show Platform;

// Configure the SDK
await AppstackPlugin.configure(
  Platform.isIOS ? 'ios-api-key' : 'android-api-key'
);

// Check if SDK is disabled (optional - for debugging)
final isDisabled = await AppstackPlugin.isSdkDisabled();
if (isDisabled) {
  print('Warning: SDK is disabled - check your API key');
}

// Enable Apple Search Ads attribution (iOS only)
if (Platform.isIOS) {
  await AppstackPlugin.enableAppleAdsAttribution();
}

// Get the Appstack ID
final appstackId = await AppstackPlugin.getAppstackId();
print('Appstack ID: $appstackId');

// Track events
await AppstackPlugin.sendEvent(EventType.purchase, revenue: 29.99);
```

## Documentation

- [Plugin README](./appstack_plugin/README.md) - Complete API documentation
- [Usage Guide](./appstack_plugin/USAGE.md) - Detailed usage examples
- [Changelog](./appstack_plugin/CHANGELOG.md) - Version history

## Platform Support

- **iOS**: 14.3+
- **Android**: API 21+ (Android 5.0+)
- **Flutter**: 3.3.0+

## License

MIT License - see [LICENSE](./appstack_plugin/LICENSE) for details