// lib/features/dashboard/view/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:ta_client/app/routes/routes.dart';
import 'package:ta_client/core/widgets/custom_appbar.dart';
import 'package:ta_client/core/widgets/custom_bottom_navbar.dart';
import 'package:ta_client/features/transaction/bloc/dashboard_bloc.dart';
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

  final NumberFormat _rupiahFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp. ',
    decimalDigits: 0,
  );

  // Track the selected month-year. We only care about year and month.
  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  // Method to filter and sort transactions by selected month and by newest first.
  List<Transaction> _filterAndSortTransactions(List<Transaction> transactions) {
    // Filter transactions for the selected month
    final filtered = transactions
        .where(
          (t) =>
              t.date.year == selectedMonth.year &&
              t.date.month == selectedMonth.month,
        )
        .toList()

      // Sort in descending order: newest first.
      ..sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentTab = index;
    });
  }

  // A callback to update the selected month from the AppBar
  void updateSelectedMonth(DateTime newMonth) {
    setState(() {
      selectedMonth = DateTime(newMonth.year, newMonth.month);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        isSelectionMode: isSelectionMode,
        selectedMonth: selectedMonth,
        onMonthChanged: updateSelectedMonth,
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is DashboardLoaded) {
            // Filter and sort before passing to widget.
            final filteredItems = _filterAndSortTransactions(state.items);
            // Calculate total pemasukan
            final totalPemasukan = filteredItems
                .where((t) => t.type == "Pemasukan")
                .fold<double>(0, (sum, t) => sum + t.amount);

            final totalPengeluaran = filteredItems
                .where((t) => t.type == "Pengeluaran")
                .fold<double>(0, (sum, t) => sum + t.amount);

            final totalAkhir = totalPemasukan - totalPengeluaran;

            final formattedPemasukan = _rupiahFormatter.format(totalPemasukan);
            final formattedPengeluaran = _rupiahFormatter.format(totalPengeluaran);
            final formattedAkhir = _rupiahFormatter.format(totalAkhir);

            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          Text(
                            "Total Pemasukan",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          Text(
                            "$formattedPemasukan",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            "Total Pengeluaran",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          Text(
                            "$formattedPengeluaran",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            "Total",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          Text(
                            "$formattedAkhir",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: TransactionGroupedItemsWidget(
                    items: filteredItems,
                    isSelectionMode: isSelectionMode,
                  ),
                ),
              ],
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
          if (context.mounted) {
            if (result is Transaction) {
              context.read<DashboardBloc>().add(DashboardItemAdded(result));
            } else {
              // If nothing returned, fall back to a full reload.
              context.read<DashboardBloc>().add(DashboardReloadRequested());
            }
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
