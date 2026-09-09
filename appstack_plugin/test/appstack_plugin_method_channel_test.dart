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

  const EventChannel attributionParamsEventChannel =
      EventChannel('appstack_plugin/attribution_params');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(attributionParamsEventChannel, null);
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
          capturedArgs =
              Map<String, dynamic>.from(methodCall.arguments as Map);
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
          capturedArgs =
              Map<String, dynamic>.from(methodCall.arguments as Map);
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
          capturedArgs =
              Map<String, dynamic>.from(methodCall.arguments as Map);
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

  group('getAttributionParamsWithCallback', () {
    test('emits a single mapped value then closes', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
        attributionParamsEventChannel,
        MockStreamHandler.inline(
          onListen: (arguments, sink) {
            sink.success(<dynamic, dynamic>{
              'source': 'apple',
              'campaign': 'x',
            });
            sink.endOfStream();
          },
        ),
      );

      final events =
          await platform.getAttributionParamsWithCallback().toList();

      expect(events, hasLength(1));
      expect(events.first, isA<Map<String, dynamic>>());
      expect(events.first, {'source': 'apple', 'campaign': 'x'});
    });

    test('maps a null event to null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
        attributionParamsEventChannel,
        MockStreamHandler.inline(
          onListen: (arguments, sink) {
            sink.success(null);
            sink.endOfStream();
          },
        ),
      );

      final events =
          await platform.getAttributionParamsWithCallback().toList();

      expect(events, [null]);
    });

    test('forwards platform errors on the stream', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
        attributionParamsEventChannel,
        MockStreamHandler.inline(
          onListen: (arguments, sink) {
            sink.error(code: 'ERR', message: 'boom', details: null);
          },
        ),
      );

      expect(
        platform.getAttributionParamsWithCallback(),
        emitsError(isA<PlatformException>()),
      );
    });
  });
}
