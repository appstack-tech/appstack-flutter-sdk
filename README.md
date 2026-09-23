<p align="center">
  <a href="https://www.appstack.tech">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/appstack-tech/appstack-flutter-sdk/main/.github/assets/appstack_logo_white_wordmark.png">
      <img alt="Appstack" src="https://raw.githubusercontent.com/appstack-tech/appstack-flutter-sdk/main/.github/assets/appstack_logo_black_wordmark.png" width="280">
    </picture>
  </a>
</p>

<p align="center">
  Mobile attribution and ad-network optimization for Flutter apps.
</p>

<p align="center">
  <a href="https://pub.dev/packages/appstack_plugin"><img alt="pub.dev" src="https://img.shields.io/pub/v/appstack_plugin.svg"></a>
  <img alt="Platforms" src="https://img.shields.io/badge/platforms-iOS%2015%2B%20%7C%20Android%205.0%2B-blue.svg">
  <a href="https://github.com/appstack-tech/appstack-flutter-sdk/blob/main/appstack_plugin/LICENSE"><img alt="License" src="https://img.shields.io/badge/license-MIT-lightgrey.svg"></a>
</p>

<p align="center">
  <a href="https://docs.appstack.tech/SDKs/flutter"><b>Documentation</b></a>
  &nbsp;·&nbsp;
  <a href="https://docs.appstack.tech/reference/flutter">API reference</a>
  &nbsp;·&nbsp;
  <a href="https://github.com/appstack-tech/appstack-flutter-sdk/blob/main/appstack_plugin/CHANGELOG.md">Changelog</a>
  &nbsp;·&nbsp;
  <a href="https://www.appstack.tech/contact">Support</a>
</p>

---

The Appstack Flutter plugin tracks installs and in-app events, attributes them to your ad campaigns, and sends conversions back to Meta, Google, TikTok, Apple Ads and other networks. It wraps the native Appstack iOS and Android SDKs.

## Installation

```yaml
dependencies:
  appstack_plugin: ^2.10.1
```

Then run `flutter pub get`. iOS (Swift Package Manager or CocoaPods) and Android setup are covered in the [documentation](https://docs.appstack.tech/SDKs/flutter).

## Quick start

```dart
import 'dart:io' show Platform;
import 'package:appstack_plugin/appstack_plugin.dart';

await AppstackPlugin.configure(Platform.isIOS ? 'your_ios_api_key' : 'your_android_api_key');

await AppstackPlugin.sendEvent(
  EventType.purchase,
  parameters: {'revenue': 29.99, 'currency': 'USD'},
);
```

Setup, event types, Apple Ads attribution, integrations (RevenueCat, Superwall) and troubleshooting are covered in the **[official documentation](https://docs.appstack.tech/SDKs/flutter)**.

## Documentation

- **[Flutter SDK guide](https://docs.appstack.tech/SDKs/flutter)**: installation, configuration and event tracking
- **[API reference](https://docs.appstack.tech/reference/flutter)**: every public method and type
- **[Apple Ads](https://docs.appstack.tech/Integrations/apple-ads)**: Apple Ads attribution setup
- **[RevenueCat](https://docs.appstack.tech/Integrations/revenuecat)** and **[Superwall](https://docs.appstack.tech/Integrations/superwall)**: subscription platform integrations
- **[Changelog](https://github.com/appstack-tech/appstack-flutter-sdk/blob/main/appstack_plugin/CHANGELOG.md)**: release notes for every version

## Repository layout

- [`appstack_plugin/`](appstack_plugin): the Flutter plugin published to [pub.dev](https://pub.dev/packages/appstack_plugin)
- [`sample_app/`](sample_app): an example app that uses the plugin

## Other platforms

[iOS](https://docs.appstack.tech/SDKs/swift) · [Android](https://docs.appstack.tech/SDKs/kotlin) · [React Native](https://docs.appstack.tech/SDKs/react-native) · [Unity](https://docs.appstack.tech/SDKs/unity)

## Support

Questions or issues? [Open an issue](https://github.com/appstack-tech/appstack-flutter-sdk/issues) or [contact us](https://www.appstack.tech/contact).

## License

Released under the [MIT License](https://github.com/appstack-tech/appstack-flutter-sdk/blob/main/appstack_plugin/LICENSE).
