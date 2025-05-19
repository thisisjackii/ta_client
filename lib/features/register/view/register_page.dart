// lib/features/register/view/register_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/app/routes/routes.dart';
import 'package:ta_client/core/constants/app_colors.dart';
import 'package:ta_client/core/services/service_locator.dart';
import 'package:ta_client/core/widgets/custom_button.dart';
import 'package:ta_client/core/widgets/custom_date_selector.dart';
import 'package:ta_client/core/widgets/custom_text_field.dart';
import 'package:ta_client/features/otp/bloc/otp_bloc.dart';
import 'package:ta_client/features/otp/bloc/otp_state.dart' as OtpStateClass;
import 'package:ta_client/features/register/bloc/register_bloc.dart';
import 'package:ta_client/features/register/bloc/register_event.dart';
import 'package:ta_client/features/register/bloc/register_state.dart';
import 'package:ta_client/features/register/services/register_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  List<Map<String, String>> _occupations = []; // Now List<Map<String, String>>
  bool _isLoadingOccupations = true;
  String? _selectedOccupationId; // Still stores the ID

  // Controllers for text fields if needed for validation or complex interactions
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();
  String _birthdateString = ''; // Store birthdate as string from picker

  @override
  void initState() {
    super.initState();
    _fetchOccupations();
    // Pre-fill controllers if BLoC has existing state (e.g., after failed validation + OTP attempt)
    final initialState = context.read<RegisterBloc>().state;
    _nameController.text = initialState.name;
    _usernameController.text = initialState.username;
    _emailController.text = initialState.email;
    _passwordController.text = initialState.password;
    _addressController.text = initialState.address;
    _birthdateString =
        initialState.birthdate?.toIso8601String().substring(0, 10) ??
        ''; // Example format
    _selectedOccupationId = initialState.occupationId.isNotEmpty
        ? initialState.occupationId
        : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _fetchOccupations() async {
    setState(() => _isLoadingOccupations = true);
    try {
      final registerService = sl<RegisterService>();
      final occsData = await registerService.fetchOccupations();
      setState(() {
        _occupations = occsData; // Directly assign the list of maps
        _isLoadingOccupations = false;
      });
    } catch (e) {
      setState(() => _isLoadingOccupations = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat daftar profesi: $e')),
        );
      }
    }
  }

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
      body: MultiBlocListener(
        listeners: [
          BlocListener<RegisterBloc, RegisterState>(
            listener: (context, state) {
              // Update text controllers if BLoC state changes (e.g. after an error and state reset)
              // This ensures UI fields reflect BLoC state if it's the source of truth after certain events.
              if (_nameController.text != state.name) {
                _nameController.text = state.name;
              }
              if (_usernameController.text != state.username) {
                _usernameController.text = state.username;
              }
              if (_emailController.text != state.email) {
                _emailController.text = state.email;
              }
              if (_passwordController.text != state.password) {
                _passwordController.text = state.password;
              }
              if (_addressController.text != state.address) {
                _addressController.text = state.address;
              }
              // _birthdateString updated via CustomDateSelector's callback
              if (_selectedOccupationId != state.occupationId) {
                setState(() {
                  // Update local _selectedOccupationId for dropdown
                  _selectedOccupationId = state.occupationId.isNotEmpty
                      ? state.occupationId
                      : null;
                });
              }

              if (state.status == RegisterStatus.success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Registrasi berhasil! Mengalihkan ke halaman login…',
                    ),
                  ),
                );
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  Routes.login,
                  (route) => false,
                );
              } else if (state.status == RegisterStatus.failure &&
                  state.errorMessage != null) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
                context.read<RegisterBloc>().add(RegisterClearError());
              }
            },
          ),
          BlocListener<OtpBloc, OtpStateClass.OtpState>(
            listener: (context, otpState) {
              final registerBloc = context.read<RegisterBloc>();
              if (registerBloc.state.status ==
                      RegisterStatus.awaitingOtpVerification &&
                  otpState is OtpStateClass.OtpSuccess) {
                Navigator.pushNamed(
                  context,
                  Routes.otpVerification,
                  arguments: otpState.email,
                ).then((otpVerifiedSuccessfully) {
                  if (otpVerifiedSuccessfully == true) {
                    registerBloc.add(RegisterOtpVerified());
                  } else {
                    registerBloc.add(RegisterClearError());
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Verifikasi OTP dibatalkan atau gagal.'),
                      ),
                    );
                  }
                });
              } else if (registerBloc.state.status ==
                      RegisterStatus.submitting &&
                  otpState is OtpStateClass.OtpFailure) {
                // If OTP request fails while register form was submitting to request OTP
                registerBloc.add(
                  RegisterFailure(
                    'Gagal meminta OTP: ${otpState.errorMessage}',
                  ),
                );
              }
            },
          ),
        ],
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            // Add a Form widget for validation
            // key: _formKey, // If you need to use _formKey.currentState.validate()
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
                  controller: _nameController, // Use controller
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
                  controller: _usernameController,
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
                  controller: _emailController,
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
                  controller: _passwordController,
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
                  controller: _addressController,
                  label: 'Alamat',
                  icons: Icons.location_on,
                  onChanged: (v) => context.read<RegisterBloc>().add(
                    RegisterAddressChanged(v),
                  ),
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
                  onDateSelected: (dateString) {
                    // Expecting string from CustomDateSelector
                    _birthdateString = dateString; // Update local string state
                    context.read<RegisterBloc>().add(
                      RegisterBirthdateChanged(dateString),
                    );
                  },
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
                if (_isLoadingOccupations)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    // Value is occupationId (String)
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.work),
                      hintText: 'Pilih Profesi',
                    ),
                    value: _selectedOccupationId, // Current selected ID
                    items: _occupations.map((Map<String, String> occMap) {
                      return DropdownMenuItem<String>(
                        value: occMap['id'], // The value is the ID
                        child: Text(occMap['name']!),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        final selectedOccMap = _occupations.firstWhere(
                          (occ) => occ['id'] == newValue,
                        );
                        setState(() {
                          _selectedOccupationId = newValue;
                        });
                        context.read<RegisterBloc>().add(
                          RegisterOccupationIdChanged(
                            newValue,
                            selectedOccMap['name']!,
                          ),
                        );
                      }
                    },
                    validator: (value) => value == null || value.isEmpty
                        ? 'Profesi harus dipilih'
                        : null,
                  ),
                const SizedBox(height: 16),
                BlocBuilder<RegisterBloc, RegisterState>(
                  builder: (context, state) {
                    final isLoadingActual =
                        state.status == RegisterStatus.submitting ||
                        state.status ==
                            RegisterStatus.awaitingOtpVerification ||
                        state.status == RegisterStatus.finalizing;
                    return CustomButton(
                      label: isLoadingActual ? 'Memproses…' : 'Daftar',
                      onPressed: isLoadingActual
                          ? null
                          : () {
                              // Update BLoC state with current text field values before submitting
                              // This is important if onChanged doesn't cover all edge cases or if user types and immediately submits
                              context.read<RegisterBloc>().add(
                                RegisterNameChanged(_nameController.text),
                              );
                              context.read<RegisterBloc>().add(
                                RegisterUsernameChanged(
                                  _usernameController.text,
                                ),
                              );
                              context.read<RegisterBloc>().add(
                                RegisterEmailChanged(_emailController.text),
                              );
                              context.read<RegisterBloc>().add(
                                RegisterPasswordChanged(
                                  _passwordController.text,
                                ),
                              );
                              context.read<RegisterBloc>().add(
                                RegisterAddressChanged(_addressController.text),
                              );
                              // Birthdate and Occupation are already in BLoC state via their specific onChanged/onDateSelected

                              // Now dispatch submit
                              context.read<RegisterBloc>().add(
                                RegisterFormSubmitted(),
                              );
                            },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
