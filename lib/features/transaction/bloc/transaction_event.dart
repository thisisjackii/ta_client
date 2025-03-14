// lib/features/transaction/bloc/transaction_bloc.dart
part of 'transaction_bloc.dart';

abstract class TransactionEvent extends Equatable {
  const TransactionEvent();
  @override
  List<Object> get props => [];
}

class CreateTransactionRequested extends TransactionEvent {
  const CreateTransactionRequested(this.transaction);
  final Transaction transaction;
  @override
  List<Object> get props => [transaction];
}

class UpdateTransactionRequested extends TransactionEvent {
  const UpdateTransactionRequested(this.transaction);
  final Transaction transaction;
  @override
  List<Object> get props => [transaction];
}

class DeleteTransactionRequested extends TransactionEvent {
  const DeleteTransactionRequested(this.transactionId);
  final String transactionId;
  @override
  List<Object> get props => [transactionId];
}
