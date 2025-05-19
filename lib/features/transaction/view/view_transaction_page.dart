// lib/features/transaction/view/view_transaction_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/core/constants/app_colors.dart';
// import 'package:quickalert/quickalert.dart';
// import 'package:ta_client/app/routes/routes.dart';
import 'package:ta_client/features/transaction/bloc/transaction_bloc.dart';
import 'package:ta_client/features/transaction/models/transaction.dart';
import 'package:ta_client/features/transaction/view/widgets/transaction_form.dart';
import 'package:ta_client/features/transaction/view/widgets/transaction_form_mode.dart';

class ViewTransactionPage extends StatelessWidget {
  const ViewTransactionPage({required this.transaction, super.key});
  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        final currentTransaction =
            state.lastProcessedTransaction ??
            transaction; // Use updatedTransaction if available
        return Scaffold(
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
                  IconButton(
                    icon: Icon(
                      currentTransaction.isBookmarked
                          ? Icons.star
                          : Icons.star_border,
                      color: currentTransaction.isBookmarked
                          ? Colors.yellow[700]
                          : Colors.black,
                    ),
                    onPressed: () {
                      context.read<TransactionBloc>().add(
                        ToggleBookmarkRequested(currentTransaction.id),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          body: TransactionForm(
            mode: TransactionFormMode.view,
            transaction: currentTransaction,
            onSubmit: (updatedTransaction) {
              context.read<TransactionBloc>().add(
                UpdateTransactionRequested(updatedTransaction),
              );
            },
            onDelete: () {
              context.read<TransactionBloc>().add(
                DeleteTransactionRequested(currentTransaction.id),
              );
            },
          ),
        );
      },
    );
  }
}
