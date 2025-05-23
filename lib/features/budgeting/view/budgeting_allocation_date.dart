// lib/features/budgeting/view/budgeting_allocation_date.dart
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

class BudgetingAllocationDatePage extends StatefulWidget {
  // Renamed
  const BudgetingAllocationDatePage({super.key});
  @override
  _BudgetingAllocationDatePageState createState() =>
      _BudgetingAllocationDatePageState();
}

class _BudgetingAllocationDatePageState
    extends State<BudgetingAllocationDatePage> {
  DateTime? _tempStartDate;
  DateTime? _tempEndDate;

  @override
  void initState() {
    super.initState();
    final initialState = context.read<BudgetingBloc>().state;
    _tempStartDate = initialState.planStartDate;
    _tempEndDate = initialState.planEndDate;
    // context.read<BudgetingBloc>().add(BudgetingResetExpensePeriodConfirmation());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showDateSelectionDialog();
    });
  }

  Future<void> _showDateSelectionDialog() async {
    final budgetingBloc = context.read<BudgetingBloc>();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return BlocListener<BudgetingBloc, BudgetingState>(
              bloc: budgetingBloc,
              listenWhen: (prev, curr) =>
                  prev.loading != curr.loading ||
                  curr.planDateConfirmed ||
                  curr.dateError != null ||
                  curr.error != null,
              listener: (listenerContext, state) {
                if (state.dateError != null && !state.loading) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Date Error: ${state.dateError}')),
                  );
                  budgetingBloc.add(BudgetingClearError());
                  _showDateSelectionDialog();
                } else if (state.error != null &&
                    !state.loading &&
                    !state.planDateConfirmed) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Period Error: ${state.error}')),
                  );
                  budgetingBloc.add(BudgetingClearError());
                  _showDateSelectionDialog();
                } else if (state.planDateConfirmed && !state.loading) {
                  Navigator.pop(dialogContext);
                  Navigator.pushReplacementNamed(
                    context,
                    Routes.budgetingAllocationPage,
                  );
                }
              },
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                ),
                title: const Text('Pilih Periode Alokasi Pengeluaran'),
                contentPadding: const EdgeInsets.all(24),
                content: BudgetingDateSelection(
                  startDate:
                      _tempStartDate ?? budgetingBloc.state.planStartDate,
                  endDate: _tempEndDate ?? budgetingBloc.state.planEndDate,
                  onStartDateChanged: (date) =>
                      setDialogState(() => _tempStartDate = date),
                  onEndDateChanged: (date) =>
                      setDialogState(() => _tempEndDate = date),
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text(AppStrings.cancel),
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      Navigator.pop(
                        context,
                      ); // Back from BudgetingAllocationDatePage
                    },
                  ),
                  ElevatedButton(
                    child:
                        budgetingBloc.state.loading &&
                            !budgetingBloc.state.planDateConfirmed
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(AppStrings.ok),
                    onPressed: () {
                      if (_tempStartDate != null && _tempEndDate != null) {
                        budgetingBloc.add(
                          BudgetingPlanDateRangeSelected(
                            start: _tempStartDate!,
                            end: _tempEndDate!,
                            // periodId: budgetingBloc.state.expensePeriodId, // If editing
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Silakan pilih tanggal mulai dan akhir.',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      if (!budgetingBloc.state.planDateConfirmed && mounted) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
