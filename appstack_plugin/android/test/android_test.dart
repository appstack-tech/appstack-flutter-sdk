import 'package:flutter_test/flutter_test.dart';
import 'package:android/android.dart';
import 'package:android/android_platform_interface.dart';
import 'package:android/android_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAndroidPlatform
    with MockPlatformInterfaceMixin
    implements AndroidPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final AndroidPlatform initialPlatform = AndroidPlatform.instance;

  test('$MethodChannelAndroid is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAndroid>());
  });

  test('getPlatformVersion', () async {
    Android androidPlugin = Android();
    MockAndroidPlatform fakePlatform = MockAndroidPlatform();
    AndroidPlatform.instance = fakePlatform;

    expect(await androidPlugin.getPlatformVersion(), '42');
  });
}
