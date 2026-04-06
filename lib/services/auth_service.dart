import '../config/api_config.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'storage_service.dart';

/// Result of a login attempt — either a User or MFA challenge
class LoginResult {
  final User? user;
  final bool mfaRequired;
  final String? sessionId;
  final String? mfaType; // "totp" or "push"
  final String? mfaData; // e.g. phone number for push

  LoginResult({
    this.user,
    this.mfaRequired = false,
    this.sessionId,
    this.mfaType,
    this.mfaData,
  });
}

/// Authentication service
class AuthService {
  /// Login with ESEO credentials
  /// Returns a LoginResult — check mfaRequired to know if MFA is needed
  static Future<LoginResult> login(String email, String password) async {
    final response = await ApiService.post(
      ApiConfig.login,
      {
        'email': email,
        'password': password,
      },
      includeAuth: false,
    );

    final data = ApiService.handleResponse(response);

    if (data['mfa_required'] == true) {
      return LoginResult(
        mfaRequired: true,
        sessionId: data['session_id'],
        mfaType: data['mfa_type'],
        mfaData: data['mfa_data']?.toString(),
      );
    }

    final user = User.fromJson(data);
    await StorageService.saveToken(user.accessToken);
    await StorageService.saveEseoId(user.eseoId);

    return LoginResult(user: user);
  }

  /// Verify MFA code (TOTP or push)
  static Future<User> verifyMfa(String sessionId, {String? totpCode}) async {
    final body = <String, dynamic>{'session_id': sessionId};
    if (totpCode != null) {
      body['totp_code'] = totpCode;
    }

    final response = await ApiService.post(
      ApiConfig.mfaVerify,
      body,
      includeAuth: false,
    );

    final data = ApiService.handleResponse(response);
    final user = User.fromJson(data);

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
      await ApiService.delete(
        ApiConfig.logout,
        includeAuth: true,
      );
    } catch (e) {
      // Continue logout even if API call fails
    } finally {
      await StorageService.clearAll();
    }
  }

  /// Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    return await StorageService.isAuthenticated();
  }
}
