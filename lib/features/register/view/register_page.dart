// lib/features/register/view/register_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; // For DateFormat
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
  String? _selectedOccupationId;
  DateTime? _selectedBirthdate; // Store as DateTime
  bool _birthdateFieldTouched = false;

  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncFieldsFromBloc(context.read<RegisterBloc>().state, isInit: true);
        _fetchOccupations();
      }
    });
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

  void _syncFieldsFromBloc(RegisterState state, {bool isInit = false}) {
    var needsUiUpdate = false;

    if (_nameController.text != state.name) _nameController.text = state.name;
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

    if (_selectedBirthdate != state.birthdate) {
      _selectedBirthdate = state.birthdate;
      if (!isInit) needsUiUpdate = true;
    }

    final blocOccupationId = state.occupationId.isNotEmpty
        ? state.occupationId
        : null;
    if (_selectedOccupationId != blocOccupationId) {
      _selectedOccupationId = blocOccupationId;
      if (!isInit) needsUiUpdate = true;
    }

    if (needsUiUpdate && mounted) {
      setState(() {});
    }
  }

  Future<void> _fetchOccupations() async {
    if (!mounted) return;
    setState(() => _isLoadingOccupations = true);
    try {
      final registerService = sl<RegisterService>();
      final occsData = await registerService.fetchOccupations();
      if (mounted) {
        setState(() {
          _occupations = occsData;
          _isLoadingOccupations = false;
          final currentBlocOccupationId = context
              .read<RegisterBloc>()
              .state
              .occupationId;
          if (currentBlocOccupationId.isNotEmpty &&
              _occupations.any((o) => o['id'] == currentBlocOccupationId)) {
            _selectedOccupationId = currentBlocOccupationId;
          } else if (_selectedOccupationId != null &&
              !_occupations.any((o) => o['id'] == _selectedOccupationId)) {
            _selectedOccupationId = null;
            context.read<RegisterBloc>().add(
              const RegisterOccupationIdChanged('', ''),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingOccupations = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal memuat daftar profesi: ${e}')),
            );
          }
        });
      }
    }
  }

  void _updateBlocWithCurrentFieldValues() {
    // Renamed for clarity
    final bloc = context.read<RegisterBloc>();
    // Dispatch events only if local UI state differs from BLoC state
    // This helps if BLoC is the source of truth and UI might get out of sync
    // or if an intermediate action didn't update BLoC for some reason.
    if (bloc.state.name != _nameController.text.trim()) {
      bloc.add(RegisterNameChanged(_nameController.text.trim()));
    }
    if (bloc.state.username != _usernameController.text.trim()) {
      bloc.add(RegisterUsernameChanged(_usernameController.text.trim()));
    }
    if (bloc.state.email != _emailController.text.trim()) {
      bloc.add(RegisterEmailChanged(_emailController.text.trim()));
    }
    if (bloc.state.password != _passwordController.text) {
      bloc.add(RegisterPasswordChanged(_passwordController.text));
    }
    if (bloc.state.address != _addressController.text.trim()) {
      bloc.add(RegisterAddressChanged(_addressController.text.trim()));
    }
    if (bloc.state.birthdate != _selectedBirthdate) {
      bloc.add(RegisterBirthdateChanged(_selectedBirthdate));
    }

    var currentSelectedOccName =
        bloc.state.occupationName; // Default to current BLoC name
    if (_selectedOccupationId != null && _selectedOccupationId!.isNotEmpty) {
      if (_occupations.isNotEmpty) {
        try {
          final selectedOccData = _occupations.firstWhere(
            (occ) => occ['id'] == _selectedOccupationId,
          );
          currentSelectedOccName = selectedOccData['name']!;
        } catch (e) {
          /* Keep BLoC name */
        }
      }
      // Only dispatch if ID or derived name is different from BLoC
      if (bloc.state.occupationId != _selectedOccupationId ||
          bloc.state.occupationName != currentSelectedOccName) {
        bloc.add(
          RegisterOccupationIdChanged(
            _selectedOccupationId!,
            currentSelectedOccName,
          ),
        );
      }
    } else if (bloc.state.occupationId.isNotEmpty) {
      // If local is null but BLoC has one
      bloc.add(const RegisterOccupationIdChanged('', ''));
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
          onPressed: () => Navigator.of(context).pop(),
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
                prev.status != curr.status ||
                curr.errorMessage != null ||
                // Also listen to individual field changes if BLoC state might change them
                prev.name != curr.name ||
                prev.username != curr.username ||
                prev.email != curr.email ||
                prev.password != curr.password ||
                prev.address != curr.address ||
                prev.birthdate != curr.birthdate ||
                prev.occupationId != curr.occupationId,
            listener: (context, state) {
              _syncFieldsFromBloc(
                state,
              ); // Sync local UI elements with BLoC state

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
                context.read<RegisterBloc>().add(const RegisterClearError());
              }
            },
          ),
          BlocListener<OtpBloc, OtpStateClass.OtpState>(
            listenWhen: (prev, currOtpState) {
              final currentRegisterStatus = context
                  .read<RegisterBloc>()
                  .state
                  .status;
              return currentRegisterStatus ==
                      RegisterStatus.awaitingOtpVerification ||
                  (currentRegisterStatus == RegisterStatus.submitting &&
                      currOtpState is! OtpStateClass.OtpInitial &&
                      prev is OtpStateClass.OtpInitial);
            },
            listener: (context, otpState) {
              final registerBloc = context.read<RegisterBloc>();
              final currentRegisterStatus = registerBloc.state.status;

              if (currentRegisterStatus ==
                  RegisterStatus.awaitingOtpVerification) {
                if (otpState is OtpStateClass.OtpSuccess) {
                  Navigator.pushNamed(
                    context,
                    Routes.otpVerification,
                    arguments: OtpVerificationPageArguments(
                      email: otpState.email,
                      flow: OtpFlow.registration,
                    ),
                  ).then((otpVerifiedSuccessfully) {
                    if (mounted) {
                      if (otpVerifiedSuccessfully == true) {
                        registerBloc.add(const RegisterOtpVerified());
                      } else {
                        registerBloc.add(const RegisterClearError());
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
                } else if (otpState is OtpStateClass.OtpFailure) {
                  registerBloc.add(
                    RegisterFailure(
                      'Gagal meminta OTP: ${otpState.errorMessage}',
                    ),
                  );
                }
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
                  onChanged: (value) => context.read<RegisterBloc>().add(
                    RegisterNameChanged(value.trim()),
                  ),
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
                  onChanged: (value) => context.read<RegisterBloc>().add(
                    RegisterUsernameChanged(value.trim()),
                  ),
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
                  onChanged: (value) => context.read<RegisterBloc>().add(
                    RegisterEmailChanged(value.trim()),
                  ),
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
                  onChanged: (value) => context.read<RegisterBloc>().add(
                    RegisterPasswordChanged(value),
                  ),
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
                  onChanged: (value) => context.read<RegisterBloc>().add(
                    RegisterAddressChanged(value.trim()),
                  ),
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
                  key: ValueKey(
                    _selectedBirthdate,
                  ), // Rebuild if _selectedBirthdate instance changes
                  label: 'Pilih Tanggal Lahir', // This is just the placeholder
                  initialDate:
                      _selectedBirthdate, // This will pre-fill the date
                  icons: Icons.date_range_rounded,
                  onDateSelected: (DateTime? date) {
                    if (mounted) {
                      setState(() {
                        _selectedBirthdate = date;
                        _birthdateFieldTouched = true;
                      });
                      context.read<RegisterBloc>().add(
                        RegisterBirthdateChanged(date),
                      );
                    }
                  },
                  validator: (DateTime? value) {
                    // FormField validator
                    if (value == null) {
                      return 'Tanggal lahir harus dipilih';
                    }
                    return null;
                  },
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
                          orElse: () => {'id': '', 'name': 'Error'},
                        );
                        if (mounted) {
                          setState(() => _selectedOccupationId = newValue);
                        }
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
                    final isLoadingButton =
                        state.status == RegisterStatus.submitting ||
                        state.status ==
                            RegisterStatus.awaitingOtpVerification ||
                        state.status == RegisterStatus.finalizing;
                    return CustomButton(
                      label: isLoadingButton ? 'Memproses…' : 'Daftar Akun',
                      onPressed: isLoadingButton
                          ? null
                          : () {
                              setState(() {
                                _birthdateFieldTouched = true;
                              });
                              _updateBlocWithCurrentFieldValues(); // Ensure BLoC has the latest from text fields

                              // Access BLoC state *after* potential updates from _updateBlocWithCurrentFieldValues
                              final currentBlocState = context
                                  .read<RegisterBloc>()
                                  .state;

                              if ((_formKey.currentState?.validate() ??
                                      false) &&
                                  currentBlocState.birthdate != null) {
                                // Check canRequestOtp from the BLoC state which is now synced
                                if (currentBlocState.canRequestOtp) {
                                  context.read<RegisterBloc>().add(
                                    const RegisterFormSubmitted(),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Harap lengkapi semua field yang wajib.',
                                      ),
                                    ),
                                  );
                                }
                              } else {
                                var errorMsg =
                                    'Harap isi semua field dengan benar.';
                                if (currentBlocState.birthdate == null) {
                                  errorMsg = 'Tanggal lahir harus dipilih.';
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(errorMsg)),
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
