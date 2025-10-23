import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class AppPermissionHandler {
  AppPermissionHandler._();

  static Future<bool> checkAndRequestCamera() async {
    return _checkAndRequest(Permission.camera);
  }

  static Future<bool> checkAndRequestStorage() async {
    if (Platform.isAndroid) {
      return _checkAndRequest(Permission.storage);
    } else if (Platform.isIOS) {
      return _checkAndRequest(Permission.photos);
    }
    // For other platforms, return true or handle accordingly
    return true;
  }

  static Future<bool> checkAndRequestLocation() async {
    return _checkAndRequest(Permission.locationWhenInUse);
  }

  static Future<bool> _checkAndRequest(Permission permission) async {
    final status = await permission.status;
    if (status.isGranted) return true;
    final result = await permission.request();
    return result.isGranted;
  }
}
