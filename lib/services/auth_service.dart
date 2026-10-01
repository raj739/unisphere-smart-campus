import 'package:unisphere_mobile/core/network/api_client.dart';
import 'package:unisphere_mobile/core/network/api_config.dart';
import 'package:unisphere_mobile/core/storage/storage_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final data = await ApiClient.post(
      ApiConfig.login,
      authenticated: false,
      body: {'email': email, 'password': password},
    );

    await StorageService.saveSession(
      token: data['access_token'],
      role: data['role'],
      userId: data['user_id'],
    );

    return Map<String, dynamic>.from(data);
  }

  static Future<void> logout() async {
    await StorageService.clearSession();
  }
}
