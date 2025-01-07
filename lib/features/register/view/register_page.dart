// register_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/app/routes/routes.dart';
import 'package:ta_client/core/widgets/custom_button.dart';
import 'package:ta_client/core/widgets/custom_text_field.dart';
import 'package:ta_client/features/register/bloc/register_bloc.dart';
import 'package:ta_client/features/register/bloc/register_event.dart';
import 'package:ta_client/features/register/bloc/register_state.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  static Widget create() {
    return BlocProvider(
      create: (context) => RegisterBloc(),
      child: const RegisterPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: BlocListener<RegisterBloc, RegisterState>(
        listener: (context, state) {
          if (state is RegisterSuccess) {
            Navigator.pushReplacementNamed(context, Routes.dashboard);
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
              CustomTextField(
                label: 'Full Name',
                onChanged: (value) => context
                    .read<RegisterBloc>()
                    .add(RegisterNameChanged(value)),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) => context
                    .read<RegisterBloc>()
                    .add(RegisterEmailChanged(value)),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Password',
                isObscured: true,
                onChanged: (value) => context
                    .read<RegisterBloc>()
                    .add(RegisterPasswordChanged(value)),
              ),
              const SizedBox(height: 16),
              CustomButton(
                label: 'Register',
                onPressed: () {
                  context.read<RegisterBloc>().add(RegisterSubmitted());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
