import '../config/api_config.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'storage_service.dart';

/// Authentication service
class AuthService {
  /// Login with ESEO credentials
  static Future<User> login(String email, String password) async {
    final response = await ApiService.post(
      ApiConfig.login,
      {
        'email': email,
        'password': password,
      },
      includeAuth: false,
    );

    final data = ApiService.handleResponse(response);
    final user = User.fromJson(data);

    // Save token and eseo_id to secure storage
    await StorageService.saveToken(user.accessToken);
    await StorageService.saveEseoId(user.eseoId);

    return user;
  }

  /// Register device token for push notifications
  static Future<void> registerDeviceToken(String deviceToken) async {
    final response = await ApiService.post(
      ApiConfig.registerDevice,
      {'device_token': deviceToken},
      includeAuth: true,
    );

    ApiService.handleResponse(response);
  }

  /// Logout
  static Future<void> logout() async {
    try {
      // Call backend logout endpoint
      await ApiService.delete(
        ApiConfig.logout,
        includeAuth: true,
      );
    } catch (e) {
      // Continue logout even if API call fails
    } finally {
      // Clear local storage
      await StorageService.clearAll();
    }
  }

  /// Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    return await StorageService.isAuthenticated();
  }
}
