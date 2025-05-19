// lib/features/otp/services/otp_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:http/http.dart' as http;
// Note: This service uses a plain http.Client because OTP request/verify
// are typically public endpoints and don't require an authentication token.
// If your /otp/request for an existing user (e.g., to change email) *is* authenticated,
// then this would need to use AuthenticatedClient. For now, assuming public.

class OtpException implements Exception {
  // Optional: to store HTTP status code from server

  OtpException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() {
    if (statusCode != null) {
      return 'OtpException: $message (Status: $statusCode)';
    }
    return 'OtpException: $message';
  }
}

class OtpService {
  OtpService({required String baseUrl}) : _baseUrl = baseUrl;

  final String _baseUrl;
  final http.Client _client = http.Client(); // Using a plain http.Client

  Future<void> requestOtp(String email, {String? userId}) async {
    final url = Uri.parse(
      '$_baseUrl/otp/request',
    ); // Matches backend public route
    final requestBody = <String, String>{'email': email};
    if (userId != null && userId.isNotEmpty) {
      requestBody['userId'] =
          userId; // Optional: if OTP is for an existing, identified user
    }

    debugPrint('[OtpService-API] POST $url for email: $email, userId: $userId');
    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        // OTP sent successfully (backend responded with success)
        debugPrint('[OtpService-API] OTP requested successfully for $email.');
        return;
      } else {
        // Attempt to parse error message from backend
        String errorMessage = 'Failed to request OTP.';
        try {
          final errorBody = json.decode(response.body) as Map<String, dynamic>;
          errorMessage = errorBody['message'] as String? ?? errorMessage;
        } catch (_) {
          // Ignore parsing error, use default message + status code
          errorMessage =
              'Failed to request OTP. Server responded with status ${response.statusCode}.';
        }
        throw OtpException(errorMessage, statusCode: response.statusCode);
      }
    } catch (e) {
      debugPrint('[OtpService-API] Error requesting OTP: $e');
      if (e is OtpException) rethrow; // Re-throw our custom exception
      throw OtpException(
        'Could not connect to request OTP. Please check your network connection and try again.',
      );
    }
  }

  Future<bool> verifyOtp(String email, String otp) async {
    final url = Uri.parse(
      '$_baseUrl/otp/verify',
    ); // Matches backend public route
    debugPrint('[OtpService-API] POST $url for email: $email, otp: $otp');
    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'otp': otp}),
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body) as Map<String, dynamic>;
        if (responseBody['success'] == true) {
          debugPrint('[OtpService-API] OTP verified successfully for $email.');
          return true; // OTP verified
        } else {
          // Backend indicated success:false but with a 200, use its message
          throw OtpException(
            responseBody['message'] as String? ??
                'OTP verification indicated failure.',
            statusCode: response.statusCode,
          );
        }
      } else {
        // Attempt to parse error message from backend for non-200 responses
        String errorMessage = 'OTP verification failed.';
        try {
          final errorBody = json.decode(response.body) as Map<String, dynamic>;
          errorMessage = errorBody['message'] as String? ?? errorMessage;
        } catch (_) {
          errorMessage =
              'OTP verification failed. Server responded with status ${response.statusCode}.';
        }
        throw OtpException(errorMessage, statusCode: response.statusCode);
      }
    } catch (e) {
      debugPrint('[OtpService-API] Error verifying OTP: $e');
      if (e is OtpException) rethrow;
      throw OtpException(
        'Could not connect to verify OTP. Please check your network connection and try again.',
      );
    }
  }

  // Call this when the service instance is no longer needed, e.g. in a dispose method of a provider.
  void dispose() {
    _client.close();
  }
}
