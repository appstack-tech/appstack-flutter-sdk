# Updating the AppstackSDK XCFramework

This document explains how to update the bundled AppstackSDK XCFramework for CocoaPods users.

WARNING : This feature will be removed as soon as this ticket will be completed and we will go back to SPM usage to have a much cleaner repository ([deprecation on flutter's side of cocoapods](https://github.com/flutter/flutter/issues/168015))

## Overview

The plugin ships the native iOS SDK through two independent paths, and **they must
stay in lockstep**:

| Path | Used by | Source of the binary |
|---|---|---|
| Swift Package Manager | Flutter 3.44+ | the `exact:` pin in `ios/appstack_plugin/Package.swift` |
| CocoaPods | older Flutter | the vendored `ios/AppstackSDK.xcframework` (tracked in git) |

Nothing in the build forces those to agree. They diverged once and it shipped:
**2.4.0 vendored a `4.4.0-rc0` XCFramework against an `exact: "4.4.0"` pin.** The
public `.swiftinterface` was identical across rc0/rc1/rc2/final, so `flutter
analyze`, `pod lib lint`, the unit tests and both build/link legs all passed —
only the binaries differed. SwiftPM users and CocoaPods users were running
different code.

## Two hard rules

1. **Always vendor the official release zip for the pinned tag.** Never build the
   framework yourself, and never `cp -R` it out of a local `ios-appstack-sdk`
   checkout or another project — a working tree can hold an unreleased or rc
   build, which is exactly how the 2.4.0 mismatch happened.
2. **Never vendor an rc while pinning a final** (or vice versa). If you change
   the `exact:` pin, re-vendor in the *same commit*.

Both are enforced by `tool/check_ios_sdk_parity.sh`, which runs on every PR
(`test.yml`) and gates the release before anything expensive happens
(`publish.yml`). See [Verifying parity](#verifying-parity).

## Update Process

When a new version of the iOS AppstackSDK is released, follow these steps to update the bundled XCFramework:

### 1. Update the SwiftPM pin

In `ios/appstack_plugin/Package.swift`, set the dependency to the new tag:

```swift
.package(url: "https://github.com/appstack-tech/ios-appstack-sdk.git", exact: "X.Y.Z"),
```

Keep it an `exact:` pin. A version range cannot be reconciled with a single
vendored binary, and the parity check will refuse to run against one.

### 2. Re-vendor the XCFramework from the official release

Upstream publishes the SDK as a SwiftPM `binaryTarget`, so each tag has a release
zip *and* a checksum committed in upstream's own `Package.swift`. Use that
checksum — it is the only authoritative fingerprint of the artifact.

```bash
cd /path/to/appstack-flutter-sdk/appstack_plugin

VERSION=X.Y.Z   # must match the exact: pin above

# Read the release URL and the checksum upstream committed for this tag, and
# capture them rather than assuming the asset path — if upstream ever renames the
# asset, this keeps following the manifest instead of guessing.
MANIFEST=$(curl -fsSL "https://raw.githubusercontent.com/appstack-tech/ios-appstack-sdk/$VERSION/Package.swift")
ZIP_URL=$(printf '%s' "$MANIFEST" | sed -nE 's/.*url:[[:space:]]*"(https:\/\/[^"]*\.zip)".*/\1/p')
EXPECTED=$(printf '%s' "$MANIFEST" | sed -nE 's/.*checksum:[[:space:]]*"([0-9a-fA-F]{64})".*/\1/p')
echo "$ZIP_URL"; echo "$EXPECTED"

# Download the artifact and verify it before it goes anywhere near the repo.
curl -fsSL -o /tmp/AppstackSDK.xcframework.zip "$ZIP_URL"
shasum -a 256 /tmp/AppstackSDK.xcframework.zip   # must equal $EXPECTED

# Replace the vendored copy with the zip contents, verbatim.
rm -rf ios/AppstackSDK.xcframework
ditto -x -k /tmp/AppstackSDK.xcframework.zip ios/
```

Notes on that last step:

- **Use `ditto -x -k`, not `unzip`.** macOS's `unzip` does not faithfully restore
  symlinked framework bundles.
- **Extract verbatim — do not reshape the tree.** Upstream's zip stores the
  maccatalyst slice flattened rather than with the canonical
  `Versions/Current` symlink layout. Leave it flattened: that is the same on-disk
  layout every SwiftPM consumer already gets, it keeps the vendored tree
  byte-identical to the pinned artifact, and it removes any question of whether
  the pub.dev archive preserves framework symlinks. Hand-reconstructing the
  bundle is a drift vector, not a cleanup.
- The checksum covers the **zip**, not the extracted `.xcframework`. You cannot
  hash the vendored directory and compare it against the checksum.

### 3. Confirm parity

```bash
bash tool/check_ios_sdk_parity.sh
```

This must pass before you go any further. It re-derives everything from upstream
rather than trusting the copy you just made.

### 4. Validate the Podspec

```bash
# Navigate to the iOS directory
cd ios

# Run pod lib lint to validate the podspec
pod lib lint appstack_plugin.podspec --allow-warnings
```

### 5. Update Version Numbers

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

### 6. Test the Integration

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

### 7. Commit the Changes

Commit the pin and the re-vendored framework **together** — a commit that moves
one without the other is the bug this document exists to prevent.

```bash
git add ios/appstack_plugin/Package.swift ios/AppstackSDK.xcframework
git commit -m "Upgrade AppstackSDK XCFramework to X.Y.Z"
```

## Verifying parity

`tool/check_ios_sdk_parity.sh` is the mechanical guard that the two integration
paths ship the same build:

```bash
bash appstack_plugin/tool/check_ios_sdk_parity.sh
```

It reads the `exact:` pin, fetches upstream's `Package.swift` at that tag, pulls
the release URL and checksum out of it, downloads the zip, verifies its SHA256,
extracts it, and compares it against the vendored tree file-by-file. On drift it
prints the differing paths.

Where it runs:

- **`.github/workflows/test.yml`** — on every PR, before the Flutter toolchain is
  even installed.
- **`.github/workflows/publish.yml`** — as the `verify` job that gates
  `integration`, so drift cancels a release before the simulator/emulator matrix
  and before GCP auth.

The check is deliberately fail-closed: an unparseable manifest, a moved release
asset, a missing tag or a network error all fail the build rather than passing
quietly. If it starts failing for a structural reason, fix the script — do not
skip it. The mismatch it catches survived an entire release precisely because
nothing else looks at the bytes.

Two things that make a naive comparison report false drift, both handled by the
script (worth knowing if you ever compare by hand):

- Upstream's zip stores the maccatalyst slice **flattened**, while a framework
  bundle may use the canonical **symlink** layout. `diff -r` then reports ~24
  bogus "Only in" entries and can abort with "Directory loop detected".
  Normalizing both sides with `find -L -type f` yields the same logical tree.
- The top-level `Info.plist` lists `AvailableLibraries` in an order that is not
  stable between copies, so byte-comparing that one file can fail even when the
  slices are equivalent. Vendoring the zip verbatim keeps it identical; if it
  ever shows up as the *only* difference, compare the parsed plists before
  assuming real drift.

## XCFramework Structure

Whatever the pinned release contains, verbatim. As of 4.5.0 that is three slices
plus dSYMs (69 files following symlinks):

```text
AppstackSDK.xcframework/
├── Info.plist
├── ios-arm64/
│   ├── AppstackSDK.framework/
│   │   ├── AppstackSDK (binary)
│   │   ├── Headers/AppstackSDK.h
│   │   ├── Info.plist
│   │   └── Modules/
│   │       ├── AppstackSDK.swiftmodule/
│   │       └── module.modulemap
│   └── dSYMs/AppstackSDK.framework.dSYM/
├── ios-arm64_x86_64-simulator/
│   ├── AppstackSDK.framework/          (same shape, + _CodeSignature/)
│   └── dSYMs/AppstackSDK.framework.dSYM/
└── ios-arm64_x86_64-maccatalyst/
    ├── AppstackSDK.framework/          (Versions/A/… layout, flattened in the zip)
    └── dSYMs/AppstackSDK.framework.dSYM/
```

Do not add, prune or restructure slices to make this diagram match — the vendored
tree must equal the pinned artifact. If the shape changes upstream, update the
diagram.

## Supported Architectures

The XCFramework must support:
- **Device:** `arm64` (iOS devices)
- **Simulator:** `arm64` and `x86_64` (Apple Silicon and Intel Macs)

The release also carries a Mac Catalyst slice (`ios-arm64_x86_64-maccatalyst`).
The podspec only declares `s.ios.vendored_frameworks`, so CocoaPods never links
it — it is vendored because it is part of the official artifact, and stripping it
would break parity with the pinned release.

## Minimum iOS Version

The XCFramework should support iOS 15.0+ as specified in the podspec:
```ruby
s.platform = :ios, '15.0'
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

