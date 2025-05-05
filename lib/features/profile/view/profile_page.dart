// lib/features/profile/view/profile_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/app/routes/routes.dart';
import 'package:ta_client/core/constants/app_colors.dart';
import 'package:ta_client/core/widgets/custom_bottom_navbar.dart';

import 'package:ta_client/features/profile/bloc/profile_bloc.dart';
import 'package:ta_client/features/profile/bloc/profile_event.dart';
import 'package:ta_client/features/profile/bloc/profile_state.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _currentTab = 3; // Akun tab index

  @override
  void initState() {
    super.initState();
    // Trigger initial profile load
    context.read<ProfileBloc>().add(ProfileLoadRequested());
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentTab = index;
    });
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, Routes.dashboard);
      case 1:
        Navigator.pushReplacementNamed(context, Routes.evaluationIntro);
      case 2:
        Navigator.pushReplacementNamed(context, Routes.budgetingIntro);
      case 3:
        // Already on Profile: refresh
        context.read<ProfileBloc>().add(ProfileLoadRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Pengguna'),
        backgroundColor: AppColors.greyBackground,
      ),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoadInProgress) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ProfileLoadSuccess) {
            final user = state.user;
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(
                      'https://ipt.images.tshiftcdn.com/200626/x/0/best-aspect-ratios-for-landscape-photography-in-iceland-5.jpg?auto=compress%2Cformat&ch=Width%2CDPR&dpr=1&ixlib=php-3.3.0&w=883',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(user.name, style: const TextStyle(fontSize: 18)),
                  Text(user.email, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Ubah Profil'),
                    subtitle: const Text('Ubah data pribadi Anda'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () =>
                        Navigator.pushNamed(context, Routes.profileEdit),
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Logout'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // TODO: call AuthState.logout() and navigate to login
                    },
                  ),
                ],
              ),
            );
          } else if (state is ProfileLoadFailure) {
            return Center(child: Text('Error: ${state.error}'));
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomBottomNavbar(
        currentTab: _currentTab,
        onTabSelected: _onTabSelected,
      ),
    );
  }
}
