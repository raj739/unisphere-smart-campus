import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokenKey = 'unisphere_access_token';

  static const String _roleKey = 'unisphere_role';

  static const String _userIdKey = 'unisphere_user_id';

  static Future<void> saveSession({
    required String token,
    required String role,
    required int userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_tokenKey, token);

    await prefs.setString(_roleKey, role);

    await prefs.setInt(_userIdKey, userId);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_tokenKey);
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_roleKey);
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getInt(_userIdKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();

    return token != null && token.isNotEmpty;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_userIdKey);
  }
}
