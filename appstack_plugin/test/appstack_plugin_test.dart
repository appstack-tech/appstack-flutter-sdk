import 'package:flutter_test/flutter_test.dart';
import 'package:appstack_plugin/appstack_plugin.dart';
import 'package:appstack_plugin/appstack_plugin_platform_interface.dart';
import 'package:appstack_plugin/appstack_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAppstackPluginPlatform
    with MockPlatformInterfaceMixin
    implements AppstackPluginPlatform {
  @override
  Future<bool> configure(
    String apiKey,
    bool isDebug,
    String? endpointBaseUrl,
    int logLevel,
  ) =>
      Future.value(true);

  @override
  Future<bool> sendEvent(String eventType, String? eventName, double revenue) =>
      Future.value(true);

  @override
  Future<bool> enableAppleAdsAttribution() => Future.value(true);

  @override
  Future<String?> getAppstackId() => Future.value('mock-appstack-id-456');
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

    expect(await AppstackPlugin.configure('test-api-key'), true);
  });

  test('sendEvent', () async {
    MockAppstackPluginPlatform fakePlatform = MockAppstackPluginPlatform();
    AppstackPluginPlatform.instance = fakePlatform;

    expect(
      await AppstackPlugin.sendEvent(EventType.purchase, revenue: 19.99),
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
