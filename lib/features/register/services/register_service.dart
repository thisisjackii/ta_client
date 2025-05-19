// lib/features/register/services/register_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
// Import Occupation model if you want to fetch occupations for dropdown
// import 'package:ta_client/features/register/models/occupation_model.dart';

class RegisterException implements Exception {
  RegisterException(this.message);
  final String message;
  @override
  String toString() => message;
}

class RegisterService {
  RegisterService({required String baseUrl}) : _baseUrl = baseUrl;
  final String _baseUrl;
  final http.Client _client =
      http.Client(); // Plain client for public register endpoint

  // Method to fetch occupations for the dropdown
  Future<List<Map<String, String>>> fetchOccupations() async {
    // Returns List<{id, name}>
    final uri = Uri.parse(
      '$_baseUrl/occupations',
    ); // Assuming a GET /occupations endpoint
    debugPrint('[RegisterService-API] GET $uri');
    try {
      final response = await _client.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        return data.map((occ) {
          final item = occ as Map<String, dynamic>;
          return {
            // Directly return the map
            'id': item['id'] as String,
            'name': item['name'] as String,
          };
        }).toList();
      } else {
        throw RegisterException(
          'Failed to load occupations: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw RegisterException('Error fetching occupations: $e');
    }
  }

  Future<void> register({
    // This is the actual account creation call
    required String name,
    required String username,
    required String email,
    required String password,
    required String address,
    required DateTime birthdate,
    required String occupationId, // Expects occupationId
  }) async {
    final uri = Uri.parse('$_baseUrl/users/register'); // Backend endpoint
    final requestBody = {
      'name': name,
      'username': username,
      'email': email,
      'password': password,
      'address': address,
      'birthdate': birthdate.toIso8601String(),
      'occupationId': occupationId, // Send ID to backend
    };
    debugPrint('[RegisterService-API] POST $uri with body: $requestBody');

    try {
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 201) {
        debugPrint('[RegisterService-API] Registration successful for $email');
        // Optionally parse and return the created user if backend sends it back
        // final body = jsonDecode(response.body) as Map<String, dynamic>;
        // return User.fromJson(body['user']); // Assuming User model exists
        return;
      } else {
        String errorMessage = 'Registration failed.';
        try {
          final body = json.decode(response.body) as Map<String, dynamic>;
          errorMessage =
              body['message'] as String? ??
              'Registration failed with status ${response.statusCode}.';
        } catch (_) {
          errorMessage =
              'Registration failed with status ${response.statusCode}. Response: ${response.body}';
        }
        throw RegisterException(errorMessage);
      }
    } catch (e) {
      debugPrint('[RegisterService-API] Error during registration: $e');
      if (e is RegisterException) rethrow;
      throw RegisterException(
        'Could not connect to register. Please check your network and try again.',
      );
    }
  }
}
