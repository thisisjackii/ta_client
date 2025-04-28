// lib/features/budgeting/view/widgets/budgeting_date_selection.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/core/widgets/custom_date_picker.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_bloc.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_event.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_state.dart';

class BudgetingDateSelection extends StatelessWidget {
  const BudgetingDateSelection({super.key});
  @override
  Widget build(BuildContext c) {
    return BlocBuilder<BudgetingBloc, BudgetingState>(
      builder: (ctx, state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomDatePicker(
              label: 'Start Date',
              isDatePicker: true,
              selectedDate: state.startDate,
              onDateChanged: (d) =>
                  ctx.read<BudgetingBloc>().add(StartDateChanged(d)),
            ),
            const SizedBox(height: 8),
            CustomDatePicker(
              label: 'End Date',
              isDatePicker: true,
              selectedDate: state.endDate,
              onDateChanged: (d) =>
                  ctx.read<BudgetingBloc>().add(EndDateChanged(d)),
            ),
          ],
        );
      },
    );
  }
}
