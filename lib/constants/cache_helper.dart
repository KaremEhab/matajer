import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheHelper {
  static SharedPreferences? sharedPreferences;

  static Future<void> init() async {
    sharedPreferences = await SharedPreferences.getInstance();
  }

  static Future<bool> saveData({
    required String key,
    required dynamic value,
  }) async {
    if (value is String) return await sharedPreferences!.setString(key, value);
    if (value is int) return await sharedPreferences!.setInt(key, value);
    if (value is double) return await sharedPreferences!.setDouble(key, value);
    if (value is bool) return await sharedPreferences!.setBool(key, value);

    // ✅ دعم Map<String, dynamic>
    if (value is Map<String, dynamic>) {
      final jsonString = jsonEncode(value);
      return await sharedPreferences!.setString(key, jsonString);
    }

    throw Exception("Unsupported value type for key: $key");
  }

  static dynamic getData({
    required String key,
    bool decodeJson = false, // ✅ لو عايز تفك ترميز الـ JSON تلقائياً
  }) {
    final value = sharedPreferences!.get(key);

    if (decodeJson && value is String) {
      try {
        return jsonDecode(value);
      } catch (_) {
        return value;
      }
    }

    return value;
  }

  static Future<bool> removeData({required String key}) async {
    return await sharedPreferences!.remove(key);
  }
}
