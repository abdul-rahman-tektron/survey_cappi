import 'package:hive/hive.dart';
import 'package:srpf/res/hive_keys.dart';

class HiveStorageService {
  HiveStorageService._();

  static late Box _box;

  /// Call this once at app start
  static Future<void> init() async {
    _box = await Hive.openBox('appBox');
  }

  /// LANGUAGE CODE
  static Future<void> setLanguageCode(String langCode) async {
    await _box.put(HiveKeys.languageCode, langCode);
  }

  static String? getLanguageCode() {
    return _box.get(HiveKeys.languageCode);
  }

  //Set Remember Me Data
  static Future<void> setRememberMe(String flow) async {
    await _box.put(HiveKeys.rememberMe, flow);
  }

  static String? getRememberMe() {
    return _box.get(HiveKeys.rememberMe);
  }

  static Future<void> setUserData(String flow) async {
    await _box.put(HiveKeys.userData, flow);
  }

  static String? getUserData() {
    return _box.get(HiveKeys.userData);
  }


  /// Remove specific key
  static Future<void> remove(String key) async {
    await _box.delete(key);
  }

  /// Clear all
  static Future<void> clear() async {
    await _box.clear();
  }

  static Future<void> clearOnLogout() async {
    // List of keys you want to preserve even after logout
    final List<String> preserveKeys = [
      HiveKeys.rememberMe,
      HiveKeys.onboardingCompleted,
      // Add more keys in future as needed
    ];

    // Temporary storage of values for preserved keys
    final Map<String, dynamic> preservedData = {};

    for (final key in preserveKeys) {
      if (_box.containsKey(key)) {
        preservedData[key] = _box.get(key);
      }
    }

    // Clear all data
    await _box.clear();

    // Restore preserved values
    for (final entry in preservedData.entries) {
      await _box.put(entry.key, entry.value);
    }
  }
}