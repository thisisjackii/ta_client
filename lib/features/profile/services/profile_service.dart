// lib/features/profile/services/profile_service.dart
// No dart:convert needed
import 'package:dio/dio.dart'; // Import Dio
import 'package:flutter/foundation.dart';
import 'package:ta_client/features/profile/models/user_model.dart'; // Your existing User model for profile

class ProfileApiException implements Exception {
  ProfileApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => 'ProfileApiException: $message (Status: $statusCode)';
}

class ProfileService {
  ProfileService({required Dio dio}) : _dio = dio; // Inject Dio
  final Dio _dio;

  Future<User> fetchProfile() async {
    const endpoint = '/users/profile'; // Relative to Dio's baseUrl
    debugPrint('[ProfileService-DIO] GET $endpoint');

    try {
      final response = await _dio.get<dynamic>(endpoint);
      if (response.statusCode == 200 && response.data?['user'] is Map) {
        // Backend sends { success: true, user: {...} }
        return User.fromJson(response.data['user'] as Map<String, dynamic>);
      } else {
        throw ProfileApiException(
          response.data?['message']?.toString() ??
              'Failed to load profile from server.',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      debugPrint(
        '[ProfileService-DIO] DioException fetching profile: ${e.response?.data ?? e.message}',
      );
      throw ProfileApiException(
        e.response?.data?['message']?.toString() ??
            e.message ??
            'Network error fetching profile.',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      debugPrint('[ProfileService-DIO] Unexpected error fetching profile: $e');
      throw ProfileApiException(
        'An unexpected error occurred while fetching profile.',
      );
    }
  }

  Future<User> updateProfile(User user) async {
    const endpoint = '/users/profile'; // Relative to Dio's baseUrl
    // User.toJson() should produce the DTO backend expects (UpdateUserProfileDto)
    final requestBody = user.toJson(); // Assuming a method for API update DTO
    debugPrint(
      '[ProfileService-DIO] PUT $endpoint',
    ); // Body logged by interceptor

    try {
      final response = await _dio.put<dynamic>(endpoint, data: requestBody);
      if (response.statusCode == 200 && response.data?['user'] is Map) {
        // Backend sends { success: true, user: {...} }
        return User.fromJson(response.data['user'] as Map<String, dynamic>);
      } else {
        throw ProfileApiException(
          response.data?['message']?.toString() ??
              'Failed to update profile on server.',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      debugPrint(
        '[ProfileService-DIO] DioException updating profile: ${e.response?.data ?? e.message}',
      );
      throw ProfileApiException(
        e.response?.data?['message']?.toString() ??
            e.message ??
            'Network error updating profile.',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      debugPrint('[ProfileService-DIO] Unexpected error updating profile: $e');
      throw ProfileApiException(
        'An unexpected error occurred while updating profile.',
      );
    }
  }
}
