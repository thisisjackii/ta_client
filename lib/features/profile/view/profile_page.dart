// lib/features/profile/view/profile_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/app/routes/routes.dart';
import 'package:ta_client/core/constants/app_colors.dart';
import 'package:ta_client/core/state/auth_state.dart';
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
    _loadProfile();
  }

  void _loadProfile() {
    // Check if user is authenticated before loading profile
    // This check could also be done at a higher level (e.g., route guard)
    final authState = context.read<AuthState>();
    if (authState.isAuthenticated) {
      context.read<ProfileBloc>().add(ProfileLoadRequested());
    } else {
      // If somehow user lands here unauthenticated, redirect to login
      // This shouldn't happen if routing is set up correctly based on AuthState
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            Routes.login,
            (route) => false,
          );
        }
      });
    }
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

  Future<void> _handleLogout() async {
    if (!mounted) return;
    // Show confirmation dialog
    final confirmLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Anda yakin ingin keluar dari akun ini?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false); // User canceled
              },
            ),
            TextButton(
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(dialogContext).pop(true); // User confirmed
              },
            ),
          ],
        );
      },
    );

    if (confirmLogout ?? false) {
      if (!mounted) return;
      // Access AuthState using Provider/context.read
      final authState = context.read<AuthState>();
      await authState.logout(); // This clears token and updates isAuthenticated

      // After logout, AuthState will notify its listeners.
      // The main App widget (or a root listener) should react to isAuthenticated becoming false
      // and navigate to the login/welcome screen.
      // However, for immediate navigation from here:
      if (mounted) {
        // Check mounted again after await
        await Navigator.pushNamedAndRemoveUntil(
          context,
          Routes.welcome,
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch AuthState to rebuild if authentication status changes (e.g., token expires elsewhere)
    // This helps ensure that if user becomes unauthenticated, this page reacts.
    final authState = context.watch<AuthState>();
    if (!authState.isAuthenticated && !authState.isLoading) {
      // Also check isLoading
      // If not authenticated and not in initial loading phase, redirect
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            Routes.login,
            (route) => false,
          );
        }
      });
      return const Scaffold(
        body: Center(child: Text('Sesi berakhir, mengalihkan ke login...')),
      ); // Placeholder UI
    }

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
                    onTap: _handleLogout,
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
