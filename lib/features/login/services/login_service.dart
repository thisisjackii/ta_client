// lib/features/login/services/login_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ta_client/features/login/models/login_response.dart';

class LoginService {
  LoginService({this.baseUrl = 'https://your-api.example.com'});
  final String baseUrl;

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/login');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (resp.statusCode == 200) {
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      return LoginResponse.fromJson(json);
    } else if (resp.statusCode == 401) {
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      throw Exception(json['message'] ?? 'Invalid credentials');
    } else {
      throw Exception('Server error (${resp.statusCode})');
    }
  }
}
