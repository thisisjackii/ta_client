// lib/features/budgeting/view/budgeting_income_date.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/app/routes/routes.dart';
import 'package:ta_client/core/constants/app_dimensions.dart';
import 'package:ta_client/core/constants/app_strings.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_bloc.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_event.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_state.dart';
import 'package:ta_client/features/budgeting/view/widgets/budgeting_date_selection.dart';

class BudgetingIncomeDate extends StatefulWidget {
  const BudgetingIncomeDate({super.key});

  @override
  _BudgetingIncomeDateState createState() => _BudgetingIncomeDateState();
}

class _BudgetingIncomeDateState extends State<BudgetingIncomeDate> {
  @override
  void initState() {
    super.initState();
    // Clear out any previous income‐date confirmation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BudgetingBloc>().add(ResetIncomeDateConfirmation());
      _showDialog();
    });
  }

  Future<void> _showDialog() async {
    final parentCtx = context;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return BlocConsumer<BudgetingBloc, BudgetingState>(
          listenWhen: (prev, cur) =>
              prev.incomeDateConfirmed != cur.incomeDateConfirmed ||
              prev.dateError != cur.dateError,
          listener: (ctx, state) {
            if (state.dateError != null) {
              // Show date‐error
              showDialog<void>(
                context: dialogCtx,
                builder: (_) => AlertDialog(
                  title: const Text('Gagal'),
                  content: Text(state.dateError!),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            } else if (state.incomeDateConfirmed) {
              // Close dialog, then go to the actual income page
              Navigator.pop(dialogCtx);
              Navigator.pushReplacementNamed(parentCtx, Routes.budgetingIncome);
            }
          },
          builder: (_, state) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
              ),
              contentPadding: const EdgeInsets.all(24),
              content: BudgetingDateSelection(
                // **IMPORTANT** use the income fields & events
                startDate: state.incomeStartDate,
                endDate: state.incomeEndDate,
                onStartDateChanged: (d) => dialogCtx.read<BudgetingBloc>().add(
                  IncomeStartDateChanged(d),
                ),
                onEndDateChanged: (d) => dialogCtx.read<BudgetingBloc>().add(
                  IncomeEndDateChanged(d),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text(AppStrings.cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    final st = context.read<BudgetingBloc>().state;
                    dialogCtx.read<BudgetingBloc>().add(
                      ConfirmIncomeDateRange(
                        start: st.incomeStartDate!,
                        end: st.incomeEndDate!,
                      ),
                    );
                  },
                  child: const Text(AppStrings.ok),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext c) => const Scaffold();
}
