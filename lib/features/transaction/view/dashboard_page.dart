// lib/features/dashboard/view/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/app/routes/routes.dart';
import 'package:ta_client/app/view/app.dart';
import 'package:ta_client/core/widgets/custom_appbar.dart';
import 'package:ta_client/core/widgets/custom_bottom_navbar.dart';
import 'package:ta_client/features/transaction/bloc/dashboard_bloc.dart';
import 'package:ta_client/features/transaction/bloc/dashboard_event.dart';
import 'package:ta_client/features/transaction/bloc/dashboard_state.dart';
import 'package:ta_client/features/transaction/models/transaction.dart';
import 'package:ta_client/features/transaction/view/widgets/transaction_grouped_items.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with RouteAware {
  int _currentTab = 0;
  final ValueNotifier<bool> isSelectionMode = ValueNotifier(false);

  void _onTabSelected(int index) {
    setState(() {
      _currentTab = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        isSelectionMode: isSelectionMode,
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is DashboardLoaded) {
            return TransactionGroupedItemsWidget(
              items: state.items,
              isSelectionMode: isSelectionMode,
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
        onPressed: () async {
          final result =
              await Navigator.pushNamed(context, Routes.createTransaction);
          // If a new transaction is returned, add it to the dashboard immediately.
          if (result is Transaction) {
            context
                .read<DashboardBloc>()
                .add(DashboardItemAdded(result));
          } else {
            // If nothing returned, fall back to a full reload.
            context.read<DashboardBloc>().add(DashboardReloadRequested());
          }
        },
        shape: const CircleBorder(),
        backgroundColor: const Color(0xFF1D3B5A),
        child: const Icon(Icons.create, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomBottomNavbar(
        currentTab: _currentTab,
        onTabSelected: _onTabSelected,
      ),
    );
  }
}
