# Changelog

All notable changes to the Appstack Flutter Plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.7.0] - 2026-09-03

### Changed
- **Updated the Appstack iOS SDK to 4.6.0 and the Appstack Android SDK to 1.8.0** — both releases encrypt the **custom parameters you pass to `sendEvent()`** on the device, before they leave the app, so personal data a Flutter app puts in an event (an email, a phone number, a name) is no longer readable in transit or at the ingestion tier. It is entirely backend-driven: the native SDKs seal every custom parameter whose key is *not* in the backend's plaintext allowlist, and that allowlist is served in remote config, so no Dart change and no `configure()` flag is involved. Because it is an inverse allowlist, a parameter name the SDK has never seen is protected by default; keys that must stay readable (`currency`, `revenue`, campaign fields) are excluded server-side. **Revenue reporting is unchanged** — revenue is extracted into `transaction_details` before encryption, and `transaction_details`, deeplink user data, identifiers and other top-level event fields are not encrypted. If a value cannot be sealed it is omitted from the event rather than sent in the clear, and the rest of the event still sends.
  - Platform floor differs: on **Android** this applies at the SDK's API 21 floor (the implementation is internal Kotlin over the platform JCA primitives — no new dependency, and the AAR grows ~36 KB). On **iOS** on-device encryption requires **iOS 17+**; on iOS 15 and 16 the values are encrypted server-side as before, so behaviour there is unchanged.
  - With no `parameter_encryption` block in remote config — or an absent, unsupported or malformed one — both SDKs keep sending plaintext custom parameters exactly as before and the backend applies its existing encryption. The config is held in memory only and never persisted, so a backend rollback or key rotation takes effect on the next config fetch.

### Fixed

These are iOS SDK 4.6.0 fixes. Android already behaved this way, so each one closes a Flutter cross-platform inconsistency rather than changing Android.

- **A `null` in an event's `parameters` map no longer silently drops the whole event on iOS.** Passing Dart `null` as a parameter value previously caused the event to be discarded without a word; `null` values are now omitted from the payload and the event sends with the rest. Nulls *inside* arrays are preserved. This now matches Android, so the same `sendEvent()` call no longer produces an event on one platform and nothing on the other.
- **`sendEvent()` no longer crashes the app on iOS when a parameter holds a value JSON cannot represent.** Such keys are now dropped individually and named in an error log, and the event still sends with its remaining parameters. From Dart the reachable cases are `double.nan` / `double.infinity` and the typed-data lists (`Uint8List`, `Int32List`, `Int64List`, `Float64List`) — these encode over the platform channel and previously reached the native crash. The other values the native fix covers (`Date`, `URL`, `Set`, custom objects) cannot be sent from Flutter at all: Flutter's `StandardMessageCodec` rejects a Dart `DateTime`, `Uri`, `Set` or arbitrary object with an `ArgumentError` before it ever reaches the bridge, so that part of the fix does not change Flutter behaviour. Stick to strings, finite numbers, booleans, lists, and nested string-keyed maps.
- **A `null` in the attribution match response no longer discards the whole response on iOS** — a single null query parameter could previously cost an install its attribution data, which surfaced through `getAttributionParams()` as missing attribution.

No Dart API changed in this release: `EventType`, `configure()`, `sendEvent()`, `getAttributionParams()` and the rest keep their current signatures, and both bridges still pass parameters and native values through untouched. `sendEvent()`'s documented behaviour around `null` and unsupported parameter values has been tightened to describe what the native SDKs now do.

## [2.6.0] - 2026-08-11

### Added
- `AppstackPlugin.setCustomerUserId(customerUserId)` — sets or clears the customer user ID after `configure()`, bridging the native iOS/Android setter of the same name. Use it when a login reveals the ID; calling `configure()` a second time does not work, as a repeat `configure()` is a no-op and ignores its `customerUserId`. Clear it on logout so the previous user's ID stops being attached to later events. Passing `null` (or a blank string) clears the stored ID — unlike `configure()`, which treats a blank value as "not provided" because it never clears. Safe to call at any time; last write wins.

