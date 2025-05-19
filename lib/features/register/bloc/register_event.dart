// features/register/bloc/register_event.dart

import 'package:equatable/equatable.dart';

abstract class RegisterEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class RegisterNameChanged extends RegisterEvent {
  RegisterNameChanged(this.name);
  final String name;
  @override
  List<Object?> get props => [name];
}

class RegisterUsernameChanged extends RegisterEvent {
  RegisterUsernameChanged(this.username);
  final String username;
  @override
  List<Object?> get props => [username];
}

class RegisterEmailChanged extends RegisterEvent {
  RegisterEmailChanged(this.email);
  final String email;
  @override
  List<Object?> get props => [email];
}

class RegisterPasswordChanged extends RegisterEvent {
  RegisterPasswordChanged(this.password);
  final String password;
  @override
  List<Object?> get props => [password];
}

class RegisterAddressChanged extends RegisterEvent {
  RegisterAddressChanged(this.address);
  final String address;
  @override
  List<Object?> get props => [address];
}

class RegisterBirthdateChanged extends RegisterEvent {
  RegisterBirthdateChanged(this.birthdate);
  final String birthdate;
  @override
  List<Object?> get props => [birthdate];
}

class RegisterOccupationChanged extends RegisterEvent {
  RegisterOccupationChanged(this.occupation);
  final String occupation;
  @override
  List<Object?> get props => [occupation];
}

class RegisterSubmitted extends RegisterEvent {}

class RegisterOccupationIdChanged extends RegisterEvent {
  // Keep name for state display
  RegisterOccupationIdChanged(this.occupationId, this.occupationName);
  // Changed to handle ID
  final String occupationId;
  final String occupationName;
  @override
  List<Object?> get props => [occupationId, occupationName];
}

// Submission and OTP flow
class RegisterFormSubmitted extends RegisterEvent {
  // Renamed from RegisterSubmitted
  RegisterFormSubmitted();
}

class RegisterOtpVerified extends RegisterEvent {
  // Dispatched after OTPBloc signals success
  RegisterOtpVerified();
}

class RegisterFailure extends RegisterEvent {
  RegisterFailure(this.errorMessage);
  final String errorMessage;
  @override
  List<Object?> get props => [errorMessage];
}

class RegisterClearError extends RegisterEvent {}
