// lib/features/evaluation/view/evaluation_date_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/app/routes/routes.dart';
import 'package:ta_client/core/constants/app_dimensions.dart';
import 'package:ta_client/core/constants/app_strings.dart';
import 'package:ta_client/core/widgets/custom_date_picker.dart';
import 'package:ta_client/features/evaluation/bloc/evaluation_bloc.dart';
import 'package:ta_client/features/evaluation/bloc/evaluation_event.dart';

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

  bool isAtLeastOneMonthApart(DateTime start, DateTime end) {
    final oneMonthLater = DateTime(start.year, start.month + 1, start.day);
    return !end.isBefore(oneMonthLater);
  }

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 300), _openDateDialog);
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
              Navigator.pop(context);
              if (!isAtLeastOneMonthApart(_start!, _end!)) {
                final difference = _end!.difference(_start!).inDays;
                if (difference < 30) {
                  _snackBarController = ScaffoldMessenger.of(context)
                      .showSnackBar(
                        const SnackBar(
                          content: Text('Date range must be at least 1 month.'),
                        ),
                      );
                  _snackBarController!.closed.then(
                    (_) => _snackBarController = null,
                  );
                  return;
                }
                context.read<EvaluationBloc>().add(
                  SelectDateRange(_start!, _end!),
                );
                context.read<EvaluationBloc>().add(LoadDashboard());
                Navigator.pushNamed(context, Routes.evaluationDashboard);
              } else {
                _snackBarController = ScaffoldMessenger.of(context)
                    .showSnackBar(
                      const SnackBar(content: Text(AppStrings.dateRangePrompt)),
                    );
                _snackBarController!.closed.then(
                  (_) => _snackBarController = null,
                );
              }
            },
            child: const Text(AppStrings.ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => const Scaffold();
}
