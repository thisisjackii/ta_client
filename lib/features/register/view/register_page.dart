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
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xffFBFDFF),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/');
          },
        ),
        title: const Text(
          'Daftar',
          style: TextStyle(
            fontVariations: [
              FontVariation('wght', 800),
            ],
          ),
        ),
        centerTitle: true,
      ),
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
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Username',
                  style: TextStyle(
                    fontVariations: [
                      FontVariation('wght', 600),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                label: 'Full Name',
                icons: Icons.person,
                onChanged: (value) => context
                    .read<RegisterBloc>()
                    .add(RegisterNameChanged(value)),
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Email',
                  style: TextStyle(
                    fontVariations: [
                      FontVariation('wght', 600),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                label: 'Email',
                icons: Icons.email,
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) => context
                    .read<RegisterBloc>()
                    .add(RegisterEmailChanged(value)),
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Password',
                  style: TextStyle(
                    fontVariations: [
                      FontVariation('wght', 600),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                label: 'Password',
                icons: Icons.lock,
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
