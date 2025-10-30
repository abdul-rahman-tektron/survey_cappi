import 'package:package_info_plus/package_info_plus.dart';

class AppInfoHelper {
  static Future<String> versionLabel() async {
    final info = await PackageInfo.fromPlatform();
    return 'v${info.version}';
  }
}