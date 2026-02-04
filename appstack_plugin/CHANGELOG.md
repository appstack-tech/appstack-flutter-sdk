# Changelog

All notable changes to the Appstack Flutter Plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.6.0] - 2026-01-28

### Added
- **Updated the iOS SDK to 3.6.0**

## [1.5.1] - 2026-01-28

### Added
- **Updated the Android SDK to 1.3.1**
- **Updated the iOS SDK to 3.5.1**
- **Add the support of customer_user_id in configure method**

## [1.5.0] - 2026-01-28

### Added
- **Updated the Android SDK to 1.3.0**
- **Updated the iOS SDK to 3.5.0**

## [1.4.1] - 2026-01-15

### Added
- **Fix some bugs linked to Apple Search Ads attribution (upgrade to iOS 3.3.1)**

## [1.4.0] - 2026-01-14

### Added
- **Rollback some buggy modifications of 3.2.0 (upgrade to 3.3.0)**

## [1.3.0] - 2026-01-02

### Added
- **New securities on iOS (upgrade to 3.2.0)**

## [1.2.0] - 2025-12-15

### Added
- **New matching method on Android (upgrade to 1.2.2)**
- **New securities on iOS (upgrade to 3.1.1)**

## [1.1.0] - 2025-12-09

### Added
- New `getAttributionParams()` method to retrieve attribution parameters from the SDK
- Updated iOS and Android SDK references to latest versions with attribution params support
- Added attribution params display in sample app

## [1.0.4] - 2025-12-04

### Fixed
- Updated the iOS SDK dependencies (SPM & Pods static files) to 3.0.2. 

## [1.0.3] - 2025-11-25

### Fixed
- Updated the way we are handling the methods on iOS to ensure we are avoiding
crashes & threads hanging

## [1.0.2] - 2025-11-17

### Fixed
- Updated SPM plugin code to use `parameters` map instead of deprecated `revenue` parameter in `sendEvent` method

## [1.0.1] - 2025-11-17

### Fixed
- Fixed iOS SDK version reference to use 3.0.0 instead of 2.5.0, resolving compilation errors with `sendEvent` parameters and `isSdkDisabled` method

## [1.0.0] - 2025-11-14

### Changed
- **BREAKING CHANGE**: Modified `sendEvent()` method to accept `parameters` map instead of `revenue` parameter
- Updated iOS SDK reference to 3.0.0
- Updated Android SDK reference to 1.0.0
- Both SDK versions now use parameters dictionary for event data instead of separate revenue parameter
- Updated all examples and documentation to use the new parameters-based API

### Migration Guide
```dart
// Old API (deprecated)
await AppstackPlugin.sendEvent(EventType.purchase, revenue: 29.99);

// New API (current)
await AppstackPlugin.sendEvent(EventType.purchase, parameters: {'revenue': 29.99, 'currency': 'USD'});
```

## [0.0.14] - 2025-10-31

### Changed
- Modified `configure()` method to return `Future<void>` instead of `Future<bool>`
- Updated documentation and examples to reflect the void return type
- Add a method `isSdkDisabled()` to see the value configured in the iOS or the Android SDK

## [0.0.13] - 2025-10-29

### Added
- New `getAppstackId()` method to retrieve the unique Appstack ID for the current user
- Updated example app to demonstrate the new `getAppstackId()` functionality
- Comprehensive test coverage for the new method across all platform layers
- Retrieve IDFA automatically on iOS

### Changed
- Updated iOS native implementation to expose `getAppstackId()` from AppstackSDK
- Updated Android native implementation to expose `getAppstackId()` from AppstackSDK
- Enhanced documentation with usage examples for the new method

## [0.0.12] - 2025-10-17
- **IMPORTANT** : Add the support to be able to install the SDK with CocoaPods
- **WARNING** : This support feature will be removed as soon as this ticket will be completed and we will go back to SPM usage to have a much cleaner repository ([deprecation on flutter's side of cocoapods](https://github.com/flutter/flutter/issues/168015))

## [0.0.11] - 2025-10-16
- Update the documentation to reference the SPM setup needed to make works the SDK

## [0.0.10] - 2025-10-15
- Update the changelog for 0.0.9 and 0.0.10 to avoid having a reduced score on pub.dev

## [0.0.9] - 2025-10-15
- Update the iOS SDK reference to 2.5.0 (use the new automatic releases for iOS)

## [0.0.8] - 2025-10-06

### Fixed
- Clean the bundling of the iOS Appstack SDK (using SPM / GitHub refs)

## [0.0.7] - 2025-10-06

### Fixed
- Fixed some bugs due to the cleanup

## [0.0.6] - 2025-10-06

### Fixed - DEPRECATED
- Fixed some bugs due to the cleanup

## [0.0.5] - 2025-10-06

### Fixed - DEPRECATED
- Did some cleanup to do easier maintenances on the SDK

## [0.0.4] - 2025-10-06

### Fixed
- Match in a better way what is expected for Swift Package Manager handling

## [0.0.3] - 2025-10-06

### Added
- Example documentation necessary for pub.dev points completion
- Formatting using dart format .
- add Package.swift to handle Swift Package Manager

## [0.0.2] - 2025-10-06

### Added
- Automatic release CD for the appstack_plugin


## [0.0.1] - 2025-10-06

### Added
- Initial release of Appstack Flutter Plugin
- Support for iOS (14.3+) and Android (API 21+)
- Event tracking with `sendEvent()` method
- Revenue tracking for purchase events
- Apple Search Ads attribution support on iOS
- Comprehensive EventType enum with standard attribution events
- Debug mode and custom log levels
- Custom endpoint URL support
- Simple, clean API following Flutter best practices

### Features
- **iOS Integration**: Full support for Apple Search Ads attribution
- **Android Integration**: Google Play Store attribution support
- **Event Types**: 
  - Lifecycle: install, login, signUp, register
  - Monetization: purchase, addToCart, addToWishlist, initiateCheckout, startTrial, subscribe
  - Gaming: levelStart, levelComplete
  - Engagement: tutorialComplete, search, viewItem, viewContent, share
  - Custom: custom events with custom names
- **Configuration Options**: Debug mode, log levels, custom endpoints
- **Documentation**: Complete README and USAGE guide

### Technical Details
- Minimum iOS version: 14.3
- Minimum Android SDK: 21 (Android 5.0)
- Flutter SDK: 3.3.0+
- Dart SDK: 3.9.2+
- Dependencies:
  - iOS: AppstackSDK ~> 2.0
  - Android: tech.appstack.android-sdk:appstack-android-sdk:0.0.12