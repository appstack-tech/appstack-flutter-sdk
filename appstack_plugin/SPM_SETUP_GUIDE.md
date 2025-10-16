# Swift Package Manager Setup Guide

## Problem

When using `appstack_plugin` in a Flutter app, you may encounter this error:

```
Swift Compiler Error (Xcode): No such module 'AppstackSDK'
/Users/.../.pub-cache/hosted/pub.dev/appstack_plugin-X.X.X/ios/Classes/AppstackPlugin.swift:2:7
```

This happens because the plugin uses Swift Package Manager (SPM) for its iOS SDK dependency, but SPM support needs to be explicitly enabled in Flutter.

## Solution

### Step 1: Enable Swift Package Manager in Flutter

Run this command **once** to enable SPM support globally:

```bash
flutter config --enable-swift-package-manager
```

You can verify it's enabled by running:

```bash
flutter config --list | grep swift
```

You should see:
```
enable-swift-package-manager: true
```

### Step 2: Clean and Regenerate Your Project

Navigate to your app directory and run:

```bash
flutter clean
flutter pub get
```

### Step 3: Reinstall CocoaPods (if using)

```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
```

### Step 4: Build Your App

```bash
flutter run
# or
flutter build ios
```

You should see a line that says:
```
Adding Swift Package Manager integration...
```

This confirms that Flutter is properly integrating the SPM packages.

## How It Works

The `appstack_plugin` uses a hybrid approach:

1. **CocoaPods** manages Flutter and other dependencies
2. **Swift Package Manager** manages the AppstackSDK dependency
3. **Flutter** automatically bridges them together when SPM support is enabled

When you enable SPM support, Flutter:
- Creates `ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/`
- Generates a master Swift Package that includes all plugins with SPM dependencies
- Adds the package reference to your Xcode project automatically
- Downloads the AppstackSDK from GitHub during build

## Troubleshooting

### Error persists after enabling SPM

If you still see the error:

1. **Check Flutter version**:
   ```bash
   flutter --version
   ```
   Make sure you're on Flutter 3.16 or later.

2. **Verify SPM is enabled**:
   ```bash
   flutter config --list | grep swift
   ```

3. **Check the generated package exists**:
   ```bash
   ls ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/
   ```
   
   You should see a `Package.swift` file.

4. **Clean everything thoroughly**:
   ```bash
   flutter clean
   cd ios
   rm -rf Pods Podfile.lock DerivedData
   cd ..
   flutter pub get
   cd ios
   pod install
   cd ..
   flutter run
   ```

### Network errors during build

The AppstackSDK is downloaded from GitHub during the first build. Ensure:
- You have internet connectivity
- GitHub is accessible from your network
- Your firewall allows Xcode to download packages

### Xcode project issues

If Xcode complains about missing packages:

1. Open your project in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. In Xcode menu: **File → Packages → Resolve Package Versions**

3. Clean build folder: **Product → Clean Build Folder** (⌘⇧K)

4. Build: **Product → Build** (⌘B)

## For CI/CD

If you're setting up CI/CD, ensure:

1. Flutter SPM support is enabled in the CI environment:
   ```bash
   flutter config --enable-swift-package-manager
   ```

2. First build will download packages (may take longer)

3. Consider caching:
   - `~/.pub-cache` (Dart packages)
   - `ios/Pods` (CocoaPods)
   - `~/Library/Developer/Xcode/DerivedData` (Xcode build cache, but be careful with this)

## Requirements

- **Flutter**: 3.16 or later (3.24+ recommended)
- **iOS Deployment Target**: 14.3 or later
- **Xcode**: 14.0 or later
- **CocoaPods**: 1.11.0 or later (if using)
- **Internet connection**: For initial package download

## Why SPM?

The plugin uses SPM for the iOS SDK because:

1. **No binary distribution needed**: The SDK source is on GitHub, no need to bundle large XCFrameworks
2. **Always up-to-date**: Can reference specific versions or branches
3. **Better dependency management**: SPM handles transitive dependencies
4. **Modern approach**: Aligns with Apple's recommended tooling

## Further Help

If you continue to have issues:

1. Check the [GitHub Issues](https://github.com/appstack-tech/appstack-flutter-sdk/issues)
2. Verify your Flutter environment: `flutter doctor -v`
3. Check Xcode version: `xcodebuild -version`
