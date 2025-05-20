// lib/features/otp/services/otp_service.dart
import 'package:dio/dio.dart'; // Import Dio
import 'package:flutter/foundation.dart'; // For debugPrint
// Note: This service uses a plain http.Client because OTP request/verify
// are typically public endpoints and don't require an authentication token.
// If your /otp/request for an existing user (e.g., to change email) *is* authenticated,
// then this would need to use AuthenticatedClient. For now, assuming public.

class OtpException implements Exception {
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
  OtpService({required Dio dio}) : _dio = dio; // Inject Dio

  final Dio _dio; // Store Dio instance

  Future<void> requestOtp(String email, {String? userId}) async {
    const endpoint = '/otp/request'; // Relative to Dio's baseUrl
    final requestBody = <String, dynamic>{'email': email};
    if (userId != null && userId.isNotEmpty) {
      requestBody['userId'] = userId;
    }

    debugPrint(
      '[OtpService-DIO] POST $endpoint for email: $email, userId: $userId',
    );
    try {
      // Dio handles JSON encoding for maps by default with 'application/json' content type
      final response = await _dio.post<dynamic>(endpoint, data: requestBody);

      // Dio throws DioException for non-2xx status codes, so if we reach here, it's likely 200-299.
      // Backend sends 200 for OTP sent.
      if (response.statusCode == 200) {
        debugPrint(
          '[OtpService-DIO] OTP requested successfully for $email. Response Data: ${response.data}',
        );
        return;
      } else {
        // This case might be redundant if Dio always throws for non-2xx
        throw OtpException(
          (response.data is Map<String, dynamic>
                  ? (response.data as Map<String, dynamic>)['message']
                        as String?
                  : null) ??
              'Failed to request OTP from server.',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      debugPrint(
        '[OtpService-DIO] DioException requesting OTP: ${e.response?.data ?? e.message}',
      );
      throw OtpException(
        (e.response?.data is Map<String, dynamic>
                ? (e.response?.data as Map<String, dynamic>)['message']
                      as String?
                : null) ??
            e.message ??
            'Network error requesting OTP.',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      debugPrint('[OtpService-DIO] Unexpected error requesting OTP: $e');
      throw OtpException('An unexpected error occurred while requesting OTP.');
    }
  }

  Future<bool> verifyOtp(String email, String otp) async {
    const endpoint = '/otp/verify';
    final requestBody = {'email': email, 'otp': otp};
    debugPrint('[OtpService-DIO] POST $endpoint for email: $email, otp: $otp');

    try {
      final response = await _dio.post<dynamic>(endpoint, data: requestBody);

      if (response.statusCode == 200) {
        // response.data is already a Map<String, dynamic> if backend sent JSON
        final responseData = response.data as Map<String, dynamic>?;
        if (responseData?['success'] == true) {
          debugPrint('[OtpService-DIO] OTP verified successfully for $email.');
          return true;
        } else {
          throw OtpException(
            responseData?['message'] as String? ??
                'OTP verification indicated failure.',
            statusCode: response.statusCode,
          );
        }
      } else {
        // Redundant if Dio throws for non-2xx
        throw OtpException(
          (response.data is Map<String, dynamic>
                  ? (response.data as Map<String, dynamic>)['message']
                        as String?
                  : null) ??
              'OTP verification failed from server.',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      debugPrint(
        '[OtpService-DIO] DioException verifying OTP: ${e.response?.data ?? e.message}',
      );
      throw OtpException(
        (e.response?.data is Map<String, dynamic>
                ? (e.response?.data as Map<String, dynamic>)['message']
                      as String?
                : null) ??
            e.message ??
            'Network error verifying OTP.',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      debugPrint('[OtpService-DIO] Unexpected error verifying OTP: $e');
      throw OtpException(
        'An unexpected error occurred during OTP verification.',
      );
    }
  }
}
