// lib/features/budgeting/view/budgeting_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:ta_client/core/constants/app_colors.dart';
import 'package:ta_client/core/constants/app_dimensions.dart';
import 'package:ta_client/core/utils/calculations.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_bloc.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_event.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_state.dart';
import 'package:ta_client/features/budgeting/services/budgeting_service.dart'
    show FrontendBudgetAllocation; // For typing
import 'package:ta_client/features/budgeting/view/widgets/budgeting_expendable_allocation_card.dart';
// For Transaction data to calculate current spending
import 'package:ta_client/features/transaction/bloc/dashboard_bloc.dart'
    as TxDashboardBloc; // Aliased
import 'package:ta_client/features/transaction/models/transaction.dart'
    as TxModel; // Aliased

class BudgetingDashboard extends StatefulWidget {
  const BudgetingDashboard({super.key});

  @override
  State<BudgetingDashboard> createState() => _BudgetingDashboardState();
}

class _BudgetingDashboardState extends State<BudgetingDashboard> {
  // These are now managed by backend timestamps on BudgetAllocation,
  // but client might still want session-based flags to avoid immediate re-alert if user stays on page.
  final Set<String> _sessionWarned90CategoryIds = {};
  final Set<String> _sessionAlerted100CategoryIds = {};

  @override
  void initState() {
    super.initState();
    // Ensure data is loaded if navigating directly or after a save
    final budgetingState = context.read<BudgetingBloc>().state;
    if (budgetingState.expensePeriodId != null &&
        budgetingState.expensePeriodId!.isNotEmpty) {
      context.read<BudgetingBloc>().add(
        BudgetingLoadExistingAllocations(
          periodId: budgetingState.expensePeriodId!,
        ),
      );
      // Also refresh income summary for display
      if (budgetingState.incomePeriodId != null &&
          budgetingState.incomePeriodId!.isNotEmpty) {
        context.read<BudgetingBloc>().add(
          BudgetingLoadIncomeSummary(periodId: budgetingState.incomePeriodId!),
        );
      }
    }
    // Also fetch transactions for spending calculation
    context.read<TxDashboardBloc.DashboardBloc>().add(
      TxDashboardBloc.DashboardLoadRequested(),
    );
  }

