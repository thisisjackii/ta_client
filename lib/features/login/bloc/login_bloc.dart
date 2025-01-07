import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/features/login/bloc/login_event.dart';
import 'package:ta_client/features/login/bloc/login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(LoginInitial());

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
