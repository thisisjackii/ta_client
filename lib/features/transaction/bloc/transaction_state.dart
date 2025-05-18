// lib/features/transaction/bloc/transaction_state.dart
part of 'transaction_bloc.dart';

class TransactionState extends Equatable {
  const TransactionState({
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
    this.operation,
    this.createdTransaction,
    this.classifiedCategory,
    this.accountTypes = const [],
    this.categories = const [],
    this.subcategories = const [],
  });
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;
  final TransactionOperation? operation;
  final Transaction? createdTransaction;
  final String? classifiedCategory; // e.g. raw value from API
  final List<AccountType> accountTypes;
  final List<Category> categories;
  final List<Subcategory> subcategories;

  @override
  List<Object?> get props => [
    isLoading,
    isSuccess,
    errorMessage,
    operation,
    createdTransaction,
    classifiedCategory,
  ];

  TransactionState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
    TransactionOperation? operation,
    Transaction? createdTransaction,
    String? classifiedCategory,
    List<AccountType>? accountTypes,
    List<Category>? categories,
    List<Subcategory>? subcategories,
  }) {
    return TransactionState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage ?? this.errorMessage,
      operation: operation ?? this.operation,
      createdTransaction: createdTransaction ?? this.createdTransaction,
      classifiedCategory: classifiedCategory ?? this.classifiedCategory,
        accountTypes: accountTypes ?? this.accountTypes,
      categories: categories ?? this.categories,
      subcategories: subcategories ?? this.subcategories,
    );
  }
}
