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

class BudgetingAllocationDate extends StatefulWidget {
  const BudgetingAllocationDate({super.key});
  @override
  _BudgetingAllocationDateState createState() =>
      _BudgetingAllocationDateState();
}

class _BudgetingAllocationDateState extends State<BudgetingAllocationDate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // reset the expense‐date flag before showing the dialog
      context.read<BudgetingBloc>().add(ResetExpenseDateConfirmation());
      _showDatePickerModal();
    });
  }

  Future<void> _showDatePickerModal() async {
    final parentCtx = context;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return BlocConsumer<BudgetingBloc, BudgetingState>(
          listenWhen: (prev, cur) =>
              prev.expenseDateConfirmed != cur.expenseDateConfirmed ||
              prev.dateError != cur.dateError,
          listener: (blocCtx, state) {
            if (state.dateError != null) {
              // show error alert
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
            } else if (state.expenseDateConfirmed) {
              // close the date picker
              Navigator.pop(dialogCtx);
              // 👉 route to the **allocation** page first (not straight to expense)
              Navigator.pushReplacementNamed(
                parentCtx,
                Routes.budgetingAllocationPage,
              );
            }
          },
          builder: (_, state) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
              ),
              contentPadding: const EdgeInsets.all(24),
              content: BudgetingDateSelection(
                // wire up the EXPENSE fields & events:
                startDate: state.expenseStartDate,
                endDate: state.expenseEndDate,
                onStartDateChanged: (d) => dialogCtx.read<BudgetingBloc>().add(
                  ExpenseStartDateChanged(d),
                ),
                onEndDateChanged: (d) => dialogCtx.read<BudgetingBloc>().add(
                  ExpenseEndDateChanged(d),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text(AppStrings.cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    final s = state.expenseStartDate;
                    final e = state.expenseEndDate;
                    if (s == null || e == null) {
                      showDialog<void>(
                        context: dialogCtx,
                        builder: (_) => AlertDialog(
                          title: const Text('Gagal'),
                          content: const Text(
                            'Kamu harus memilih tanggal mulai dan akhir.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogCtx),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                      return;
                    }
                    dialogCtx.read<BudgetingBloc>().add(
                      ConfirmExpenseDateRange(start: s, end: e),
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
  Widget build(BuildContext context) => const Scaffold();
}
