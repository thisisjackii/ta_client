// lib/features/otp/view/otp_verification_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/app/routes/routes.dart'; // For navigation to next step (e.g., reset password screen)
import 'package:ta_client/core/constants/app_colors.dart';
import 'package:ta_client/features/otp/bloc/otp_bloc.dart';
import 'package:ta_client/features/otp/bloc/otp_event.dart';
import 'package:ta_client/features/otp/bloc/otp_state.dart';

class OtpVerificationPage extends StatefulWidget {
  // Changed to StatefulWidget
  const OtpVerificationPage({required this.email, super.key});

  final String email; // Email passed via navigation arguments

  static Widget create(BuildContext context) {
    // create method to retrieve arguments
    final email = ModalRoute.of(context)?.settings.arguments as String?;
    if (email == null) {
      // Handle error: email argument is required.
      // For simplicity, returning a placeholder. In a real app, navigate back or show error.
      return const Scaffold(
        body: Center(child: Text('Error: Email for OTP not provided.')),
      );
    }
    // OtpBloc is already provided by MultiBlocProvider in app.dart
    // No need to BlocProvider here if it's global.
    // If OtpBloc is specific to this flow and not global, then provide it here.
    return OtpVerificationPage(email: email);
  }

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi OTP'),
        backgroundColor: AppColors.greyBackground,
      ),
      body: BlocListener<OtpBloc, OtpState>(
        listener: (context, state) {
          if (state is OtpSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('OTP berhasil diverifikasi!')),
            );
            // Navigate to the next step, e.g., reset password screen, or dashboard
            // For a password reset flow:
            // Navigator.pushReplacementNamed(
            //   context,
            //   Routes.resetPasswordPage,
            //   arguments: widget.email,
            // );
            // For registration flow, maybe navigate to login or dashboard:
            Navigator.pushNamedAndRemoveUntil(
              context,
              Routes.dashboard,
              (route) => false,
            );
          } else if (state is OtpFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Verifikasi OTP Gagal: ${state.errorMessage}'),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Masukkan kode OTP yang dikirim ke ${widget.email}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _otpController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter OTP',
                ),
                keyboardType: TextInputType.number,
                maxLength: 6, // Assuming 6-digit OTP
                textAlign: TextAlign.center,
                onChanged: (value) {
                  // Dispatch OtpCodeChanged event so BLoC knows the current OTP input
                  context.read<OtpBloc>().add(OtpCodeChanged(value));
                },
              ),
              const SizedBox(height: 24),
              BlocBuilder<OtpBloc, OtpState>(
                builder: (context, state) {
                  if (state is OtpLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return ElevatedButton(
                    onPressed: () {
                      // Dispatch event to OtpBloc for verification
                      // The BLoC already has the email from OtpRequestSuccess state or passed to it
                      context.read<OtpBloc>().add(
                        OtpVerificationSubmitted(widget.email),
                      );
                    },
                    child: const Text('Verifikasi'),
                  );
                },
              ),
              TextButton(
                onPressed: () {
                  // Resend OTP logic
                  context.read<OtpBloc>().add(
                    OtpRequestSubmitted(widget.email),
                  );
                },
                child: const Text('Kirim ulang OTP'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
