import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/features/register/bloc/register_event.dart';
import 'package:ta_client/features/register/bloc/register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  RegisterBloc() : super(RegisterInitial()) {
    on<RegisterSubmitted>(_onRegisterSubmitted);
  }

  Future<void> _onRegisterSubmitted(
    RegisterSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    emit(RegisterLoading());
    try {
      // Simulate registration logic
      await Future<void>.delayed(const Duration(seconds: 2));
      emit(RegisterSuccess());
    } catch (e) {
      emit(RegisterFailure(e.toString()));
    }
  }
}
