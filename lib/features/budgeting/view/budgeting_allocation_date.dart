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
  final TextEditingController _planDescriptionController =
      TextEditingController(); // DECLARED
  bool _dialogIsOpen = false;

  @override
  void initState() {
    super.initState();
    final initialState = context.read<BudgetingBloc>().state;
    _tempStartDate = initialState.planStartDate;
    _tempEndDate = initialState.planEndDate;
    _planDescriptionController.text = initialState.planDescription ?? '';

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
    _planDescriptionController.dispose(); // DISPOSED
    super.dispose();
  }

  Future<void> _showDateSelectionDialog() async {
    if (_dialogIsOpen) return;
    _dialogIsOpen = true;
    final budgetingBloc = context.read<BudgetingBloc>();

    _planDescriptionController.text =
        budgetingBloc.state.planDescription ?? _planDescriptionController.text;
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
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        // USE IT HERE
                        controller: _planDescriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Rencana (Opsional)',
                          hintText: 'cth: Anggaran April',
                        ),
                      ),
                      const SizedBox(height: 16),
                      BudgetingDateSelection(
                        startDate: _tempStartDate,
                        endDate: _tempEndDate,
                        onStartDateChanged: (date) =>
                            setDialogState(() => _tempStartDate = date),
                        onEndDateChanged: (date) =>
                            setDialogState(() => _tempEndDate = date),
                      ),
                    ],
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
                              planDescription:
                                  _planDescriptionController.text.trim().isEmpty
                                  ? null
                                  : _planDescriptionController.text.trim(),
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
