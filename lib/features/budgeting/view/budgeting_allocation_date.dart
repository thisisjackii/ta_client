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
import 'package:ta_client/features/budgeting/view/widgets/budgeting_flow_navigation_guard.dart';

class BudgetingAllocationDatePage extends StatefulWidget {
  const BudgetingAllocationDatePage({super.key});
  @override
  _BudgetingAllocationDatePageState createState() =>
      _BudgetingAllocationDatePageState();
}

class _BudgetingAllocationDatePageState
    extends State<BudgetingAllocationDatePage>
    with BudgetingFlowNavigationGuard {
  DateTime? _tempStartDate;
  DateTime? _tempEndDate;
  bool _dialogIsOpen = false;

  @override
  void initState() {
    super.initState();
    final initialState = context.read<BudgetingBloc>().state;
    _tempStartDate = initialState.planStartDate;
    _tempEndDate = initialState.planEndDate;

    if (!(initialState.isEditing &&
        initialState.currentBudgetPlan != null &&
        initialState.planDateConfirmed)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_dialogIsOpen) {
          _showDateSelectionDialog();
        }
      });
    } else if (initialState.isEditing &&
        initialState.currentBudgetPlan != null &&
        initialState.planDateConfirmed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            Routes.budgetingAllocationPage,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _showDateSelectionDialog() async {
    if (_dialogIsOpen) return;
    _dialogIsOpen = true;
    final budgetingBloc = context.read<BudgetingBloc>();

    _tempStartDate = budgetingBloc.state.planStartDate ?? _tempStartDate;
    _tempEndDate = budgetingBloc.state.planEndDate ?? _tempEndDate;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) async {
                if (didPop) return;
                Navigator.of(dialogContext).pop();
                _dialogIsOpen = false;
                await handlePopAttempt(context: this.context, didPop: false);
              },
              child: BlocListener<BudgetingBloc, BudgetingState>(
                bloc: budgetingBloc,
                listenWhen: (prev, curr) =>
                    prev.loading != curr.loading ||
                    curr.planDateConfirmed ||
                    curr.dateError != null ||
                    (curr.error != null && !curr.planDateConfirmed),
                listener: (listenerContext, state) {
                  if (state.dateError != null && !state.loading) {
                    if (Navigator.canPop(dialogContext)) {
                      Navigator.pop(dialogContext);
                    }
                    _dialogIsOpen = false;
                    ScaffoldMessenger.of(listenerContext).showSnackBar(
                      SnackBar(
                        content: Text('Error Tanggal: ${state.dateError}'),
                      ),
                    );
                    budgetingBloc.add(BudgetingClearError());
                    if (mounted && !_dialogIsOpen) _showDateSelectionDialog();
                  } else if (state.error != null &&
                      !state.loading &&
                      !state.planDateConfirmed) {
                    if (Navigator.canPop(dialogContext)) {
                      Navigator.pop(dialogContext);
                    }
                    _dialogIsOpen = false;
                    ScaffoldMessenger.of(listenerContext).showSnackBar(
                      SnackBar(content: Text('Error Periode: ${state.error}')),
                    );
                    budgetingBloc.add(BudgetingClearError());
                    if (mounted && !_dialogIsOpen) _showDateSelectionDialog();
                  } else if (state.planDateConfirmed && !state.loading) {
                    if (Navigator.canPop(dialogContext)) {
                      Navigator.pop(dialogContext);
                    }
                    _dialogIsOpen = false;
                    if (mounted) {
                      Navigator.pushReplacementNamed(
                        this.context,
                        Routes.budgetingAllocationPage,
                      );
                    }
                  }
                },
                child: AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.cardRadius,
                    ),
                  ),
                  title: const Text('Pilih Periode Alokasi Pengeluaran'),
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
                        handleAppBarOrButtonCancel(this.context);
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
                          budgetingBloc.add(
                            BudgetingPlanDateRangeSelected(
                              start: _tempStartDate!,
                              end: _tempEndDate!,
                            ),
                          );
                          // For EvaluationDatePage, the dispatch would be to EvaluationBloc
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
        setState(() {
          _dialogIsOpen = false;
        });
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
          title: const Text('Pilih Periode Alokasi'),
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
                  context.watch<BudgetingBloc>().state.planDateConfirmed)
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text('Memuat detail alokasi untuk diedit...'),
                  ],
                )
              : (_dialogIsOpen
                    ? const CircularProgressIndicator()
                    : const Text('Silakan pilih periode melalui dialog.')),
        ),
      ),
    );
  }
}
