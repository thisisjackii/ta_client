import 'package:http/http.dart' as http;

class RegisterService {
  static Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('https://api.example.com/register'),
      body: {'name': name, 'email': email, 'password': password},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to register. Please try again.');
    }
  }
}
