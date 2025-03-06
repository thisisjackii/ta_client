// constants.dart
class ApiConstants {
  static const String baseUrl = 'https://api.example.com';
  static const String registerEndpoint = '/api/user/register';

  // Default headers used for most requests
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'MyFlutterApp/1.0.0',
    'Cache-Control': 'no-cache',
  };
}

class SecureStorageKeys {
  static const String registerName = 'register_name';
  static const String registerUsername = 'register_username';
  static const String registerEmail = 'register_email';
  static const String registerPhone = 'register_phone';
  static const String registerPassword = 'register_password';
}
