// lib/features/register/bloc/register_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/features/register/bloc/register_event.dart';
import 'package:ta_client/features/register/bloc/register_state.dart';
import 'package:ta_client/features/register/services/register_service.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  RegisterBloc({required RegisterService registerService})
    : _service = registerService,
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
    on<RegisterClearError>(
      (_, emit) => emit(
        state.copyWith(clearErrorMessage: true, status: RegisterStatus.initial),
      ),
    );
  }

  final RegisterService _service;

  Future<void> _onFormSubmitted(
    RegisterFormSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    if (!state.isReadyToRegister) {
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
      await _service.register(
        name: state.name,
        username: state.username,
        email: state.email,
        password: state.password,
        address: state.address,
        birthdate: state.birthdate!, // Not null due to isReadyToRegister check
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
          errorMessage: 'Terjadi kesalahan saat registrasi: $err',
        ),
      );
    }
  }
}
