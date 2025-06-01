import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; // Keep for DateFormat
import 'package:ta_client/app/routes/routes.dart';
import 'package:ta_client/core/constants/app_colors.dart'; // Assuming you have this for colors
import 'package:ta_client/features/profile/bloc/profile_bloc.dart';
import 'package:ta_client/features/profile/bloc/profile_event.dart';
import 'package:ta_client/features/profile/bloc/profile_state.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  _ProfileEditPageState createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController
  _nameController; // Retained for consistency with existing logic
  late TextEditingController _emailController;
  late TextEditingController _usernameController;
  late TextEditingController
  _addressController; // Not in image, but keep for existing logic
  late TextEditingController _occupationController;
  late TextEditingController
  _dummyPasswordController; // For visual "Ubah Password"
  DateTime? _birthdate;
  final bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<ProfileBloc>().state;
    _dummyPasswordController = TextEditingController(
      text: '********',
    ); // Dummy password

    if (state is ProfileLoadSuccess) {
      final user = state.user;
      _nameController = TextEditingController(
        text: user.name,
      ); // Keep for logic
      _emailController = TextEditingController(text: user.email);
      _usernameController = TextEditingController(text: user.username);
      _addressController = TextEditingController(
        text: user.address,
      ); // Keep for logic
      _occupationController = TextEditingController(text: user.occupationName);
      _birthdate = user.birthdate;
    } else {
      // Initialize with empty or placeholder if no data yet,
      // but image shows pre-filled data.
      // Assuming ProfileLoadSuccess will be the state when this page is normally reached.
      _nameController = TextEditingController();
      _emailController = TextEditingController();
      _usernameController = TextEditingController();
      _addressController = TextEditingController();
      _occupationController = TextEditingController();
      // If data isn't loaded, it might be better to show a loading state
      // or an error rather than empty fields if the design expects data.
      // For now, adhering to existing logic which might re-trigger load.
      if (state is! ProfileLoadInProgress) {
        // Avoid dispatching if already loading
        context.read<ProfileBloc>().add(ProfileLoadRequested());
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _addressController.dispose();
    _occupationController.dispose();
    _dummyPasswordController.dispose();
    super.dispose();
  }

  void _onSave() {
    // Existing save logic - NO CHANGES HERE
    if (!_formKey.currentState!.validate()) {
      // Check _birthdate validity for the original logic if it was essential for validation
      if (_birthdate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tanggal lahir tidak boleh kosong.')),
        );
        return;
      }
      return;
    }

    final state = context.read<ProfileBloc>().state;
    if (state is! ProfileLoadSuccess) return;

    final updated = state.user.copyWith(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(), // Email is not editable in UI image
      username: _usernameController.text.trim(),
      address: _addressController.text.trim(), // Address not in UI image
      occupationName: _occupationController.text.trim(),
      birthdate: _birthdate,
    );

    context.read<ProfileBloc>().add(ProfileUpdateRequested(updated));
  }

  Future<void> _pickBirthdate() async {
    // Existing date pick logic - NO CHANGES HERE
    final date = await showDatePicker(
      context: context,
      initialDate: _birthdate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      // Optional: Add builder for theming date picker if needed
    );

    if (date != null) {
      setState(() {
        _birthdate = date;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Match image background
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
          // Existing listener logic - NO CHANGES HERE
          if (state is ProfileLoadSuccess &&
              ModalRoute.of(context)?.isCurrent == true) {
            // Check if this page is still the current route before navigating
            // This is important if _onSave triggers multiple ProfileLoadSuccess states quickly.
            // For profile edit, usually after update success, we pop.
            // If the UI shows success then auto-navigates, this is okay.
            // If it's a specific "update success" state, better to listen for that.
            // For now, assuming ProfileLoadSuccess after update means go back.
            if (Navigator.canPop(context)) {
              Navigator.pop(context); // Go back to profile page after save
            } else {
              Navigator.pushReplacementNamed(context, Routes.profilePage);
            }
          } else if (state is ProfileLoadFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.error)));
          }
        },
        builder: (context, state) {
          if (state is ProfileLoadInProgress &&
              _usernameController.text.isEmpty) {
            // Show loading only if initial data isn't there
            return const Center(child: CircularProgressIndicator());
          }

          // If state is ProfileLoadSuccess, update controllers (handles case where data loads after initState)
          if (state is ProfileLoadSuccess) {
            // Only update if text is different to prevent cursor jump and redundant sets
            if (_nameController.text != state.user.name) {
              _nameController.text = state.user.name;
            }
            if (_emailController.text != state.user.email) {
              _emailController.text = state.user.email;
            }
            if (_usernameController.text != state.user.username) {
              _usernameController.text = state.user.username;
            }
            if (_addressController.text != state.user.address) {
              _addressController.text = state.user.address;
            }
            if (_occupationController.text != state.user.occupationName) {
              _occupationController.text = state.user.occupationName;
            }
            if (_birthdate != state.user.birthdate) {
              _birthdate = state
                  .user
                  .birthdate; // Direct assignment, setState below if needed
            }
          }

          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ), // Adjusted padding
            child: Form(
              key: _formKey,
              child: Column(
                // Changed to Column for better control over spacing and button
                children: [
                  Expanded(
                    child: ListView(
                      children: [
                        // Username
                        _buildStyledTextField(
                          controller: _usernameController,
                          label: 'Username',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 20),

                        // Email (Display only as per image - not typically editable without verification)
                        _buildStyledTextField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          readOnly: true, // Email is not editable in image
                        ),
                        const SizedBox(height: 20),

                        // Ubah Password (Visual Only)
                        _buildStyledTextField(
                          controller: _dummyPasswordController,
                          label: 'Ubah Password',
                          icon: Icons.lock_outline,
                          obscureText: !_isPasswordVisible,
                          readOnly: true, // This is a dummy field for display
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              // This would toggle visibility if it were a real password field
                              // For a dummy field, this action could navigate to a change password screen
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Navigasi ke halaman ubah password (belum diimplementasi).',
                                  ),
                                ),
                              );
                              // setState(() {
                              //   _isPasswordVisible = !_isPasswordVisible;
                              // });
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Tanggal Lahir
                        _buildDateField(context),
                        const SizedBox(height: 20),

                        // Profesi (Using TextFormField for similar styling, could be DropdownButtonFormField)
                        _buildStyledTextField(
                          controller: _occupationController,
                          label: 'Profesi',
                          icon: Icons
                              .work_outline, // Using work_outline from image
                          // For a real dropdown, you'd use DropdownButtonFormField
                          // For now, just a text field to match appearance.
                          suffixIcon: const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.grey,
                          ),
                          onTap: () {
                            // TODO: Implement occupation picker/dropdown if this becomes interactive
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Pemilihan profesi belum diimplementasi.',
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(
                          height: 16,
                        ), // Space before button if list scrolls
                      ],
                    ),
                  ),
                  const SizedBox(height: 24), // Space above button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            AppColors.primary, // Use your app's primary color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _onSave,
                      child: const Text(
                        'Simpan',
                        style: TextStyle(fontSize: 16, color: Colors.white),
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
