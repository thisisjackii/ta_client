// lib/features/transaction/view/create_transaction_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:quickalert/quickalert.dart';
import 'package:ta_client/app/routes/routes.dart';
import 'package:ta_client/core/constants/app_colors.dart';
import 'package:ta_client/features/transaction/bloc/dashboard_bloc.dart';
import 'package:ta_client/features/transaction/bloc/transaction_bloc.dart';
import 'package:ta_client/features/transaction/view/widgets/transaction_form.dart';

class CreateTransactionPage extends StatelessWidget {
  const CreateTransactionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<TransactionBloc, TransactionState>(
      listener: (context, state) {
        if (state.isSuccess && state.operation == TransactionOperation.create) {
          // QuickAlert.show(
          //   context: context,
          //   type: QuickAlertType.success,
          //   text: 'Transaction Completed Successfully!',
          //   onConfirmBtnTap: () {
          //     Navigator.of(context).pushReplacementNamed(Routes.dashboard);
          //   },
          //   onCancelBtnTap: () {
          //     Navigator.of(context).pushReplacementNamed(Routes.dashboard);
          //   },
          // );
          if (state.lastProcessedTransaction != null) {
            // Ensure we have the new transaction
            // Dispatch event to DashboardBloc
            context.read<DashboardBloc>().add(
              DashboardTransactionCreated(state.lastProcessedTransaction!),
            );
          } else {
            // Fallback: force refresh if new transaction data isn't available for optimistic update
            context.read<DashboardBloc>().add(DashboardForceRefreshRequested());
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('New transaction created!')),
          );
          // Simply pop; DashboardPage's RouteAware (didPopNext) will trigger a reload.
          Future<void>.delayed(const Duration(seconds: 3), () {
            if (context.mounted) {
              Navigator.of(context).pushReplacementNamed(Routes.dashboard);
            }
          });
        } else if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${state.errorMessage}')),
          );
          // QuickAlert.show(
          //   context: context,
          //   type: QuickAlertType.error,
          //   title: 'Oops...',
          //   text: 'Error: ${state.errorMessage}',
          // );
          context.read<TransactionBloc>().add(TransactionClearStatus());
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.greyBackground,
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                IconButton(icon: const Icon(Icons.info), onPressed: () {}),
              ],
            ),
          ],
        ),
        body: TransactionForm(
          onSubmit: (transaction) {
            context.read<TransactionBloc>().add(
              CreateTransactionRequested(transaction),
            );
          },
          onDescriptionChanged: (description) {
            context.read<TransactionBloc>().add(
              ClassifyTransactionRequested(description),
            );
          },
        ),
      ),
    );
  }
}
