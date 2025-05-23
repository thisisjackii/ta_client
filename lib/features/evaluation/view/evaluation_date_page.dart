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
  DateTime? _end; // single controller to prevent repeats
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>?
  _snackBarController;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final initialBlocState = context.read<EvaluationBloc>().state;

    // Initialize dialog dates from BLoC state if available, otherwise default
    _start =
        initialBlocState.evaluationStartDate ?? DateTime(now.year, now.month);
    _end =
        initialBlocState.evaluationEndDate ??
        DateUtils.addDaysToDate(DateTime(now.year, now.month + 1), -1);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openDateDialog();
    });
  }

  // Helper to get the last day of a given month
  DateTime _lastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  /// Checks if the period is at least one month based on your specific criteria:
  /// 1. If start and end are in the same month: true if start is 1st and end is last day of that month.
  /// 2. If start and end are in different months:
  ///    a. If end is in the month immediately following start: true if end.day >= start.day.
  ///    b. If end is more than one month after start: true.
  bool isAtLeastOneMonthApart(DateTime start, DateTime end) {
    if (end.isBefore(start)) return false; // Invalid range

    // Normalize to ignore time part for day comparisons
    final normStart = DateUtils.dateOnly(start);
    final normEnd = DateUtils.dateOnly(end);

    // Case 1: Start and end dates are in the same calendar month
    if (DateUtils.isSameMonth(normStart, normEnd)) {
      final isFirstDay = normStart.day == 1;
      final isLastDay = normEnd.day == _lastDayOfMonth(normStart).day;
      // "if it's between 1 and last day of the month" - this means it IS the full month.
      return isFirstDay && isLastDay;
    }

    // Case 2: End date is in a subsequent month
    // Calculate the date one month after the start date
    final oneMonthAfterStartAnchor = DateUtils.addMonthsToMonthDate(
      normStart,
      1,
    );

    // If normEnd is in any month AFTER the month of oneMonthAfterStartAnchor, it's definitely > 1 month
    if (normEnd.year > oneMonthAfterStartAnchor.year ||
        (normEnd.year == oneMonthAfterStartAnchor.year &&
            normEnd.month > oneMonthAfterStartAnchor.month)) {
      return true;
    }

    // If normEnd is in the SAME month as oneMonthAfterStartAnchor (i.e., exactly one month later)
    if (DateUtils.isSameMonth(normEnd, oneMonthAfterStartAnchor)) {
      // "it's the same date number between one month and the other"
      return normEnd.day >= normStart.day;
    }

    // If normEnd is before the month of oneMonthAfterStartAnchor (but not in the same month as start),
    // this case should not be hit if previous checks are correct.
    // e.g. start=Jan 15, end=Feb 10. oneMonthAfterStartAnchor=Feb 15. normEnd is not same month as oneMonthAfterStartAnchor
    // and not in a month AFTER. This means it's less than a month by day number.
    return false;
  }

  void _openDateDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text(AppStrings.dateRangePrompt),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomDatePicker(
              label: 'Start',
              isDatePicker: true,
              selectedDate: _start,
              onDateChanged: (d) => setState(() => _start = d),
            ),
            const SizedBox(height: AppDimensions.smallPadding),
            CustomDatePicker(
              label: 'End',
              isDatePicker: true,
              selectedDate: _end,
              onDateChanged: (d) => setState(() => _end = d),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (_start == null || _end == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Harap pilih tanggal mulai dan akhir.'),
                  ),
                );
                return;
              }
              if (_end!.isBefore(_start!)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Tanggal akhir tidak boleh sebelum tanggal mulai.',
                    ),
                  ),
                );
                return;
              }

              if (!isAtLeastOneMonthApart(_start!, _end!)) {
                _snackBarController?.close();
                _snackBarController = ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Rentang periode evaluasi minimal adalah 1 bulan (sesuai kriteria).',
                    ),
                  ),
                );
                _snackBarController!.closed.then(
                  (_) => _snackBarController = null,
                );
                return; // Don't pop, let user correct
              }

              // Dates are valid, pop the dialog
              Navigator.pop(context);

              // Dispatch event to BLoC. BLoC will handle period creation and then load dashboard.
              context.read<EvaluationBloc>().add(
                EvaluationDateRangeSelected(_start!, _end!),
              );
              // Navigation will now be handled by a BlocListener on EvaluationBloc in this page or a parent
            },
            child: const Text(AppStrings.ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to EvaluationBloc for navigation after dates are processed and dashboard is loaded
    return BlocListener<EvaluationBloc, EvaluationState>(
      listener: (context, state) {
        if (!state.loading &&
            state.error == null &&
            state.dashboardItems.isNotEmpty) {
          // If dashboard items are loaded successfully (implying period was set and data fetched)
          if (ModalRoute.of(context)?.isCurrent ?? false) {
            // Check if this page is still current
            Navigator.pushReplacementNamed(context, Routes.evaluationDashboard);
          }
        } else if (!state.loading && state.error != null) {
          // If an error occurred during period ensuring or dashboard loading after date selection
          // (and it wasn't handled by the dialog's listener, e.g., dialog already closed)
          _snackBarController?.close();
          _snackBarController = ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.error!)));
          _snackBarController!.closed.then((_) => _snackBarController = null);
          // Optionally, re-open dialog or allow user to retry
          // For now, just show error. User might need to go back and try again.
        }
      },
      child: const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ), // Initial loading state
      ),
    );
  }
}
