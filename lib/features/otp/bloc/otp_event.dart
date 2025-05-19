import 'package:equatable/equatable.dart';

abstract class OtpEvent extends Equatable {
  const OtpEvent();

  @override
  List<Object> get props => [];
}

class OtpCodeChanged extends OtpEvent {
  const OtpCodeChanged(this.otp);

  final String otp;

  @override
  List<Object> get props => [otp];
}

class OtpRequestSubmitted extends OtpEvent {
  const OtpRequestSubmitted(this.email, {this.userId});

  final String email;
  final String? userId;

  @override
  List<Object> get props => [email, userId ?? ''];
}

class OtpVerificationSubmitted extends OtpEvent {
  const OtpVerificationSubmitted(this.email);

  final String email;

  @override
  List<Object> get props => [email];
}

class OtpVerificationFailure extends OtpEvent {
  const OtpVerificationFailure(this.error);

  final String error;

  @override
  List<Object> get props => [error];
}
