// register_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/features/register/bloc/register_event.dart';
import 'package:ta_client/features/register/bloc/register_state.dart';
import 'package:ta_client/features/register/services/register_service.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  RegisterBloc({required this.registerService}) : super(RegisterInitial()) {
    on<RegisterSubmitted>(_onRegisterSubmitted);
  }
  final RegisterService registerService;

  Future<void> _onRegisterSubmitted(
    RegisterSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    emit(RegisterLoading());
    try {
      final isRegistered = await registerService.register(event.model);

      if (isRegistered) {
        emit(RegisterSuccess());
      } else {
        emit(const RegisterFailure('Registration failed'));
      }
    } catch (e) {
      emit(RegisterFailure(e.toString()));
    }
  }
}
