// lib/features/otp/view/otp_verification_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/app/routes/routes.dart'; // For navigation to next step (e.g., reset password screen)
import 'package:ta_client/core/constants/app_colors.dart';
import 'package:ta_client/features/otp/bloc/otp_bloc.dart';
import 'package:ta_client/features/otp/bloc/otp_event.dart';
import 'package:ta_client/features/otp/bloc/otp_state.dart';

// Add this enum (e.g., in a shared types file or here)
enum OtpFlow { registration, passwordReset, general }

class OtpVerificationPageArguments {
  // Add any other data needed for different flows

  OtpVerificationPageArguments({required this.email, required this.flow});
  final String email;
  final OtpFlow flow;
}

class OtpVerificationPage extends StatefulWidget {
  const OtpVerificationPage({
    required this.args,
    super.key,
  }); // Modified constructor

  final OtpVerificationPageArguments args; // Use arguments object

  static Widget create(BuildContext context) {
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (routeArgs is OtpVerificationPageArguments) {
      // Check type
      return OtpVerificationPage(args: routeArgs);
    } else if (routeArgs is Map<String, dynamic>) {
      // Fallback for older Map way
      final email = routeArgs['email'] as String?;
      final flow =
          routeArgs['flow'] as OtpFlow? ??
          OtpFlow.general; // Default if not passed
      if (email == null) {
        return const Scaffold(
          body: Center(child: Text('Error: Email for OTP not provided.')),
        );
      }
      return OtpVerificationPage(
        args: OtpVerificationPageArguments(email: email, flow: flow),
      );
    }
    // Handle error: arguments are required and of the correct type.
    return const Scaffold(
      body: Center(child: Text('Error: Invalid arguments for OTP page.')),
    );
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
            if (widget.args.flow == OtpFlow.registration) {
              Navigator.pop(context, true); // Pop true for registration flow
              // } else if (widget.args.flow == OtpFlow.passwordReset) {
              //   Navigator.pushReplacementNamed(
              //     context,
              //     Routes.actualNewPasswordPage,
              //     arguments: widget.args.email,
              //   );
            } else {
              Navigator.pushNamedAndRemoveUntil(
                context,
                Routes.dashboard,
                (route) => false,
              );
            }
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
                'Masukkan kode OTP yang dikirim ke ${widget.args.email}',
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
                        OtpVerificationSubmitted(widget.args.email),
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
                    OtpRequestSubmitted(
                      widget.args.email,
                      // userId: null /* or pass if available for this flow */,
                    ),
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
