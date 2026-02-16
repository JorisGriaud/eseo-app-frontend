import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'storage_service.dart';

/// HTTP client service with JWT authentication
class ApiService {
  /// Get headers with JWT token
  static Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (includeAuth) {
      final token = await StorageService.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// POST request
  static Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool includeAuth = false,
  }) async {
    final url = Uri.parse(ApiConfig.getUrl(endpoint));
    final headers = await _getHeaders(includeAuth: includeAuth);

    try {
      final response = await http
          .post(
            url,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.connectionTimeout);

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// GET request
  static Future<http.Response> get(
    String endpoint, {
    bool includeAuth = true,
  }) async {
    final url = Uri.parse(ApiConfig.getUrl(endpoint));
    final headers = await _getHeaders(includeAuth: includeAuth);

    try {
      final response = await http
          .get(
            url,
            headers: headers,
          )
          .timeout(ApiConfig.receiveTimeout);

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// DELETE request
  static Future<http.Response> delete(
    String endpoint, {
    bool includeAuth = true,
  }) async {
    final url = Uri.parse(ApiConfig.getUrl(endpoint));
    final headers = await _getHeaders(includeAuth: includeAuth);

    try {
      final response = await http
          .delete(
            url,
            headers: headers,
          )
          .timeout(ApiConfig.connectionTimeout);

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Handle API response
  static Map<String, dynamic> handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      // Error handling
      throw ApiException(
        statusCode: response.statusCode,
        message: _extractErrorMessage(response),
      );
    }
  }

  /// Extract error message from response
  static String _extractErrorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      return body['detail'] ?? body['message'] ?? 'Une erreur est survenue';
    } catch (e) {
      return 'Erreur ${response.statusCode}';
    }
  }
}

/// Custom API exception
class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({
    required this.statusCode,
    required this.message,
  });

  @override
  String toString() => message;
}
