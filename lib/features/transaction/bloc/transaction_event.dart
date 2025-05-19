// lib/features/transaction/bloc/transaction_event.dart
part of 'transaction_bloc.dart';

abstract class TransactionEvent extends Equatable {
  const TransactionEvent();
  @override
  List<Object> get props => [];
}

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

class UpdateTransactionRequested extends TransactionEvent {
  const UpdateTransactionRequested(this.transaction);
  final Transaction transaction;
  @override
  List<Object> get props => [transaction];
}

class LoadAccountTypesRequested extends TransactionEvent {}

class LoadCategoriesRequested extends TransactionEvent {
  const LoadCategoriesRequested(this.accountTypeId);
  final String accountTypeId;
  @override
  List<Object> get props => [accountTypeId];
}

class LoadSubcategoriesRequested extends TransactionEvent {
  const LoadSubcategoriesRequested(this.categoryId);
  final String categoryId;
  @override
  List<Object> get props => [categoryId];
}

// ... (existing events)
class TransactionClearStatus
    extends TransactionEvent {} // To reset flags like isSuccess, errorMessage
