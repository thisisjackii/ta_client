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
import 'package:ta_client/features/budgeting/view/widgets/budgeting_flow_navigation_guard.dart';

class BudgetingIncomeDatePage extends StatefulWidget {
  const BudgetingIncomeDatePage({super.key});
  @override
  _BudgetingIncomeDatePageState createState() =>
      _BudgetingIncomeDatePageState();
}

class _BudgetingIncomeDatePageState extends State<BudgetingIncomeDatePage>
    with BudgetingFlowNavigationGuard {
  DateTime? _tempStartDate;
  DateTime? _tempEndDate;
  bool _dialogIsOpen = false;

  @override
  void initState() {
    super.initState();
    final initialState = context.read<BudgetingBloc>().state;
    _tempStartDate = initialState.incomeCalculationStartDate;
    _tempEndDate = initialState.incomeCalculationEndDate;

    if (!(initialState.isEditing &&
        initialState.currentBudgetPlan != null &&
        initialState.incomeDateConfirmed)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_dialogIsOpen) {
          _showDateSelectionDialog();
        }
      });
    } else if (initialState.isEditing &&
        initialState.currentBudgetPlan != null &&
        initialState.incomeDateConfirmed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, Routes.budgetingIncome);
        }
      });
    }
  }

  Future<void> _showDateSelectionDialog() async {
    if (_dialogIsOpen) return;
    _dialogIsOpen = true;
    final budgetingBloc = context.read<BudgetingBloc>();

    // Sync page-level temp dates with BLoC state if dialog is reopened
    // These are what BudgetingDateSelection will initially display.
    _tempStartDate =
        budgetingBloc.state.incomeCalculationStartDate ??
        _tempStartDate; // For income page
    _tempEndDate =
        budgetingBloc.state.incomeCalculationEndDate ??
        _tempEndDate; // For income page

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          // This StatefulBuilder is for the AlertDialog content
          builder: (BuildContext alertContext, StateSetter setDialogState) {
            // Use alertContext
            return PopScope(
              // Guard the dialog itself from accidental dismiss without confirmation
              canPop:
                  false, // Initially false, meaning onPopInvokedWithResult will be called
              onPopInvokedWithResult: (didPop, result) async {
                if (didPop) return;
                // User tried to dismiss dialog (e.g. system back), trigger main page's guard
                Navigator.of(dialogContext).pop(); // Close this dialog first
                _dialogIsOpen = false;
                await handlePopAttempt(
                  context: context,
                  didPop: false,
                ); // Use page context
              },
              child: BlocListener<BudgetingBloc, BudgetingState>(
                bloc: budgetingBloc,
                listenWhen: (prev, curr) =>
                    prev.loading != curr.loading ||
                    curr.incomeDateConfirmed ||
                    curr.dateError != null ||
                    (curr.error != null && !curr.incomeDateConfirmed),
                listener: (listenerContext, state) {
                  if (state.dateError != null && !state.loading) {
                    if (Navigator.canPop(dialogContext)) {
                      Navigator.pop(dialogContext);
                    }
                    _dialogIsOpen = false;
                    ScaffoldMessenger.of(listenerContext).showSnackBar(
                      // Use listenerContext for SnackBar
                      SnackBar(
                        content: Text('Error Tanggal: ${state.dateError}'),
                      ),
                    );
                    budgetingBloc.add(BudgetingClearError());
                    if (mounted && !_dialogIsOpen) _showDateSelectionDialog();
                  } else if (state.error != null &&
                      !state.loading &&
                      !state.incomeDateConfirmed) {
                    if (Navigator.canPop(dialogContext)) {
                      Navigator.pop(dialogContext);
                    }
                    _dialogIsOpen = false;
                    ScaffoldMessenger.of(listenerContext).showSnackBar(
                      SnackBar(content: Text('Error Periode: ${state.error}')),
                    );
                    budgetingBloc.add(BudgetingClearError());
                    if (mounted && !_dialogIsOpen) _showDateSelectionDialog();
                  } else if (state.incomeDateConfirmed && !state.loading) {
                    if (Navigator.canPop(dialogContext)) {
                      Navigator.pop(dialogContext);
                    }
                    _dialogIsOpen = false;
                    if (mounted) {
                      Navigator.pushReplacementNamed(
                        context,
                        Routes.budgetingIncome,
                      ); // Use page context
                    }
                  }
                },
                child: AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.cardRadius,
                    ),
                  ),
                  title: const Text('Pilih Periode Pemasukan'),
                  contentPadding: const EdgeInsets.all(24),
                  content: BudgetingDateSelection(
                    initialStartDate: _tempStartDate, // Pass page's temp date
                    initialEndDate: _tempEndDate, // Pass page's temp date
                    onStartDateChanged: (date) {
                      // This callback is from BudgetingDateSelection
                      // It updates the page's _tempStartDate,
                      // which then rebuilds the AlertDialog via setDialogState
                      setDialogState(() {
                        _tempStartDate = date;
                        // If the new start date makes the end date invalid, adjust end date
                        if (_tempEndDate != null &&
                            date != null &&
                            date.isAfter(_tempEndDate!)) {
                          _tempEndDate = date;
                        }
                      });
                    },
                    onEndDateChanged: (date) {
                      setDialogState(() {
                        _tempEndDate = date;
                        // If the new end date makes the start date invalid, adjust start date
                        if (_tempStartDate != null &&
                            date != null &&
                            date.isBefore(_tempStartDate!)) {
                          _tempStartDate = date;
                        }
                      });
                    },
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: const Text(AppStrings.cancel),
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        _dialogIsOpen = false;
                        handleAppBarOrButtonCancel(context);
                      },
                    ),
                    ElevatedButton(
                      child:
                          budgetingBloc.state.loading &&
                              !(budgetingBloc.state.incomeDateConfirmed ||
                                  budgetingBloc
                                      .state
                                      .planDateConfirmed) // Check correct confirmed flag
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(AppStrings.ok),
                      onPressed: () {
                        // Validation still happens here using the page's _tempStartDate and _tempEndDate
                        if (_tempStartDate != null && _tempEndDate != null) {
                          if (_tempEndDate!.isBefore(_tempStartDate!)) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Tanggal akhir tidak boleh sebelum tanggal mulai.',
                                ),
                              ),
                            );
                            return;
                          }
                          // Add other page-specific validations (e.g., 1-month rule for evaluation)

                          // Dispatch to BLoC
                          // Check page type
                          budgetingBloc.add(
                            BudgetingIncomeDateRangeSelected(
                              start: _tempStartDate!,
                              end: _tempEndDate!,
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
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      if (mounted) {
        // Ensure widget is still mounted
        setState(() {
          // Reflect that dialog is no longer open
          _dialogIsOpen = false;
        });
        // If dialog was dismissed without confirming dates (e.g. if barrierDismissible was true)
        // and the BLoC state doesn't reflect confirmed dates, trigger the page's pop guard.
        // This handles cases where the user might tap outside a dismissible dialog.
        // However, with barrierDismissible: false, this .whenComplete block primarily serves
        // to reset _dialogIsOpen. The explicit cancel/ok buttons handle navigation.
        final currentBlocState = context.read<BudgetingBloc>().state;
        if (!currentBlocState.incomeDateConfirmed &&
            !currentBlocState.isEditing) {
          // If still not confirmed and not in an editing flow that might bypass this dialog
          // handleAppBarOrButtonCancel(this.context); // Potentially trigger guard if flow was abandoned
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canPopBudgetingFlow(context),
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        // Matched to onPopInvokedWithResult by ignoring result
        if (didPop) return;
        await handlePopAttempt(
          context: context,
          didPop: didPop,
        ); // Pass null for result
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pilih Periode Pemasukan'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => handleAppBarOrButtonCancel(context),
          ),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child:
              (context.watch<BudgetingBloc>().state.isEditing &&
                  context.watch<BudgetingBloc>().state.currentBudgetPlan !=
                      null &&
                  context.watch<BudgetingBloc>().state.incomeDateConfirmed)
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text('Memuat data pemasukan untuk diedit...'),
                  ],
                )
              : (_dialogIsOpen // Show loading if dialog is supposed to be open but content is just a placeholder
                    ? const CircularProgressIndicator()
                    : const Text('Silakan pilih periode melalui dialog.')),
        ),
      ),
    );
  }
}
