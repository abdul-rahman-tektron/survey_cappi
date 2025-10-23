import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:srpf/res/strings.dart';

class SecureStorageService {
  static FlutterSecureStorage? _secureStorage;

  // Initialize with encryptedSharedPreferences on Android
  static Future init() async {
    _secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
  }

  // Safe read wrapper to handle BadPaddingException
  static Future<String?> _safeRead(String key) async {
    try {
      return await _secureStorage?.read(key: key);
    } catch (e, stack) {
      print("SecureStorage read error: $e");
    }
  }

  static Future<void> setToken(String value) async {
    await _secureStorage?.write(key: AppStrings.accessToken, value: value);
  }

  static Future<String?> getToken() async {
    return await _safeRead(AppStrings.accessToken);
  }

  static Future<void> removeParticularKey(String key) async {
    await _secureStorage?.delete(key: key);
  }

  static Future<void> clearData() async {
    await _secureStorage?.deleteAll();
  }
}