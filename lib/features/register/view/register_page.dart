// features/register/ui/register_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/app/routes/routes.dart';
import 'package:ta_client/core/constants/app_colors.dart';
import 'package:ta_client/core/widgets/custom_button.dart';
import 'package:ta_client/core/widgets/custom_date_selector.dart';
import 'package:ta_client/core/widgets/custom_text_field.dart';
import 'package:ta_client/features/register/bloc/register_bloc.dart';
import 'package:ta_client/features/register/bloc/register_event.dart';
import 'package:ta_client/features/register/bloc/register_state.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.greyBackground,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Daftar',
          style: TextStyle(fontVariations: [FontVariation('wght', 800)]),
        ),
        centerTitle: true,
      ),
      body: BlocListener<RegisterBloc, RegisterState>(
        listener: (context, state) {
          if (state.status == RegisterStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Registrasi berhasil! Mengalihkan ke halaman login…',
                ),
              ),
            );
            Navigator.pushReplacementNamed(context, Routes.login);
          } else if (state.status == RegisterStatus.failure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Nama Lengkap',
                style: TextStyle(
                  fontSize: 12,
                  fontVariations: [FontVariation('wght', 600)],
                ),
              ),
              const SizedBox(height: 2),
              CustomTextField(
                label: 'Nama Lengkap',
                icons: Icons.person,
                onChanged: (v) =>
                    context.read<RegisterBloc>().add(RegisterNameChanged(v)),
              ),
              const SizedBox(height: 4),
              const Text(
                'Username',
                style: TextStyle(
                  fontSize: 12,
                  fontVariations: [FontVariation('wght', 600)],
                ),
              ),
              const SizedBox(height: 2),
              CustomTextField(
                label: 'Username',
                icons: Icons.person,
                onChanged: (v) => context.read<RegisterBloc>().add(
                  RegisterUsernameChanged(v),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Email',
                style: TextStyle(
                  fontSize: 12,
                  fontVariations: [FontVariation('wght', 600)],
                ),
              ),
              const SizedBox(height: 2),
              CustomTextField(
                label: 'Email',
                icons: Icons.email,
                keyboardType: TextInputType.emailAddress,
                onChanged: (v) =>
                    context.read<RegisterBloc>().add(RegisterEmailChanged(v)),
              ),
              const SizedBox(height: 4),
              const Text(
                'Password',
                style: TextStyle(
                  fontSize: 12,
                  fontVariations: [FontVariation('wght', 600)],
                ),
              ),
              const SizedBox(height: 2),
              CustomTextField(
                label: 'Password',
                icons: Icons.lock,
                isObscured: true,
                onChanged: (v) => context.read<RegisterBloc>().add(
                  RegisterPasswordChanged(v),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Alamat Domisili',
                style: TextStyle(
                  fontSize: 12,
                  fontVariations: [FontVariation('wght', 600)],
                ),
              ),
              const SizedBox(height: 2),
              CustomTextField(
                label: 'Alamat',
                icons: Icons.location_on,
                onChanged: (v) =>
                    context.read<RegisterBloc>().add(RegisterAddressChanged(v)),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tanggal Lahir',
                style: TextStyle(
                  fontSize: 12,
                  fontVariations: [FontVariation('wght', 600)],
                ),
              ),
              const SizedBox(height: 2),
              CustomDateSelector(
                label: 'Tanggal Lahir',
                icons: Icons.date_range_rounded,
                onDateSelected: (date) => context.read<RegisterBloc>().add(
                  RegisterBirthdateChanged(date),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Profesi',
                style: TextStyle(
                  fontSize: 12,
                  fontVariations: [FontVariation('wght', 600)],
                ),
              ),
              const SizedBox(height: 2),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Pelajar/Mahasiswa',
                    child: Text('Pelajar/Mahasiswa'),
                  ),
                  DropdownMenuItem(value: 'Karyawan', child: Text('Karyawan')),
                ],
                onChanged: (v) => context.read<RegisterBloc>().add(
                  RegisterOccupationChanged(v!),
                ),
              ),
              const SizedBox(height: 16),
              BlocBuilder<RegisterBloc, RegisterState>(
                builder: (context, state) {
                  return CustomButton(
                    label: state.status == RegisterStatus.submitting
                        ? 'Loading…'
                        : 'Register',
                    onPressed: state.status == RegisterStatus.submitting
                        ? null
                        : () => context.read<RegisterBloc>().add(
                            RegisterSubmitted(),
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