  void _showNotificationSnackBar(String message, Color backgroundColor) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Check if the widget is still in the tree
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });
  }

  void _showAlertDialog(String title, String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BudgetingBloc, BudgetingState>(
      builder: (context, budgetState) {
        // For current spending, we need transactions from DashboardBloc
        return BlocBuilder<
          TxDashboardBloc.DashboardBloc,
          TxDashboardBloc.DashboardState
        >(
          builder: (txContext, txState) {
            var currentPeriodTransactions = <TxModel.Transaction>[];
            if (txState is TxDashboardBloc.DashboardLoaded &&
                budgetState.expenseStartDate != null &&
                budgetState.expenseEndDate != null) {
              currentPeriodTransactions = txState.items
                  .where(
                    (tx) =>
                        tx.accountTypeName?.toLowerCase() == 'pengeluaran' &&
                        !tx.date.isBefore(budgetState.expenseStartDate!) &&
                        !tx.date.isAfter(
                          budgetState.expenseEndDate!
                              .add(const Duration(days: 1))
                              .subtract(const Duration(microseconds: 1)),
                        ),
                  )
                  .toList();
            }

            // Group FrontendBudgetAllocation by categoryId for display
            final groupedAllocations =
                <String, List<FrontendBudgetAllocation>>{};
            double totalBudgetedAmount = 0;

            for (final alloc in budgetState.currentAllocations) {
              groupedAllocations
                  .putIfAbsent(alloc.categoryId, () => [])
                  .add(alloc);
            }
            // Calculate total budgeted amount (sum of unique parent category amounts)
            final processedCategoryIdsForTotal = <String>{};
            for (final alloc in budgetState.currentAllocations) {
              if (!processedCategoryIdsForTotal.contains(alloc.categoryId)) {
                totalBudgetedAmount +=
                    alloc.amount; // amount is the parent category's total
                processedCategoryIdsForTotal.add(alloc.categoryId);
              }
            }

            return Scaffold(
              appBar: AppBar(
                title: const Text('Rangkuman Anggaran Anda'),
                backgroundColor: AppColors.greyBackground,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                ),
              ),
              body:
                  budgetState.loading && budgetState.currentAllocations.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.all(AppDimensions.padding),
                      children: [
                        const BudgetingExpandableAllocationCard(), // Shows total income based on BLoC state
                        Center(
                          child: Card(
                            /* ... Date display card ... */
                            color: AppColors.dateCardBackground,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.cardRadius,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDimensions.padding,
                                vertical: AppDimensions.smallPadding,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.date_range,
                                    size: AppDimensions.iconSize,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(
                                    width: AppDimensions.smallPadding,
                                  ),
                                  Text(
                                    '${budgetState.expenseStartDate != null ? DateFormat('dd/MM/yyyy').format(budgetState.expenseStartDate!) : '--'}'
                                    ' - '
                                    '${budgetState.expenseEndDate != null ? DateFormat('dd/MM/yyyy').format(budgetState.expenseEndDate!) : '--'}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.padding),
                        Text(
                          'Total Anggaran Pengeluaran: ${formatToRupiah(totalBudgetedAmount)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.padding),

                        if (groupedAllocations.isEmpty && !budgetState.loading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'Belum ada rencana anggaran untuk periode ini.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),

                        ...groupedAllocations.entries.map((entry) {
                          final categoryId = entry.key;
                          final subAllocations = entry.value;
                          if (subAllocations.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          final parentCategoryBudgetAmount = subAllocations
                              .first
                              .amount; // All share same parent amount
                          final parentCategoryName =
                              subAllocations.first.categoryName;

                          final subcategoryIdsForThisCategory = subAllocations
                              .map((sa) => sa.subcategoryId)
                              .toList();

                          final currentSpendingForCategory =
                              currentPeriodTransactions
                                  .where(
                                    (tx) => subcategoryIdsForThisCategory
                                        .contains(tx.subcategoryId),
                                  )
                                  .fold(
                                    0.toDouble(),
                                    (sum, tx) => sum + tx.amount,
                                  );

                          final ratio = parentCategoryBudgetAmount == 0
                              ? 0.0
                              : currentSpendingForCategory /
                                    parentCategoryBudgetAmount;
                          final percent = ratio * 100;
                          final Color barColor = percent <= 32
                              ? Colors.green
                              : (percent <= 65 ? Colors.orange : Colors.red);

                          // Notification Logic Check
                          if (parentCategoryBudgetAmount > 0) {
                            // Only check if there's a budget
                            if (percent >= 100 &&
                                !_sessionAlerted100CategoryIds.contains(
                                  categoryId,
                                )) {
                              _sessionAlerted100CategoryIds.add(categoryId);
                              _showAlertDialog(
                                'Anggaran Terlampaui!',
                                'Pengeluaran untuk "$parentCategoryName" telah mencapai atau melebihi 100%!',
                              );
                            } else if (percent >= 90 &&
                                percent < 100 &&
                                !_sessionWarned90CategoryIds.contains(
                                  categoryId,
                                )) {
                              _sessionWarned90CategoryIds.add(categoryId);
                              _showNotificationSnackBar(
                                '⚠️ Anggaran "$parentCategoryName" sudah mencapai ${percent.toStringAsFixed(0)}%!',
                                Colors.orange[700]!,
                              );
                            }
                          }

                          return Card(
                            margin: const EdgeInsets.only(
                              bottom: AppDimensions.smallPadding,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.cardRadius,
                              ),
                            ),
                            child: ExpansionTile(
                              key: PageStorageKey<String>(
                                categoryId,
                              ), // For preserving expansion state
                              title: Row(
                                children: [
                                  Icon(
                                    Icons.label_important_outline,
                                    color: Theme.of(context).primaryColor,
                                  ), // Example icon
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      parentCategoryName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${formatToRupiah(currentSpendingForCategory)} / ${formatToRupiah(parentCategoryBudgetAmount)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: LinearProgressIndicator(
                                value: ratio.clamp(0.0, 1.0),
                                backgroundColor: AppColors.greyBackground,
                                valueColor: AlwaysStoppedAnimation(barColor),
                              ),
                              children: subAllocations.map((subAlloc) {
                                // Find spending for this specific subcategory
                                final currentSpendingForSubcategory =
                                    currentPeriodTransactions
                                        .where(
                                          (tx) =>
                                              tx.subcategoryId ==
                                              subAlloc.subcategoryId,
                                        )
                                        .fold(0.toDouble(), (sum, tx) => sum + tx.amount);

                                return ListTile(
                                  dense: true,
                                  title: Text(subAlloc.subcategoryName),
                                  trailing: Text(
                                    // Displaying subcategory spending. The subAlloc.amount is PARENT's budget.
                                    formatToRupiah(
                                      currentSpendingForSubcategory,
                                    ),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        }),
                      ],
                    ),
            );
          },
        );
      },
    );
  }
}
