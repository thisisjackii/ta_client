// lib/features/budgeting/view/budgeting_income_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/app/routes/routes.dart';
import 'package:ta_client/core/constants/app_colors.dart';
import 'package:ta_client/core/constants/app_dimensions.dart';
import 'package:ta_client/core/constants/app_strings.dart';
import 'package:ta_client/core/utils/calculations.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_bloc.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_event.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_state.dart';

class BudgetingIncome extends StatelessWidget {
  const BudgetingIncome({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BudgetingBloc, BudgetingState>(
        builder: (context, state) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.budgetingTitle),
          backgroundColor: AppColors.primary,
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppDimensions.padding),
          children: [
            const Text(
              AppStrings.incomeSelectionTitle,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.smallPadding),
            ...state.incomes.map((inc) {
              final selected = state.selectedIncomeIds.contains(inc.id);
              return Padding(
                padding:
                    const EdgeInsets.only(bottom: AppDimensions.smallPadding),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.smallPadding),),
                  child: ListTile(
                    leading: Checkbox(
                        value: selected,
                        onChanged: (_) => context
                            .read<BudgetingBloc>()
                            .add(SelectIncomeCategory(inc.id)),
                        shape: const CircleBorder(),),
                    title:
                        Text(inc.title, style: const TextStyle(fontSize: 12)),
                    subtitle: Text(formatToRupiah(inc.value),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold,),),
                  ),
                ),
              );
            }),
            if (state.selectedIncomeIds.isNotEmpty) ...[
              Card(
                color: AppColors.dateCardBackground,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.cardRadius),),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.padding),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(AppStrings.total,
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold,),),
                      Text(
                          formatToRupiah(state.selectedIncomeIds.fold<int>(
                              0,
                              (sum, id) =>
                                  sum +
                                  state.incomes
                                      .firstWhere((i) => i.id == id)
                                      .value,),),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,),),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppDimensions.smallPadding),
            const Text(AppStrings.calculationNote,
                style: TextStyle(fontSize: 8, color: Colors.grey),),
            const SizedBox(height: AppDimensions.padding),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pushNamed(context, Routes.budgetingAllocationDate),
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text(AppStrings.start,
                  style: TextStyle(color: Colors.white),),
            ),
          ],
        ),
      );
    },);
  }
}
