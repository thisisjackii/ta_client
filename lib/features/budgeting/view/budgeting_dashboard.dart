// lib/features/budgeting/view/budgeting_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:ta_client/app/routes/routes.dart';
import 'package:ta_client/core/constants/app_colors.dart';
import 'package:ta_client/core/constants/app_dimensions.dart';
import 'package:ta_client/core/utils/calculations.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_bloc.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_event.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_state.dart';
import 'package:ta_client/features/budgeting/services/budgeting_service.dart'
    show FrontendBudgetAllocation, FrontendBudgetPlan; // For typing
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

  void _startEditPlan(BuildContext context, FrontendBudgetPlan plan) {
    context.read<BudgetingBloc>().add(BudgetingStartEdit(planId: plan.id));
    // Navigate to the first step of budgeting, BLoC will prefill from the loaded plan
    Navigator.pushNamed(context, Routes.budgetingIncomeDate);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BudgetingBloc, BudgetingState>(
      // Changed to BlocConsumer
      listenWhen: (prev, curr) =>
          curr.error != null || curr.infoMessage != null || curr.saveSuccess,
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!), backgroundColor: Colors.red),
          );
          context.read<BudgetingBloc>().add(BudgetingClearError());
        }
        if (state.infoMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.infoMessage!)));
          context.read<BudgetingBloc>().add(BudgetingClearInfoMessage());
        }
        if (state.saveSuccess) {
          // After a direct dashboard edit leads to save
          // Optionally show a success message, or just let the UI rebuild
          context.read<BudgetingBloc>().add(
            const BudgetingClearStatus(),
          ); // Reset saveSuccess flag
        }
      },
      builder: (context, budgetState) {
        return BlocBuilder<
          TxDashboardBloc.DashboardBloc,
          TxDashboardBloc.DashboardState
        >(
          builder: (txContext, txState) {
            final currentPlan = budgetState.currentBudgetPlan;

            if (budgetState.loading && currentPlan == null) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text(
                    // planDescription,
                    'Rencana Anggaran',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: AppColors.greyBackground,
                ),
                body: const Center(child: CircularProgressIndicator()),
              );
            }

            if (currentPlan == null) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text(
                    // planDescription,
                    'Rencana Anggaran',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: AppColors.greyBackground,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () =>
                        Navigator.of(context).popAndPushNamed(Routes.dashboard),
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
                title: const Text(
                  // planDescription,
                  'Rencana Anggaran',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                backgroundColor: AppColors.greyBackground,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () =>
                      Navigator.of(context).popAndPushNamed(Routes.dashboard),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_note),
                    tooltip: 'Ubah Rencana Ini',
                    onPressed:
                        budgetState
                            .loading // Disable if bloc is busy
                        ? null
                        : () => _startEditPlan(context, currentPlan),
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
                  context.read<BudgetingBloc>().add(
                    BudgetingLoadPlanDetails(planId: currentPlan.id),
                  );
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

                      // Check for spending to disable interactions (TC-63, TC-67)
                      // This check needs to be accurate.
                      // `budgetState.initialSpendingForEditedPlan` is populated when `BudgetingStartEdit` runs.
                      // For dashboard view, this might not be populated unless we explicitly load it.
                      // Let's assume `currentSpendingForCategory` is a good proxy for "has progress" for now.
                      final categoryHasProgress =
                          currentSpendingForCategory > 0;

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

                      return Dismissible(
                        key: ValueKey<String>(
                          categoryId,
                        ), // Unique key for Dismissible
                        direction:
                            DismissDirection.endToStart, // Swipe left to delete
                        confirmDismiss: (direction) async {
                          if (categoryHasProgress) {
                            _showAlertDialog(
                              'Tidak Dapat Menghapus',
                              'Kategori "$parentCategoryName" tidak dapat dihapus karena sudah memiliki progres pengeluaran.',
                            );
                            return false; // Prevent dismissal
                          }
                          final result = await QuickAlert.show(
                            context: context,
                            type: QuickAlertType.confirm,
                            title: 'Hapus Alokasi Kategori?',
                            text:
                                'Anda yakin ingin menghapus alokasi untuk "$parentCategoryName"?',
                            confirmBtnText: 'Ya, Hapus',
                            cancelBtnText: 'Batal',
                            onConfirmBtnTap: () => Navigator.of(
                              context,
                              rootNavigator: true,
                            ).pop(true),
                            onCancelBtnTap: () => Navigator.of(
                              context,
                              rootNavigator: true,
                            ).pop(false),
                          );
                          return (result as bool?) ?? false;
                        },
                        onDismissed: (direction) {
                          if (!categoryHasProgress) {
                            context.read<BudgetingBloc>().add(
                              BudgetingDeleteCategoryAllocation(
                                categoryId: categoryId,
                              ),
                            );
                          }
                        },
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: Card(
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
                              final isChecked = subAllocationsInCat.any(
                                (sa) =>
                                    sa.subcategoryId == subAlloc.subcategoryId,
                              );
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
                              return CheckboxListTile(
                                dense: true,
                                title: Row(
                                  // Use Row to place amount on the right
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(subAlloc.subcategoryName),
                                    ),
                                    Text(
                                      formatToRupiah(
                                        currentSpendingForSubcategory,
                                      ),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                                value: isChecked,
                                onChanged:
                                    categoryHasProgress // Disable if parent category has progress
                                    ? null
                                    : (bool? newValue) {
                                        if (newValue != null) {
                                          // Show confirmation for subcategory change
                                          QuickAlert.show(
                                            context: context,
                                            type: QuickAlertType.confirm,
                                            title: 'Ubah Subkategori?',
                                            text:
                                                "Anda yakin ingin ${newValue ? 'memasukkan' : 'mengeluarkan'} subkategori '${subAlloc.subcategoryName}' dari alokasi ini?",
                                            confirmBtnText: 'Ya',
                                            cancelBtnText: 'Batal',
                                            onConfirmBtnTap: () {
                                              Navigator.of(
                                                context,
                                                rootNavigator: true,
                                              ).pop(); // Dismiss alert
                                              context.read<BudgetingBloc>().add(
                                                BudgetingToggleDashboardSubItem(
                                                  parentCategoryId: categoryId,
                                                  subcategoryId:
                                                      subAlloc.subcategoryId,
                                                  isSelected: newValue,
                                                ),
                                              );
                                            },
                                            onCancelBtnTap: () => Navigator.of(
                                              context,
                                              rootNavigator: true,
                                            ).pop(),
                                          );
                                        }
                                      },
                              );
                            }).toList(),
                          ),
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

// Helper for FrontendBudgetAllocation to include selected sub-items for its category
// This is conceptual. The actual `FrontendBudgetAllocation` model and how
// `selectedExpenseSubItems` is mapped to it when loading/saving a plan needs to be consistent.
// For the dashboard view, `currentPlan.allocations` would need to be structured so each category's
// allocation detail also lists its *selected* subcategories for this plan.
// If `FrontendBudgetAllocation` only represents one subcategory's portion, then the `CheckboxListTile`
// `value` logic would be simpler (checking if that specific `subAlloc.subcategoryId` is part of the plan's
// list of *active* subcategories under this category).

// Let's refine FrontendBudgetAllocation and its use:
// Assumed modification to FrontendBudgetAllocation or how it's used:
// When a plan is loaded (FrontendBudgetPlan), its `allocations` list contains
// `FrontendBudgetAllocation` objects. Each object now might represent a *category-level* allocation
// and contain a list of its *selected subcategory IDs* for that plan.

// If FrontendBudgetAllocation remains per-subcategory:
// Then to get `isChecked` for `CheckboxListTile`:
// final bool isChecked = subAllocationsInCat.any((sa) => sa.subcategoryId == subAlloc.subcategoryId);
// This seems more direct given the existing model.
