import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:ta_client/app/routes/routes.dart';
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

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _usernameController;
  late TextEditingController _addressController;
  late TextEditingController _occupationController;
  DateTime? _birthdate;

  @override
  void initState() {
    super.initState();
    final state = context.read<ProfileBloc>().state;

    if (state is ProfileLoadSuccess) {
      final user = state.user;
      _nameController = TextEditingController(text: user.name);
      _emailController = TextEditingController(text: user.email);
      _usernameController = TextEditingController(text: user.username);
      _addressController = TextEditingController(text: user.address);
      _occupationController = TextEditingController(text: user.occupationName);
      _birthdate = user.birthdate;
    } else {
      _nameController = TextEditingController();
      _emailController = TextEditingController();
      _usernameController = TextEditingController();
      _addressController = TextEditingController();
      _occupationController = TextEditingController();
      context.read<ProfileBloc>().add(ProfileLoadRequested());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _addressController.dispose();
    _occupationController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (!_formKey.currentState!.validate() || _birthdate == null) return;

    final state = context.read<ProfileBloc>().state;
    if (state is! ProfileLoadSuccess) return;

    final updated = state.user.copyWith(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      username: _usernameController.text.trim(),
      address: _addressController.text.trim(),
      occupationName: _occupationController.text.trim(),
      birthdate: _birthdate,
    );

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
      setState(() {
        _birthdate = date;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil')),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileLoadSuccess) {
            Navigator.pushReplacementNamed(context, Routes.profilePage);
          } else if (state is ProfileLoadFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.error)));
          }
        },
        builder: (context, state) {
          if (state is ProfileLoadInProgress) {
            return const Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  _buildTextField(
                    _nameController,
                    'Nama Lengkap',
                    Icons.person,
                  ),
                  _buildTextField(
                    _usernameController,
                    'Username',
                    Icons.alternate_email,
                  ),
                  _buildTextField(
                    _emailController,
                    'Email',
                    Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  _buildTextField(_addressController, 'Alamat', Icons.home),
                  _buildTextField(
                    _occupationController,
                    'Pekerjaan',
                    Icons.work,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.cake),
                    title: Text(
                      _birthdate != null
                          ? DateFormat('yyyy-MM-dd').format(_birthdate!)
                          : 'Tanggal Lahir',
                    ),
                    onTap: _pickBirthdate,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _onSave,
                    child: const Text('Simpan'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        keyboardType: keyboardType,
        validator: (v) =>
            (v == null || v.isEmpty) ? '$label tidak boleh kosong' : null,
      ),
    );
  }
}
