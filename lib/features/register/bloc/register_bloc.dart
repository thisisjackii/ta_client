import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/features/register/bloc/register_event.dart';
import 'package:ta_client/features/register/bloc/register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  RegisterBloc() : super(RegisterInitial()) {
    on<RegisterSubmitted>(_onRegisterSubmitted);
  }

  /// Handles [RegisterSubmitted] event by emitting an [RegisterLoading] state,
  /// then simulating the registration process. If successful, emits
  /// an [RegisterSuccess] state, otherwise emits an [RegisterFailure] state with
  /// the error message.
  //
  /// This function simulates a delay to mimic registration logic.
  Future<void> _onRegisterSubmitted(
    RegisterSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    emit(RegisterLoading());
    try {
      // Simulate registration logic
      await Future.delayed(const Duration(seconds: 2));
      emit(RegisterSuccess());
    } catch (e) {
      emit(RegisterFailure(e.toString()));
    }
  }
}
