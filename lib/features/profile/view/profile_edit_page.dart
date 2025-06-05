import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; // Keep for DateFormat
import 'package:ta_client/app/routes/routes.dart';
import 'package:ta_client/core/constants/app_colors.dart'; // Assuming you have this for colors
import 'package:ta_client/core/services/service_locator.dart';
import 'package:ta_client/features/profile/bloc/profile_bloc.dart';
import 'package:ta_client/features/profile/bloc/profile_event.dart';
import 'package:ta_client/features/profile/bloc/profile_state.dart';
import 'package:ta_client/features/profile/models/user_model.dart';
import 'package:ta_client/features/register/services/register_service.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  _ProfileEditPageState createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _usernameController;
  late TextEditingController _addressController;
  // late TextEditingController _occupationController; // Replaced by dropdown
  late TextEditingController _dummyPasswordController;
  DateTime? _birthdate;
  final bool _isPasswordVisible = false; // Kept for dummy field

  List<Map<String, String>> _occupations = [];
  String? _selectedOccupationIdForUpdate;
  bool _isLoadingOccupations = true;
  bool _wasSaving =
      false; // To track if ProfileLoadSuccess is after an update attempt

  @override
  void initState() {
    super.initState();
    final profileBlocState = context.read<ProfileBloc>().state;
    _dummyPasswordController = TextEditingController(text: '********');

    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _usernameController = TextEditingController();
    _addressController = TextEditingController();
    // _occupationController = TextEditingController(); // No longer needed

    if (profileBlocState is ProfileLoadSuccess) {
      _updateControllersFromUser(profileBlocState.user);
    } else {
      if (profileBlocState is! ProfileLoadInProgress) {
        context.read<ProfileBloc>().add(ProfileLoadRequested());
      }
    }
    _fetchOccupations();
  }

  void _updateControllersFromUser(User user) {
    if (_nameController.text != user.name) _nameController.text = user.name;
    if (_emailController.text != user.email) _emailController.text = user.email;
    if (_usernameController.text != user.username) {
      _usernameController.text = user.username;
    }
    if (_addressController.text != user.address) {
      _addressController.text = user.address;
    }

    if (_birthdate != user.birthdate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Ensure setState is safe
        if (mounted) setState(() => _birthdate = user.birthdate);
      });
    }

    // Update selectedOccupationIdForUpdate based on user.occupationId
    // This needs to happen AFTER _occupations list is populated by _fetchOccupations
    // So, _fetchOccupations will handle setting _selectedOccupationIdForUpdate if user.occupationId matches.
    if (user.occupationId != null &&
        _occupations.any((o) => o['id'] == user.occupationId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _selectedOccupationIdForUpdate = user.occupationId);
        }
      });
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
          // After occupations are loaded, try to set the selected one if profile data is available
          final profileState = context.read<ProfileBloc>().state;
          if (profileState is ProfileLoadSuccess &&
              profileState.user.occupationId != null) {
            if (_occupations.any(
              (o) => o['id'] == profileState.user.occupationId,
            )) {
              _selectedOccupationIdForUpdate = profileState.user.occupationId;
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingOccupations = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat daftar pekerjaan: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _addressController.dispose();
    // _occupationController.dispose(); // Removed
    _dummyPasswordController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) {
      if (_birthdate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tanggal lahir tidak boleh kosong.')),
        );
        return;
      }
      // Occupation is validated by DropdownButtonFormField's validator
      return;
    }

    final state = context.read<ProfileBloc>().state;
    if (state is! ProfileLoadSuccess) return;

    final updated = state.user.copyWith(
      name: _nameController.text.trim(),
      username: _usernameController.text.trim(),
      address: _addressController.text.trim(),
      birthdate: _birthdate,
      occupationId: _selectedOccupationIdForUpdate, // Use the ID
      // occupationName will be derived by backend or not needed for update DTO
    );

    setState(() {
      _wasSaving = true;
    }); // Set flag before dispatching
    context.read<ProfileBloc>().add(ProfileUpdateRequested(updated));
  }

  Future<void> _pickBirthdate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _birthdate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _birthdate = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Ubah Profil',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0, // No shadow like in image
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileLoadSuccess) {
            // If data loaded (either initially or after update), sync controllers
            _updateControllersFromUser(state.user); // Sync UI

            if (_wasSaving) {
              // Check if this success is after an update attempt
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profil berhasil diubah!')),
              );
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, Routes.profilePage);
              }
              _wasSaving = false; // Reset flag
            }
          } else if (state is ProfileLoadFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.error)));
            _wasSaving = false; // Reset flag on failure too
          }
        },
        builder: (context, state) {
          if (state is ProfileLoadInProgress &&
              _usernameController.text.isEmpty &&
              !_wasSaving) {
            return const Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      children: [
                        _buildStyledTextField(
                          controller: _usernameController,
                          label: 'Username',
                          icon: Icons.person_outline,
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Username tidak boleh kosong.'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        _buildStyledTextField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          readOnly: true,
                        ),
                        const SizedBox(height: 20),
                        _buildStyledTextField(
                          controller: _dummyPasswordController,
                          label: 'Ubah Password',
                          icon: Icons.lock_outline,
                          obscureText: !_isPasswordVisible,
                          readOnly: true,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Navigasi ke halaman ubah password (belum diimplementasi).',
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildDateField(context),
                        const SizedBox(height: 20),

                        // Occupation Dropdown
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pekerjaan',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (_isLoadingOccupations)
                              const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            else
                              DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.work_outline,
                                    color: Colors.grey[400],
                                    size: 20,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ), // Adjust horizontal if needed for prefixIcon
                                  border: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: AppColors.primary.withOpacity(0.7),
                                      width: 1.5,
                                    ),
                                  ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                ),
                                value: _selectedOccupationIdForUpdate,
                                hint: const Text(
                                  'Pilih Pekerjaan',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                isExpanded: true,
                                items: _occupations.map((
                                  Map<String, String> occ,
                                ) {
                                  return DropdownMenuItem<String>(
                                    value: occ['id'],
                                    child: Text(
                                      occ['name']!,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(
                                    () =>
                                        _selectedOccupationIdForUpdate = value,
                                  );
                                },
                                validator: (value) =>
                                    (value == null || value.isEmpty)
                                    ? 'Pekerjaan tidak boleh kosong.'
                                    : null,
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: (state is ProfileLoadInProgress && _wasSaving)
                          ? null
                          : _onSave, // Disable button if saving
                      child: (state is ProfileLoadInProgress && _wasSaving)
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text(
                              'Simpan',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // New styled text field builder
  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    bool obscureText = false,
    Widget? suffixIcon,
    VoidCallback? onTap,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          obscureText: obscureText,
          onTap: onTap,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 10,
            ),
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: AppColors.primary.withOpacity(0.7),
                width: 1.5,
              ),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            // Remove labelText from here as we have a separate Text widget for label
          ),
          validator: readOnly
              ? null
              : (validator ??
                    (v) => (v == null || v.isEmpty)
                        ? '$label tidak boleh kosong.'
                        : null),
        ),
      ],
    );
  }

  Widget _buildDateField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tanggal Lahir',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: _pickBirthdate,
          child: InputDecorator(
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.calendar_today_outlined,
                color: Colors.grey[400],
                size: 20,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
              ), // Adjust horizontal if needed
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.primary.withOpacity(0.7),
                  width: 1.5,
                ),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Text(
              _birthdate != null
                  ? DateFormat('d/M/yyyy').format(
                      _birthdate!,
                    ) // Format d/M/yyyy
                  : 'Pilih tanggal', // Placeholder
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _birthdate != null ? Colors.black : Colors.grey[600],
              ),
            ),
          ),
        ),
        if (_birthdate == null &&
            _formKey.currentState != null &&
            !_formKey.currentState!.validate()) // Basic check for error display
          Padding(
            padding: const EdgeInsets.only(
              top: 8,
              left: 12,
            ), // Adjust alignment
            child: Text(
              'Tanggal lahir tidak boleh kosong.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  // Original _buildTextField is removed as _buildStyledTextField replaces it for UI matching.
  // If you need to keep existing validation or other specific logic from the old one for
  // fields not shown in the image (like Nama Lengkap, Alamat), you'd keep that and use it accordingly.
}
