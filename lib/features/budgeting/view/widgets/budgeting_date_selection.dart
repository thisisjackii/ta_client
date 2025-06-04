// lib/features/budgeting/view/widgets/budgeting_date_selection.dart
import 'package:flutter/material.dart';
import 'package:ta_client/core/widgets/custom_date_picker.dart';

typedef DateChanged =
    void Function(DateTime? date); // Allow null for clearing or initial state

class BudgetingDateSelection extends StatefulWidget {
  const BudgetingDateSelection({
    super.key,
    this.initialStartDate, // Renamed from startDate for clarity
    this.initialEndDate, // Renamed from endDate for clarity
    this.onStartDateChanged,
    this.onEndDateChanged,
  });

  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final DateChanged? onStartDateChanged;
  final DateChanged? onEndDateChanged;

  @override
  State<BudgetingDateSelection> createState() => _BudgetingDateSelectionState();
}

class _BudgetingDateSelectionState extends State<BudgetingDateSelection> {
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  @override
  void initState() {
    super.initState();
    _selectedStartDate = widget.initialStartDate;
    _selectedEndDate = widget.initialEndDate;
  }

  // This is important if the dialog is rebuilt with new initial dates from the BLoC
  @override
  void didUpdateWidget(BudgetingDateSelection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialStartDate != oldWidget.initialStartDate) {
      _selectedStartDate = widget.initialStartDate;
    }
    if (widget.initialEndDate != oldWidget.initialEndDate) {
      _selectedEndDate = widget.initialEndDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomDatePicker(
          label: 'Start Date',
          isDatePicker: true,
          selectedDate: _selectedStartDate,
          lastDate:
              _selectedEndDate, // End date picker is constrained by selected start date
          onDateChanged: (date) {
            setState(() {
              _selectedStartDate = date;
              // If new start date is after current end date, adjust end date
              if (_selectedEndDate != null && date.isAfter(_selectedEndDate!)) {
                _selectedEndDate = date;
                widget.onEndDateChanged?.call(
                  _selectedEndDate,
                ); // Notify parent
              }
            });
            widget.onStartDateChanged?.call(
              date,
            ); // Notify parent of start date change
          },
        ),
        const SizedBox(height: 8),
        CustomDatePicker(
          label: 'End Date',
          isDatePicker: true,
          selectedDate: _selectedEndDate,
          firstDate:
              _selectedStartDate, // Start date picker is constrained by selected end date
          onDateChanged: (date) {
            setState(() {
              _selectedEndDate = date;
              // If new end date is before current start date, adjust start date
              if (_selectedStartDate != null &&
                  date.isBefore(_selectedStartDate!)) {
                _selectedStartDate = date;
                widget.onStartDateChanged?.call(
                  _selectedStartDate,
                ); // Notify parent
              }
            });
            widget.onEndDateChanged?.call(
              date,
            ); // Notify parent of end date change
          },
        ),
      ],
    );
  }
}
