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
import 'package:ta_client/features/otp/view/otp_verification_page.dart';
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
  List<Map<String, String>> _occupations = [];
  bool _isLoadingOccupations = true;
  bool _birthdateTouched = false;
  String? _selectedOccupationId;

  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();
  String _birthdateString = '';

  final _formKey = GlobalKey<FormState>(); // For manual validation if needed

  @override
  void initState() {
    super.initState();
    _fetchOccupations();
    _syncControllersWithBloc(context.read<RegisterBloc>().state, isInit: true);
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

  void _syncControllersWithBloc(RegisterState state, {bool isInit = false}) {
    // Only update if text is different or it's init, to avoid cursor jumps
    if (isInit || _nameController.text != state.name) {
      _nameController.text = state.name;
    }
    if (isInit || _usernameController.text != state.username) {
      _usernameController.text = state.username;
    }
    if (isInit || _emailController.text != state.email) {
      _emailController.text = state.email;
    }
    if (isInit || _passwordController.text != state.password) {
      _passwordController.text = state.password;
    }
    if (isInit || _addressController.text != state.address) {
      _addressController.text = state.address;
    }

    final blocBirthdateString =
        state.birthdate?.toIso8601String().substring(0, 10) ?? '';
    if (isInit || _birthdateString != blocBirthdateString) {
      _birthdateString = blocBirthdateString;
    }

    final blocOccupationId = state.occupationId.isNotEmpty
        ? state.occupationId
        : null;
    if (isInit || _selectedOccupationId != blocOccupationId) {
      // No setState here, dropdown rebuilds via BlocBuilder
      _selectedOccupationId = blocOccupationId;
    }
  }

  Future<void> _fetchOccupations() async {
    setState(() => _isLoadingOccupations = true);
    try {
      final registerService = sl<RegisterService>();
      final occsData = await registerService.fetchOccupations();
      if (mounted) {
        setState(() {
          _occupations = occsData;
          _isLoadingOccupations = false;
          // If an occupationId was set in BLoC before occupations loaded, ensure dropdown reflects it
          final currentBlocOccupationId = context
              .read<RegisterBloc>()
              .state
              .occupationId;
          if (currentBlocOccupationId.isNotEmpty &&
              _occupations.any((o) => o['id'] == currentBlocOccupationId)) {
            _selectedOccupationId = currentBlocOccupationId;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingOccupations = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat daftar profesi: $e')),
        );
      }
    }
  }

  void _dispatchAllFieldsToBloc() {
    final bloc = context.read<RegisterBloc>();
    bloc.add(RegisterNameChanged(_nameController.text.trim()));
    bloc.add(RegisterUsernameChanged(_usernameController.text.trim()));
    bloc.add(RegisterEmailChanged(_emailController.text.trim()));
    bloc.add(
      RegisterPasswordChanged(_passwordController.text),
    ); // No trim for password
    bloc.add(RegisterAddressChanged(_addressController.text.trim()));
    bloc.add(RegisterBirthdateChanged(_birthdateString)); // Already string
    // Occupation ID is dispatched by dropdown's onChanged directly
    if (_selectedOccupationId != null && _occupations.isNotEmpty) {
      final selectedOccData = _occupations.firstWhere(
        (occ) => occ['id'] == _selectedOccupationId,
        orElse: () => {'id': '', 'name': ''},
      );
      if (selectedOccData['id']!.isNotEmpty) {
        bloc.add(
          RegisterOccupationIdChanged(
            selectedOccData['id']!,
            selectedOccData['name']!,
          ),
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
          'Daftar Akun Baru',
          style: TextStyle(
            fontVariations: [FontVariation('wght', 800)],
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<RegisterBloc, RegisterState>(
            listenWhen: (prev, curr) =>
                prev.status != curr.status || curr.errorMessage != null,
            listener: (context, state) {
              _syncControllersWithBloc(
                state,
              ); // Keep UI in sync with BLoC potentially

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
                context.read<RegisterBloc>().add(
                  RegisterClearError(),
                ); // Reset error for next attempt
              } else if (state.status ==
                  RegisterStatus.awaitingOtpVerification) {
                // This status means OTP request was successful from RegisterBloc's perspective
                // Now waiting for OtpBloc to handle UI and then signal back via RegisterOtpVerified event
                // The navigation to OTP page will be triggered by OtpBlocListener below
              }
            },
          ),
          BlocListener<OtpBloc, OtpStateClass.OtpState>(
            listener: (context, otpState) {
              final registerBloc = context.read<RegisterBloc>();
              final currentRegisterStatus = registerBloc.state.status;

              if (currentRegisterStatus == RegisterStatus.submitting &&
                  otpState is OtpStateClass.OtpSuccess) {
                // This means OTP was requested by RegisterFormSubmitted and was successful.
                // Navigate to OTP verification page.
                Navigator.pushNamed(
                  context,
                  Routes.otpVerification,
                  arguments: OtpVerificationPageArguments(
                    email: otpState.email,
                    flow: OtpFlow.registration,
                  ), // Pass email and flow type
                ).then((otpVerifiedSuccessfully) {
                  if (otpVerifiedSuccessfully == true) {
                    registerBloc.add(RegisterOtpVerified());
                  } else {
                    // OTP verification failed or was cancelled, reset RegisterBloc state
                    registerBloc.add(RegisterClearError());
                    if (mounted) {
                      // Check if widget is still in the tree
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Verifikasi OTP dibatalkan atau gagal.',
                          ),
                        ),
                      );
                    }
                  }
                });
              } else if (currentRegisterStatus == RegisterStatus.submitting &&
                  otpState is OtpStateClass.OtpFailure) {
                // OTP request itself failed
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
            key: _formKey,
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
                CustomTextField(
                  controller: _nameController,
                  label: 'Masukkan Nama Lengkap',
                  icons: Icons.person,
                  validator: (v) =>
                      (v?.isEmpty ?? true) ? 'Nama tidak boleh kosong' : null,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Username',
                  style: TextStyle(
                    fontSize: 12,
                    fontVariations: [FontVariation('wght', 600)],
                  ),
                ),
                CustomTextField(
                  controller: _usernameController,
                  label: 'Masukkan Username',
                  icons: Icons.account_circle,
                  validator: (v) => (v?.isEmpty ?? true)
                      ? 'Username tidak boleh kosong'
                      : null,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Email',
                  style: TextStyle(
                    fontSize: 12,
                    fontVariations: [FontVariation('wght', 600)],
                  ),
                ),
                CustomTextField(
                  controller: _emailController,
                  label: 'Masukkan Email',
                  icons: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v?.isEmpty ?? true)
                      ? 'Email tidak boleh kosong'
                      : (!(v?.contains('@') ?? false)
                            ? 'Format email salah'
                            : null),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Password',
                  style: TextStyle(
                    fontSize: 12,
                    fontVariations: [FontVariation('wght', 600)],
                  ),
                ),
                CustomTextField(
                  controller: _passwordController,
                  label: 'Masukkan Password',
                  icons: Icons.lock,
                  isObscured: true,
                  validator: (v) => (v?.isEmpty ?? true)
                      ? 'Password tidak boleh kosong'
                      : ((v?.length ?? 0) < 6
                            ? 'Password minimal 6 karakter'
                            : null),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Alamat Domisili',
                  style: TextStyle(
                    fontSize: 12,
                    fontVariations: [FontVariation('wght', 600)],
                  ),
                ),
                CustomTextField(
                  controller: _addressController,
                  label: 'Masukkan Alamat Domisili',
                  icons: Icons.location_on,
                  validator: (v) =>
                      (v?.isEmpty ?? true) ? 'Alamat tidak boleh kosong' : null,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tanggal Lahir',
                  style: TextStyle(
                    fontSize: 12,
                    fontVariations: [FontVariation('wght', 600)],
                  ),
                ),
                CustomDateSelector(
                  label: _birthdateString.isNotEmpty
                      ? _birthdateString
                      : 'Pilih Tanggal Lahir', // Show selected date or label
                  icons: Icons.date_range_rounded,
                  onDateSelected: (dateString) {
                    if (mounted) {
                      // Ensure widget is still mounted
                      setState(() {
                        _birthdateString = dateString;
                        _birthdateTouched = true; // Mark as touched
                      });
                    }
                  },
                ),
                if (_birthdateString.isEmpty &&
                    (_formKey.currentState?.validate() ?? false) &&
                    _birthdateTouched) // Check if touched
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Tanggal lahir harus dipilih',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                const Text(
                  'Profesi',
                  style: TextStyle(
                    fontSize: 12,
                    fontVariations: [FontVariation('wght', 600)],
                  ),
                ),
                if (_isLoadingOccupations)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.work),
                      hintText: 'Pilih Profesi',
                    ),
                    value: _selectedOccupationId,
                    items: _occupations.map((Map<String, String> occMap) {
                      return DropdownMenuItem<String>(
                        value: occMap['id'],
                        child: Text(occMap['name']!),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        final selectedOccData = _occupations.firstWhere(
                          (occ) => occ['id'] == newValue,
                        );
                        setState(() => _selectedOccupationId = newValue);
                        // Dispatch to BLoC immediately if form interacts with BLoC on field change
                        context.read<RegisterBloc>().add(
                          RegisterOccupationIdChanged(
                            newValue,
                            selectedOccData['name']!,
                          ),
                        );
                      }
                    },
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Profesi harus dipilih'
                        : null,
                  ),
                const SizedBox(height: 24),
                BlocBuilder<RegisterBloc, RegisterState>(
                  builder: (context, state) {
                    final isLoadingActual =
                        state.status == RegisterStatus.submitting ||
                        state.status ==
                            RegisterStatus.awaitingOtpVerification ||
                        state.status == RegisterStatus.finalizing;
                    return CustomButton(
                      label: isLoadingActual ? 'Memproses…' : 'Daftar Akun',
                      onPressed: isLoadingActual
                          ? null
                          : () {
                              if (_formKey.currentState?.validate() ?? false) {
                                if (_birthdateString.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Tanggal lahir harus diisi.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (_selectedOccupationId == null ||
                                    _selectedOccupationId!.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Profesi harus dipilih.'),
                                    ),
                                  );
                                  return;
                                }
                                _dispatchAllFieldsToBloc(); // Ensure BLoC state is up-to-date
                                context.read<RegisterBloc>().add(
                                  RegisterFormSubmitted(),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Harap isi semua field dengan benar.',
                                    ),
                                  ),
                                );
                              }
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

// In otp_verification_page.dart, you'll need to define OtpFlow
// enum OtpFlow { registration, passwordReset, general }
// And pass it during navigation:
// Navigator.pushNamed(context, Routes.otpVerification, arguments: {'email': email, 'flow': OtpFlow.registration});
// Then in OtpVerificationPage, use this flow to decide:
// if (flow == OtpFlow.registration) { Navigator.pop(context, true); } else { /* other navigation */ }
