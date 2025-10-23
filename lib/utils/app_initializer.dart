// lib/utils/app_initializer.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:srpf/utils/storage/secure_storage.dart';
import 'package:srpf/utils/storage/hive_storage.dart';
import 'package:srpf/utils/location_helper.dart';
import 'package:srpf/res/colors.dart';

class AppInitializer {
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    await _initializeStorage();
    await _initializeLocation();
    await _setSystemUi();
  }

  static Future<void> _initializeStorage() async {
    await Hive.initFlutter();
    await HiveStorageService.init();
    await SecureStorageService.init();
  }

  static Future<void> _initializeLocation() async {
    // Your LocationHelper should internally handle permission prompts / caching
    await LocationHelper.initialize();
    // If you want to *force* an immediate permission request, uncomment (if available):
    // await LocationHelper.requestPermission();
    // Optionally warm up a first fix (non-fatal if it fails)
    // await LocationHelper.getCurrentLocation();
  }

  static Future<void> _setSystemUi() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemStatusBarContrastEnforced: true,
      statusBarColor: AppColors.primary,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  /// Loads persisted auth + user blob (kept compatible with your current main)
  static Future<Map<String, dynamic>> loadUserData() async {
    final token = await SecureStorageService.getToken();

    return {
      "token": token,
    };
  }
}





