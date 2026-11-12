import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appstack_plugin/src/method_channel_appstack_plugin.dart';

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
          capturedArgs = Map<String, dynamic>.from(methodCall.arguments as Map);
        }
        return null;
      });

      await platform.configure(
        'my-api-key',
        2,
        'customer-123',
      );

      expect(capturedArgs, isNotNull);
      final args = capturedArgs!;
      expect(args['apiKey'], 'my-api-key');
      expect(args['logLevel'], 2);
      expect(args['customerUserId'], 'customer-123');
      // isDebug/endpointBaseUrl are no longer sent over the channel.
      expect(args.containsKey('isDebug'), isFalse);
      expect(args.containsKey('endpointBaseUrl'), isFalse);
    });

    test('invokes native configure with null optionals', () async {
      Map<String, dynamic>? capturedArgs;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'configure' && methodCall.arguments != null) {
          capturedArgs = Map<String, dynamic>.from(methodCall.arguments as Map);
        }
        return null;
      });

      await platform.configure('key', 1, null);

      expect(capturedArgs, isNotNull);
      final args = capturedArgs!;
      expect(args['apiKey'], 'key');
      expect(args['logLevel'], 1);
      expect(args['customerUserId'], isNull);
      expect(args.containsKey('isDebug'), isFalse);
      expect(args.containsKey('endpointBaseUrl'), isFalse);
    });

    test('succeeds when native returns', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'configure') return null;
        return null;
      });

      await platform.configure('test-api-key', 1, null);
    });
  });

  group('setCustomerUserId', () {
    test('invokes native setCustomerUserId with the id', () async {
      Map<String, dynamic>? capturedArgs;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'setCustomerUserId') {
          capturedArgs = Map<String, dynamic>.from(methodCall.arguments as Map);
        }
        return null;
      });

      await platform.setCustomerUserId('customer-123');

      expect(capturedArgs, isNotNull);
      expect(capturedArgs!['customerUserId'], 'customer-123');
    });

    // Dropping the key would drop the clear: the native handlers read the argument.
    test('sends the customerUserId key with a null value on clear', () async {
      Map<String, dynamic>? capturedArgs;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'setCustomerUserId') {
          capturedArgs = Map<String, dynamic>.from(methodCall.arguments as Map);
        }
        return null;
      });

      await platform.setCustomerUserId(null);

      expect(capturedArgs, isNotNull);
      expect(capturedArgs!.containsKey('customerUserId'), isTrue);
      expect(capturedArgs!['customerUserId'], isNull);
    });

    test('forwards a blank id without normalizing it away', () async {
      final captured = <String?>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'setCustomerUserId') {
          captured.add(
            (methodCall.arguments as Map)['customerUserId'] as String?,
          );
        }
        return null;
      });

      await platform.setCustomerUserId('');
      await platform.setCustomerUserId('  ');

      expect(captured, ['', '  ']);
    });

    test('propagates platform exceptions', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'setCustomerUserId') {
          throw PlatformException(code: 'SET_CUSTOMER_USER_ID_ERROR');
        }
        return null;
      });

      expect(
        () => platform.setCustomerUserId('customer-123'),
        throwsA(isA<PlatformException>()),
      );
    });
  });

  group('deleteUserData', () {
    test('invokes native deleteUserData without arguments', () async {
      MethodCall? captured;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (methodCall) async {
        captured = methodCall;
        return null;
      });

      await platform.deleteUserData();

      expect(captured!.method, 'deleteUserData');
      expect(captured!.arguments, isNull);
    });

    test('propagates platform exceptions', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (methodCall) async {
        if (methodCall.method == 'deleteUserData') {
          throw PlatformException(code: 'DELETE_USER_DATA_ERROR');
        }
        return null;
      });

      expect(
        () => platform.deleteUserData(),
        throwsA(isA<PlatformException>()),
      );
    });
  });

  group('handleUniversalLink', () {
    test('forwards URL and allowlist and converts the result', () async {
      MethodCall? captured;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (methodCall) async {
        captured = methodCall;
        return {
          'deeplinkId': 'abc',
          'queryParams': {'screen': 'offer'},
          'url': 'https://links.example.com/abc?screen=offer',
        };
      });

      final value = await platform.handleUniversalLink(
        'https://links.example.com/abc?screen=offer',
        ['links.example.com'],
      );

      expect(captured!.method, 'handleUniversalLink');
      expect(captured!.arguments, {
        'url': 'https://links.example.com/abc?screen=offer',
        'allowedHosts': ['links.example.com'],
      });
      expect(value!['deeplinkId'], 'abc');
    });

    test('returns null when native ignores the URL', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async => null);
      expect(
        await platform.handleUniversalLink('https://appstack.link/abc', null),
        isNull,
      );
    });
  });

  group('sendEvent', () {
    test('completes whatever native replies', () async {
      for (final reply in <Object?>[null, true, false]) {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'sendEvent') return reply;
          return null;
        });

        await expectLater(
          platform.sendEvent('PURCHASE', null, {'revenue': 9.99}),
          completes,
        );
      }
    });

    test('surfaces native errors', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        throw PlatformException(code: 'EVENT_SEND_ERROR');
      });

      await expectLater(
        platform.sendEvent('LOGIN', null, null),
        throwsA(isA<PlatformException>()),
      );
    });

    test('passes correct arguments to native', () async {
      Map<String, dynamic>? capturedArgs;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'sendEvent' && methodCall.arguments != null) {
          capturedArgs = Map<String, dynamic>.from(methodCall.arguments as Map);
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

    test('returns an empty map when native returns null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'getAttributionParams') return null;
        return null;
      });

      expect(await platform.getAttributionParams(), isEmpty);
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
      expect(result['key'], 42);
      expect(result['nested'], true);
    });
  });
}
