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
  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  Map<String, dynamic>? filterCriteria;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyBackground,
      appBar: CustomAppBar(
        isSelectionMode: isSelectionMode,
        selectedMonth: selectedMonth,
        filterCriteria: filterCriteria,
        onMonthChanged: updateSelectedMonth,
        onFilterChanged: updateFilterCriteria,
        onShowDoubleEntryRecap: () {
          final dashboardState = context.read<DashboardBloc>().state;
          if (dashboardState is DashboardLoaded) {
            Navigator.pushNamed(
              context,
              Routes.doubleEntryRecapPage,
              arguments: dashboardState.items,
            );
          }
        },
      ),
      body: BlocConsumer<DashboardBloc, DashboardState>(
        listener: (context, state) {
          if (state is DashboardUnauthenticated) {
            // The Dio interceptor + AuthState should handle actual logout and token clearing.
            // This listener just reacts to navigate.
            Navigator.pushNamedAndRemoveUntil(
              context,
              Routes.login,
              (route) => false,
            );
          }
          // Potentially show snackbar for state.isSyncing if DashboardLoading contains it
          if (state is DashboardLoading && state.isSyncing) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sinkronisasi data...'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is DashboardLoading &&
              state.items.isEmpty &&
              !state.isSyncing) {
            // Only show full loading if no items and not just syncing
            return const Center(child: CircularProgressIndicator());
          } else if (state is DashboardLoaded ||
              (state is DashboardLoading && state.items.isNotEmpty)) {
            // Show content if loaded OR if loading but we have previous items
            final itemsToDisplay = state is DashboardLoaded
                ? state.items
                : (state as DashboardLoading).items;
            final filteredItems = _filterAndSortTransactions(itemsToDisplay);

            final totalPemasukan = filteredItems
                .where((t) => t.accountTypeName?.toLowerCase() == 'pemasukan')
                .fold<double>(0, (sum, t) => sum + t.amount);
            final totalPengeluaran = filteredItems
                .where((t) => t.accountTypeName?.toLowerCase() == 'pengeluaran')
                .fold<double>(0, (sum, t) => sum + t.amount);
            final formattedPemasukan = formatToRupiah(totalPemasukan);
            final formattedPengeluaran = formatToRupiah(totalPengeluaran);
            final formattedAkhir = formatToRupiah(
              totalPemasukan - totalPengeluaran,
            );

            return RefreshIndicator(
              onRefresh: () async {
                context.read<DashboardBloc>().add(
                  DashboardForceRefreshRequested(),
                );
              },
              child: Column(
                children: [
                  TransactionTotalsSummary(
                    pemasukan: formattedPemasukan,
                    pengeluaran: formattedPengeluaran,
                    total: formattedAkhir,
                  ),
                  if (state is DashboardLoading && state.isSyncing)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Sinkronisasi...',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: filteredItems.isEmpty
                        ? Center(
                            child: Text(
                              'Tidak ada transaksi untuk periode ini.',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          )
                        : TransactionGroupedItemsWidget(
                            items: filteredItems,
                            isSelectionMode: isSelectionMode,
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
                    onPressed: () => context.read<DashboardBloc>().add(
                      DashboardLoadRequested(),
                    ),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }
          return const Center(
            child: Text('Mohon tunggu...'),
          ); // Fallback for other initial states
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Tambah Transaksi',
        onPressed: () async {
          final result = await Navigator.pushNamed(
            context,
            Routes.createTransaction,
          );
          if (mounted) {
            // Check if widget is still in the tree
            if (result is Transaction) {
              // If TransactionBloc successfully created a transaction, it emits new state.
              // DashboardBloc should listen to TransactionBloc or be updated by a shared service/event.
              // For direct update:
              context.read<DashboardBloc>().add(
                DashboardTransactionCreated(result),
              );
            } else if (result == true) {
              // Or some other signal that a change happened
              context.read<DashboardBloc>().add(
                DashboardForceRefreshRequested(),
              ); // General refresh
            }
            // No 'else' needed if no specific action for other results
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

  void updateFilterCriteria(Map<String, dynamic>? criteria) {
    setState(() {
      filterCriteria = criteria;
      final startDate = criteria?['startDate'] as DateTime?;
      // final endDate = criteria?['endDate'] as DateTime?; // Not directly used for selectedMonth here
      if (startDate != null) {
        selectedMonth = DateTime(startDate.year, startDate.month);
      }
      // No explicit reload here, filtering happens in _filterAndSortTransactions
    });
  }

  void updateSelectedMonth(DateTime newMonth) {
    setState(() {
      selectedMonth = DateTime(newMonth.year, newMonth.month);
      // Clear date range from filterCriteria if month is changed via arrows/picker
      // to avoid conflicting filters, unless you want to keep them.
      if (filterCriteria != null) {
        filterCriteria!.remove('startDate');
        filterCriteria!.remove('endDate');
      }
    });
  }

  List<Transaction> _filterAndSortTransactions(List<Transaction> transactions) {
    return transactions.where((t) {
      var matches = true;

      // Date Range from filterCriteria takes precedence
      final filterStartDate = filterCriteria?['startDate'] as DateTime?;
      final filterEndDate = filterCriteria?['endDate'] as DateTime?;

      if (filterStartDate != null && filterEndDate != null) {
        matches =
            matches &&
            !t.date.isBefore(filterStartDate) &&
            !t.date.isAfter(
              filterEndDate
                  .add(const Duration(days: 1))
                  .subtract(const Duration(microseconds: 1)),
            );
      } else if (filterStartDate != null) {
        matches = matches && !t.date.isBefore(filterStartDate);
      } else if (filterEndDate != null) {
        matches =
            matches &&
            !t.date.isAfter(
              filterEndDate
                  .add(const Duration(days: 1))
                  .subtract(const Duration(microseconds: 1)),
            );
      } else {
        // Fallback to selectedMonth filter if no date range from filterCriteria
        matches =
            matches &&
            t.date.year == selectedMonth.year &&
            t.date.month == selectedMonth.month;
      }

      if (!matches) return false; // Early exit if date doesn't match

      final parentCategoryFilter = filterCriteria?['parent'] as String?;
      if (parentCategoryFilter != null && parentCategoryFilter.isNotEmpty) {
        matches =
            matches &&
            t.accountTypeName?.toLowerCase() ==
                parentCategoryFilter.toLowerCase();
      }
      if (!matches) return false;

      final childCategoryFilter = filterCriteria?['child'] as String?;
      if (childCategoryFilter != null && childCategoryFilter.isNotEmpty) {
        matches =
            matches &&
            t.categoryName?.toLowerCase() == childCategoryFilter.toLowerCase();
        // Note: DFD shows 'child' as Kategori, but your code implies 'categoryName' is the Kategori,
        // and 'accountTypeName' is the parent (Tipe Akun). This seems consistent.
      }
      if (!matches) return false;

      final bookmarkedOnly = filterCriteria?['bookmarked'] as bool? ?? false;
      if (bookmarkedOnly) {
        matches = matches && t.isBookmarked;
      }
      return matches;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  void _onTabSelected(int index) {
    if (_currentTab == index && index == 0) {
      // If already on Home and Home is selected
      context.read<DashboardBloc>().add(
        DashboardSyncPendingRequested(),
      ); // Trigger sync
    } else {
      setState(() {
        _currentTab = index;
      });
    }
    // Navigation logic for other tabs
    if (index != 0) {
      // Prevent re-navigating to dashboard if already on it
      switch (index) {
        // case 0: Navigator.pushReplacementNamed(context, Routes.dashboard); break; // Already handled by setstate/rebuild
        case 1:
          Navigator.pushNamed(context, Routes.evaluationIntro);
        case 2:
          Navigator.pushNamed(context, Routes.budgetingIntro);
        case 3:
          Navigator.pushNamed(context, Routes.profilePage);
      }
    }
  }
}
