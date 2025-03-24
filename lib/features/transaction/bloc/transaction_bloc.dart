// lib/features/transaction/bloc/transaction_bloc.dart
library transaction_bloc;

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ta_client/core/services/connectivity_service.dart';
import 'package:ta_client/features/transaction/models/transaction.dart';
import 'package:ta_client/features/transaction/repositories/transaction_repository.dart';
import 'package:ta_client/features/transaction/services/transaction_service.dart';

part 'transaction_event.dart';
part 'transaction_state.dart';

enum TransactionOperation { create, update, delete }

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  TransactionBloc({
    required this.repository,
    required this.connectivityService,
    required this.transactionService,
  }) : super(const TransactionState()) {
    on<CreateTransactionRequested>(_onCreate);
    on<UpdateTransactionRequested>(_onUpdate);
    on<DeleteTransactionRequested>(_onDelete);
    on<ClassifyTransactionRequested>(_onClassify);
  }
  final TransactionRepository repository;
  final ConnectivityService connectivityService;
  final TransactionService transactionService;

  Future<void> _onCreate(
    CreateTransactionRequested event,
    Emitter<TransactionState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoading: true,
        operation: TransactionOperation.create,
      ),
    );
    try {
      final online = await connectivityService.isOnline;
      await repository.createTransaction(event.transaction, isOnline: online);
      // Now, force a reload of the dashboard data.
      final updatedItems = await repository.fetchTransactions(isOnline: online);
      // Optionally, verify that the newly created transaction is in the list.
      final created = event.transaction;
      final found = updatedItems.any(
        (t) =>
            t.type == created.type &&
            t.description == created.description &&
            t.category == created.category &&
            t.subcategory == created.subcategory &&
            t.amount == created.amount &&
            t.date.difference(created.date).inSeconds.abs() < 1,
      );
      if (found) {
        emit(state.copyWith(isLoading: false, isSuccess: true, createdTransaction: created));
      } else {
        throw Exception('New transaction not found in updated dashboard data.');
      }
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          isSuccess: false,
          errorMessage: e.toString(),
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
      ),
    );
    try {
      final online = await connectivityService.isOnline;
      await repository.updateTransaction(event.transaction, isOnline: online);
      // Force a reload of transactions
      final updatedItems = await repository.fetchTransactions(isOnline: online);
      // For update, we can compare by id since an updated transaction should have a valid id.
      final updated = event.transaction;
      final found = updatedItems.any((t) => t.id == updated.id);
      if (found) {
        emit(state.copyWith(isLoading: false, isSuccess: true));
      } else {
        throw Exception('Updated transaction not found in refreshed data.');
      }
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          isSuccess: false,
          errorMessage: e.toString(),
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
      ),
    );
    try {
      final online = await connectivityService.isOnline;
      await repository.deleteTransaction(event.transactionId, isOnline: online);
      // Force a reload of transactions
      final updatedItems = await repository.fetchTransactions(isOnline: online);
      // Ensure that the deleted transaction is no longer present.
      final notFound = !updatedItems.any((t) => t.id == event.transactionId);
      if (notFound) {
        emit(state.copyWith(isLoading: false, isSuccess: true));
      } else {
        throw Exception('Deleted transaction still found in refreshed data.');
      }
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          isSuccess: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onClassify(
    ClassifyTransactionRequested event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      // Optionally, you might set a loading flag for classification only:
      emit(state.copyWith(isLoading: true));
      final result = await transactionService.classifyTransaction(event.description);
      // Here, result['category'] is the raw predicted value.
      // For display purposes, you can append the sparkle in the UI.
      emit(state.copyWith(
          isLoading: false, classifiedCategory: result['category'] as String? ?? '',),);
    } catch (error) {
      emit(state.copyWith(
          isLoading: false,
          errorMessage: error.toString(),),);
    }
  }
}
