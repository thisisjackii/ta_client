// lib/features/budgeting/view/budgeting_income_date.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ta_client/app/routes/routes.dart';
import 'package:ta_client/core/constants/app_colors.dart';
import 'package:ta_client/core/constants/app_dimensions.dart';
import 'package:ta_client/core/constants/app_strings.dart';
import 'package:ta_client/features/budgeting/view/widgets/budgeting_date_selection.dart';

class BudgetingIncomeDate extends StatefulWidget {
  const BudgetingIncomeDate({super.key});

  @override
  State<BudgetingIncomeDate> createState() => _BudgetingIncomeDateState();
}

class _BudgetingIncomeDateState extends State<BudgetingIncomeDate> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 300), _showDatePickerModal);
  }

  void _showDatePickerModal() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.cardRadius),),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          content: const BudgetingDateSelection(),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(AppStrings.cancel),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, Routes.budgetingIncome);
              },
              child: const Text(AppStrings.ok),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}
