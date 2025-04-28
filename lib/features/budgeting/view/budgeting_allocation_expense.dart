// lib/features/budgeting/view/budgeting_allocation_expense.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/app/routes/routes.dart';
import 'package:ta_client/core/constants/app_colors.dart';
import 'package:ta_client/core/constants/app_dimensions.dart';
import 'package:ta_client/core/constants/app_strings.dart';
import 'package:ta_client/core/constants/category_mapping.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_bloc.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_event.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_state.dart';

class BudgetingAllocationExpense extends StatelessWidget {
  const BudgetingAllocationExpense({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BudgetingBloc, BudgetingState>(
      builder: (context, state) {
        // Filter to only allocations whose category title was selected
        final selectedAllocations = state.allocations
            .where(
              (alloc) => state.selectedCategories.contains(alloc.title),
            )
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.budgetingTitle),
            backgroundColor: AppColors.primary,
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppDimensions.padding),
            children: [
              const Text(
                AppStrings.total,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppDimensions.smallPadding),
              const Text(
                AppStrings.allocationExpenseDescription,
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: AppDimensions.smallPadding),

              // Only show ExpansionTiles for the categories the user selected
              ...selectedAllocations.map((alloc) {
                final title = alloc.title;
                final subItems = categoryMapping[title] ?? <String>[];
                return ExpansionTile(
                  key: PageStorageKey<String>(
                    title,
                  ), // preserves expansion state across scroll
                  maintainState:
                      true, // retains child widget state when collapsed
                  title: Text(title),
                  children: subItems.map((sub) {
                    final isChecked =
                        state.selectedSubExpenses[title]?.contains(sub) ??
                            false;
                    return CheckboxListTile(
                      key:
                          ValueKey('${title}_$sub}'), // unique key per checkbox
                      controlAffinity: ListTileControlAffinity
                          .leading, // checkbox on the left
                      contentPadding: EdgeInsets.zero, // consistent tap area
                      value: isChecked,
                      title: Text(sub),
                      onChanged: (val) {
                        context.read<BudgetingBloc>().add(
                              ToggleExpenseSubItem(
                                allocationId: alloc.id,
                                subItem: sub,
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
                  onPressed: () =>
                      Navigator.pushNamed(context, Routes.budgetingDashboard),
                  child: const Text(
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
