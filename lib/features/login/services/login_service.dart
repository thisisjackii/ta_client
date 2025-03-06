// lib/features/login/services/login_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class LoginService {
  LoginService({required this.baseUrl});
  final String baseUrl;

  Future<String?> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/api/login/login');
    final response = await http.post(
      url,
      body: jsonEncode({'email': email, 'password': password}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      // Assuming the API returns a token or success flag
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      // return data['success'] as bool;
      return data['token'] as String?;
    } else {
      throw Exception('Failed to log in');
    }
  }
}
