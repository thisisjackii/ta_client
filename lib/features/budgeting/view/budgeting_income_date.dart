// lib/features/budgeting/view/budgeting_income_date.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/app/routes/routes.dart';
import 'package:ta_client/core/constants/app_colors.dart';
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

class _BudgetingIncomeDateState extends State<BudgetingIncomeDate>
    with RouteAware {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showDialog());
  }

  Future<void> _showDialog() async {
    context.read<BudgetingBloc>().add(ResetDateConfirmation());
    final parentCtx = context;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return BlocConsumer<BudgetingBloc, BudgetingState>(
          listenWhen: (p, c) =>
              p.dateError != c.dateError || p.dateConfirmed != c.dateConfirmed,
          listener: (_, st) {
            if (st.dateError != null) {
              showDialog<void>(
                context: dialogCtx,
                builder: (context) => AlertDialog(
                  title: const Text('Gagal'),
                  content: Text(st.dateError!),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            } else if (st.dateConfirmed) {
              Navigator.pop(dialogCtx);
              Navigator.pushNamed(parentCtx, Routes.budgetingIncome);
            }
          },
          builder: (_, __) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
              ),
              contentPadding: const EdgeInsets.all(24),
              content: const BudgetingDateSelection(),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text(AppStrings.cancel),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed: () {
                    final st = context.read<BudgetingBloc>().state;
                    context.read<BudgetingBloc>().add(
                          ConfirmDateRange(
                            start: st.startDate!,
                            end: st.endDate!,
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
