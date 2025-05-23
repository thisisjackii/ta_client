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
import 'package:ta_client/features/budgeting/view/widgets/budgeting_date_selection.dart'; // Assuming this widget is reused

class BudgetingIncomeDatePage extends StatefulWidget {
  // Renamed for clarity
  const BudgetingIncomeDatePage({super.key});

  @override
  _BudgetingIncomeDatePageState createState() =>
      _BudgetingIncomeDatePageState();
}

class _BudgetingIncomeDatePageState extends State<BudgetingIncomeDatePage> {
  DateTime? _tempStartDate;
  DateTime? _tempEndDate;

  @override
  void initState() {
    super.initState();
    // Initialize temp dates from BLoC state if available (e.g., if user comes back)
    final initialState = context.read<BudgetingBloc>().state;
    _tempStartDate = initialState.incomeCalculationStartDate;
    _tempEndDate = initialState.incomeCalculationEndDate;

    // Clear any previous date confirmation or errors related to income period
    // context.read<BudgetingBloc>().add(BudgetingResetIncomePeriodConfirmation()); // You might need such an event

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showDateSelectionDialog();
    });
  }

  Future<void> _showDateSelectionDialog() async {
    final budgetingBloc = context
        .read<BudgetingBloc>(); // Get BLoC instance once

    await showDialog<void>(
      context: context,
      barrierDismissible: false, // User must confirm or cancel
      builder: (dialogContext) {
        // Use a local StatefulBuilder or a small StatefulWidget for the dialog's internal date state
        // to avoid rebuilding the whole page on every dialog date change.
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return BlocListener<BudgetingBloc, BudgetingState>(
              bloc: budgetingBloc, // Listen to the BLoC from the page
              listenWhen: (prev, curr) =>
                  prev.loading != curr.loading || // Listen for loading changes
                  curr.incomeDateConfirmed || // Listen for confirmation
                  curr.dateError != null || // Listen for date validation errors
                  curr.error !=
                      null, // Listen for general errors from ensureAndGetPeriod
              listener: (listenerContext, state) {
                if (state.dateError != null && !state.loading) {
                  Navigator.pop(
                    dialogContext,
                  ); // Close the date picker dialog first
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Date Error: ${state.dateError}')),
                  );
                  budgetingBloc.add(BudgetingClearError()); // Clear the error
                  _showDateSelectionDialog(); // Re-open dialog
                } else if (state.error != null &&
                    !state.loading &&
                    !state.incomeDateConfirmed) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Period Error: ${state.error}')),
                  );
                  budgetingBloc.add(BudgetingClearError());
                  _showDateSelectionDialog();
                } else if (state.incomeDateConfirmed && !state.loading) {
                  Navigator.pop(dialogContext); // Close this dialog
                  Navigator.pushReplacementNamed(
                    context,
                    Routes.budgetingIncome,
                  );
                }
              },
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                ),
                title: const Text('Pilih Periode Pemasukan'),
                contentPadding: const EdgeInsets.all(24),
                content: BudgetingDateSelection(
                  startDate:
                      _tempStartDate ??
                      budgetingBloc.state.incomeCalculationStartDate,
                  endDate:
                      _tempEndDate ??
                      budgetingBloc.state.incomeCalculationEndDate,
                  onStartDateChanged: (date) =>
                      setDialogState(() => _tempStartDate = date),
                  onEndDateChanged: (date) =>
                      setDialogState(() => _tempEndDate = date),
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text(AppStrings.cancel),
                    onPressed: () {
                      Navigator.pop(dialogContext); // Close dialog
                      Navigator.pop(
                        context,
                      ); // Go back from BudgetingIncomeDatePage itself
                    },
                  ),
                  ElevatedButton(
                    child:
                        budgetingBloc.state.loading &&
                            !budgetingBloc.state.incomeDateConfirmed
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(AppStrings.ok),
                    onPressed: () {
                      if (_tempStartDate != null && _tempEndDate != null) {
                        budgetingBloc.add(
                          BudgetingIncomeDateRangeSelected(
                            start: _tempStartDate!,
                            end: _tempEndDate!,
                            // periodId: budgetingBloc.state.incomePeriodId, // Pass if editing an existing period's dates
                          ),
                        );
                        // Don't pop here, listener will handle it upon state.incomeDateConfirmed
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
      // If dialog is dismissed by back button before confirmation, navigate back from page
      if (!budgetingBloc.state.incomeDateConfirmed && mounted) {
        // Check if mounted before popping, in case the page itself was disposed.
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // This page primarily shows a dialog. The Scaffold is a fallback or loading container.
    return const Scaffold(
      body: Center(
        // Show a loading indicator if BLoC is busy from previous screen or initial dialog logic
        child: CircularProgressIndicator(),
      ),
    );
  }
}
