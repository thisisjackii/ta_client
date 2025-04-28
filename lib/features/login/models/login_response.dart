// lib/features/login/models/login_response.dart

class LoginResponse {
  LoginResponse({
    required this.success,
    required this.token,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] as bool,
      token: json['token'] as String,
      user: json['user'] as Map<String, dynamic>,
    );
  }
  final bool success;
  final String token;
  final Map<String, dynamic> user;
}
