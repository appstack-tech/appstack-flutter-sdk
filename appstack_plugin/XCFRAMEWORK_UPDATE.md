# Updating the AppstackSDK XCFramework

This document explains how to update the bundled AppstackSDK XCFramework for CocoaPods users.

WARNING : This feature will be removed as soon as this ticket will be completed and we will go back to SPM usage to have a much cleaner repository ([deprecation on flutter's side of cocoapods](https://github.com/flutter/flutter/issues/168015))

## Overview

The Flutter plugin includes a copy of the AppstackSDK XCFramework in the `ios/` directory. This allows CocoaPods users to integrate the SDK without requiring Swift Package Manager support.

## Update Process

When a new version of the iOS AppstackSDK is released, follow these steps to update the bundled XCFramework:

### 1. Copy the New XCFramework

```bash
# Navigate to the Flutter plugin directory
cd /path/to/appstack-flutter-sdk/appstack_plugin

# Remove the old XCFramework
rm -rf ios/AppstackSDK.xcframework

# Copy the new XCFramework from the iOS SDK
cp -R /path/to/ios-appstack-sdk/AppstackSDK.xcframework ios/
```

### 2. Validate the Podspec

```bash
# Navigate to the iOS directory
cd ios

# Run pod lib lint to validate the podspec
pod lib lint appstack_plugin.podspec --allow-warnings
```

### 3. Update Version Numbers

If the iOS SDK version has changed, update the following files:

**`ios/appstack_plugin.podspec`:**
- Update the `s.version` if needed
- Add version notes in comments if appropriate

**`README.md`:**
- Update any version references
- Update minimum iOS version if changed

**`CHANGELOG.md`:**
- Document the XCFramework update
- Note any breaking changes or new features

### 4. Test the Integration

Test the updated XCFramework with a sample Flutter app:

```bash
# Create or use a test Flutter app
cd /path/to/test-app

# Clean and reinstall
flutter clean
cd ios
pod deintegrate
pod install
cd ..

# Build the iOS app
flutter build ios --debug
```

### 5. Commit the Changes

```bash
git add ios/AppstackSDK.xcframework
git commit -m "Update AppstackSDK XCFramework to version X.X.X"
```

## XCFramework Structure

The XCFramework should contain the following structure:

```
AppstackSDK.xcframework/
├── Info.plist
├── ios-arm64/
│   └── AppstackSDK.framework/
│       ├── AppstackSDK (binary)
│       ├── Headers/
│       │   └── AppstackSDK.h
│       ├── Info.plist
│       └── Modules/
│           ├── AppstackSDK.swiftmodule/
│           └── module.modulemap
└── ios-arm64_x86_64-simulator/
    └── AppstackSDK.framework/
        ├── AppstackSDK (binary)
        ├── Headers/
        │   └── AppstackSDK.h
        ├── Info.plist
        └── Modules/
            ├── AppstackSDK.swiftmodule/
            └── module.modulemap
```

## Supported Architectures

The XCFramework must support:
- **Device:** `arm64` (iOS devices)
- **Simulator:** `arm64` and `x86_64` (Apple Silicon and Intel Macs)

## Minimum iOS Version

The XCFramework should support iOS 13.0+ as specified in the podspec:
```ruby
s.platform = :ios, '13.0'
```

## Troubleshooting

### Validation Fails

If `pod lib lint` fails:
1. Check that all required architectures are present
2. Verify the XCFramework structure matches the expected format
3. Ensure the minimum iOS version is compatible
4. Check for any missing Swift module files

### Build Errors

If Flutter builds fail after updating:
1. Run `flutter clean`
2. Delete the `Pods` directory and `Podfile.lock`
3. Run `pod install` again
4. Check Xcode build logs for specific errors

### "No such module 'AppstackSDK'" Error

This usually means:
1. The XCFramework wasn't copied correctly
2. The podspec path is wrong
3. Pod install needs to be run again

## Related Documentation

- [SPM Setup Guide](./SPM_SETUP_GUIDE.md) - For users who prefer Swift Package Manager
- [iOS AppstackSDK](https://github.com/appstack-tech/ios-appstack-sdk) - Source of the XCFramework
- [React Native SDK](../react-native-appstack-sdk/ios/) - Similar CocoaPods integration pattern

## Support

For issues with XCFramework updates:
- Check the iOS SDK repository for release notes
- Verify XCFramework integrity with `file ios/AppstackSDK.xcframework/*/AppstackSDK.framework/AppstackSDK`
- Contact support at support@appstack.tech

