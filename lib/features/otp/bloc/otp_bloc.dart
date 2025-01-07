import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/features/otp/bloc/otp_event.dart';
import 'package:ta_client/features/otp/bloc/otp_state.dart';

class OtpBloc extends Bloc<OtpEvent, OtpState> {
  OtpBloc() : super(OtpInitial()) {
    on<OtpSubmitted>(_onOtpSubmitted);
  }

  /// Handles the [OtpSubmitted] event by emitting an [OtpLoading] state,
  /// then simulating the OTP verification process. If successful, emits
  /// an [OtpSuccess] state, otherwise emits an [OtpFailure] state with the
  /// error message.
  ///
  /// This function simulates a delay to mimic OTP verification logic.
  Future<void> _onOtpSubmitted(
    OtpSubmitted event,
    Emitter<OtpState> emit,
  ) async {
    emit(OtpLoading());
    try {
      // Simulate OTP verification logic
      await Future.delayed(const Duration(seconds: 2));
      emit(OtpSuccess());
    } catch (e) {
      emit(OtpFailure(e.toString()));
    }
  }
}
