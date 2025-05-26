// lib/features/transaction/bloc/transaction_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
// For debugPrint
// Not directly used, repo handles
import 'package:ta_client/features/transaction/models/account_type.dart'; // Keep for hierarchy
import 'package:ta_client/features/transaction/models/category.dart'; // Keep for hierarchy
import 'package:ta_client/features/transaction/models/subcategory.dart'; // Keep for hierarchy
import 'package:ta_client/features/transaction/models/transaction.dart';
import 'package:ta_client/features/transaction/repositories/transaction_hierarchy_repository.dart';
import 'package:ta_client/features/transaction/repositories/transaction_repository.dart';
import 'package:ta_client/features/transaction/services/transaction_service.dart'
    show
        TransactionApiException,
        TransactionService; // For classify and specific errors

part 'transaction_event.dart';
part 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  TransactionBloc({
    required this.repository,
    required this.hierarchyRepository,
    required this.transactionService, // Keep for classify
  }) : super(const TransactionState()) {
    on<CreateTransactionRequested>(_onCreate);
    on<UpdateTransactionRequested>(_onUpdate);
    on<DeleteTransactionRequested>(_onDelete);
    on<ClassifyTransactionRequested>(_onClassify);
    on<ToggleBookmarkRequested>(_onToggleBookmark);
    on<LoadAccountTypesRequested>(_onLoadAccountTypes);
    on<LoadCategoriesRequested>(_onLoadCategories);
    on<LoadSubcategoriesRequested>(_onLoadSubcategories);
    on<TransactionClearStatus>(_onClearStatus);
  }
  final TransactionRepository repository;
  final TransactionHierarchyRepository hierarchyRepository;
  final TransactionService
  transactionService; // For classify, as it's a direct API call

  Future<void> _onClassify(
    ClassifyTransactionRequested event,
    Emitter<TransactionState> emit,
  ) async {
    if (event.description.trim().isEmpty) {
      emit(
        state.copyWith(clearErrorMessage: true),
      ); // Clear previous classification
      return;
    }
    emit(
      state.copyWith(
        isLoading: true,
        operation: TransactionOperation.classify,
        clearErrorMessage: true,
      ),
    );
    try {
      final result = await transactionService.classifyTransaction(
        event.description,
      );
      // result structure: { subcategoryId?, subcategoryName?, categoryId?, categoryName?, accountTypeId?, accountTypeName?, confidence }
      emit(state.copyWith(isLoading: false, classifiedResult: result));
    } on TransactionApiException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Gagal mengklasifikasikan: $error',
        ),
      );
    }
  }

  Future<void> _onToggleBookmark(
    ToggleBookmarkRequested event,
    Emitter<TransactionState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoading: true,
        operation: TransactionOperation.bookmark,
        clearErrorMessage: true,
      ),
    );
    try {
      final updatedTransaction = await repository.toggleBookmark(
        event.transactionId,
      );
      emit(
        state.copyWith(
          isLoading: false,
          isSuccess: true,
          lastProcessedTransaction: updatedTransaction,
        ),
      );
    } on TransactionApiException catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          isSuccess: false,
          errorMessage: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          isSuccess: false,
          errorMessage: 'Gagal bookmark: $e',
        ),
      );
    }
  }

  Future<void> _onCreate(
    CreateTransactionRequested event,
    Emitter<TransactionState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoading: true,
        operation: TransactionOperation.create,
        clearErrorMessage: true,
        isSuccess: false,
      ),
    );
    try {
      final createdTransaction = await repository.createTransaction(
        event.transaction,
      );
      emit(
        state.copyWith(
          isLoading: false,
          isSuccess: true,
          lastProcessedTransaction: createdTransaction,
        ),
      );
    } on TransactionApiException catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          isSuccess: false,
          errorMessage: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          isSuccess: false,
          errorMessage: 'Gagal membuat transaksi: $e',
        ),
      );
    }
  }

  Future<void> _onUpdate(
    UpdateTransactionRequested event,
    Emitter<TransactionState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoading: true,
        operation: TransactionOperation.update,
        clearErrorMessage: true,
        isSuccess: false,
      ),
    );
    try {
      final updatedTransaction = await repository.updateTransaction(
        event.transaction,
      );
      emit(
        state.copyWith(
          isLoading: false,
          isSuccess: true,
          lastProcessedTransaction: updatedTransaction,
        ),
      );
    } on TransactionApiException catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          isSuccess: false,
          errorMessage: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          isSuccess: false,
          errorMessage: 'Gagal memperbarui transaksi: $e',
        ),
      );
    }
  }

  Future<void> _onDelete(
    DeleteTransactionRequested event,
    Emitter<TransactionState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoading: true,
        operation: TransactionOperation.delete,
        clearErrorMessage: true,
        isSuccess: false,
      ),
    );
    try {
      await repository.deleteTransaction(event.transactionId);
      emit(
        state.copyWith(isLoading: false, isSuccess: true),
      ); // No specific transaction to return
    } on TransactionApiException catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          isSuccess: false,
          errorMessage: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          isSuccess: false,
          errorMessage: 'Gagal menghapus transaksi: $e',
        ),
      );
    }
  }

  void _onClearStatus(
    TransactionClearStatus event,
    Emitter<TransactionState> emit,
  ) {
    emit(
      state.copyWith(
        isSuccess: false,
        clearErrorMessage: true,
        clearInfoMessage: true,
      ),
    );
  }

  // Hierarchy loading methods remain largely the same, as hierarchy repo handles online/offline
  Future<void> _onLoadAccountTypes(
    LoadAccountTypesRequested event,
    Emitter<TransactionState> emit,
  ) async {
    emit(state.copyWith(isLoadingHierarchy: true, clearErrorMessage: true));
    try {
      // hierarchyRepository handles online/offline
      final accountTypes = await hierarchyRepository.fetchAccountTypes();
      emit(
        state.copyWith(isLoadingHierarchy: false, accountTypes: accountTypes),
      );
    } catch (e) {
      emit(
        state.copyWith(isLoadingHierarchy: false, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onLoadCategories(
    LoadCategoriesRequested event,
    Emitter<TransactionState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoadingHierarchy: true,
        categories: [], // Clear previous categories for this account type
        subcategories:
            [], // Clear all subcategories, as they depend on new categories
        clearErrorMessage: true,
      ),
    );

    // If accountTypeId is empty (e.g., "Pilih Tipe Akun" was selected), emit empty lists and stop.
    if (event.accountTypeId.isEmpty) {
      emit(
        state.copyWith(
          isLoadingHierarchy: false,
          categories: [],
          subcategories: [],
        ),
      );
      return;
    }

    try {
      final categoriesForAccountType = await hierarchyRepository
          .fetchCategories(event.accountTypeId);

      // Now, fetch subcategories for all these categories
      final allRelevantSubcategories = <Subcategory>[];
      if (categoriesForAccountType.isNotEmpty) {
        // Only proceed if categories were found
        for (final category in categoriesForAccountType) {
          try {
            final subcategoriesForThisCategory = await hierarchyRepository
                .fetchSubcategories(category.id);
            allRelevantSubcategories.addAll(subcategoriesForThisCategory);
          } catch (e) {
            // Log error for this specific category's subcategories but continue
            debugPrint(
              '[TransactionBloc] Failed to load subcategories for ${category.id}: $e',
            );
          }
        }
      }

      emit(
        state.copyWith(
          isLoadingHierarchy: false,
          categories: categoriesForAccountType,
          subcategories:
              allRelevantSubcategories, // Emit all fetched subcategories
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(isLoadingHierarchy: false, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onLoadSubcategories(
    LoadSubcategoriesRequested event,
    Emitter<TransactionState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoadingHierarchy: true,
        subcategories: [],
        clearErrorMessage: true,
      ),
    ); // Clear subcategories
    try {
      final subcategories = await hierarchyRepository.fetchSubcategories(
        event.categoryId,
      );
      emit(
        state.copyWith(isLoadingHierarchy: false, subcategories: subcategories),
      );
    } catch (e) {
      emit(
        state.copyWith(isLoadingHierarchy: false, errorMessage: e.toString()),
      );
    }
  }
}

enum TransactionOperation {
  create,
  update,
  delete,
  bookmark,
  classify,
  hierarchy,
}
