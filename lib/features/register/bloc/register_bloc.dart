// lib/features/register/bloc/register_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:intl/intl.dart'; // Not needed here if event carries DateTime
import 'package:ta_client/features/otp/bloc/otp_bloc.dart';
import 'package:ta_client/features/otp/bloc/otp_event.dart'
    as OtpEventClass; // Alias
import 'package:ta_client/features/otp/services/otp_service.dart'; // For OtpException
import 'package:ta_client/features/register/bloc/register_event.dart';
import 'package:ta_client/features/register/bloc/register_state.dart';
import 'package:ta_client/features/register/services/register_service.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  RegisterBloc({
    required RegisterService registerService,
    required this.otpBloc,
  }) : _service = registerService,
       super(const RegisterState()) {
    on<RegisterNameChanged>(
      (event, emit) => emit(
        state.copyWith(
          name: event.name,
          status: RegisterStatus.initial,
          clearErrorMessage: true,
        ),
      ),
    );
    on<RegisterUsernameChanged>(
      (event, emit) => emit(
        state.copyWith(
          username: event.username,
          status: RegisterStatus.initial,
          clearErrorMessage: true,
        ),
      ),
    );
    on<RegisterEmailChanged>(
      (event, emit) => emit(
        state.copyWith(
          email: event.email,
          status: RegisterStatus.initial,
          clearErrorMessage: true,
        ),
      ),
    );
    on<RegisterPasswordChanged>(
      (event, emit) => emit(
        state.copyWith(
          password: event.password,
          status: RegisterStatus.initial,
          clearErrorMessage: true,
        ),
      ),
    );
    on<RegisterAddressChanged>(
      (event, emit) => emit(
        state.copyWith(
          address: event.address,
          status: RegisterStatus.initial,
          clearErrorMessage: true,
        ),
      ),
    );
    on<RegisterBirthdateChanged>((event, emit) {
      // Event now carries DateTime?
      emit(
        state.copyWith(
          birthdate: event.birthdate,
          status: RegisterStatus.initial,
          clearErrorMessage: true,
        ),
      );
    });
    on<RegisterOccupationIdChanged>(
      (event, emit) => emit(
        state.copyWith(
          occupationId: event.occupationId,
          occupationName: event.occupationName,
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
  final OtpBloc otpBloc;

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
      otpBloc.add(OtpEventClass.OtpRequestSubmitted(state.email));
      emit(state.copyWith(status: RegisterStatus.awaitingOtpVerification));
    } on OtpException catch (e) {
      emit(
        state.copyWith(
          status: RegisterStatus.failure,
          errorMessage: 'Gagal meminta OTP: ${e.message}',
        ),
      );
    } catch (err) {
      emit(
        state.copyWith(
          status: RegisterStatus.failure,
          errorMessage: 'Terjadi kesalahan saat meminta OTP: $err',
        ),
      );
    }
  }

  Future<void> _onOtpVerifiedAndFinalizeRegistration(
    RegisterOtpVerified event,
    Emitter<RegisterState> emit,
  ) async {
    if (state.status != RegisterStatus.awaitingOtpVerification) {
      emit(
        state.copyWith(
          status: RegisterStatus.failure,
          errorMessage: 'Proses registrasi tidak valid.',
        ),
      );
      return;
    }
    if (!state.canRequestOtp) {
      emit(
        state.copyWith(
          status: RegisterStatus.failure,
          errorMessage: 'Data registrasi tidak lengkap setelah verifikasi OTP.',
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
      await _service.register(
        name: state.name,
        username: state.username,
        email: state.email,
        password: state.password,
        address: state.address,
        birthdate: state.birthdate!, // Not null due to canRequestOtp check
        occupationId: state.occupationId,
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
          errorMessage: 'Registrasi akhir gagal: $err',
        ),
      );
    }
  }
}
