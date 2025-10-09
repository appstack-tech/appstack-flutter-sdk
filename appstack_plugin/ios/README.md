# iOS Native Implementation

This directory contains the iOS native implementation for the Appstack Flutter Plugin.

## Structure

- `Classes/AppstackPlugin.swift` - Flutter plugin bridge implementation
- `appstack_plugin/` - Swift Package Manager module
  - `Package.swift` - SPM package definition with GitHub dependency
  - `Sources/appstack_plugin/` - Plugin source code
- `appstack_plugin.podspec` - CocoaPods specification

## AppstackSDK Dependency

The iOS AppstackSDK is **automatically fetched from GitHub** via Swift Package Manager. The dependency is defined in `appstack_plugin/Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/appstack-tech/ios-appstack-sdk.git", exact: "2.3.0"),
]
```

### Why Swift Package Manager?

- ✅ **No bundled binaries**: Reduces repository size and maintenance overhead
- ✅ **Always up-to-date**: Automatically fetches the specified version from the official repository
- ✅ **Single source of truth**: Uses the same SDK as native iOS apps
- ✅ **Better version management**: Semantic versioning with easy updates

### Updating the SDK Version

To update the AppstackSDK to a newer version:

1. Edit `appstack_plugin/Package.swift` and update the exact version:
   ```swift
   .package(url: "https://github.com/appstack-tech/ios-appstack-sdk.git", exact: "2.4.0"),
   ```

2. The framework will be automatically fetched during the next build

3. No need to commit any XCFramework files

**Note:** We use `exact:` instead of `from:` to pin to a specific release version, ensuring consistent builds across all environments.

## Implementation Details

The plugin uses Flutter's MethodChannel to communicate between Dart and native iOS code:

- **configure**: Initializes the SDK with API key and optional parameters
- **sendEvent**: Tracks events with optional revenue
- **enableAppleAdsAttribution**: Enables Apple Search Ads attribution (iOS only)

All EventType enum values are mapped from Dart strings to Swift EventType enum values.

## CocoaPods Integration

For Flutter apps using CocoaPods (default), the SPM dependency is automatically resolved when running `pod install`. Flutter's build system handles the integration of Swift Package Manager dependencies with CocoaPods.

