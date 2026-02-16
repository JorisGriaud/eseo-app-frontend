import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage service for JWT token and user data
class StorageService {
  static const _storage = FlutterSecureStorage();

  // Storage keys
  static const String _keyToken = 'jwt_token';
  static const String _keyEseoId = 'eseo_id';

  /// Save authentication token
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  /// Get authentication token
  static Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  /// Save ESEO ID
  static Future<void> saveEseoId(String eseoId) async {
    await _storage.write(key: _keyEseoId, value: eseoId);
  }

  /// Get ESEO ID
  static Future<String?> getEseoId() async {
    return await _storage.read(key: _keyEseoId);
  }

  /// Clear all stored data (logout)
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// Check if user is authenticated (has token)
  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
