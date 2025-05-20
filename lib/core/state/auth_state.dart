// lib/core/state/auth_state.dart
import 'package:flutter/material.dart';
// Remove: import 'package:hive/hive.dart'; // No longer directly used
import 'package:jwt_decode/jwt_decode.dart';
import 'package:ta_client/core/services/hive_service.dart'; // Import HiveService
import 'package:ta_client/core/services/service_locator.dart'; // For sl

class UserSessionData {
  // Add other fields from JWT payload if needed (e.g., username, roles)
  // final String? username;

  UserSessionData({required this.id, required this.email /*, this.username */});
  final String id;
  final String email;
}

class AuthState extends ChangeNotifier {
  // Expose loading state

  AuthState() {
    // Automatically try to log in when AuthState is first created (e.g., by GetIt)
    tryAutoLogin();
  }
  UserSessionData? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = true; // To indicate initial auth check state

  UserSessionData? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  Future<void> tryAutoLogin() async {
    _isLoading = true;
    notifyListeners(); // Notify UI that loading has started

    final hiveService = sl<HiveService>(); // Get HiveService
    final token = await hiveService.getAuthToken();

    if (token != null && token.isNotEmpty) {
      try {
        // Optional: Add client-side token expiry check using jwt_decode
        // bool isExpired = Jwt.isExpired(token);
        // if (isExpired) throw Exception("Token expired");

        final payload = Jwt.parseJwt(token); // Can throw if token is malformed
        _currentUser = UserSessionData(
          id:
              payload['id'] as String? ??
              '', // Ensure these keys match your JWT payload
          email: payload['email'] as String? ?? '',
          // username: payload['username'] as String?, // Example
        );
        if (_currentUser!.id.isEmpty) {
          throw Exception('User ID missing in token');
        }

        _isAuthenticated = true;
        debugPrint(
          '[AuthState] Auto-login successful for user: ${_currentUser?.id}',
        );
      } catch (e) {
        debugPrint(
          '[AuthState] Auto-login failed (token issue: $e). Clearing token.',
        );
        await hiveService.deleteAuthToken(); // Clear invalid/expired token
        _isAuthenticated = false;
        _currentUser = null;
      }
    } else {
      _isAuthenticated = false;
      _currentUser = null;
      debugPrint('[AuthState] No token found for auto-login.');
    }
    _isLoading = false;
    notifyListeners();
  }

  // Called by LoginBloc after successful API login AND token is stored in Hive
  void processLoginSuccess(String token) {
    _isLoading = true; // May briefly show loading while parsing token
    notifyListeners();
    try {
      final payload = Jwt.parseJwt(token);
      _currentUser = UserSessionData(
        id: payload['id'] as String? ?? '',
        email: payload['email'] as String? ?? '',
      );
      if (_currentUser!.id.isEmpty) {
        throw Exception('User ID missing in token after login');
      }

      _isAuthenticated = true;
      debugPrint('[AuthState] Login processed for user: ${_currentUser?.id}');
    } catch (e) {
      debugPrint(
        '[AuthState] Error processing token on login: $e. Forcing logout state.',
      );
      // If token processing fails after login, treat as unauthenticated
      _isAuthenticated = false;
      _currentUser = null;
      sl<HiveService>().deleteAuthToken(); // Ensure bad token is cleared
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    final hiveService = sl<HiveService>();
    await hiveService.deleteAuthToken();
    _currentUser = null;
    _isAuthenticated = false;
    debugPrint('[AuthState] User logged out.');
    _isLoading = false;
    notifyListeners();
  }
}
