import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ta_client/core/widgets/custom_date_picker.dart';
import 'package:ta_client/app/routes/routes.dart';

class EvaluationDateSelection extends StatefulWidget {
  const EvaluationDateSelection({super.key});

  @override
  State<EvaluationDateSelection> createState() => _EvaluationDateSelectionState();
}

class _EvaluationDateSelectionState extends State<EvaluationDateSelection> {
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      _showDatePickerModal();
    });
  }

  void _showDatePickerModal() {
    showDialog(
      context: context,
      barrierDismissible: false, // Optional: block outside tap to dismiss
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Pilih Rentang Tanggal',
                    style: TextStyle(
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
                  Expanded(
                    child: CustomDatePicker(
                      label: 'Start Date',
                      isDatePicker: true,
                      onDateChanged: (date) {
                        setState(() {
                          startDate = date;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomDatePicker(
                      label: 'End Date',
                      isDatePicker: true,
                      onDateChanged: (date) {
                        setState(() {
                          endDate = date;
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pushNamed(context, Routes.evaluationDashboard);
                      },
                      child: const Text('OK'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('')),
    );
  }
}
