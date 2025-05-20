// lib/features/register/services/register_service.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class RegisterException implements Exception {
  RegisterException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => 'RegisterException: $message (Status: $statusCode)';
}

class RegisterService {
  RegisterService({required Dio dio}) : _dio = dio;
  final Dio _dio;

  Future<List<Map<String, String>>> fetchOccupations() async {
    const endpoint = '/occupations';
    debugPrint('[RegisterService-DIO] GET $endpoint for occupations');
    try {
      final response = await _dio.get<dynamic>(endpoint);
      // Assuming backend for /occupations returns a direct list of {id, name}
      // If it's wrapped like { success: true, data: [] }, adjust accordingly.
      // For now, let's assume it's wrapped as this is common in your backend.
      if (response.statusCode == 200 &&
          response.data is Map<String, dynamic> &&
          response.data['data'] is List) {
        final data = response.data['data'] as List<dynamic>;
        return data.map((occ) {
          final item = occ as Map<String, dynamic>;
          return {'id': item['id'] as String, 'name': item['name'] as String};
        }).toList();
      } else if (response.statusCode == 200 && response.data is List) {
        // Fallback for direct list
        final data = response.data as List<dynamic>;
        return data.map((occ) {
          final item = occ as Map<String, dynamic>;
          return {'id': item['id'] as String, 'name': item['name'] as String};
        }).toList();
      } else {
        throw RegisterException(
          response.data?['message']?.toString() ??
              'Failed to load occupations from server.',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      debugPrint(
        '[RegisterService-DIO] DioException fetching occupations: ${e.response?.data ?? e.message}',
      );
      throw RegisterException(
        e.response?.data?['message']?.toString() ??
            e.message ??
            'Network error fetching occupations.',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      debugPrint(
        '[RegisterService-DIO] Unexpected error fetching occupations: $e',
      );
      if (e is RegisterException) rethrow;
      throw RegisterException(
        'An unexpected error occurred while fetching occupations: ${e}',
      );
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String username,
    required String email,
    required String password,
    required String address,
    required DateTime birthdate,
    required String occupationId,
  }) async {
    const endpoint = '/users/register';
    final requestBody = {
      'name': name,
      'username': username,
      'email': email,
      'password': password,
      'address': address,
      'birthdate': birthdate.toUtc().toIso8601String(),
      'occupationId': occupationId,
    };
    debugPrint('[RegisterService-DIO] POST $endpoint with body: $requestBody');
    try {
      final response = await _dio.post<dynamic>(endpoint, data: requestBody);
      if (response.statusCode == 201 &&
          response.data is Map<String, dynamic> &&
          response.data['success'] == true &&
          response.data['user'] is Map<String, dynamic>) {
        debugPrint(
          '[RegisterService-DIO] Registration successful for $email. Response Data: ${response.data}',
        );
        return response.data['user'] as Map<String, dynamic>;
      } else {
        throw RegisterException(
          response.data?['message']?.toString() ??
              'Registration failed on server.',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      debugPrint(
        '[RegisterService-DIO] DioException during registration: ${e.response?.data ?? e.message}',
      );
      throw RegisterException(
        e.response?.data?['message']?.toString() ??
            e.message ??
            'Network error during registration.',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      debugPrint(
        '[RegisterService-DIO] Unexpected error during registration: $e',
      );
      if (e is RegisterException) rethrow;
      throw RegisterException(
        'An unexpected error occurred during registration: ${e}',
      );
    }
  }
}
