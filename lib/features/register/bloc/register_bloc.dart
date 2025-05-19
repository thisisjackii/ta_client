// lib/features/register/bloc/register_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/features/otp/bloc/otp_bloc.dart'; // To dispatch OTP request
import 'package:ta_client/features/otp/bloc/otp_event.dart'
    as OtpEventClass; // Alias
import 'package:ta_client/features/otp/services/otp_service.dart';
import 'package:ta_client/features/register/bloc/register_event.dart';
import 'package:ta_client/features/register/bloc/register_state.dart';
import 'package:ta_client/features/register/services/register_service.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  RegisterBloc({
    required RegisterService registerService,
    required this.otpBloc, // Inject OtpBloc
  }) : _service = registerService,
       super(const RegisterState()) {
    on<RegisterNameChanged>(
      (e, emit) => emit(
        state.copyWith(
          name: e.name,
          status: RegisterStatus.initial,
          clearErrorMessage: true,
        ),
      ),
    );
    on<RegisterUsernameChanged>(
      (e, emit) => emit(
        state.copyWith(
          username: e.username,
          status: RegisterStatus.initial,
          clearErrorMessage: true,
        ),
      ),
    );
    on<RegisterEmailChanged>(
      (e, emit) => emit(
        state.copyWith(
          email: e.email,
          status: RegisterStatus.initial,
          clearErrorMessage: true,
        ),
      ),
    );
    on<RegisterPasswordChanged>(
      (e, emit) => emit(
        state.copyWith(
          password: e.password,
          status: RegisterStatus.initial,
          clearErrorMessage: true,
        ),
      ),
    );
    on<RegisterAddressChanged>(
      (e, emit) => emit(
        state.copyWith(
          address: e.address,
          status: RegisterStatus.initial,
          clearErrorMessage: true,
        ),
      ),
    );
    on<RegisterBirthdateChanged>((e, emit) {
      final date = DateTime.tryParse(
        e.birthdate,
      ); // Assuming e.birthdate is ISO string
      emit(
        state.copyWith(
          birthdate: date,
          status: RegisterStatus.initial,
          clearErrorMessage: true,
        ),
      );
    });
    on<RegisterOccupationIdChanged>(
      (e, emit) => emit(
        state.copyWith(
          occupationId: e.occupationId,
          occupationName: e.occupationName,
          status: RegisterStatus.initial,
          clearErrorMessage: true,
        ),
      ),
    );

    on<RegisterFormSubmitted>(_onFormSubmitted);
    on<RegisterOtpVerified>(_onOtpVerifiedAndFinalizeRegistration);
    on<RegisterClearError>(
      (_, emit) => emit(
        state.copyWith(clearErrorMessage: true, status: RegisterStatus.initial),
      ),
    );
  }

  final RegisterService _service;
  final OtpBloc otpBloc; // Injected OtpBloc

  Future<void> _onFormSubmitted(
    RegisterFormSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    if (!state.canRequestOtp) {
      emit(
        state.copyWith(
          status: RegisterStatus.failure,
          errorMessage: 'Semua field wajib diisi dengan benar.',
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        status: RegisterStatus.submitting,
        clearErrorMessage: true,
      ),
    );
    try {
      // Step 1: Request OTP for the email
      // The userId for OTP request is null here as user is not yet created.
      otpBloc.add(OtpEventClass.OtpRequestSubmitted(state.email));
      // RegisterBloc will now wait for OtpBloc to signal success/failure.
      // The navigation to OTP page will be handled by UI listening to OtpBloc.
      // RegisterBloc changes its status to awaitingOtpVerification.
      emit(state.copyWith(status: RegisterStatus.awaitingOtpVerification));
    } on OtpException catch (e) {
      // Catch OtpException from otpBloc if it throws immediately
      emit(
        state.copyWith(
          status: RegisterStatus.failure,
          errorMessage: 'Gagal meminta OTP: ${e.message}',
        ),
      );
    } catch (err) {
      // Catch general errors
      emit(
        state.copyWith(
          status: RegisterStatus.failure,
          errorMessage: 'Terjadi kesalahan: $err',
        ),
      );
    }
  }

  Future<void> _onOtpVerifiedAndFinalizeRegistration(
    RegisterOtpVerified event,
    Emitter<RegisterState> emit,
  ) async {
    // This event is dispatched by the UI (e.g., OtpVerificationPage)
    // after OtpBloc confirms OTP verification was successful.
    if (state.status != RegisterStatus.awaitingOtpVerification) {
      // Avoid re-registering if already successful or in another state
      emit(
        state.copyWith(
          status: RegisterStatus.failure,
          errorMessage: 'Proses registrasi tidak valid.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: RegisterStatus.finalizing,
        clearErrorMessage: true,
      ),
    );
    try {
      // Now call the actual registration service
      await _service.register(
        name: state.name,
        username: state.username,
        email: state.email,
        password: state.password,
        address: state.address,
        birthdate: state.birthdate!, // Already validated in canRequestOtp
        occupationId: state.occupationId, // Send ID
      );
      emit(state.copyWith(status: RegisterStatus.success));
    } on RegisterException catch (e) {
      emit(
        state.copyWith(status: RegisterStatus.failure, errorMessage: e.message),
      );
    } catch (err) {
      emit(
        state.copyWith(
          status: RegisterStatus.failure,
          errorMessage: 'Registrasi gagal: $err',
        ),
      );
    }
  }
}