### Changed
- **Updated the Appstack iOS SDK to 4.5.0** — on iOS, `getAttributionParams()` no longer comes back empty: the map now always carries an `appstack_match_status` key reporting the attribution outcome (`matched`, `matched_no_params`, `organic`, `skipped`, `failed` or `not_configured`). Only `failed` is worth re-reading later; the rest are settled answers. The Dart signature is unchanged — the result is still nullable, so existing null checks keep working — but code that read an empty result as "not attributed" should switch to the status key. Treat the key as iOS-only for now: Android 1.7.0 does not add it, so an empty map still means "nothing yet" there. Also fixed on iOS: a `setCustomerUserId()` call made immediately after `configure()` is no longer overwritten by the `customerUserId` passed to `configure()`, and a blank customer user ID is treated as absent rather than sent as an empty string.
- **Updated the Appstack Android SDK to 1.7.0** — adds the native `setCustomerUserId` setter that `AppstackPlugin.setCustomerUserId()` bridges on Android. No new permission is required.

## [2.5.0] - 2026-08-06

### Changed
- **Updated the Appstack iOS SDK to 4.4.1** — attribution matching now includes additional network context to improve match diagnostics.
- **Updated the Appstack Android SDK to 1.6.0** — attribution matching now includes additional device and network context to improve match accuracy, and the Play install referrer is now resolved before the match request so attribution can be determined deterministically. No new permission is required.
- **`EventType.install` is no longer sent when passed to `sendEvent()`** — both native SDKs already track the install automatically, so sending it by hand previously double-counted installs. Such calls are now logged and discarded natively; the Dart call still succeeds.

### Fixed
- **Android: a remotely disabled app no longer fires the attribution match request** — previously `enabled=false` suppressed only the event POSTs, and a fresh install still called `/attribution/match`. A disabled app now makes no attribution network calls at all.

## [2.4.0] - 2026-07-21

### Changed
- **Updated the Appstack iOS SDK to 4.4.0**
- **Updated the Appstack Android SDK to 1.5.0**
- Raised the minimum supported iOS version to **15.0** (required by iOS SDK 4.4.0). This applies to both integration paths — the Swift Package Manager package (`Package.swift`) and the CocoaPods podspec.

## [2.2.2] - 2026-06-24

### Changed
- **Updated the Appstack iOS SDK to 4.3.1**

## [2.2.1] - 2026-06-17

### Changed
- **Updated the Appstack Android SDK to 1.4.1**

## [2.2.0] - 2026-06-05

### Added
- **Updated the Appstack iOS SDK to 4.2.1**

## [2.1.1] - 2026-05-19

### Fixed
- Synced iOS native implementation across all integration paths (CocoaPods and SPM): the SPM source copies of `AppstackPlugin.swift` were stale and missing `customerUserId`, `wrapperVersion`, and the attribution event channel, causing an undefined symbol error at build time.

## [2.1.0] - 2026-05-19

### Added
- `wrapperVersion` is now automatically passed to the native iOS and Android SDKs on configure, identifying the Flutter wrapper version (e.g. `flutter-2.1.0`). This is handled internally and not exposed to the public API.

## [2.0.6] - 2026-04-23

### Added
- **Updated the Appstack iOS SDK to 4.0.5**

## [2.0.5] - 2026-04-20

### Added
- New `getAttributionParamsWithCallback()` method — retrieves attribution parameters via a push-style stream backed by a native background thread (Swift `Task.detached` on iOS, `Thread` on Android). The stream emits one value then closes. Use this as an alternative to `getAttributionParams()` when attribution retrieval time may vary.

## [2.0.4] - 2026-04-08

### Added
- **Updated the Appstack iOS SDK to 4.0.4**

## [2.0.3] - 2026-04-08

### Added
- **Updated the Appstack iOS SDK to 4.0.2**

## [2.0.2] - 2026-02-10

### Added
- **Updated the supported version of flutter**

## [2.0.1] - 2026-02-10

### Added
- **Updated the iOS SDK to 4.0.1**

## [2.0.0] - 2026-02-08

### Added
- **Updated the iOS SDK to 4.0.0**

## [1.6.2] - 2026-02-08

### Added
- **Updated the iOS SDK to 3.6.2**

## [1.6.1] - 2026-02-08

### Added
- **Updated the iOS SDK to 3.6.1**

## [1.6.0] - 2026-02-04

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