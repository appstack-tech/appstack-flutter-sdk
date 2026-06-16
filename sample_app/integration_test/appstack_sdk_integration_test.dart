// Integration tests for the Appstack Flutter SDK.
//
// These exercise the full Dart -> platform channel -> native plugin -> native
// SDK round trip on a real device/simulator. The same suite is run once per
// iOS integration path (SwiftPM and CocoaPods/XCFramework) — see README.md.
//
// The primary value is build/link coverage: if the app compiles, launches and
// these calls return without a `MissingPluginException` or undefined-symbol
// link failure, the chosen integration path is wired correctly. That is exactly
// the class of regression that shipped in v1.0.1 and v2.1.1.
//
// No live backend is assumed. Provide a real key with:
//   flutter test integration_test \
//     --dart-define=APPSTACK_API_KEY=your-key
// Without it, a placeholder is used; the SDK may report itself disabled, which
// the tests tolerate.

import 'dart:io' show Platform;

import 'package:appstack_plugin/appstack_plugin.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _apiKey = String.fromEnvironment(
  'APPSTACK_API_KEY',
  defaultValue: 'integration-test-placeholder-key',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Appstack SDK native bridge', () {
    setUpAll(() async {
      // Must succeed (complete without throwing) on every integration path.
      await AppstackPlugin.configure(_apiKey, isDebug: true, logLevel: 0);
    });

    testWidgets('isSdkDisabled returns a bool over the channel', (_) async {
      final disabled = await AppstackPlugin.isSdkDisabled();
      expect(disabled, isA<bool>());
    });

    testWidgets('sendEvent round-trips for a standard event', (_) async {
      final ok = await AppstackPlugin.sendEvent(
        EventType.purchase,
        parameters: {'revenue': 9.99, 'currency': 'USD'},
      );
      expect(ok, isA<bool>());
    });

    testWidgets('sendEvent round-trips for a custom event', (_) async {
      final ok = await AppstackPlugin.sendEvent(
        EventType.custom,
        eventName: 'integration_test_event',
        parameters: {'k': 'v'},
      );
      expect(ok, isA<bool>());
    });

    testWidgets('getAppstackId returns a String? without throwing', (_) async {
      final id = await AppstackPlugin.getAppstackId();
      expect(id, anyOf(isNull, isA<String>()));
    });

    testWidgets('getAttributionParams returns a Map? without throwing',
        (_) async {
      final params = await AppstackPlugin.getAttributionParams();
      expect(params, anyOf(isNull, isA<Map<String, dynamic>>()));
    });

    testWidgets('getAttributionParamsWithCallback emits then closes',
        (_) async {
      // The stream is contracted to emit exactly one value then close.
      final params = await AppstackPlugin
          .getAttributionParamsWithCallback()
          .first
          .timeout(const Duration(seconds: 10));
      expect(params, anyOf(isNull, isA<Map<String, dynamic>>()));
    });

    testWidgets('enableAppleAdsAttribution behaves per platform', (_) async {
      final result = await AppstackPlugin.enableAppleAdsAttribution();
      expect(result, isA<bool>());
      if (!Platform.isIOS) {
        // Documented: returns false on non-iOS platforms.
        expect(result, isFalse);
      }
    });
  });
}
