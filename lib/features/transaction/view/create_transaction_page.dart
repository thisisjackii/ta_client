// lib/features/transaction/view/create_transaction_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/features/transaction/bloc/transaction_bloc.dart';
import 'package:ta_client/features/transaction/view/widgets/transaction_form.dart';

class CreateTransactionPage extends StatelessWidget {
  const CreateTransactionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<TransactionBloc, TransactionState>(
      listener: (context, state) {
        if (state.isSuccess && state.operation == TransactionOperation.create) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction created successfully!')),
          );
          // Simply pop; DashboardPage's RouteAware (didPopNext) will trigger a reload.
          Navigator.of(context).pop(state.createdTransaction);
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
                IconButton(icon: const Icon(Icons.info), onPressed: () {}),
                IconButton(
                    icon: const Icon(Icons.bookmark_add), onPressed: () {},),
              ],
            ),
          ],
        ),
        body: TransactionForm(
          onSubmit: (transaction) {
            context
                .read<TransactionBloc>()
                .add(CreateTransactionRequested(transaction));
          },
        ),
      ),
    );
  }
}
