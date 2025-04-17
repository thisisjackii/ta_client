import 'package:flutter/material.dart';
import 'package:ta_client/core/widgets/custom_date_picker.dart';

class CustomDateRangeSelector extends StatelessWidget {
  final String title;
  final bool isIncome;
  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<DateTime?> onStartDateChanged;
  final ValueChanged<DateTime?> onEndDateChanged;

  const CustomDateRangeSelector({
    super.key,
    required this.title,
    required this.isIncome,
    required this.startDate,
    required this.endDate,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ),

        // Date pickers
        Row(
          children: [
            // PUT IN HERE
          ],
        ),
      ],
    );
  }
}
