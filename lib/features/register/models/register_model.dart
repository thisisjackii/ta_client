import 'package:equatable/equatable.dart';

class RegisterModel extends Equatable {
  const RegisterModel({
    required this.name,
    required this.username,
    required this.password,
    this.email,
    this.phone,
  }) : assert(
          email != null || phone != null,
          'Either email or phone must be provided.',
        );

  factory RegisterModel.fromJson(Map<String, dynamic> json) {
    return RegisterModel(
      name: json['name'] as String,
      username: json['username'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      password: json['password'] as String,
    );
  }

  final String name;
  final String username;
  final String? email;
  final String? phone;
  final String password;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'username': username,
      'email': email,
      'phone': phone,
      'password': password,
    };
  }

  @override
  List<Object?> get props => [name, username, email, phone, password];
}
