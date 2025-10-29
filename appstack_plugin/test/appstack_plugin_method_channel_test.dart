import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appstack_plugin/appstack_plugin_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelAppstackPlugin platform = MethodChannelAppstackPlugin();
  const MethodChannel channel = MethodChannel('appstack_plugin');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'configure':
          return true;
        case 'sendEvent':
          return true;
        case 'enableAppleAdsAttribution':
          return true;
        case 'getAppstackId':
          return 'test-appstack-id-123';
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('configure', () async {
    expect(await platform.configure('test-api-key', false, null, 1), true);
  });

  test('sendEvent', () async {
    expect(await platform.sendEvent('PURCHASE', 'test-event', 9.99), true);
  });

  test('enableAppleAdsAttribution', () async {
    expect(await platform.enableAppleAdsAttribution(), true);
  });

  test('getAppstackId', () async {
    expect(await platform.getAppstackId(), 'test-appstack-id-123');
  });
}
