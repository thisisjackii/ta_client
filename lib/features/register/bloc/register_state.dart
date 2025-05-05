// features/register/bloc/register_state.dart

import 'package:equatable/equatable.dart';

enum RegisterStatus { initial, submitting, success, failure }

class RegisterState extends Equatable {
  const RegisterState({
    this.name = '',
    this.username = '',
    this.email = '',
    this.password = '',
    this.address = '',
    this.birthdate,
    this.occupation = '',
    this.status = RegisterStatus.initial,
    this.errorMessage,
  });
  final String name;
  final String username;
  final String email;
  final String password;
  final String address;
  final DateTime? birthdate;
  final String occupation;
  final RegisterStatus status;
  final String? errorMessage;

  RegisterState copyWith({
    String? name,
    String? username,
    String? email,
    String? password,
    String? address,
    DateTime? birthdate,
    String? occupation,
    RegisterStatus? status,
    String? errorMessage,
  }) {
    return RegisterState(
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      address: address ?? this.address,
      birthdate: birthdate ?? this.birthdate,
      occupation: occupation ?? this.occupation,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    name,
    username,
    email,
    password,
    address,
    birthdate,
    occupation,
    status,
    errorMessage,
  ];
}
