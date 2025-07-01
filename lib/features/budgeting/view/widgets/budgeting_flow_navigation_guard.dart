// lib/features/budgeting/view/widgets/budgeting_flow_navigation_guard.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/app/routes/routes.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_bloc.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_event.dart';

mixin BudgetingFlowNavigationGuard<T extends StatefulWidget> on State<T> {
  bool canPopBudgetingFlow(BuildContext context) {
    final budgetingState = BlocProvider.of<BudgetingBloc>(context).state;
    if (!budgetingState.incomeDateConfirmed &&
        !budgetingState.planDateConfirmed &&
        !budgetingState.isEditing) {
      return true;
    }
    return false;
  }

  // Changed signature for onPopInvokedWithResult (we ignore the result 'R?' here)
  Future<void> handlePopAttempt({
    required BuildContext context,
    required bool didPop,
    Object? result,
  }) async {
    // The 'result' parameter is from onPopInvokedWithResult, we can ignore it for this guard.
    if (didPop) {
      // If canPop was true, system already handled the pop.
      return;
    }

    // If canPop was false, didPop will be false. Show confirmation.
    final confirmCancel = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Batalkan Perubahan?'),
        content: const Text(
          'Anda yakin ingin membatalkan pembuatan/perubahan rencana anggaran ini? Perubahan yang belum disimpan akan hilang.',
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Tidak'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          TextButton(
            child: const Text(
              'Ya, Batalkan',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );

    if (confirmCancel ?? false) {
      if (context.mounted) {
        context.read<BudgetingBloc>().add(BudgetingResetState());
        await Navigator.pushNamedAndRemoveUntil(
          context,
          Routes.dashboard,
          (route) => false,
        );
      }
    }
  }

  void handleAppBarOrButtonCancel(BuildContext context) {
    if (canPopBudgetingFlow(context)) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } else {
      // For PopScope, if canPop is false, onPopInvoked will be called.
      // So, programmatically trying to pop will also trigger our handlePopAttempt via onPopInvoked.
      // However, to be explicit and ensure our dialog shows:
      handlePopAttempt(
        context: context,
        didPop: false,
      ); // Simulate that pop was prevented and no result passed
    }
  }
}
