# Changelog

All notable changes to the Appstack Flutter Plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
  - Android: attribution-sdk 0.0.9