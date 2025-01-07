import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/features/login/bloc/login_event.dart';
import 'package:ta_client/features/login/bloc/login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(LoginInitial());

  /// Handles [LoginEvent]s by mapping them to [LoginState]s.
  ///
  /// When a [LoginSubmitted] event is received, this function yields a
  /// [LoginLoading] state, simulates a login process asynchronously, and then
  /// yields either a [LoginSuccess] or [LoginFailure] state. If any error occurs
  /// during the simulation, a [LoginFailure] state is yielded with the error
  /// message.
  @override
  Stream<LoginState> mapEventToState(LoginEvent event) async* {
    if (event is LoginSubmitted) {
      yield LoginLoading();
      try {
        // Simulate login logic
        await Future.delayed(const Duration(seconds: 2));
        yield LoginSuccess();
      } catch (e) {
        yield LoginFailure(e.toString());
      }
    }
  }
}
