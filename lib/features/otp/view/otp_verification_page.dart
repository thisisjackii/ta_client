// otp_verification_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/app/routes/routes.dart';
import 'package:ta_client/features/otp/bloc/otp_bloc.dart';
import 'package:ta_client/features/otp/bloc/otp_event.dart';
import 'package:ta_client/features/otp/bloc/otp_state.dart';

class OtpVerificationPage extends StatelessWidget {
  const OtpVerificationPage({super.key});

  /// Creates an [OtpVerificationPage] and wraps it in a [BlocProvider]
  /// that provides an [OtpBloc].
  ///
  /// This is a convenience method for creating an [OtpVerificationPage] with
  /// an [OtpBloc] provider. It is intended to be used as a root widget in
  /// a Flutter application.
  static Widget create() {
    return BlocProvider(
      create: (context) => OtpBloc(),
      child: const OtpVerificationPage(),
    );
  }

  /// Builds a [Scaffold] with an [AppBar] with the title 'OTP Verification'
  /// and a [Column] with a [TextField] for entering the OTP and an
  /// [ElevatedButton] for submitting the OTP.
  ///
  /// The [BlocListener] listens for [OtpSuccess] and [OtpFailure] events
  /// and navigates to the [Routes.dashboard] route on success and shows
  /// a [SnackBar] with the error message on failure.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OTP Verification')),
      body: BlocListener<OtpBloc, OtpState>(
        listener: (context, state) {
          if (state is OtpSuccess) {
            Navigator.pushReplacementNamed(context, Routes.dashboard);
          } else if (state is OtpFailure) {
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
                  labelText: 'Enter OTP',
                ),
                onChanged: (value) =>
                    context.read<OtpBloc>().add(OtpCodeChanged(value)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  context.read<OtpBloc>().add(OtpSubmitted());
                },
                child: const Text('Verify'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
