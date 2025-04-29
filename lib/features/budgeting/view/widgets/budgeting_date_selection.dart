// lib/features/budgeting/view/widgets/budgeting_date_selection.dart
import 'package:flutter/material.dart';
import 'package:ta_client/core/widgets/custom_date_picker.dart';

typedef DateChanged = void Function(DateTime);

class BudgetingDateSelection extends StatelessWidget {
  const BudgetingDateSelection({
    super.key,
    this.startDate,
    this.endDate,
    this.onStartDateChanged,
    this.onEndDateChanged,
  });

  /// Either the income or expense start date
  final DateTime? startDate;

  /// Either the income or expense end date
  final DateTime? endDate;

  /// Fired when user picks a new start date
  final DateChanged? onStartDateChanged;

  /// Fired when user picks a new end date
  final DateChanged? onEndDateChanged;

  @override
  Widget build(BuildContext c) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomDatePicker(
          label: 'Start Date',
          isDatePicker: true,
          selectedDate: startDate,
          onDateChanged: onStartDateChanged,
        ),
        const SizedBox(height: 8),
        CustomDatePicker(
          label: 'End Date',
          isDatePicker: true,
          selectedDate: endDate,
          onDateChanged: onEndDateChanged,
        ),
      ],
    );
  }
}
