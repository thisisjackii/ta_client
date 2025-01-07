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

class OtpSubmitted extends OtpEvent {}
