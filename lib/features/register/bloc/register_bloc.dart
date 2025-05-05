// features/register/bloc/register_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/features/register/bloc/register_event.dart';
import 'package:ta_client/features/register/bloc/register_state.dart';
import 'package:ta_client/features/register/services/register_service.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  RegisterBloc({required RegisterService registerService})
    : _service = registerService,
      super(const RegisterState()) {
    on<RegisterNameChanged>((e, emit) => emit(state.copyWith(name: e.name)));
    on<RegisterUsernameChanged>(
      (e, emit) => emit(state.copyWith(username: e.username)),
    );
    on<RegisterEmailChanged>((e, emit) => emit(state.copyWith(email: e.email)));
    on<RegisterPasswordChanged>(
      (e, emit) => emit(state.copyWith(password: e.password)),
    );
    on<RegisterAddressChanged>(
      (e, emit) => emit(state.copyWith(address: e.address)),
    );
    on<RegisterBirthdateChanged>(
      (e, emit) =>
          emit(state.copyWith(birthdate: DateTime.tryParse(e.birthdate))),
    );
    on<RegisterOccupationChanged>(
      (e, emit) => emit(state.copyWith(occupation: e.occupation)),
    );

    on<RegisterSubmitted>((_, emit) async {
      emit(state.copyWith(status: RegisterStatus.submitting));
      try {
        await _service.register(
          name: state.name,
          username: state.username,
          email: state.email,
          password: state.password,
          address: state.address,
          birthdate: state.birthdate!,
          occupation: state.occupation,
        );
        emit(state.copyWith(status: RegisterStatus.success));
      } catch (err) {
        emit(
          state.copyWith(
            status: RegisterStatus.failure,
            errorMessage: err.toString(),
          ),
        );
      }
    });
  }
  final RegisterService _service;
}
