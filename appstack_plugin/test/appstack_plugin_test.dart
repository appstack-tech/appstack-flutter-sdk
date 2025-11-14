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
}

void main() {
  final AppstackPluginPlatform initialPlatform =
      AppstackPluginPlatform.instance;

  test('$MethodChannelAppstackPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAppstackPlugin>());
  });

  test('configure', () async {
    MockAppstackPluginPlatform fakePlatform = MockAppstackPluginPlatform();
    AppstackPluginPlatform.instance = fakePlatform;

    await AppstackPlugin.configure('test-api-key');
  });

  test('sendEvent', () async {
    MockAppstackPluginPlatform fakePlatform = MockAppstackPluginPlatform();
    AppstackPluginPlatform.instance = fakePlatform;

    expect(
      await AppstackPlugin.sendEvent(
        EventType.purchase,
        parameters: {'revenue': 19.99, 'currency': 'USD'},
      ),
      true,
    );
  });

  test('enableAppleAdsAttribution', () async {
    MockAppstackPluginPlatform fakePlatform = MockAppstackPluginPlatform();
    AppstackPluginPlatform.instance = fakePlatform;

    expect(await AppstackPlugin.enableAppleAdsAttribution(), true);
  });

  test('getAppstackId', () async {
    MockAppstackPluginPlatform fakePlatform = MockAppstackPluginPlatform();
    AppstackPluginPlatform.instance = fakePlatform;

    expect(await AppstackPlugin.getAppstackId(), 'mock-appstack-id-456');
  });
}
