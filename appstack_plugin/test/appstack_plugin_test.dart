import 'package:flutter_test/flutter_test.dart';
import 'package:appstack_plugin/appstack_plugin.dart';
import 'package:appstack_plugin/appstack_plugin_platform_interface.dart';
import 'package:appstack_plugin/appstack_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAppstackPluginPlatform
    with MockPlatformInterfaceMixin
    implements AppstackPluginPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final AppstackPluginPlatform initialPlatform =
      AppstackPluginPlatform.instance;

  test('$MethodChannelAppstackPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAppstackPlugin>());
  });

  test('getPlatformVersion', () async {
    AppstackPlugin appstackPlugin = AppstackPlugin();
    MockAppstackPluginPlatform fakePlatform = MockAppstackPluginPlatform();
    AppstackPluginPlatform.instance = fakePlatform;

    expect(await appstackPlugin.getPlatformVersion(), '42');
  });
}
