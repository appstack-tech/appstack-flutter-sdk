# Build and runtime checks

The pull-request gate has two complementary parts:

- **Build and link checks** compile the sample application through each supported
  native integration path. Flutter runs iOS through both SwiftPM and
  CocoaPods/XCFramework, plus Android through Gradle.
- **Hermetic runtime checks** launch the application on a simulator or emulator,
  drive the public `AppstackPlugin` API, and validate the native SDK's requests
  against a local recording backend.

No real Appstack key or Appstack service is used. The harness configures the
native SDK with `runtime-validation-local-key` and routes traffic only to host
loopback.

## Validated runtime contract

`tool/run_runtime_validation.sh`:

1. Starts `tool/runtime_validation/mock_server.py` on random loopback ports.
2. Injects the HTTP proxy URL into the native test application.
3. On Android, generates a one-day local certificate, bundles its CA only in the
   temporary debug application, and forwards the HTTP and HTTPS ports with
   `adb reverse`.
4. Runs `integration_test/appstack_sdk_integration_test.dart` on the target.
5. Validates the probe's `APPSTACK_RUNTIME_RESULT` line and the mock's JSONL
   request recording.

The validator proves that configuration and attribution matching occurred, the
UTF-8 attribution value `café 🚀` crossed the native bridge intact, and custom
and standard events reached the native wire boundary. It also checks
`customer_user_id`, `wrapper_version`, strings, numbers, booleans, arrays, nested
maps, and UTF-8 event parameters.

Native lifecycle and install events are recorded but their counts are not
asserted because they depend on persisted native SDK state.

## Running locally

Install dependencies from `sample_app/`:

```bash
flutter pub get
```

### iOS — SwiftPM

```bash
flutter config --enable-swift-package-manager
bash tool/run_runtime_validation.sh ios [simulator-udid]
```

### iOS — CocoaPods/XCFramework

```bash
flutter config --no-enable-swift-package-manager
cd ios && pod install && cd ..
bash tool/run_runtime_validation.sh ios [simulator-udid]
```

When no UDID is supplied, the harness selects and boots the first available
iPhone simulator. `IOS_SIMULATOR_UDID` provides the same override through the
environment.

### Android

Start an emulator or attach a device, then run:

```bash
bash tool/run_runtime_validation.sh android [device-serial]
```

When no serial is supplied, the harness uses `ANDROID_SERIAL` or the first
authorized target returned by `adb devices`.

The harness prints its diagnostics directory. It contains the Flutter runtime
log, mock-server log, recorded requests, generated certificate, and validator
output. When a runtime check fails, CI prints the relevant text files in grouped
GitHub Actions logs; it does not upload or retain them as artifacts.

## Test-only native configuration

iOS reads the generated `ios/Flutter/RuntimeValidation.xcconfig` through an
optional include. Android reads Gradle manifest placeholders and temporarily adds
`android/app/src/runtimeValidationGenerated/res` as a debug resource source.
Both generated locations are ignored and removed when the harness exits. Normal
sample and published-plugin builds receive no proxy URL or local certificate.
