// lib/features/login/bloc/login_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:ta_client/features/login/bloc/login_event.dart';
import 'package:ta_client/features/login/bloc/login_state.dart';
import 'package:ta_client/features/login/services/login_service.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({required LoginService loginService})
    : _loginService = loginService,
      super(const LoginFormState()) {
    on<LoginEmailChanged>(_onEmailChanged);
    on<LoginPasswordChanged>(_onPasswordChanged);
    on<LoginSubmitted>(_onSubmitted);
  }
  final LoginService _loginService;

  void _onEmailChanged(LoginEmailChanged event, Emitter<LoginState> emit) {
    final current = state as LoginFormState;
    emit(current.copyWith(email: event.email, errorMessage: ''));
  }

  void _onPasswordChanged(
    LoginPasswordChanged event,
    Emitter<LoginState> emit,
  ) {
    final current = state as LoginFormState;
    emit(current.copyWith(password: event.password, errorMessage: ''));
  }

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    final current = state as LoginFormState;
    if (current.email.isEmpty || current.password.isEmpty) {
      emit(current.copyWith(errorMessage: 'Email & password cannot be empty'));
      return;
    }

    emit(const LoginLoading());
    try {
      final resp = await _loginService.login(
        email: current.email,
        password: current.password,
      );

      // **Store token in Hive encrypted box**
      final box = Hive.box<String>('secureBox');
      await box.put('jwt_token', resp.token);

      emit(LoginSuccess(user: resp.user));
    } catch (e) {
      emit(LoginFailure(e.toString()));
      emit(current.copyWith(errorMessage: e.toString()));
    }
  }
}
