// lib/features/login/services/login_service.dart

import 'package:dio/dio.dart'; // Import Dio
import 'package:flutter/foundation.dart';
import 'package:ta_client/features/login/models/login_response.dart';

class LoginException implements Exception {
  LoginException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => 'LoginException: $message (Status: $statusCode)';
}

class LoginService {
  LoginService({required Dio dio}) : _dio = dio; // Inject Dio
  final Dio _dio;

  Future<LoginResponse> login({
    required String email, // Backend accepts email or username here
    required String password,
  }) async {
    const endpoint = '/users/login'; // Relative to Dio's baseUrl
    final requestBody = {'email': email, 'password': password};
    debugPrint(
      '[LoginService-DIO] POST $endpoint',
    ); // Body logged by interceptor

    try {
      final response = await _dio.post<dynamic>(endpoint, data: requestBody);

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        // response.data is already a Map<String, dynamic>
        return LoginResponse.fromJson(response.data as Map<String, dynamic>);
      } else {
        // This case might be redundant if Dio always throws for non-2xx
        throw LoginException(
          response.data?['message']?.toString() ?? 'Login failed on server.',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      debugPrint(
        '[LoginService-DIO] DioException during login: ${e.response?.data ?? e.message}',
      );
      throw LoginException(
        e.response?.data?['message']?.toString() ??
            e.message ??
            'Network error during login.',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      debugPrint('[LoginService-DIO] Unexpected error during login: $e');
      throw LoginException('An unexpected error occurred during login.');
    }
  }
}
