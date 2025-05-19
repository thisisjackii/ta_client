// lib/features/transaction/bloc/transaction_state.dart
part of 'transaction_bloc.dart';

class TransactionState extends Equatable {
  const TransactionState({
    this.isLoading = false, // General loading for CUD operations
    this.isLoadingHierarchy = false, // Specific loading for category hierarchy
    this.isSuccess = false,
    this.errorMessage,
    this.infoMessage, // For non-error messages like "queued for sync"
    this.operation,
    this.lastProcessedTransaction, // The transaction that was just created/updated/bookmarked
    this.classifiedResult, // Stores the full Map<String, dynamic> from classify endpoint
    this.accountTypes = const [],
    this.categories = const [],
    this.subcategories = const [],
  });

  final bool isLoading;
  final bool isLoadingHierarchy;
  final bool isSuccess;
  final String? errorMessage;
  final String? infoMessage;
  final TransactionOperation? operation;
  final Transaction? lastProcessedTransaction;
  final Map<String, dynamic>? classifiedResult;

  final List<AccountType> accountTypes;
  final List<Category> categories;
  final List<Subcategory> subcategories;

  @override
  List<Object?> get props => [
    isLoading,
    isLoadingHierarchy,
    isSuccess,
    errorMessage,
    infoMessage,
    operation,
    lastProcessedTransaction,
    classifiedResult,
    accountTypes,
    categories,
    subcategories,
  ];

  TransactionState copyWith({
    bool? isLoading,
    bool? isLoadingHierarchy,
    bool? isSuccess,
    String? errorMessage,
    bool clearErrorMessage = false, // Added to explicitly clear
    String? infoMessage,
    bool clearInfoMessage = false, // Added to explicitly clear
    TransactionOperation? operation,
    Transaction? lastProcessedTransaction,
    Map<String, dynamic>? classifiedResult, // Can be set to null to clear
    List<AccountType>? accountTypes,
    List<Category>? categories,
    List<Subcategory>? subcategories,
  }) {
    return TransactionState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingHierarchy: isLoadingHierarchy ?? this.isLoadingHierarchy,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
      infoMessage: clearInfoMessage ? null : infoMessage ?? this.infoMessage,
      operation: operation ?? this.operation,
      lastProcessedTransaction:
          lastProcessedTransaction ?? this.lastProcessedTransaction,
      classifiedResult: classifiedResult ?? this.classifiedResult,
      accountTypes: accountTypes ?? this.accountTypes,
      categories: categories ?? this.categories,
      subcategories: subcategories ?? this.subcategories,
    );
  }
}
