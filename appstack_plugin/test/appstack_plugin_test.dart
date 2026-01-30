import 'package:flutter_test/flutter_test.dart';
import 'package:appstack_plugin/appstack_plugin.dart';
import 'package:appstack_plugin/appstack_plugin_platform_interface.dart';
import 'package:appstack_plugin/appstack_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAppstackPluginPlatform
    with MockPlatformInterfaceMixin
    implements AppstackPluginPlatform {
  @override
  Future<void> configure(
    String apiKey,
    bool isDebug,
    String? endpointBaseUrl,
    int logLevel,
    String? customerUserId,
  ) => Future.value();

  @override
  Future<bool> sendEvent(
    String eventType,
    String? eventName,
    Map<String, dynamic>? parameters,
  ) => Future.value(true);

  @override
  Future<bool> enableAppleAdsAttribution() => Future.value(true);

  @override
  Future<String?> getAppstackId() => Future.value('mock-appstack-id-456');

  @override
  Future<bool> isSdkDisabled() => Future.value(false);

  @override
  Future<Map<String, dynamic>?> getAttributionParams() => Future.value(null);
}

void main() {
  final AppstackPluginPlatform initialPlatform =
      AppstackPluginPlatform.instance;

  tearDown(() {
    AppstackPluginPlatform.instance = initialPlatform;
  });

  group('default instance', () {
    test('$MethodChannelAppstackPlugin is the default instance', () {
      expect(initialPlatform, isInstanceOf<MethodChannelAppstackPlugin>());
    });
  });

  group('AppstackPlugin.configure', () {
    test('succeeds with minimal apiKey', () async {
      final fakePlatform = MockAppstackPluginPlatform();
      AppstackPluginPlatform.instance = fakePlatform;

      await AppstackPlugin.configure('test-api-key');
    });

    test('succeeds with all optional parameters', () async {
      final fakePlatform = MockAppstackPluginPlatform();
      AppstackPluginPlatform.instance = fakePlatform;

      await AppstackPlugin.configure(
        'test-api-key',
        isDebug: true,
        endpointBaseUrl: 'https://custom.endpoint',
        logLevel: 2,
        customerUserId: 'user-123',
      );
    });

    test('throws ArgumentError when apiKey is empty', () async {
      final fakePlatform = MockAppstackPluginPlatform();
      AppstackPluginPlatform.instance = fakePlatform;

      expect(
        () => AppstackPlugin.configure(''),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          'API key must be a non-empty string',
        )),
      );
    });

    test('throws ArgumentError when logLevel is less than 0', () async {
      final fakePlatform = MockAppstackPluginPlatform();
      AppstackPluginPlatform.instance = fakePlatform;

      expect(
        () => AppstackPlugin.configure('key', logLevel: -1),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          'logLevel must be a number between 0 and 3',
        )),
      );
    });

    test('throws ArgumentError when logLevel is greater than 3', () async {
      final fakePlatform = MockAppstackPluginPlatform();
      AppstackPluginPlatform.instance = fakePlatform;

      expect(
        () => AppstackPlugin.configure('key', logLevel: 4),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          'logLevel must be a number between 0 and 3',
        )),
      );
    });

    test('throws Exception when platform configure fails', () async {
      final fakePlatform = MockAppstackPluginPlatform();
      AppstackPluginPlatform.instance = fakePlatform;

      // Use a custom platform that throws
      AppstackPluginPlatform.instance = _ThrowingPlatform(
        throwOnConfigure: true,
      );

      expect(
        () => AppstackPlugin.configure('key'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Failed to configure Appstack SDK'),
        )),
      );
    });

    test('does not rethrow when isSdkDisabled throws after configure', () async {
      AppstackPluginPlatform.instance = _ThrowingPlatform(
        throwOnIsSdkDisabled: true,
      );

      await AppstackPlugin.configure('key');
      // Should complete without throwing (errors are caught and logged)
    });

    test('completes when isSdkDisabled is true after configure', () async {
      AppstackPluginPlatform.instance = _SdkDisabledPlatform();

      await AppstackPlugin.configure('key');
      // Should complete; SDK disabled warning is logged
    });
  });

  group('AppstackPlugin.sendEvent', () {
    test('returns true when platform succeeds', () async {
      final fakePlatform = MockAppstackPluginPlatform();
      AppstackPluginPlatform.instance = fakePlatform;

      expect(
        await AppstackPlugin.sendEvent(
          EventType.purchase,
          parameters: {'revenue': 19.99, 'currency': 'USD'},
        ),
        true,
      );
    });

    test('sends with eventName for custom events', () async {
      final fakePlatform = MockAppstackPluginPlatform();
      AppstackPluginPlatform.instance = fakePlatform;

      expect(
        await AppstackPlugin.sendEvent(
          EventType.custom,
          eventName: 'my_custom_event',
          parameters: {'key': 'value'},
        ),
        true,
      );
    });

    test('throws Exception when platform fails', () async {
      AppstackPluginPlatform.instance = _ThrowingPlatform(
        throwOnSendEvent: true,
      );

      expect(
        () => AppstackPlugin.sendEvent(EventType.login),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Failed to send event'),
        )),
      );
    });
  });

  group('AppstackPlugin.enableAppleAdsAttribution', () {
    test('returns true when platform succeeds', () async {
      final fakePlatform = MockAppstackPluginPlatform();
      AppstackPluginPlatform.instance = fakePlatform;

      expect(await AppstackPlugin.enableAppleAdsAttribution(), true);
    });

    test('throws Exception when platform fails', () async {
      AppstackPluginPlatform.instance =
          _ThrowingPlatform(throwOnEnableAppleAdsAttribution: true);

      expect(
        () => AppstackPlugin.enableAppleAdsAttribution(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Failed to enable Apple Ads Attribution'),
        )),
      );
    });
  });

  group('AppstackPlugin.getAppstackId', () {
    test('returns value from platform', () async {
      final fakePlatform = MockAppstackPluginPlatform();
      AppstackPluginPlatform.instance = fakePlatform;

      expect(await AppstackPlugin.getAppstackId(), 'mock-appstack-id-456');
    });

    test('throws Exception when platform fails', () async {
      AppstackPluginPlatform.instance =
          _ThrowingPlatform(throwOnGetAppstackId: true);

      expect(
        () => AppstackPlugin.getAppstackId(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Failed to get Appstack ID'),
        )),
      );
    });
  });

  group('AppstackPlugin.isSdkDisabled', () {
    test('returns false when platform returns false', () async {
      final fakePlatform = MockAppstackPluginPlatform();
      AppstackPluginPlatform.instance = fakePlatform;

      expect(await AppstackPlugin.isSdkDisabled(), false);
    });

    test('returns true when platform returns true', () async {
      final fakePlatform = _SdkDisabledPlatform();
      AppstackPluginPlatform.instance = fakePlatform;

      expect(await AppstackPlugin.isSdkDisabled(), true);
    });

    test('throws Exception when platform fails', () async {
      AppstackPluginPlatform.instance =
          _ThrowingPlatform(throwOnIsSdkDisabled: true);

      expect(
        () => AppstackPlugin.isSdkDisabled(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Failed to check SDK disabled status'),
        )),
      );
    });
  });

  group('AppstackPlugin.getAttributionParams', () {
    test('returns null when platform returns null', () async {
      final fakePlatform = MockAppstackPluginPlatform();
      AppstackPluginPlatform.instance = fakePlatform;

      expect(await AppstackPlugin.getAttributionParams(), isNull);
    });

    test('returns map when platform returns data', () async {
      final fakePlatform = _AttributionParamsPlatform();
      AppstackPluginPlatform.instance = fakePlatform;

      expect(
        await AppstackPlugin.getAttributionParams(),
        {'source': 'apple', 'campaign': 'test'},
      );
    });

    test('throws Exception when platform fails', () async {
      AppstackPluginPlatform.instance =
          _ThrowingPlatform(throwOnGetAttributionParams: true);

      expect(
        () => AppstackPlugin.getAttributionParams(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Failed to get attribution params'),
        )),
      );
    });
  });
}

