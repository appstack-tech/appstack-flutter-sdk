# Integration tests

These tests drive the public `AppstackPlugin` API on a **real device/simulator**,
exercising the full Dart → platform channel → native plugin → native SDK round
trip. The pure-Dart unit tests in `appstack_plugin/test/` mock the channel; these
do not — so they're the only thing that proves the native side actually links and
runs.

## Why two iOS runs (SwiftPM vs CocoaPods)?

SwiftPM and CocoaPods/XCFramework are two different ways the native iOS SDK is
linked into the app. They differ only at **build/link time**, not at runtime — so
there's a single shared test suite, run twice under two build configurations.

Just compiling and launching each path catches the regressions that have actually
shipped (v1.0.1, v2.1.1 were both undefined-symbol/missing-module link failures on
one path). CI runs both; see `.github/workflows/integration.yml`.

## Running locally

From `sample_app/`:

```bash
flutter pub get
```

### iOS — SwiftPM path (default on Flutter 3.44+)

```bash
flutter config --enable-swift-package-manager      # no-op on 3.44+
flutter test integration_test \
  --dart-define=APPSTACK_API_KEY=your-key \
  -d <ios-simulator-id>
```

### iOS — CocoaPods / bundled XCFramework path

```bash
flutter config --no-enable-swift-package-manager
cd ios && pod install && cd ..
flutter test integration_test \
  --dart-define=APPSTACK_API_KEY=your-key \
  -d <ios-simulator-id>
```

### Android

```bash
flutter test integration_test \
  --dart-define=APPSTACK_API_KEY=your-key \
  -d <android-emulator-id>
```

## Notes

- `APPSTACK_API_KEY` is optional. Without it, a placeholder key is used and the
  SDK may report itself disabled — the suite tolerates this because its job is to
  validate the bridge/linkage, not backend behavior. Provide a real key to also
  validate end-to-end delivery.
- List available devices with `flutter devices` / `xcrun simctl list devices`.
