// lib/features/budgeting/view/budgeting_allocation_expense.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/app/routes/routes.dart';
import 'package:ta_client/core/constants/app_colors.dart';
import 'package:ta_client/core/constants/app_dimensions.dart';
import 'package:ta_client/core/constants/app_strings.dart';
// No longer need category_mapping.dart, suggestions provide subcategories
import 'package:ta_client/features/budgeting/bloc/budgeting_bloc.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_event.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_state.dart';

class BudgetingAllocationExpense extends StatelessWidget {
  const BudgetingAllocationExpense({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BudgetingBloc, BudgetingState>(
      listenWhen: (prev, curr) =>
          curr.saveSuccess || curr.error != null || curr.infoMessage != null,
      listener: (context, state) {
        if (state.saveSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.infoMessage ?? 'Rencana anggaran berhasil disimpan!',
              ),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate to dashboard after successful save
          Navigator.pushNamedAndRemoveUntil(
            context,
            Routes.budgetingDashboard,
            (route) => false,
          ); // Clears stack
        } else if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!), backgroundColor: Colors.red),
          );
          context.read<BudgetingBloc>().add(BudgetingClearError());
        } else if (state.infoMessage != null) {
          // For "queued for sync" messages
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.infoMessage!)));
          context.read<BudgetingBloc>().add(BudgetingClearError());
          // Still navigate to dashboard, UI can show pending state there
          Navigator.pushNamedAndRemoveUntil(
            context,
            Routes.budgetingDashboard,
            (route) => false,
          );
        }
      },
      builder: (context, state) {
        // Get the full suggestion objects for selected categories
        final selectedCategorySuggestions = state.expenseCategorySuggestions
            .where(
              (suggestion) =>
                  state.selectedExpenseCategoryIds.contains(suggestion.id),
            )
            .toList();

        if (state.loading &&
            selectedCategorySuggestions.isEmpty &&
            !state.saveSuccess) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.budgetingTitle)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (!state.planDateConfirmed) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.budgetingTitle)),
            body: const Center(
              child: Text('Periode pengeluaran belum diatur.'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              AppStrings.budgetingTitle,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.greyBackground,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppDimensions.padding),
            children: [
              const Text(
                AppStrings.allocationExpenseDescription,
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: AppDimensions.padding),

              if (selectedCategorySuggestions.isEmpty)
                const Center(
                  child: Text(
                    'Tidak ada kategori pengeluaran yang dipilih untuk alokasi.',
                  ),
                ),

              ...selectedCategorySuggestions.map((suggestion) {
                final categoryId = suggestion.id;
                final categoryName = suggestion.name;
                final subItems =
                    suggestion.subcategories; // List<SimpleSubcategory>
                final allocatedPercentage =
                    state.expenseAllocationPercentages[categoryId] ?? 0.0;

                if (allocatedPercentage == 0) {
                  return const SizedBox.shrink(); // Don't show categories with 0% allocation
                }

                return ExpansionTile(
                  key: PageStorageKey<String>(categoryId),
                  maintainState: true,
                  title: Text(
                    '$categoryName (${allocatedPercentage.toStringAsFixed(0)}%)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  initiallyExpanded: true,
                  children: subItems.map((sub) {
                    // sub is SimpleSubcategory
                    final isChecked =
                        state.selectedExpenseSubItems[categoryId]?.contains(
                          sub['id'],
                        ) ??
                        false;
                    return CheckboxListTile(
                      key: ValueKey('${categoryId}_${sub['id']}'),
                      controlAffinity: ListTileControlAffinity.leading,
                      value: isChecked,
                      title: Text(sub['name'] as String),
                      onChanged: (val) {
                        context.read<BudgetingBloc>().add(
                          BudgetingToggleExpenseSubItem(
                            parentCategoryId: categoryId,
                            subcategoryId: sub['id'] as String,
                            isSelected: val ?? false,
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              }),

              const SizedBox(height: AppDimensions.padding),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed: state.loading
                      ? null
                      : () {
                          // Add validation: at least one subcategory must be selected for each category that has >0% allocation
                          var allAllocatedCategoriesHaveSubcategories = true;
                          for (final catId
                              in state.selectedExpenseCategoryIds) {
                            final percentage =
                                state.expenseAllocationPercentages[catId] ??
                                0.0;
                            final selectedSubs =
                                state.selectedExpenseSubItems[catId] ?? [];
                            if (percentage > 0 && selectedSubs.isEmpty) {
                              allAllocatedCategoriesHaveSubcategories = false;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Pilih minimal satu subkategori untuk "$catId" yang dialokasikan.',
                                  ),
                                ),
                              );
                              break;
                            }
                          }
                          if (allAllocatedCategoriesHaveSubcategories) {
                            context.read<BudgetingBloc>().add(
                              const BudgetingSaveExpensePlan(),
                            );
                          }
                        },
                  child: state.loading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          AppStrings.save,
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
