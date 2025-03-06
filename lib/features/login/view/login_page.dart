// login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/app/routes/routes.dart';
import 'package:ta_client/features/login/bloc/login_bloc.dart';
import 'package:ta_client/features/login/bloc/login_event.dart';
import 'package:ta_client/features/login/bloc/login_state.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  /// Creates a [LoginPage] and wraps it in a [BlocProvider] that provides
  /// a [LoginBloc].
  ///
  /// This is a convenience method for creating a [LoginPage] with a
  /// [LoginBloc] provider. It is intended to be used as a root widget in
  /// a Flutter application.
  static Widget create() {
    return BlocProvider(
      create: (context) => LoginBloc(),
      child: const LoginPage(),
    );
  }

  /// Builds a [Scaffold] with an [AppBar] with the title "Login", and a
  /// [Column] in the body. The [Column] contains two [TextField]s for the
  /// email or username and password, and an [ElevatedButton] for submitting
  /// the login. The [BlocListener] listens to the [LoginBloc] and if the
  /// state is [LoginSuccess], it navigates to the [Routes.dashboard] page.
  /// If the state is [LoginFailure], it shows a [SnackBar] with the error
  /// message.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: BlocListener<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state is LoginSuccess) {
            // Navigate to dashboard using go_router (ensure route name 'dashboard' is configured).
            context.goNamed('dashboard');
          } else if (state is LoginFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage)),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Email or Username',
                ),
                onChanged: (value) =>
                    context.read<LoginBloc>().add(LoginEmailChanged(value)),
              ),
              const SizedBox(height: 16),
              TextField(
                obscureText: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Password',
                ),
                onChanged: (value) =>
                    context.read<LoginBloc>().add(LoginPasswordChanged(value)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  context.read<LoginBloc>().add(LoginSubmitted());
                },
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
