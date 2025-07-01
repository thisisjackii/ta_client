// lib/features/evaluation/view/evaluation_date_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/app/routes/routes.dart';
import 'package:ta_client/core/constants/app_dimensions.dart';
import 'package:ta_client/core/constants/app_strings.dart';
import 'package:ta_client/core/widgets/custom_date_picker.dart';
import 'package:ta_client/features/evaluation/bloc/evaluation_bloc.dart';
import 'package:ta_client/features/evaluation/bloc/evaluation_event.dart';
import 'package:ta_client/features/evaluation/bloc/evaluation_state.dart';

class EvaluationDatePage extends StatefulWidget {
  const EvaluationDatePage({super.key});
  @override
  _EvaluationDatePageState createState() => _EvaluationDatePageState();
}

class _EvaluationDatePageState extends State<EvaluationDatePage>
    with RouteAware {
  DateTime? _tempStartDateDialog;
  DateTime? _tempEndDateDialog;
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>?
  _snackBarController;
  // This flag will specifically track if the *date picker* dialog is open.
  bool _isDatePickerDialogOpen = false;
  // This flag will specifically track if the *choice* dialog is open.
  bool _isChoiceDialogOpen = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final initialBlocState = context.read<EvaluationBloc>().state;

    _tempStartDateDialog =
        initialBlocState.tempSelectedStartDate ??
        initialBlocState.evaluationStartDate ??
        DateTime(now.year, now.month);
    _tempEndDateDialog =
        initialBlocState.tempSelectedEndDate ??
        initialBlocState.evaluationEndDate ??
        _lastDayOfMonth(DateTime(now.year, now.month));

    context.read<EvaluationBloc>().add(EvaluationClearDateError());
    context.read<EvaluationBloc>().add(EvaluationClearError());
    context.read<EvaluationBloc>().add(EvaluationCancelDuplicateWarning());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only open date dialog if no other dialog is supposed to be open
      // and we are not in a conflict state from a previous action.
      if (mounted &&
          !_isDatePickerDialogOpen &&
          !_isChoiceDialogOpen &&
          !context.read<EvaluationBloc>().state.dateConflictExists) {
        _openDateDialog();
      }
    });
  }

  DateTime _lastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  bool isAtLeastOneMonthApart(DateTime start, DateTime end) {
    if (end.isBefore(start)) return false;
    final normStart = DateUtils.dateOnly(start);
    final normEnd = DateUtils.dateOnly(end);
    if (DateUtils.isSameMonth(normStart, normEnd)) {
      final isFirstDay = normStart.day == 1;
      final isLastDay = normEnd.day == _lastDayOfMonth(normStart).day;
      return isFirstDay && isLastDay;
    }
    final oneMonthAfterStartAnchor = DateUtils.addMonthsToMonthDate(
      normStart,
      1,
    );
    if (normEnd.year > oneMonthAfterStartAnchor.year ||
        (normEnd.year == oneMonthAfterStartAnchor.year &&
            normEnd.month > oneMonthAfterStartAnchor.month)) {
      return true;
    }
    if (DateUtils.isSameMonth(normEnd, oneMonthAfterStartAnchor)) {
      return normEnd.day >= normStart.day;
    }
    return false;
  }

  Future<void> _openDateDialog() async {
    if (_isDatePickerDialogOpen || _isChoiceDialogOpen) {
      return; // Prevent re-entry if any dialog is open
    }
    _isDatePickerDialogOpen = true;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    final evaluationBloc = context.read<EvaluationBloc>();

    _tempStartDateDialog =
        evaluationBloc.state.tempSelectedStartDate ??
        evaluationBloc.state.evaluationStartDate ??
        _tempStartDateDialog;
    _tempEndDateDialog =
        evaluationBloc.state.tempSelectedEndDate ??
        evaluationBloc.state.evaluationEndDate ??
        _tempEndDateDialog;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (datePickerDialogContext) => StatefulBuilder(
        builder: (BuildContext alertContext, StateSetter setDialogState) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              Navigator.of(datePickerDialogContext).pop();
              // _isDatePickerDialogOpen set to false in whenComplete
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, Routes.dashboard);
              }
            },
            child: AlertDialog(
              title: const Text(AppStrings.dateRangePrompt),
              content: Column(
                /* ... CustomDatePickers ... */
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomDatePicker(
                    label: 'Start Date',
                    isDatePicker: true,
                    selectedDate: _tempStartDateDialog,
                    lastDate: _tempEndDateDialog,
                    onDateChanged: (date) {
                      setDialogState(() {
                        _tempStartDateDialog = date;
                        if (_tempEndDateDialog != null &&
                            date.isAfter(_tempEndDateDialog!)) {
                          _tempEndDateDialog = date;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: AppDimensions.smallPadding),
                  CustomDatePicker(
                    label: 'End Date',
                    isDatePicker: true,
                    selectedDate: _tempEndDateDialog,
                    firstDate: _tempStartDateDialog,
                    onDateChanged: (date) {
                      setDialogState(() {
                        _tempEndDateDialog = date;
                        if (_tempStartDateDialog != null &&
                            date.isBefore(_tempStartDateDialog!)) {
                          _tempStartDateDialog = date;
                        }
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(datePickerDialogContext);
                    // _isDatePickerDialogOpen set to false in whenComplete
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushReplacementNamed(
                        context,
                        Routes.dashboard,
                      );
                    }
                  },
                  child: const Text(AppStrings.cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    // ... (all your date validation logic for _tempStartDateDialog, _tempEndDateDialog)
                    if (!(_tempStartDateDialog != null &&
                        _tempEndDateDialog != null &&
                        !_tempEndDateDialog!.isBefore(_tempStartDateDialog!) &&
                        isAtLeastOneMonthApart(
                          _tempStartDateDialog!,
                          _tempEndDateDialog!,
                        ) &&
                        !(_tempEndDateDialog!
                                .difference(_tempStartDateDialog!)
                                .inDays >
                            92))) {
                      // Show appropriate SnackBar if validation fails
                      ScaffoldMessenger.of(alertContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Harap periksa kembali rentang tanggal Anda.',
                          ),
                        ),
                      );
                      return;
                    }

                    // Pop this date picker dialog *before* dispatching
                    Navigator.pop(datePickerDialogContext);
                    // _isDatePickerDialogOpen will be set to false in whenComplete.

                    evaluationBloc.add(
                      EvaluationDateRangeSelected(
                        _tempStartDateDialog!,
                        _tempEndDateDialog!,
                      ),
                    );
                  },
                  child: const Text(AppStrings.ok),
                ),
              ],
            ),
          );
        },
      ),
    ).whenComplete(() {
      if (mounted) {
        _isDatePickerDialogOpen = false;
      }
    });
  }

  Future<void> _showDuplicateChoiceDialog(
    BuildContext pageContext,
    DateTime conflictedStart,
    DateTime conflictedEnd,
  ) async {
    if (_isChoiceDialogOpen || _isDatePickerDialogOpen) {
      return; // Prevent if any dialog is already up
    }
    _isChoiceDialogOpen = true;

    await showDialog<void>(
      context: pageContext,
      barrierDismissible: false,
      builder: (choiceDialogContext) {
        return AlertDialog(
          title: const Text('Periode Evaluasi Sudah Ada'),
          content: const Text(
            'Periode yang Anda pilih sudah memiliki data evaluasi. Apa yang ingin Anda lakukan?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.pop(choiceDialogContext);
                // _isChoiceDialogOpen set false in whenComplete
                pageContext.read<EvaluationBloc>().add(
                  EvaluationCancelDuplicateWarning(),
                );
                // After canceling, re-open the date picker dialog.
                // The BLoC state for CancelDuplicateWarning should set loading to false,
                // and the listener will pick this up to call _openDateDialog if appropriate.
              },
            ),
            TextButton(
              child: const Text('Lihat Riwayat Ini'),
              onPressed: () {
                Navigator.pop(choiceDialogContext);
                // _isChoiceDialogOpen set false in whenComplete
                pageContext.read<EvaluationBloc>().add(
                  EvaluationNavigateToExisting(
                    start: conflictedStart,
                    end: conflictedEnd,
                  ),
                );
              },
            ),
            ElevatedButton(
              child: const Text('Tetap Buat (Timpa)'),
              onPressed: () {
                Navigator.pop(choiceDialogContext);
                // _isChoiceDialogOpen set false in whenComplete
                pageContext.read<EvaluationBloc>().add(
                  EvaluationProceedWithDuplicate(
                    start: conflictedStart,
                    end: conflictedEnd,
                  ),
                );
              },
            ),
          ],
        );
      },
    ).whenComplete(() {
      if (mounted) {
        _isChoiceDialogOpen = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar can be removed if the page is truly blank and only shows dialogs
      // appBar: AppBar(title: Text("Select Evaluation Period")), // Optional
      body: BlocListener<EvaluationBloc, EvaluationState>(
        listener: (context, state) {
          debugPrint(
            '[EvaluationDatePage Listener] New state: loading=${state.loading}, conflict=${state.dateConflictExists}, error=${state.error}, dateError=${state.dateError}, items=${state.dashboardItems.length}',
          );

          ScaffoldMessenger.of(
            context,
          ).removeCurrentSnackBar(); // Clear old snackbars
          _snackBarController = null;

          if (state.dateConflictExists) {
            debugPrint(
              '[EvaluationDatePage Listener] Conflict detected. Attempting to show choice dialog.',
            );
            // Ensure no other dialog from this page is active.
            // The date picker dialog should have been popped by its "OK" button
            // BEFORE the BLoC event was dispatched and this state update occurred.
            if (!_isChoiceDialogOpen) {
              // Only show if not already trying to show it
              // _isDatePickerDialogOpen should be false here because the date picker
              // dialog's OK button pops itself before dispatching the event.
              if (_isDatePickerDialogOpen) {
                debugPrint(
                  '[EvaluationDatePage Listener] Warning: Date picker dialog was unexpectedly still marked open when conflict detected.',
                );
                // Potentially try to close it, but this indicates a flow issue in _openDateDialog's OK button.
              }
              _showDuplicateChoiceDialog(
                context,
                state.tempSelectedStartDate!,
                state.tempSelectedEndDate!,
              );
            } else {
              debugPrint(
                '[EvaluationDatePage Listener] Choice dialog already open or being opened. Skipping.',
              );
            }
            return; // IMPORTANT: Stop further processing in this listener pass
          }

          // If no date conflict, or a choice from conflict dialog led to a non-conflict state (e.g., after "Cancel" or "Proceed")
          if (!state.loading) {
            var shouldReopenDatePickerDueToError = false;

            if (state.dateError != null) {
              debugPrint(
                '[EvaluationDatePage Listener] Date error: ${state.dateError}',
              );
              _snackBarController = ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.dateError!)));
              context.read<EvaluationBloc>().add(EvaluationClearDateError());
              shouldReopenDatePickerDueToError = true;
            } else if (state.error != null) {
              debugPrint(
                '[EvaluationDatePage Listener] General error: ${state.error}',
              );
              _snackBarController = ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.error!)));
              context.read<EvaluationBloc>().add(EvaluationClearError());
              shouldReopenDatePickerDueToError = true;
            } else if (state.evaluationStartDate != null &&
                state.evaluationEndDate != null) {
              // This point is reached if:
              // - Initial date selection was successful (no conflict, data loaded).
              // - User chose "Proceed with Duplicate" -> BLoC re-evaluated -> data loaded.
              // - User chose "Navigate to Existing" -> BLoC set dates & items -> data available.
              debugPrint(
                '[EvaluationDatePage Listener] Dates set, no errors/conflict. Dashboard items count: ${state.dashboardItems.length}',
              );
              if (state.dashboardItems.isNotEmpty) {
                if (ModalRoute.of(context)?.isCurrent ?? false) {
                  debugPrint(
                    '[EvaluationDatePage Listener] Navigating to dashboard.',
                  );
                  Navigator.pushReplacementNamed(
                    context,
                    Routes.evaluationDashboard,
                  );
                }
                return;
              } else {
                // Dates are valid, no conflict, but no data found for this period.
                debugPrint(
                  '[EvaluationDatePage Listener] No dashboard items for the selected period.',
                );
                _snackBarController = ScaffoldMessenger.of(context)
                    .showSnackBar(
                      const SnackBar(
                        content: Text(AppStrings.noDataSubtitle),
                        backgroundColor: Colors.orangeAccent,
                      ),
                    );
                shouldReopenDatePickerDueToError = true;
              }
            } else {
              debugPrint(
                '[EvaluationDatePage Listener] Dates not set, no error/conflict. Idle or waiting for initial dialog.',
              );
            }

            if (shouldReopenDatePickerDueToError) {
              debugPrint(
                '[EvaluationDatePage Listener] Reopening date dialog due to error/no data.',
              );
              _snackBarController?.closed.then((_) {
                _snackBarController = null;
                if (mounted &&
                    !_isDatePickerDialogOpen &&
                    !_isChoiceDialogOpen) {
                  _openDateDialog();
                }
              });
            }
          } else {
            debugPrint(
              '[EvaluationDatePage Listener] State is loading. Waiting for load to complete.',
            );
          }
        },
        child: Center(
          // Provide some minimal UI, especially if dialogs are not showing.
          child:
              (context.watch<EvaluationBloc>().state.loading &&
                  !_isDatePickerDialogOpen &&
                  !_isChoiceDialogOpen)
              ? const CircularProgressIndicator()
              : const Text(
                  'Mengatur periode evaluasi...',
                ), // Or just SizedBox.shrink()
        ),
      ),
    );
  }
}
