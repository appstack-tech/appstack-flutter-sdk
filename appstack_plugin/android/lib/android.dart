
import 'android_platform_interface.dart';

class Android {
  Future<String?> getPlatformVersion() {
    return AndroidPlatform.instance.getPlatformVersion();
  }
}
