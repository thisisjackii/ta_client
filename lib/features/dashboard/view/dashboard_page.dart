// dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/core/widgets/custom_dashboard_item.dart';
import 'package:ta_client/core/widgets/custom_appbar.dart';
import 'package:ta_client/core/widgets/custom_bottom_navbar.dart';
import 'package:ta_client/features/dashboard/bloc/dashboard_bloc.dart';
import 'package:ta_client/features/dashboard/bloc/dashboard_event.dart';
import 'package:ta_client/features/dashboard/bloc/dashboard_state.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  static Widget create() {
    return BlocProvider(
      create: (context) => DashboardBloc(),
      child: const DashboardPage(),
    );
  }

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentTab = 0; // Tracks the current tab
  final List<Widget> _screens = [];

  void _onTabSelected(int index) {
    setState(() {
      _currentTab = index; // Update the selected tab
    });
  }

  final ValueNotifier<bool> isSelectionMode =
      ValueNotifier(false); // State tracker

  @override
  void dispose() {
    isSelectionMode.dispose(); // Clean up the notifier
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        isSelectionMode: isSelectionMode, // Pass the notifier to AppBar
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is DashboardLoaded) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      // Aligns components to left, center, and right
                      children: [
                        // First Component
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Title 1',
                              style: TextStyle(fontSize: 12),
                            ),
                            Text('Subtitle 1',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12,),),
                          ],
                        ),
                        // Second Component
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Title 2',
                              style: TextStyle(fontSize: 12),
                            ),
                            Text('Subtitle 2',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12,),),
                          ],
                        ),
                        // Third Component
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Title 3',
                              style: TextStyle(fontSize: 12),
                            ),
                            Text('Subtitle 3',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12,),),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GroupedItems(
                      isSelectionMode:
                          isSelectionMode, // Pass the notifier to Items list
                    ),
                  ),
                ],
              ),
            );
          } else if (state is DashboardError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context
                        .read<DashboardBloc>()
                        .add(DashboardReloadRequested()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else {
            return const Center(child: Text('Unexpected state'));
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add',
        onPressed: () {},
        shape: const CircleBorder(),
        backgroundColor: const Color(0xFF1D3B5A),
        child: const Icon(Icons.create, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomBottomNavbar(
          currentTab: _currentTab, onTabSelected: _onTabSelected,),
    );
  }
}
