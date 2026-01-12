# Appstack Flutter SDK

Flutter plugin for tracking events and revenue with Apple Search Ads attribution.

## Overview

This repository contains the Flutter SDK and a sample app. For a consistent “one page” reference (features + EAC recommendations), see the plugin README:

- `appstack_plugin/README.md`

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
  appstack_plugin: ^1.2.0
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

// Get attribution parameters
final attributionParams = await AppstackPlugin.getAttributionParams();
print('Attribution Params: $attributionParams');

// Track events
await AppstackPlugin.sendEvent(EventType.purchase, parameters: {'revenue': 29.99, 'currency': 'USD'});
```

### `getAttributionParams(): Future<Map<String, dynamic>?>`
Retrieve attribution parameters from the SDK. This returns all available attribution data that the SDK has collected.

**Returns:** A map containing attribution parameters (key-value pairs), or `null` if not available yet.

**Example:**
```dart
final attributionParams = await AppstackPlugin.getAttributionParams();
print('Attribution parameters: $attributionParams');

// Example output (varies by platform):
// {
//   "attribution_source": "google_play",
//   "install_timestamp": "1733629800",
//   "attributed": "true",
//   ...
// }
```

**Use Cases:**
- Retrieve attribution data for analytics
- Check if the app was attributed to a specific campaign
- Log attribution parameters for debugging
- Send attribution data to your backend server
- Analyze user acquisition sources

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