/// Platform that throws on selected methods (for error-path tests).
class _ThrowingPlatform extends AppstackPluginPlatform {
  _ThrowingPlatform({
    this.throwOnConfigure = false,
    this.throwOnSendEvent = false,
    this.throwOnEnableAppleAdsAttribution = false,
    this.throwOnGetAppstackId = false,
    this.throwOnIsSdkDisabled = false,
    this.throwOnGetAttributionParams = false,
  });

  final bool throwOnConfigure;
  final bool throwOnSendEvent;
  final bool throwOnEnableAppleAdsAttribution;
  final bool throwOnGetAppstackId;
  final bool throwOnIsSdkDisabled;
  final bool throwOnGetAttributionParams;

  @override
  Future<void> configure(
    String apiKey,
    bool isDebug,
    String? endpointBaseUrl,
    int logLevel,
    String? customerUserId,
  ) async {
    if (throwOnConfigure) throw Exception('configure failed');
  }

  @override
  Future<bool> sendEvent(
    String eventType,
    String? eventName,
    Map<String, dynamic>? parameters,
  ) async {
    if (throwOnSendEvent) throw Exception('sendEvent failed');
    return true;
  }

  @override
  Future<bool> enableAppleAdsAttribution() async {
    if (throwOnEnableAppleAdsAttribution) {
      throw Exception('enableAppleAdsAttribution failed');
    }
    return true;
  }

