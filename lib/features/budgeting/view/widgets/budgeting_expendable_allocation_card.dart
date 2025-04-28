// lib/features/budgeting/view/widgets/budgeting_expandable_allocation_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/core/constants/app_dimensions.dart';
import 'package:ta_client/core/constants/app_strings.dart';
import 'package:ta_client/core/utils/calculations.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_bloc.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_event.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_state.dart';

class BudgetingExpandableAllocationCard extends StatelessWidget {
  const BudgetingExpandableAllocationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BudgetingBloc, BudgetingState>(
      builder: (context, state) {
        final total = state.selectedIncomeIds.fold<int>(0, (sum, id) {
          final inc = state.incomes.firstWhere((e) => e.id == id);
          return sum + inc.value;
        });
        return Card(
          margin: const EdgeInsets.only(bottom: AppDimensions.smallPadding),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.all(AppDimensions.padding),
            title: Row(
              children: [
                const Text(
                  AppStrings.expendableAllocationCardTitle,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(formatToRupiah(total.toDouble())),
              ],
            ),
            children: [
              ...state.incomes.map((inc) {
                final selected = state.selectedIncomeIds.contains(inc.id);
                return CheckboxListTile(
                  value: selected,
                  enabled: false,
                  title: Text(inc.title),
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (_) => context
                      .read<BudgetingBloc>()
                      .add(SelectIncomeCategory(inc.id)),
                );
              }),
              // Align(
              //   alignment: Alignment.centerRight,
              //   child: TextButton.icon(
              //     icon: const Icon(Icons.save_alt_rounded, size: 18),
              //     label: const Text(AppStrings.save),
              //     onPressed: () {},
              //   ),
              // ),
            ],
          ),
        );
      },
    );
  }
}
