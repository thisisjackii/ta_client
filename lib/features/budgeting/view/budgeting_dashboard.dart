// lib/features/budgeting/view/budgeting_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:ta_client/app/routes/routes.dart';
import 'package:ta_client/core/constants/app_colors.dart';
import 'package:ta_client/core/constants/app_dimensions.dart';
import 'package:ta_client/core/utils/calculations.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_bloc.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_event.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_state.dart';
import 'package:ta_client/features/budgeting/services/budgeting_service.dart'
    show FrontendBudgetAllocation; // For typing
import 'package:ta_client/features/budgeting/view/widgets/budgeting_expendable_allocation_card.dart';
import 'package:ta_client/features/transaction/bloc/dashboard_bloc.dart'
    as TxDashboardBloc;
import 'package:ta_client/features/transaction/models/transaction.dart'
    as TxModel;

class BudgetingDashboard extends StatefulWidget {
  const BudgetingDashboard({super.key});

  @override
  State<BudgetingDashboard> createState() => _BudgetingDashboardState();
}

class _BudgetingDashboardState extends State<BudgetingDashboard> {
  final Set<String> _sessionWarned90CategoryIds = {};
  final Set<String> _sessionAlerted100CategoryIds = {};

  @override
  void initState() {
    super.initState();
    final budgetingState = context.read<BudgetingBloc>().state;
    // If there's a currentBudgetPlan, ensure its data is up-to-date
    // Or if navigating here without a plan, prompt to create or select one.
    if (budgetingState.currentBudgetPlan == null &&
        !budgetingState.loading &&
        budgetingState.error == null) {
      context.read<BudgetingBloc>().add(BudgetingLoadUserPlans());
    } else if (budgetingState.currentBudgetPlan?.id != null) {
      // Potentially refresh its allocations if needed, or rely on data from save
      context.read<BudgetingBloc>().add(
        BudgetingLoadPlanDetails(planId: budgetingState.currentBudgetPlan!.id),
      );
    } else if (budgetingState.planDateConfirmed) {
      // If dates were set but no plan yet (e.g. after save error)
      // This scenario should ideally resolve to either a currentBudgetPlan or an error state
      // For now, if no currentBudgetPlan, it will show "no plan" message.
    }

    context.read<TxDashboardBloc.DashboardBloc>().add(
      TxDashboardBloc.DashboardLoadRequested(),
    );
  }

  void _showNotificationSnackBar(String message, Color backgroundColor) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
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
        return BlocBuilder<
          TxDashboardBloc.DashboardBloc,
          TxDashboardBloc.DashboardState
        >(
          builder: (txContext, txState) {
            final currentPlan = budgetState.currentBudgetPlan;

            if (budgetState.loading && currentPlan == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('Rangkuman Anggaran')),
                body: const Center(child: CircularProgressIndicator()),
              );
            }