  @override
  Future<String?> getAppstackId() async {
    if (throwOnGetAppstackId) throw Exception('getAppstackId failed');
    return null;
  }

  @override
  Future<bool> isSdkDisabled() async {
    if (throwOnIsSdkDisabled) throw Exception('isSdkDisabled failed');
    return false;
  }

  @override
  Future<Map<String, dynamic>?> getAttributionParams() async {
    if (throwOnGetAttributionParams) {
      throw Exception('getAttributionParams failed');
    }
    return null;
  }
}

/// Platform that returns isSdkDisabled: true.
class _SdkDisabledPlatform extends AppstackPluginPlatform {
  @override
  Future<void> configure(
    String apiKey,
    bool isDebug,
    String? endpointBaseUrl,
    int logLevel,
    String? customerUserId,
  ) => Future.value();

  @override
  Future<bool> sendEvent(
    String eventType,
    String? eventName,
    Map<String, dynamic>? parameters,
  ) => Future.value(true);

  @override
  Future<bool> enableAppleAdsAttribution() => Future.value(true);

  @override
  Future<String?> getAppstackId() => Future.value(null);

  @override
  Future<bool> isSdkDisabled() => Future.value(true);

  @override
  Future<Map<String, dynamic>?> getAttributionParams() => Future.value(null);
}

/// Platform that returns non-null attribution params.
class _AttributionParamsPlatform extends AppstackPluginPlatform {
  @override
  Future<void> configure(
    String apiKey,
    bool isDebug,
    String? endpointBaseUrl,
    int logLevel,
    String? customerUserId,
  ) => Future.value();

  @override
  Future<bool> sendEvent(
    String eventType,
    String? eventName,
    Map<String, dynamic>? parameters,
  ) => Future.value(true);

  @override
  Future<bool> enableAppleAdsAttribution() => Future.value(true);

  @override
  Future<String?> getAppstackId() => Future.value(null);

  @override
  Future<bool> isSdkDisabled() => Future.value(false);

  @override
  Future<Map<String, dynamic>?> getAttributionParams() =>
      Future.value({'source': 'apple', 'campaign': 'test'});
}
