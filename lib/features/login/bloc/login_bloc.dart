// lib/features/login/bloc/login_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/core/services/hive_service.dart';
import 'package:ta_client/core/services/service_locator.dart';
import 'package:ta_client/core/state/auth_state.dart';
import 'package:ta_client/features/login/bloc/login_event.dart';
import 'package:ta_client/features/login/bloc/login_state.dart';
import 'package:ta_client/features/login/services/login_service.dart'; // This is your Dio version

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({required LoginService loginService})
    : _loginService = loginService,
      super(const LoginFormState()) {
    on<LoginEmailChanged>(_onEmailChanged);
    on<LoginPasswordChanged>(_onPasswordChanged);
    on<LoginSubmitted>(_onSubmitted);
    on<LoginReset>(_onReset);
  }
  final LoginService _loginService;

  void _onEmailChanged(LoginEmailChanged event, Emitter<LoginState> emit) {
    if (state is LoginFormState) {
      final current = state as LoginFormState;
      emit(current.copyWith(email: event.email));
    }
  }

  void _onPasswordChanged(
    LoginPasswordChanged event,
    Emitter<LoginState> emit,
  ) {
    if (state is LoginFormState) {
      final current = state as LoginFormState;
      emit(current.copyWith(password: event.password));
    }
  }

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    if (state is! LoginFormState) {
      emit(const LoginFailure('Invalid state for login submission.'));
      return;
    }
    final current = state as LoginFormState;

    if (current.email.isEmpty || current.password.isEmpty) {
      emit(current.copyWith(errorMessage: 'Email & password cannot be empty'));
      return;
    }

    emit(const LoginLoading());
    try {
      final loginApiResponse = await _loginService.login(
        email: current.email,
        password: current.password,
      );

      final hiveService = sl<HiveService>();
      await hiveService.setAuthToken(loginApiResponse.token);

      if (sl.isRegistered<AuthState>()) {
        // **USE THE CORRECT METHOD NAME HERE**
        sl<AuthState>().processLoginSuccess(loginApiResponse.token);
      }

      emit(
        LoginSuccess(
          user: loginApiResponse.user,
          token: loginApiResponse.token,
        ),
      );
    } on LoginException catch (e) {
      emit(LoginFailure(e.message));
    } catch (e) {
      emit(LoginFailure('An unexpected error occurred during login: $e'));
    }
  }

  void _onReset(LoginReset event, Emitter<LoginState> emit) {
    emit(const LoginFormState());
  }
}
