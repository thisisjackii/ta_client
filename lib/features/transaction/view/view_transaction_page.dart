// lib/features/transaction/view/view_transaction_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:ta_client/core/constants/app_colors.dart';
import 'package:ta_client/features/transaction/bloc/dashboard_bloc.dart';
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
    return BlocListener<TransactionBloc, TransactionState>(
      // Listen to TransactionBloc
      listener: (context, state) {
        if (state.isSuccess) {
          if (state.operation == TransactionOperation.update &&
              state.lastProcessedTransaction != null) {
            context.read<DashboardBloc>().add(
              DashboardTransactionUpdated(state.lastProcessedTransaction!),
            );
            // QuickAlert.show(
            //   context: context,
            //   type: QuickAlertType.success,
            //   text: 'Transaction Updated Successfully!',
            //   onConfirmBtnTap: () =>
            //       Navigator.of(context).pop(), // Pop back to dashboard
            // );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Transaction Updated Successfully!'),
              ),
            );
          } else if (state.operation == TransactionOperation.delete) {
            // For delete, transaction.id is the original ID passed to the delete event
            context.read<DashboardBloc>().add(
              DashboardTransactionDeleted(transaction.id),
            );
            // QuickAlert.show(
            //   context: context,
            //   type: QuickAlertType.success,
            //   text: 'Transaction Deleted Successfully!',
            //   onConfirmBtnTap: () => Navigator.of(context).popUntil(
            //     (route) =>
            //         route.settings.name == Routes.dashboard || route.isFirst,
            //   ),
            // );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Transaction Deleted Successfully!'),
              ),
            );
          } else if (state.operation == TransactionOperation.bookmark &&
              state.lastProcessedTransaction != null) {
            context.read<DashboardBloc>().add(
              DashboardTransactionUpdated(
                state.lastProcessedTransaction!,
              ), // Bookmark is like an update
            );
            // Optionally, show a less intrusive success message for bookmarks
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Bookmark status updated.'),
                duration: Duration(seconds: 1),
              ),
            );
          }
          // Clear status for next operation
          context.read<TransactionBloc>().add(TransactionClearStatus());
        } else if (state.errorMessage != null) {
          // QuickAlert.show(
          //   context: context,
          //   type: QuickAlertType.error,
          //   title: 'Oops...',
          //   text: 'Error: ${state.errorMessage}',
          // );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${state.errorMessage}')),
          );
          context.read<TransactionBloc>().add(TransactionClearStatus());
        }
      },
      child: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, state) {
          final currentTransaction =
              state.operation == TransactionOperation.bookmark &&
                  state.lastProcessedTransaction != null
              ? state.lastProcessedTransaction!
              : transaction;
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
              transaction:
                  currentTransaction, // Pass the potentially updated transaction
              mode: TransactionFormMode.view, // Start in view mode
              onSubmit: (updatedTransaction) {
                // This is for "Save" in edit mode
                context.read<TransactionBloc>().add(
                  UpdateTransactionRequested(updatedTransaction),
                );
              },
              onDelete: () {
                // Show confirmation dialog before deleting
                QuickAlert.show(
                  context: context,
                  type: QuickAlertType.confirm,
                  title: 'Hapus Transaksi?',
                  text: 'Anda yakin ingin menghapus transaksi ini?',
                  confirmBtnText: 'Ya, Hapus',
                  cancelBtnText: 'Batal',
                  onConfirmBtnTap: () {
                    Navigator.of(
                      context,
                      rootNavigator: true,
                    ).pop(); // Dismiss alert
                    context.read<TransactionBloc>().add(
                      DeleteTransactionRequested(currentTransaction.id),
                    );
                  },
                  onCancelBtnTap: () {
                    Navigator.of(
                      context,
                      rootNavigator: true,
                    ).pop(); // Dismiss alert
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
