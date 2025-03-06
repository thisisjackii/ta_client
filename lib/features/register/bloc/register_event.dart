// register_event.dart
import 'package:equatable/equatable.dart';
import 'package:ta_client/features/register/models/register_model.dart';

abstract class RegisterEvent extends Equatable {
  const RegisterEvent();

  @override
  List<Object> get props => [];
}

class RegisterNameChanged extends RegisterEvent {
  const RegisterNameChanged(this.name);
  final String name;

  @override
  List<Object> get props => [name];
}

class RegisterEmailChanged extends RegisterEvent {
  const RegisterEmailChanged(this.email);
  final String email;

  @override
  List<Object> get props => [email];
}

class RegisterPasswordChanged extends RegisterEvent {
  const RegisterPasswordChanged(this.password);
  final String password;

  @override
  List<Object> get props => [password];
}

class RegisterSubmitted extends RegisterEvent {
  const RegisterSubmitted(this.model);
  final RegisterModel model;

  @override
  List<Object> get props => [model];
}
