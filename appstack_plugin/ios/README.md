# iOS Native Implementation

This directory contains the iOS native implementation for the Appstack Flutter Plugin.

## Structure

- `Classes/AppstackPlugin.swift` - Flutter plugin bridge implementation
- `AppstackSDK.xcframework/` - Bundled AppstackSDK framework
- `appstack_plugin.podspec` - CocoaPods specification

## AppstackSDK.xcframework

The iOS AppstackSDK is bundled as an XCFramework that supports:
- iOS devices (arm64)
- iOS Simulator (arm64, x86_64)

### Updating the Framework

To update the AppstackSDK.xcframework to a newer version:

1. Copy the latest `AppstackSDK.xcframework` from the `ios-appstack-sdk` repository:
   ```bash
   cp -R /path/to/ios-appstack-sdk/AppstackSDK.xcframework ./
   ```

2. Commit the updated framework to version control

3. Update the version in `appstack_plugin.podspec` if needed

## Implementation Details

The plugin uses Flutter's MethodChannel to communicate between Dart and native iOS code:

- **configure**: Initializes the SDK with API key and optional parameters
- **sendEvent**: Tracks events with optional revenue
- **enableAppleAdsAttribution**: Enables Apple Search Ads attribution (iOS only)

All EventType enum values are mapped from Dart strings to Swift EventType enum values.
