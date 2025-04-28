// lib/features/login/bloc/login_state.dart

import 'package:equatable/equatable.dart';

abstract class LoginState extends Equatable {
  const LoginState();
  @override
  List<Object?> get props => [];
}

class LoginFormState extends LoginState {
  const LoginFormState({
    this.email = '',
    this.password = '',
    this.errorMessage = '',
  });
  final String email;
  final String password;
  final String errorMessage;

  LoginFormState copyWith({
    String? email,
    String? password,
    String? errorMessage,
  }) {
    return LoginFormState(
      email: email ?? this.email,
      password: password ?? this.password,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [email, password, errorMessage];
}

class LoginLoading extends LoginState {
  const LoginLoading();
}

class LoginSuccess extends LoginState {
  const LoginSuccess({required this.user});
  final Map<String, dynamic> user;
  @override
  List<Object?> get props => [user];
}

class LoginFailure extends LoginState {
  const LoginFailure(this.error);
  final String error;
  @override
  List<Object?> get props => [error];
}
