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
        final allocations = state.allocations;
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
              ...allocations.map((alloc) {
                final title = alloc.title;
                final subItems = categoryMapping[title] ?? <String>[];
                return ExpansionTile(
                  title: Text(title),
                  children: subItems.map((sub) {
                    // you can wire onChanged to bloc if needed
                    return CheckboxListTile(
                      value:
                          state.selectedSubExpenses[alloc.id]?.contains(sub) ??
                              false,
                      title: Text(sub),
                      onChanged: (val) {
                        context.read<BudgetingBloc>().add(
                              ToggleExpenseSubItem(
                                  allocationId: alloc.id,
                                  subItem: sub,
                                  isSelected: val ?? false,),
                            );
                      },
                    );
                  }).toList(),
                );
              }),
              const SizedBox(height: AppDimensions.padding),
              ElevatedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, Routes.budgetingDashboard),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,),
                child: const Text(
                  AppStrings.save,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