            if (currentPlan == null) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Anggaran'),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(
                      context,
                    ).popUntil((route) => route.isFirst),
                  ),
                ),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Belum ada rencana anggaran aktif.'),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          context.read<BudgetingBloc>().add(
                            BudgetingResetState(),
                          ); // Reset for new plan
                          Navigator.pushNamed(
                            context,
                            Routes.budgetingIncomeDate,
                          );
                        },
                        child: const Text('Buat Rencana Anggaran Baru'),
                      ),
                      // TODO: Add button to load existing plans if that feature is added
                    ],
                  ),
                ),
              );
            }

            var currentPeriodTransactions = <TxModel.Transaction>[];
            if (txState is TxDashboardBloc.DashboardLoaded) {
              currentPeriodTransactions = txState.items
                  .where(
                    (tx) =>
                        tx.accountTypeName?.toLowerCase() == 'pengeluaran' &&
                        !tx.date.isBefore(currentPlan.planStartDate) &&
                        !tx.date.isAfter(
                          currentPlan.planEndDate
                              .add(const Duration(days: 1))
                              .subtract(const Duration(microseconds: 1)),
                        ),
                  )
                  .toList();
            }

            // Group FrontendBudgetAllocation by categoryId for display
            final groupedAllocations =
                <String, List<FrontendBudgetAllocation>>{};
            for (final alloc in currentPlan.allocations) {
              groupedAllocations
                  .putIfAbsent(alloc.categoryId, () => [])
                  .add(alloc);
            }

            final dateFormat = DateFormat('dd/MM/yyyy');
            final planDateRange =
                '${dateFormat.format(currentPlan.planStartDate)} - ${dateFormat.format(currentPlan.planEndDate)}';
            final incomeCalcDateRange =
                '${dateFormat.format(currentPlan.incomeCalculationStartDate)} - ${dateFormat.format(currentPlan.incomeCalculationEndDate)}';
            final planDescription = currentPlan.description?.isNotEmpty ?? false
                ? currentPlan.description!
                : 'Rencana Anggaran';

            return Scaffold(
              appBar: AppBar(
                title: Text(
                  planDescription,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: AppColors.greyBackground,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_note),
                    tooltip: 'Ubah Rencana Ini',
                    onPressed: () {
                      // TODO: Navigate to the start of budgeting flow, pre-populating with currentPlan details
                      // This requires BLoC to have an "edit existing plan" mode/event
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fitur edit belum diimplementasikan.'),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Buat Rencana Baru',
                    onPressed: () {
                      context.read<BudgetingBloc>().add(BudgetingResetState());
                      Navigator.pushNamed(context, Routes.budgetingIncomeDate);
                    },
                  ),
                ],
              ),
              body: RefreshIndicator(
                onRefresh: () async {
                  // context.read<BudgetingBloc>().add(
                  //   BudgetingLoadExistingAllocations(
                  //     periodId: currentPlan.id,
                  //   ), // Assuming ID can be used to reload
                  // );
                  context.read<TxDashboardBloc.DashboardBloc>().add(
                    TxDashboardBloc.DashboardForceRefreshRequested(),
                  );
                },
                child: ListView(
                  padding: const EdgeInsets.all(AppDimensions.padding),
                  children: [
                    Text(
                      'Periode Rencana: $planDateRange',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'Periode Pemasukan: $incomeCalcDateRange',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: AppDimensions.smallPadding),
                    const BudgetingExpandableAllocationCard(), // Shows selected income for the plan
                    const SizedBox(height: AppDimensions.padding),
                    Text(
                      'Total Anggaran Pengeluaran: ${formatToRupiah(currentPlan.totalCalculatedIncome * groupedAllocations.values.fold(0.0, (sum, list) => sum + (list.firstOrNull?.percentage ?? 0.0)) / 100)}', // This needs re-eval based on how total is stored
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    if (currentPlan.isLocal)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Rencana ini belum tersinkronisasi.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    const SizedBox(height: AppDimensions.padding),

                    if (groupedAllocations.isEmpty && !budgetState.loading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Belum ada alokasi untuk rencana ini.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                    ...groupedAllocations.entries.map((entry) {
                      // ... (Card UI for each allocation, same as before, using currentPlan.totalCalculatedIncome for parentCategoryBudgetAmount)
                      final categoryId = entry.key;
                      final subAllocationsInCat = entry.value;
                      if (subAllocationsInCat.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      final parentCategoryName =
                          subAllocationsInCat.first.categoryName;
                      // Amount on FrontendBudgetAllocation is already the category's total allocated amount
                      final parentCategoryBudgetAmount =
                          subAllocationsInCat.first.amount;

                      final subcategoryIdsForThisCategory = subAllocationsInCat
                          .map((sa) => sa.subcategoryId)
                          .toList();
                      final currentSpendingForCategory =
                          currentPeriodTransactions
                              .where(
                                (tx) => subcategoryIdsForThisCategory.contains(
                                  tx.subcategoryId,
                                ),
                              )
                              .fold(0.toDouble(), (sum, tx) => sum + tx.amount);

                      final ratio = parentCategoryBudgetAmount == 0
                          ? 0.0
                          : currentSpendingForCategory /
                                parentCategoryBudgetAmount;
                      final percent = ratio * 100;
                      final Color barColor = percent <= 32
                          ? Colors.green
                          : (percent <= 65 ? Colors.orange : Colors.red);

                      if (parentCategoryBudgetAmount > 0) {
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
                            !_sessionWarned90CategoryIds.contains(categoryId)) {
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
                          key: PageStorageKey<String>(categoryId),
                          title: Row(
                            children: [
                              Icon(
                                Icons.label_important_outline,
                                color: Theme.of(context).primaryColor,
                              ),
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
                          children: subAllocationsInCat.map((subAlloc) {
                            final currentSpendingForSubcategory =
                                currentPeriodTransactions
                                    .where(
                                      (tx) =>
                                          tx.subcategoryId ==
                                          subAlloc.subcategoryId,
                                    )
                                    .fold(
                                      0.toDouble(),
                                      (sum, tx) => sum + tx.amount,
                                    );
                            return ListTile(
                              dense: true,
                              title: Text(subAlloc.subcategoryName),
                              trailing: Text(
                                formatToRupiah(currentSpendingForSubcategory),
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
              ),
            );
          },
        );
      },
    );
  }
}
