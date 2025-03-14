// lib/features/transaction/bloc/transaction_state.dart
part of 'transaction_bloc.dart';

class TransactionState extends Equatable {
  const TransactionState({
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
    this.operation,
    this.createdTransaction,
  });
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;
  final TransactionOperation? operation;
  final Transaction? createdTransaction;

  TransactionState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
    TransactionOperation? operation,
    Transaction? createdTransaction,
  }) {
    return TransactionState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage ?? this.errorMessage,
      operation: operation ?? this.operation,
      createdTransaction: createdTransaction ?? this.createdTransaction,
    );
  }

  @override
  List<Object?> get props => [isLoading, isSuccess, errorMessage, operation, createdTransaction];
}
