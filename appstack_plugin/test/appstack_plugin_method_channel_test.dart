import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appstack_plugin/appstack_plugin_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MethodChannelAppstackPlugin platform;
  const MethodChannel channel = MethodChannel('appstack_plugin');

  setUp(() {
    platform = MethodChannelAppstackPlugin();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('configure', () {
    test('invokes native configure with correct arguments', () async {
      Map<String, dynamic>? capturedArgs;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'configure' && methodCall.arguments != null) {
          capturedArgs =
              Map<String, dynamic>.from(methodCall.arguments as Map);
        }
        return null;
      });

      await platform.configure(
        'my-api-key',
        true,
        'https://custom.endpoint',
        2,
        'customer-123',
      );

      expect(capturedArgs, isNotNull);
      final args = capturedArgs!;
      expect(args['apiKey'], 'my-api-key');
      expect(args['isDebug'], true);
      expect(args['endpointBaseUrl'], 'https://custom.endpoint');
      expect(args['logLevel'], 2);
      expect(args['customerUserId'], 'customer-123');
    });

    test('invokes native configure with null optionals', () async {
      Map<String, dynamic>? capturedArgs;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'configure' && methodCall.arguments != null) {
          capturedArgs =
              Map<String, dynamic>.from(methodCall.arguments as Map);
        }
        return null;
      });

      await platform.configure('key', false, null, 1, null);

      expect(capturedArgs, isNotNull);
      final args = capturedArgs!;
      expect(args['apiKey'], 'key');
      expect(args['isDebug'], false);
      expect(args['endpointBaseUrl'], isNull);
      expect(args['logLevel'], 1);
      expect(args['customerUserId'], isNull);
    });

    test('succeeds when native returns', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'configure') return null;
        return null;
      });

      await platform.configure('test-api-key', false, null, 1, null);
    });
  });

  group('sendEvent', () {
    test('returns true when native returns true', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'sendEvent') return true;
        return null;
      });

      expect(
        await platform.sendEvent('PURCHASE', 'test-event', {
          'revenue': 9.99,
          'currency': 'USD',
        }),
        true,
      );
    });

    test('returns false when native returns null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'sendEvent') return null;
        return null;
      });

      expect(
        await platform.sendEvent('LOGIN', null, null),
        false,
      );
    });

    test('passes correct arguments to native', () async {
      Map<String, dynamic>? capturedArgs;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'sendEvent' && methodCall.arguments != null) {
          capturedArgs =
              Map<String, dynamic>.from(methodCall.arguments as Map);
        }
        return true;
      });

      await platform.sendEvent('CUSTOM', 'my_event', {'k': 'v'});

      expect(capturedArgs, isNotNull);
      final args = capturedArgs!;
      expect(args['eventType'], 'CUSTOM');
      expect(args['eventName'], 'my_event');
      expect(args['parameters'], {'k': 'v'});
    });
  });

  group('enableAppleAdsAttribution', () {
    test('returns true when native returns true', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'enableAppleAdsAttribution') return true;
        return null;
      });

      expect(await platform.enableAppleAdsAttribution(), true);
    });

    test('returns false when native returns false', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'enableAppleAdsAttribution') return false;
        return null;
      });

      expect(await platform.enableAppleAdsAttribution(), false);
    });

    test('returns false when native returns null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'enableAppleAdsAttribution') return null;
        return null;
      });

      expect(await platform.enableAppleAdsAttribution(), false);
    });
  });

  group('getAppstackId', () {
    test('returns value when native returns string', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'getAppstackId') return 'test-appstack-id-123';
        return null;
      });

      expect(await platform.getAppstackId(), 'test-appstack-id-123');
    });

    test('returns null when native returns null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'getAppstackId') return null;
        return null;
      });

      expect(await platform.getAppstackId(), isNull);
    });
  });

  group('isSdkDisabled', () {
    test('returns false when native returns false', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'isSdkDisabled') return false;
        return null;
      });

      expect(await platform.isSdkDisabled(), false);
    });

    test('returns true when native returns true', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'isSdkDisabled') return true;
        return null;
      });

      expect(await platform.isSdkDisabled(), true);
    });

    test('throws when native returns null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'isSdkDisabled') return null;
        return null;
      });

      expect(
        () => platform.isSdkDisabled(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('did not return a value for isSdkDisabled'),
        )),
      );
    });
  });

  group('getAttributionParams', () {
    test('returns map when native returns data', () async {
      final map = {'source': 'apple', 'campaign_id': '123'};
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'getAttributionParams') return map;
        return null;
      });

      final result = await platform.getAttributionParams();
      expect(result, {'source': 'apple', 'campaign_id': '123'});
    });

    test('returns null when native returns null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'getAttributionParams') return null;
        return null;
      });

      expect(await platform.getAttributionParams(), isNull);
    });

    test('converts dynamic map to Map<String, dynamic>', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'getAttributionParams') {
          return <String, dynamic>{'key': 42, 'nested': true};
        }
        return null;
      });

      final result = await platform.getAttributionParams();
      expect(result, isA<Map<String, dynamic>>());
      expect(result!['key'], 42);
      expect(result['nested'], true);
    });
  });
}
