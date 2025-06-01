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
  DateTime? _start;
  DateTime? _end;
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>?
  _snackBarController;
  bool _isDialogCurrentlyOpen = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final initialBlocState = context.read<EvaluationBloc>().state;

    _start =
        initialBlocState.evaluationStartDate ?? DateTime(now.year, now.month);
    _end =
        initialBlocState.evaluationEndDate ??
        DateUtils.addDaysToDate(DateTime(now.year, now.month + 1), -1);

    context.read<EvaluationBloc>().add(EvaluationClearDateError());
    context.read<EvaluationBloc>().add(EvaluationClearError());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDialogCurrentlyOpen) {
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
    if (_isDialogCurrentlyOpen) {
      // If already open, perhaps bring to front or just do nothing.
      // For now, just preventing re-entry.
      return;
    }
    _isDialogCurrentlyOpen = true;

    // It's good practice to remove any existing snackbar before showing a dialog
    // that might cover where the snackbar was, or if the dialog action leads to a new snackbar.
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    await showDialog<void>(
      context: context,
      barrierDismissible: false, // User must explicitly cancel or submit
      builder: (dialogContext) => StatefulBuilder(
        builder: (stfContext, setDialogState) {
          return AlertDialog(
            title: const Text(AppStrings.dateRangePrompt),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomDatePicker(
                  label: 'Start',
                  isDatePicker: true,
                  selectedDate: _start,
                  onDateChanged: (d) => setDialogState(() => _start = d),
                ),
                const SizedBox(height: AppDimensions.smallPadding),
                CustomDatePicker(
                  label: 'End',
                  isDatePicker: true,
                  selectedDate: _end,
                  onDateChanged: (d) => setDialogState(() => _end = d),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext); // Close dialog
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context); // Pop EvaluationDatePage itself
                  } else {
                    Navigator.pushReplacementNamed(
                      context,
                      Routes.dashboard,
                    ); // Fallback
                  }
                },
                child: const Text(AppStrings.cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  // Perform validation
                  if (_start == null || _end == null) {
                    ScaffoldMessenger.of(stfContext).showSnackBar(
                      const SnackBar(
                        content: Text('Harap pilih tanggal mulai dan akhir.'),
                      ),
                    );
                    return;
                  }
                  if (_end!.isBefore(_start!)) {
                    ScaffoldMessenger.of(stfContext).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Tanggal akhir tidak boleh sebelum tanggal mulai.',
                        ),
                      ),
                    );
                    return;
                  }
                  if (!isAtLeastOneMonthApart(_start!, _end!)) {
                    ScaffoldMessenger.of(stfContext).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Rentang periode evaluasi minimal adalah 1 bulan (sesuai kriteria).',
                        ),
                      ),
                    );
                    return;
                  }
                  // If all validations pass:
                  Navigator.pop(dialogContext); // Close the dialog first
                  // Then dispatch event. State change will be handled by BlocListener.
                  context.read<EvaluationBloc>().add(
                    EvaluationDateRangeSelected(_start!, _end!),
                  );
                },
                child: const Text(AppStrings.ok),
              ),
            ],
          );
        },
      ),
    );

    // This setState is important to update the page's view if needed
    // after the dialog closes, and to correctly set _isDialogCurrentlyOpen.
    if (mounted) {
      setState(() {
        _isDialogCurrentlyOpen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The body is minimal because the dialog is the main interaction.
      // This Scaffold provides context for SnackBars shown by the BlocListener.
      body: BlocListener<EvaluationBloc, EvaluationState>(
        listener: (context, state) {
          // Dismiss any existing snackbar on the main scaffold before showing a new one.
          ScaffoldMessenger.of(
            context,
          ).removeCurrentSnackBar(reason: SnackBarClosedReason.dismiss);
          _snackBarController = null;

          if (!state.loading) {
            // Only act when BLoC is not actively processing
            var shouldReopenDialog = false;

            if (state.dateError != null) {
              _snackBarController = ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.dateError!)));
              context.read<EvaluationBloc>().add(EvaluationClearDateError());
              shouldReopenDialog = true;
            } else if (state.error != null) {
              _snackBarController = ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.error!)));
              context.read<EvaluationBloc>().add(EvaluationClearError());
              shouldReopenDialog = true;
            } else if (state.evaluationStartDate != null &&
                state.evaluationEndDate != null) {
              // Dates are processed, no BLoC errors. Check for data.
              if (state.dashboardItems.isEmpty) {
                debugPrint(
                  'Dashboard items: ${state.dashboardItems.map((item) => item.toString()).join(', ')}',
                );
                _snackBarController = ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Oops! Belum ada data keuangan untuk periode ini. Pilih periode lain atau catat transaksi.',
                    ),
                  ),
                );
                shouldReopenDialog = true;
              } else {
                // SUCCESS: Data loaded, navigate to dashboard
                if (ModalRoute.of(context)?.isCurrent ?? false) {
                  Navigator.pushReplacementNamed(
                    context,
                    Routes.evaluationDashboard,
                  );
                }
                return; // Exit listener early on success
              }
            }

            if (shouldReopenDialog) {
              _snackBarController?.closed.then((_) {
                _snackBarController = null; // Clear controller
                // Only re-open dialog if it's not already open and widget is mounted
                if (mounted && !_isDialogCurrentlyOpen) {
                  _openDateDialog();
                }
              });
            }
          }
        },
        // The child of BlocListener is the static part of the page.
        // Since the dialog is modal and covers this, we can return a simple placeholder.
        // If BLoC is loading, it implies dialog was submitted; don't show another spinner here.
        child: Container(
          // Optional: You could put a very subtle background or branding here
          // if you don't want it to be completely white behind the dialog/snackbar.
          // For now, an empty container is fine.
        ),
      ),
    );
  }
}
