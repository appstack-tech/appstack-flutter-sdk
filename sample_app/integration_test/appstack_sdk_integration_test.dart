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

const _placeholderKey = 'integration-test-placeholder-key';
const _apiKey = String.fromEnvironment(
  'APPSTACK_API_KEY',
  defaultValue: _placeholderKey,
);
const _hasRealKey = _apiKey != _placeholderKey;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Appstack SDK native bridge', () {
    setUpAll(() async {
      // Must succeed (complete without throwing) on every integration path.
      await AppstackPlugin.configure(_apiKey, logLevel: 0);
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

    // Delivery observability: the round-trip tests above fire events immediately
    // and only prove the bridge returns a value. This one waits until the SDK is
    // actually configured before sending, so events are delivered rather than
    // dropped (Android) / left unsent at teardown. It prints what the Dart layer
    // sees; the native HTTP delivery (POST /events -> 202) shows up in the device
    // logs captured by the CI workflow.
    //
    // Skipped without a real APPSTACK_API_KEY: on the placeholder key the SDK
    // reports itself disabled and sends nothing, so there is nothing to observe.
    // Set the APPSTACK_API_KEY secret to exercise it.
    testWidgets('event delivery: sends events after config and reports data',
        (tester) async {
      if (!_hasRealKey) {
        markTestSkipped(
          'APPSTACK_API_KEY not set — skipping live event-delivery check.',
        );
        return;
      }

      // Config-load time is variable (network + emulator first-connection cost),
      // so a fixed delay is unreliable — events sent too early are dropped on
      // Android. Poll instead: attribution params populate only after config +
      // match complete, so a non-empty result is a reliable "SDK is ready"
      // signal. Capped so a match that legitimately returns nothing can't hang
      // the run (config has loaded well before the cap either way).
      for (var i = 0; i < 25; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 2)),
        );
        final p = await AppstackPlugin.getAttributionParams();
        if (p != null && p.isNotEmpty) break;
      }

      final purchase = await AppstackPlugin.sendEvent(
        EventType.purchase,
        parameters: {'revenue': 9.99, 'currency': 'USD'},
      );
      final custom = await AppstackPlugin.sendEvent(
        EventType.custom,
        eventName: 'integration_test_event',
        parameters: {'k': 'v'},
      );

      final id = await AppstackPlugin.getAppstackId();
      final params = await AppstackPlugin.getAttributionParams();

      // Surfaced in the `flutter test` output so automatic runs show what the
      // Dart layer observed.
      // ignore: avoid_print
      print('[integration] sendEvent(purchase) accepted=$purchase');
      // ignore: avoid_print
      print('[integration] sendEvent(custom) accepted=$custom');
      // ignore: avoid_print
      print('[integration] appstackId=$id');
      // ignore: avoid_print
      print('[integration] attributionParams=$params');

      // Keep the app alive so the SDK can POST the events before teardown.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 8)),
      );

      expect(purchase, isA<bool>());
      expect(custom, isA<bool>());
    });
  });
}
