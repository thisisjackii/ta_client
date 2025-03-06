// lib/features/login/view/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ta_client/features/login/bloc/login_bloc.dart';
import 'package:ta_client/features/login/bloc/login_event.dart';
import 'package:ta_client/features/login/bloc/login_state.dart';
import 'package:ta_client/features/login/services/login_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  /// Wraps LoginPage with a BlocProvider supplying a LoginBloc.
  /// [baseUrl] is used to initialize the login service.
  static Widget create({required String baseUrl}) {
    return BlocProvider(
      create: (context) =>
          LoginBloc(loginService: LoginService(baseUrl: baseUrl)),
      child: const LoginPage(),
    );
  }

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
                controller: _emailController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Email or Username',
                ),
                onChanged: (value) =>
                    context.read<LoginBloc>().add(LoginEmailChanged(value)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
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
                  final email = _emailController.text.trim();
                  final password = _passwordController.text.trim();
                  // Dispatch the event with both email and password.
                  context
                      .read<LoginBloc>()
                      .add(LoginSubmitted(email, password));
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
