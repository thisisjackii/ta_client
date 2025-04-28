// lib/features/budgeting/view/budgeting_allocation_date.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/app/routes/routes.dart';
import 'package:ta_client/core/constants/app_colors.dart';
import 'package:ta_client/core/constants/app_dimensions.dart';
import 'package:ta_client/core/constants/app_strings.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_bloc.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_event.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_state.dart';
import 'package:ta_client/features/budgeting/view/widgets/budgeting_date_selection.dart';

class BudgetingAllocationDate extends StatefulWidget {
  const BudgetingAllocationDate({super.key});

  @override
  State<BudgetingAllocationDate> createState() =>
      _BudgetingAllocationDateState();
}

class _BudgetingAllocationDateState extends State<BudgetingAllocationDate>
    with RouteAware {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showDatePickerModal();
    });
  }

  Future<void> _showDatePickerModal() async {
    context.read<BudgetingBloc>().add(ResetDateConfirmation());
    final parentCtx = context;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return BlocConsumer<BudgetingBloc, BudgetingState>(
          listenWhen: (prev, cur) =>
              prev.dateError != cur.dateError ||
              prev.dateConfirmed != cur.dateConfirmed,
          listener: (blocCtx, state) {
            if (state.dateError != null) {
              showDialog<void>(
                context: dialogCtx,
                builder: (_) => AlertDialog(
                  title: const Text('Gagal'),
                  content: Text(state.dateError!),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            } else if (state.dateConfirmed) {
              Navigator.of(dialogCtx).pop();
              Navigator.of(parentCtx).pushNamed(Routes.budgetingAllocationPage);
              ScaffoldMessenger.of(parentCtx).showSnackBar(
                const SnackBar(
                  content: Text('Tanggal valid, lanjut ke alokasi anggaran'),
                ),
              );
            }
          },
          builder: (blocCtx, state) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
              ),
              contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              content: const BudgetingDateSelection(),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text(AppStrings.cancel),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed: () {
                    final s = state.startDate;
                    final e = state.endDate;
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
                              onPressed: () => Navigator.of(dialogCtx).pop(),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                      return;
                    }
                    blocCtx.read<BudgetingBloc>().add(
                          ConfirmDateRange(start: s, end: e),
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
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}
