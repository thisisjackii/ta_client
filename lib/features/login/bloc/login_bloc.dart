// login_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/core/services/auth_storage.dart';
import 'package:ta_client/features/login/bloc/login_event.dart';
import 'package:ta_client/features/login/bloc/login_state.dart';
import 'package:ta_client/features/login/services/login_service.dart';
// import 'package:ta_client/features/login/services/auth_service.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({required this.loginService}) : super(LoginInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
  }

  final LoginService loginService;

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());
    try {
      final token = await loginService.login(event.email, event.password);
      if (token != null) {
        // Save token for future API calls.
        await AuthStorage().saveToken(token);
        emit(LoginSuccess());
      } else {
        emit(const LoginFailure('Invalid credentials'));
      }
    } catch (e) {
      emit(LoginFailure(e.toString()));
    }
  }
}
