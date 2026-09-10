import 'package:flutter_test/flutter_test.dart';
import 'package:appstack_plugin/appstack_plugin.dart';
import 'package:appstack_plugin/appstack_plugin_platform_interface.dart';
import 'package:appstack_plugin/appstack_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAppstackPluginPlatform
    with MockPlatformInterfaceMixin
    implements AppstackPluginPlatform {
  /// Every `setCustomerUserId` argument received, in order — nulls included.
  final List<String?> setCustomerUserIdCalls = <String?>[];
  String? handledUrl;
  List<String>? handledHosts;
  Map<String, dynamic>? linkResult;

  @override
  Future<void> configure(
    String apiKey,
    int logLevel,
    String? customerUserId,
  ) => Future.value();

  @override
  Future<void> setCustomerUserId(String? customerUserId) {
    setCustomerUserIdCalls.add(customerUserId);
    return Future.value();
  }

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

  @override
  Stream<Map<String, dynamic>?> getAttributionParamsWithCallback() =>
      Stream.value(null);

  @override
  Future<Map<String, dynamic>?> handleUniversalLink(
    String url,
    List<String>? allowedHosts,
  ) {
    handledUrl = url;
    handledHosts = allowedHosts;
    return Future.value(linkResult);
  }
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
        logLevel: 2,
        customerUserId: 'user-123',
      );
    });

    test('still accepts the deprecated isDebug/endpointBaseUrl no-ops', () async {
      final fakePlatform = MockAppstackPluginPlatform();
      AppstackPluginPlatform.instance = fakePlatform;

      // Passing the deprecated params must remain a compile-safe no-op during
      // the deprecation window.
      // ignore: deprecated_member_use_from_same_package
      await AppstackPlugin.configure(
        'test-api-key',
        // ignore: deprecated_member_use_from_same_package
        isDebug: true,
        // ignore: deprecated_member_use_from_same_package
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

  group('AppstackPlugin.setCustomerUserId', () {
    test('forwards the id to the platform', () async {
      final fakePlatform = MockAppstackPluginPlatform();
      AppstackPluginPlatform.instance = fakePlatform;

      await AppstackPlugin.setCustomerUserId('user-123');

      expect(fakePlatform.setCustomerUserIdCalls, ['user-123']);
    });

    // A null id is a clear, so it must reach the platform, not be filtered out.
    test('forwards null to the platform as a clear', () async {
      final fakePlatform = MockAppstackPluginPlatform();
      AppstackPluginPlatform.instance = fakePlatform;

      await AppstackPlugin.setCustomerUserId(null);

      expect(fakePlatform.setCustomerUserIdCalls, [null]);
    });

    test('forwards a blank id instead of rejecting it', () async {
      final fakePlatform = MockAppstackPluginPlatform();
      AppstackPluginPlatform.instance = fakePlatform;

      await AppstackPlugin.setCustomerUserId('');
      await AppstackPlugin.setCustomerUserId('   ');

      expect(fakePlatform.setCustomerUserIdCalls, ['', '   ']);
    });

    test('applies last-write-wins ordering', () async {
      final fakePlatform = MockAppstackPluginPlatform();
      AppstackPluginPlatform.instance = fakePlatform;

      await AppstackPlugin.setCustomerUserId('first');
      await AppstackPlugin.setCustomerUserId(null);
      await AppstackPlugin.setCustomerUserId('second');

      expect(fakePlatform.setCustomerUserIdCalls, ['first', null, 'second']);
    });

    test('throws Exception when the platform fails', () async {
      AppstackPluginPlatform.instance = _ThrowingPlatform(
        throwOnSetCustomerUserId: true,
      );

      expect(
        () => AppstackPlugin.setCustomerUserId('user-123'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Failed to set customer user ID'),
        )),
      );
    });
  });

  group('AppstackPlugin.handleUniversalLink', () {
    test('returns a typed result and forwards the allowlist', () async {
      final fakePlatform = MockAppstackPluginPlatform()
        ..linkResult = {
          'deeplinkId': 'abc',
          'queryParams': {'screen': 'offer'},
          'url': 'https://links.example.com/abc?screen=offer',
        };
      AppstackPluginPlatform.instance = fakePlatform;

      final link = await AppstackPlugin.handleUniversalLink(
        Uri.parse('https://links.example.com/abc?screen=offer'),
        allowedHosts: {' links.example.com '},
      );

      expect(link!.deeplinkId, 'abc');
      expect(link.queryParams, {'screen': 'offer'});
      expect(fakePlatform.handledHosts, ['links.example.com']);
    });

    test('maps a missing deeplinkId to null', () async {
      // iOS omits the key entirely when the native value is nil.
      final fakePlatform = MockAppstackPluginPlatform()
        ..linkResult = {
          'queryParams': {'screen': 'offer'},
          'url': 'https://links.example.com/abc?screen=offer',
        };
      AppstackPluginPlatform.instance = fakePlatform;

      final link = await AppstackPlugin.handleUniversalLink(
        Uri.parse('https://links.example.com/abc?screen=offer'),
      );

      expect(link!.deeplinkId, isNull);
      expect(link.queryParams, {'screen': 'offer'});
      expect(link.url, Uri.parse('https://links.example.com/abc?screen=offer'));
    });

    test('maps an explicitly null deeplinkId to null', () async {
      // Android sends the key through with a null value.
      final fakePlatform = MockAppstackPluginPlatform()
        ..linkResult = {
          'deeplinkId': null,
          'queryParams': <String, String>{},
          'url': 'https://links.example.com/abc',
        };
      AppstackPluginPlatform.instance = fakePlatform;

      final link = await AppstackPlugin.handleUniversalLink(
        Uri.parse('https://links.example.com/abc'),
      );

      expect(link!.deeplinkId, isNull);
      expect(link.queryParams, isEmpty);
    });

    test('rejects an empty allowed host', () async {
      AppstackPluginPlatform.instance = MockAppstackPluginPlatform();
      expect(
        () => AppstackPlugin.handleUniversalLink(
          Uri.parse('https://links.example.com/abc'),
          allowedHosts: {''},
        ),
        throwsArgumentError,
      );
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
    this.throwOnSetCustomerUserId = false,
    this.throwOnSendEvent = false,
    this.throwOnEnableAppleAdsAttribution = false,
    this.throwOnGetAppstackId = false,
    this.throwOnIsSdkDisabled = false,
    this.throwOnGetAttributionParams = false,
  });

  final bool throwOnConfigure;
  final bool throwOnSetCustomerUserId;
  final bool throwOnSendEvent;
  final bool throwOnEnableAppleAdsAttribution;
  final bool throwOnGetAppstackId;
  final bool throwOnIsSdkDisabled;
  final bool throwOnGetAttributionParams;

  @override
  Future<void> configure(
    String apiKey,
    int logLevel,
    String? customerUserId,
  ) async {
    if (throwOnConfigure) throw Exception('configure failed');
  }

  @override
  Future<void> setCustomerUserId(String? customerUserId) async {
    if (throwOnSetCustomerUserId) throw Exception('setCustomerUserId failed');
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
