// lib/features/transaction/view/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/app/routes/routes.dart';
import 'package:ta_client/core/constants/app_colors.dart';
import 'package:ta_client/core/utils/calculations.dart';
import 'package:ta_client/core/widgets/custom_appbar.dart';
import 'package:ta_client/core/widgets/custom_bottom_navbar.dart';
import 'package:ta_client/features/transaction/bloc/dashboard_bloc.dart';
import 'package:ta_client/features/transaction/models/transaction.dart';
import 'package:ta_client/features/transaction/view/widgets/transaction_grouped_items.dart';
import 'package:ta_client/features/transaction/view/widgets/transaction_totals_summary.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with RouteAware {
  int _currentTab = 0;
  final ValueNotifier<bool> isSelectionMode = ValueNotifier(false);

  // Track the selected month-year.
  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  // Store filter criteria from the filter form.
  Map<String, dynamic>? filterCriteria;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyBackground,
      appBar: CustomAppBar(
        isSelectionMode: isSelectionMode,
        selectedMonth: selectedMonth,
        onMonthChanged: updateSelectedMonth,
        onFilterChanged: updateFilterCriteria, // Pass filter criteria upward.
      ),
      body: BlocConsumer<DashboardBloc, DashboardState>(
        listener: (context, state) {
          if (state is DashboardUnauthenticated) {
            Navigator.pushReplacementNamed(context, Routes.login);
          }
        },
        builder: (context, state) {
          if (state is DashboardLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is DashboardLoaded) {
            final filteredItems = _filterAndSortTransactions(state.items);
            final totalPemasukan = filteredItems
                .where((t) => t.accountType == 'Pemasukan')
                .fold<double>(0, (sum, t) => sum + t.amount);
            final totalPengeluaran = filteredItems
                .where((t) => t.accountType == 'Pengeluaran')
                .fold<double>(0, (sum, t) => sum + t.amount);
            final totalAkhir = totalPemasukan - totalPengeluaran;
            final formattedPemasukan = formatToRupiah(totalPemasukan);
            final formattedPengeluaran = formatToRupiah(totalPengeluaran);
            final formattedAkhir = formatToRupiah(totalAkhir);

            return Column(
              children: [
                TransactionTotalsSummary(
                  pemasukan: formattedPemasukan,
                  pengeluaran: formattedPengeluaran,
                  total: formattedAkhir,
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
                    onPressed: () => context.read<DashboardBloc>().add(
                      DashboardReloadRequested(),
                    ),
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
          final result = await Navigator.pushNamed(
            context,
            Routes.createTransaction,
          );
          if (context.mounted) {
            if (result is Transaction) {
              context.read<DashboardBloc>().add(DashboardItemAdded(result));
            } else {
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

  // Callback to update filter criteria (received from CustomAppBar).
  void updateFilterCriteria(Map<String, dynamic>? criteria) {
    setState(() {
      filterCriteria = criteria;
    });
  }

  // Callback to update the selected month.
  void updateSelectedMonth(DateTime newMonth) {
    setState(() {
      selectedMonth = DateTime(newMonth.year, newMonth.month);
    });
  }

  // Filter and sort transactions using the selected month and filter criteria.
  List<Transaction> _filterAndSortTransactions(List<Transaction> transactions) {
    final filtered =
        transactions.where((t) {
            // Apply the month filter.
            final monthMatch =
                t.date.year == selectedMonth.year &&
                t.date.month == selectedMonth.month;

            // Apply parent category filter.
            final parentMatch =
                (filterCriteria == null || filterCriteria!['parent'] == null) ||
                t.accountType == filterCriteria!['parent'];

            // Apply child category filter.
            // (Assuming your Transaction model has a property 'category')
            final childMatch =
                (filterCriteria == null || filterCriteria!['child'] == null) ||
                t.categoryName == filterCriteria!['child'];

            // Apply date range filter.
            final startDate = filterCriteria?['startDate'] as DateTime?;
            final endDate = filterCriteria?['endDate'] as DateTime?;
            var dateMatch = true;
            if (startDate != null && endDate != null) {
              // t.date must be between startDate and endDate (inclusive).
              dateMatch =
                  !t.date.isBefore(startDate) && !t.date.isAfter(endDate);
            }

            return monthMatch && parentMatch && childMatch && dateMatch;
          }).toList()
          // Sort descending: newest first.
          ..sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentTab = index;
    });
  }
}
