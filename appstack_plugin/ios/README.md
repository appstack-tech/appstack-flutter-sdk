# iOS Native Implementation

This directory contains the iOS native implementation for the Appstack Flutter Plugin.

## Structure

- `appstack_plugin/` - Swift Package Manager module
  - `Package.swift` - SPM package definition with GitHub dependency
  - `Sources/appstack_plugin/AppstackPlugin.swift` - **single source of truth** for the
    Flutter plugin bridge implementation
- `appstack_plugin.podspec` - CocoaPods specification; its `source_files` points at the
  SPM `Sources/` directory above so both integration paths compile the same file (no
  duplicated copies). See
  https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-plugin-authors

## AppstackSDK Dependency

The native AppstackSDK reaches the app through **two different mechanisms, one per
integration path** — they must be kept on the same version:

- **Swift Package Manager** fetches `ios-appstack-sdk` from GitHub, pinned in
  `appstack_plugin/Package.swift`:
  ```swift
  dependencies: [
      .package(url: "https://github.com/appstack-tech/ios-appstack-sdk.git", exact: "4.2.1"),
  ]
  ```
- **CocoaPods** links the **bundled `AppstackSDK.xcframework`** committed in this
  directory, via `s.ios.vendored_frameworks` in `appstack_plugin.podspec`. CocoaPods
  cannot consume a Swift Package, so the binary has to ship in the repo for this path.

We pin with `exact:` (not `from:`) so SPM builds are reproducible.

### Updating the SDK Version

Both paths must be bumped together, or the two integrations ship different SDK builds:

1. Edit `appstack_plugin/Package.swift` and update the exact version (SPM path):
   ```swift
   .package(url: "https://github.com/appstack-tech/ios-appstack-sdk.git", exact: "4.3.0"),
   ```
2. Replace `AppstackSDK.xcframework/` with the matching build of the same release
   (CocoaPods path), and commit it.
3. Verify both paths still link — see `sample_app/integration_test/README.md`.

## Implementation Details

The plugin uses Flutter's MethodChannel to communicate between Dart and native iOS code:

- **configure**: Initializes the SDK with API key and optional parameters
- **sendEvent**: Tracks events with optional revenue
- **enableAppleAdsAttribution**: Enables Apple Search Ads attribution (iOS only)

All EventType enum values are mapped from Dart strings to Swift EventType enum values.

## CocoaPods Integration

For Flutter apps on the CocoaPods path, `pod install` reads `appstack_plugin.podspec`,
compiles `appstack_plugin/Sources/appstack_plugin/AppstackPlugin.swift`, and links the
bundled `AppstackSDK.xcframework`. (The SPM path does not use CocoaPods at all — Flutter
resolves the package directly.)

