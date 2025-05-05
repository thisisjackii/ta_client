// features/register/services/register_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class RegisterService {
  RegisterService({required String baseUrl}) : _baseUrl = baseUrl;
  final String _baseUrl;

  Future<void> register({
    required String name,
    required String username,
    required String email,
    required String password,
    required String address,
    required DateTime birthdate,
    required String occupation,
  }) async {
    final uri = Uri.parse('$_baseUrl/users/register');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'username': username,
        'email': email,
        'password': password,
        'address': address,
        'birthdate': birthdate.toIso8601String(),
        'occupation': occupation,
      }),
    );

    if (response.statusCode != 201) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['message'] ?? 'Registration failed');
    }
    // optionally parse the returned user if needed
  }
}
