import 'package:flutter_test/flutter_test.dart';
import 'package:appstack_plugin/appstack_plugin_platform_interface.dart';
import 'package:appstack_plugin/appstack_plugin_method_channel.dart';

/// A platform that does not override any method, used to verify
/// [UnimplementedError] is thrown when calling the base implementation.
class _UnimplementedPlatform extends AppstackPluginPlatform {}

void main() {
  final AppstackPluginPlatform initialPlatform =
      AppstackPluginPlatform.instance;

  tearDown(() {
    AppstackPluginPlatform.instance = initialPlatform;
  });

  group('AppstackPluginPlatform default implementation', () {
    setUp(() {
      AppstackPluginPlatform.instance = _UnimplementedPlatform();
    });

    test('configure throws UnimplementedError', () {
      expect(
        () => AppstackPluginPlatform.instance.configure(
          'key',
          false,
          null,
          1,
          null,
        ),
        throwsA(isA<UnimplementedError>().having(
          (e) => e.message,
          'message',
          contains('configure()'),
        )),
      );
    });

    test('sendEvent throws UnimplementedError', () {
      expect(
        () => AppstackPluginPlatform.instance.sendEvent(
          'PURCHASE',
          null,
          null,
        ),
        throwsA(isA<UnimplementedError>().having(
          (e) => e.message,
          'message',
          contains('sendEvent()'),
        )),
      );
    });

    test('enableAppleAdsAttribution throws UnimplementedError', () {
      expect(
        () => AppstackPluginPlatform.instance.enableAppleAdsAttribution(),
        throwsA(isA<UnimplementedError>().having(
          (e) => e.message,
          'message',
          contains('enableAppleAdsAttribution()'),
        )),
      );
    });

    test('getAppstackId throws UnimplementedError', () {
      expect(
        () => AppstackPluginPlatform.instance.getAppstackId(),
        throwsA(isA<UnimplementedError>().having(
          (e) => e.message,
          'message',
          contains('getAppstackId()'),
        )),
      );
    });

    test('isSdkDisabled throws UnimplementedError', () {
      expect(
        () => AppstackPluginPlatform.instance.isSdkDisabled(),
        throwsA(isA<UnimplementedError>().having(
          (e) => e.message,
          'message',
          contains('isSdkDisabled()'),
        )),
      );
    });

    test('getAttributionParams throws UnimplementedError', () {
      expect(
        () => AppstackPluginPlatform.instance.getAttributionParams(),
        throwsA(isA<UnimplementedError>().having(
          (e) => e.message,
          'message',
          contains('getAttributionParams()'),
        )),
      );
    });
  });

  group('AppstackPluginPlatform.instance', () {
    test('default instance is MethodChannelAppstackPlugin', () {
      expect(initialPlatform, isInstanceOf<MethodChannelAppstackPlugin>());
    });

    test('instance setter accepts valid platform', () {
      final custom = _UnimplementedPlatform();
      AppstackPluginPlatform.instance = custom;
      expect(AppstackPluginPlatform.instance, same(custom));
    });
  });
}
