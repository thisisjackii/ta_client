// lib/features/otp/bloc/otp_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/features/otp/bloc/otp_event.dart';
import 'package:ta_client/features/otp/bloc/otp_state.dart';
import 'package:ta_client/features/otp/services/otp_service.dart'; // Import the service

class OtpBloc extends Bloc<OtpEvent, OtpState> {
  OtpBloc({required this.otpService}) : super(OtpInitial()) {
    // OtpService is injected
    on<OtpRequestSubmitted>(_onOtpRequestSubmitted);
    on<OtpVerificationSubmitted>(_onOtpVerificationSubmitted);
    on<OtpCodeChanged>(_onOtpCodeChanged);
  }

  final OtpService otpService; // Holds the injected service instance
  String _currentOtpCode =
      ''; // Internal state for the OTP code entered by user
  String _emailForVerification =
      ''; // Store email when OTP request is successful

  void _onOtpCodeChanged(OtpCodeChanged event, Emitter<OtpState> emit) {
    _currentOtpCode = event.otp;
  }

  Future<void> _onOtpRequestSubmitted(
    OtpRequestSubmitted event,
    Emitter<OtpState> emit,
  ) async {
    emit(OtpLoading());
    try {
      // Call the service method
      await otpService.requestOtp(event.email, userId: event.userId);
      _emailForVerification = event.email; // Store email for verification step
      emit(OtpSuccess(email: event.email)); // Emit success state with email
    } on OtpException catch (e) {
      emit(OtpFailure(e.message));
    } catch (e) {
      emit(
        OtpFailure(
          'An unexpected error occurred while requesting OTP: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onOtpVerificationSubmitted(
    OtpVerificationSubmitted
    event, // This event might not need 'email' if we store it
    Emitter<OtpState> emit,
  ) async {
    if (_currentOtpCode.isEmpty) {
      emit(const OtpFailure('Please enter the OTP code.'));
      return;
    }
    if (_emailForVerification.isEmpty) {
      emit(
        const OtpFailure(
          'Email for OTP verification not found. Please request OTP again.',
        ),
      );
      return;
    }
    emit(OtpLoading());
    try {
      // Call the service method, using the stored email
      final success = await otpService.verifyOtp(
        _emailForVerification,
        _currentOtpCode,
      );
      if (success) {
        emit(const OtpSuccess());
      } else {
        // This branch is less likely if service throws OtpException on backend success:false
        emit(
          const OtpFailure('OTP verification indicated failure by service.'),
        );
      }
    } on OtpException catch (e) {
      emit(OtpFailure(e.message));
    } catch (e) {
      emit(
        OtpFailure(
          'An unexpected error occurred during OTP verification: ${e.toString()}',
        ),
      );
    }
  }
}
