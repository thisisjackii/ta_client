// lib/features/transaction/view/view_transaction_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/app/routes/routes.dart';
import 'package:ta_client/features/transaction/bloc/transaction_bloc.dart';
import 'package:ta_client/features/transaction/models/transaction.dart';
import 'package:ta_client/features/transaction/view/widgets/transaction_form.dart';
import 'package:ta_client/features/transaction/view/widgets/transaction_form_mode.dart';

class ViewTransactionPage extends StatelessWidget {
  const ViewTransactionPage({required this.transaction, super.key});
  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    return BlocListener<TransactionBloc, TransactionState>(
      listener: (context, state) {
        if (state.isSuccess) {
          if (state.operation == TransactionOperation.update) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Transaction updated successfully!'),),
            );
            // Replace current page with a new Dashboard page so that data is refreshed.
            Navigator.of(context).pushReplacementNamed(Routes.dashboard);
          } else if (state.operation == TransactionOperation.delete) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Transaction deleted successfully!'),),
            );
            Navigator.of(context).pushReplacementNamed(Routes.dashboard);
          }
        } else if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${state.errorMessage}')),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xffFBFDFF),
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
                IconButton(
                  icon: const Icon(Icons.info),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.bookmark_add),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
        body: TransactionForm(
          mode: TransactionFormMode.view,
          transaction: transaction,
          // When in view mode, tapping a field switches the form to edit mode.
          // When the form is edited and then submitted, it dispatches an update event.
          onSubmit: (updatedTransaction) {
            context
                .read<TransactionBloc>()
                .add(UpdateTransactionRequested(updatedTransaction));
          },
          onDelete: () {
            context
                .read<TransactionBloc>()
                .add(DeleteTransactionRequested(transaction.id));
          },
        ),
      ),
    );
  }
}
