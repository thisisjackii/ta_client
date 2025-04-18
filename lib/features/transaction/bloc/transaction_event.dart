// lib/features/transaction/bloc/transaction_event.dart
part of 'transaction_bloc.dart';

class ClassifyTransactionRequested extends TransactionEvent {
  const ClassifyTransactionRequested(this.description);
  final String description;

  @override
  List<Object> get props => [description];
}

class ToggleBookmarkRequested extends TransactionEvent {
  const ToggleBookmarkRequested(this.transactionId);
  final String transactionId;
  @override
  List<Object> get props => [transactionId];
}

class CreateTransactionRequested extends TransactionEvent {
  const CreateTransactionRequested(this.transaction);
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

abstract class TransactionEvent extends Equatable {
  const TransactionEvent();
  @override
  List<Object> get props => [];
}

class UpdateTransactionRequested extends TransactionEvent {
  const UpdateTransactionRequested(this.transaction);
  final Transaction transaction;
  @override
  List<Object> get props => [transaction];
}
