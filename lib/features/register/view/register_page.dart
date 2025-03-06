// register_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ta_client/features/register/bloc/register_bloc.dart';
import 'package:ta_client/features/register/bloc/register_event.dart';
import 'package:ta_client/features/register/bloc/register_state.dart';
import 'package:ta_client/features/register/models/register_model.dart';
import 'package:ta_client/features/register/services/register_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  static Widget create({required String baseUrl}) {
    return BlocProvider(
      create: (context) =>
          RegisterBloc(registerService: RegisterService(baseUrl: baseUrl)),
      child: const RegisterPage(),
    );
  }

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  late RegisterService _registerService;

  @override
  void initState() {
    super.initState();
    _registerService = context.read<RegisterBloc>().registerService;
    _loadCachedData();
  }

  Future<void> _loadCachedData() async {
    _nameController.text = (await _registerService.getCachedName()) ?? '';
    _emailController.text = (await _registerService.getCachedEmail()) ?? '';
    _passwordController.text =
        (await _registerService.getCachedPassword()) ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: BlocListener<RegisterBloc, RegisterState>(
        listener: (context, state) {
          if (state is RegisterSuccess) {
            // Navigator.pushReplacementNamed(context, Routes.dashboard);
            context.goNamed('/dashboard');
          } else if (state is RegisterFailure) {
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
                controller: _nameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Full Name',
                ),
                onChanged: (value) {
                  context.read<RegisterBloc>().add(RegisterNameChanged(value));
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Email',
                ),
                onChanged: (value) {
                  context.read<RegisterBloc>().add(RegisterEmailChanged(value));
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Password',
                ),
                onChanged: (value) {
                  context
                      .read<RegisterBloc>()
                      .add(RegisterPasswordChanged(value));
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final model = RegisterModel(
                    name: _nameController.text.trim(),
                    username: _usernameController.text.trim(),
                    email: _emailController.text.trim(),
                    phone: _phoneController.text.trim(),
                    password: _passwordController.text.trim(),
                  );
                  context.read<RegisterBloc>().add(RegisterSubmitted(model));
                },
                child: const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
