// lib/features/register/bloc/register_event.dart
import 'package:equatable/equatable.dart';

abstract class RegisterEvent extends Equatable {
  const RegisterEvent();
  @override
  List<Object?> get props => [];
}

class RegisterNameChanged extends RegisterEvent {
  const RegisterNameChanged(this.name);
  final String name;
  @override
  List<Object?> get props => [name];
}

class RegisterUsernameChanged extends RegisterEvent {
  const RegisterUsernameChanged(this.username);
  final String username;
  @override
  List<Object?> get props => [username];
}

class RegisterEmailChanged extends RegisterEvent {
  const RegisterEmailChanged(this.email);
  final String email;
  @override
  List<Object?> get props => [email];
}

class RegisterPasswordChanged extends RegisterEvent {
  const RegisterPasswordChanged(this.password);
  final String password;
  @override
  List<Object?> get props => [password];
}

class RegisterAddressChanged extends RegisterEvent {
  const RegisterAddressChanged(this.address);
  final String address;
  @override
  List<Object?> get props => [address];
}

class RegisterBirthdateChanged extends RegisterEvent {
  const RegisterBirthdateChanged(this.birthdate);
  final DateTime? birthdate; // MODIFIED: Now expects DateTime?
  @override
  List<Object?> get props => [birthdate];
}

// This event seems unused if RegisterOccupationIdChanged is the primary way
// class RegisterOccupationChanged extends RegisterEvent {
//   const RegisterOccupationChanged(this.occupation);
//   final String occupation;
//   @override
//   List<Object?> get props => [occupation];
// }

class RegisterOccupationIdChanged extends RegisterEvent {
  const RegisterOccupationIdChanged(this.occupationId, this.occupationName);
  final String occupationId;
  final String occupationName;
  @override
  List<Object?> get props => [occupationId, occupationName];
}

class RegisterFormSubmitted extends RegisterEvent {
  const RegisterFormSubmitted();
}

class RegisterFailure extends RegisterEvent {
  const RegisterFailure(this.errorMessage);
  final String errorMessage;
  @override
  List<Object?> get props => [errorMessage];
}

class RegisterClearError extends RegisterEvent {
  const RegisterClearError();
}
