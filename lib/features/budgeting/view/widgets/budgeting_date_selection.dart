// lib/features/budgeting/view/widgets/budgeting_date_selection.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/core/constants/app_dimensions.dart';
import 'package:ta_client/core/constants/app_strings.dart';
import 'package:ta_client/core/widgets/custom_date_picker.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_bloc.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_event.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_state.dart';

class BudgetingDateSelection extends StatelessWidget {
  const BudgetingDateSelection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BudgetingBloc, BudgetingState>(
      builder: (context, state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding:
                    const EdgeInsets.only(bottom: AppDimensions.smallPadding),
                child: Text(
                  context.read<BudgetingBloc>().state.startDate == null
                      ? AppStrings.selectDateIncome
                      : AppStrings.selectDateAllocation,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: CustomDatePicker(
                    label: 'Start Date',
                    isDatePicker: true,
                    selectedDate: state.startDate,
                    onDateChanged: (d) =>
                        context.read<BudgetingBloc>().add(StartDateChanged(d)),
                  ),
                ),
                const SizedBox(width: AppDimensions.padding),
                Expanded(
                  child: CustomDatePicker(
                    label: 'End Date',
                    isDatePicker: true,
                    selectedDate: state.endDate,
                    onDateChanged: (d) =>
                        context.read<BudgetingBloc>().add(EndDateChanged(d)),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
