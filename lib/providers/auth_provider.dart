import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

/// Authentication state provider
class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  // MFA state
  bool _mfaRequired = false;
  String? _mfaSessionId;
  String? _mfaType; // "totp" or "push"
  String? _mfaData; // e.g. phone number for push

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  bool get mfaRequired => _mfaRequired;
  String? get mfaSessionId => _mfaSessionId;
  String? get mfaType => _mfaType;
  String? get mfaData => _mfaData;

  /// Check if user is authenticated (from storage)
  Future<bool> checkAuth() async {
    _isLoading = true;

    try {
      final isAuth = await AuthService.isAuthenticated();
      if (isAuth) {
        final token = await StorageService.getToken();
        final eseoId = await StorageService.getEseoId();
        if (token != null && eseoId != null) {
          _user = User(eseoId: eseoId, accessToken: token);
        }
      }
      return isAuth;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Login with email and password
  /// Returns true if login is complete, false if MFA is required or error
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    _mfaRequired = false;
    notifyListeners();

    try {
      final result = await AuthService.login(email, password);

      if (result.mfaRequired) {
        _mfaRequired = true;
        _mfaSessionId = result.sessionId;
        _mfaType = result.mfaType;
        _mfaData = result.mfaData;
        _isLoading = false;
        notifyListeners();
        return false; // Login not complete, MFA needed
      }

      _user = result.user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Verify MFA code
  Future<bool> verifyMfa(String code) async {
    if (_mfaSessionId == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await AuthService.verifyMfa(
        _mfaSessionId!,
        totpCode: _mfaType == 'totp' ? code : null,
      );
      _clearMfaState();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Wait for push MFA approval (polling)
  Future<bool> waitForPushApproval() async {
    if (_mfaSessionId == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await AuthService.verifyMfa(_mfaSessionId!);
      _clearMfaState();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Cancel MFA and go back to login
  void cancelMfa() {
    _clearMfaState();
    notifyListeners();
  }

  void _clearMfaState() {
    _mfaRequired = false;
    _mfaSessionId = null;
    _mfaType = null;
    _mfaData = null;
  }

  /// Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await AuthService.logout();
      _user = null;
      _clearMfaState();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
