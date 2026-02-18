/// API configuration for EDT backend
class ApiConfig {
  // Base URL - change for production
  static const String baseUrl = 'https://monsousdomaine.mondomain.com';

  // Endpoints
  static const String login = '/auth/login';
  static const String registerDevice = '/auth/register-device';
  static const String logout = '/auth/logout';
  static const String agenda = '/agenda';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // For Android emulator accessing localhost, use: http://10.0.2.2:8000
  // For iOS simulator, use: http://localhost:8000
  // For real device, use your computer's IP: http://192.168.x.x:8000

  /// Get full URL for endpoint
  static String getUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
}
