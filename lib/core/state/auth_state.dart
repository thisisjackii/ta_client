// lib/core/state/auth_state.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart'; // For token
import 'package:jwt_decode/jwt_decode.dart'; // For decoding JWT to get user ID

class UserSessionData {
  // Add other fields from JWT payload if needed

  UserSessionData({required this.id, required this.email});
  // Simple class to hold user data from token
  final String id;
  final String email;
}

class AuthState extends ChangeNotifier {
  UserSessionData? _currentUser;
  bool _isAuthenticated = false;

  UserSessionData? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;

  // Call this on app start or after fetching token
  Future<void> tryAutoLogin() async {
    final box = Hive.box<String>('secureBox');
    final token = box.get('jwt_token');
    if (token != null) {
      try {
        // Optionally verify token expiry here before decoding
        final payload = Jwt.parseJwt(token);
        _currentUser = UserSessionData(
          id: payload['id'] as String,
          email: payload['email'] as String,
        );
        _isAuthenticated = true;
        debugPrint(
          '[AuthState] Auto-login successful for user: ${_currentUser?.id}',
        );
      } catch (e) {
        debugPrint('[AuthState] Auto-login failed, invalid token: $e');
        await logout(); // Clear invalid token
      }
    } else {
      _isAuthenticated = false;
      _currentUser = null;
    }
    notifyListeners();
  }

  void login(String token) {
    // LoginBloc calls this after successful API login
    try {
      final payload = Jwt.parseJwt(token);
      _currentUser = UserSessionData(
        id: payload['id'] as String,
        email: payload['email'] as String,
      );
      _isAuthenticated = true;
      // Token is already saved to Hive by LoginBloc/Service
      debugPrint('[AuthState] Login successful for user: ${_currentUser?.id}');
    } catch (e) {
      debugPrint('[AuthState] Error processing token on login: $e');
      _isAuthenticated = false;
      _currentUser = null;
    }
    notifyListeners();
  }

  Future<void> logout() async {
    final box = Hive.box<String>('secureBox');
    await box.delete('jwt_token');
    _currentUser = null;
    _isAuthenticated = false;
    debugPrint('[AuthState] User logged out.');
    notifyListeners();
  }
}
