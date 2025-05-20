// lib/features/transaction/bloc/dashboard_bloc.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/core/services/connectivity_service.dart';
import 'package:ta_client/features/transaction/models/transaction.dart';
import 'package:ta_client/features/transaction/repositories/transaction_repository.dart';
import 'package:ta_client/features/transaction/services/transaction_service.dart'
    show TransactionApiException;

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({required this.repository, required this.connectivityService})
    : super(const DashboardLoading()) {
    on<DashboardLoadRequested>(_onLoadRequested);
    on<DashboardForceRefreshRequested>(_onForceRefreshRequested);
    on<DashboardTransactionCreated>(_onTransactionCreated);
    on<DashboardTransactionUpdated>(_onTransactionUpdated);
    on<DashboardTransactionDeleted>(_onTransactionDeleted);
    on<DashboardSyncPendingRequested>(_onSyncPending);
  }

  final TransactionRepository repository;
  final ConnectivityService connectivityService;

  Future<void> _fetchAndEmitTransactions(
    Emitter<DashboardState> emit, {
    bool forceRefresh = false,
  }) async {
    emit(
      DashboardLoading(
        items: state is DashboardLoaded ? (state as DashboardLoaded).items : [],
        isSyncing: state is DashboardLoading
            ? (state as DashboardLoading).isSyncing
            : false,
      ),
    );
    try {
      final items = await repository.fetchTransactions(
        forceRefresh: forceRefresh,
      );
      emit(DashboardLoaded(items));
    } on TransactionApiException catch (e) {
      if (e.statusCode == 401) {
        // AuthState and Dio interceptor should handle actual logout.
        // This BLoC just signals that data loading failed due to auth.
        emit(DashboardUnauthenticated());
      } else {
        emit(DashboardError(e.message));
      }
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  Future<void> _onLoadRequested(
    DashboardLoadRequested event,
    Emitter<DashboardState> emit,
  ) async {
    await _fetchAndEmitTransactions(emit);
  }

  Future<void> _onForceRefreshRequested(
    DashboardForceRefreshRequested event,
    Emitter<DashboardState> emit,
  ) async {
    await _fetchAndEmitTransactions(emit, forceRefresh: true);
  }

  void _onTransactionCreated(
    DashboardTransactionCreated event,
    Emitter<DashboardState> emit,
  ) {
    if (state is DashboardLoaded) {
      final currentItems = (state as DashboardLoaded).items;
      final newItems = [event.transaction, ...currentItems]
        ..sort((a, b) => b.date.compareTo(a.date));
      emit(DashboardLoaded(newItems));
    } else {
      add(DashboardLoadRequested());
    }
  }

  void _onTransactionUpdated(
    DashboardTransactionUpdated event,
    Emitter<DashboardState> emit,
  ) {
    if (state is DashboardLoaded) {
      final currentItems = (state as DashboardLoaded).items;
      final index = currentItems.indexWhere(
        (t) => t.id == event.transaction.id,
      );
      if (index != -1) {
        final newItems = List<Transaction>.from(currentItems);
        newItems[index] = event.transaction;
        newItems.sort((a, b) => b.date.compareTo(a.date));
        emit(DashboardLoaded(newItems));
      } else {
        add(DashboardLoadRequested());
      }
    } else {
      add(DashboardLoadRequested());
    }
  }

  void _onTransactionDeleted(
    DashboardTransactionDeleted event,
    Emitter<DashboardState> emit,
  ) {
    if (state is DashboardLoaded) {
      final currentItems = (state as DashboardLoaded).items;
      final newItems = currentItems
          .where((t) => t.id != event.transactionId)
          .toList();
      emit(DashboardLoaded(newItems));
    } else {
      add(DashboardLoadRequested());
    }
  }

  Future<void> _onSyncPending(
    DashboardSyncPendingRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(
      DashboardLoading(
        items: state is DashboardLoaded ? (state as DashboardLoaded).items : [],
        isSyncing: true,
      ),
    );
    try {
      await repository.syncPendingTransactions();
      add(
        DashboardForceRefreshRequested(),
      ); // Triggers a full reload to get freshest data
    } catch (e) {
      emit(DashboardError('Sinkronisasi gagal: $e'));
      // Attempt to load from cache as a fallback after failed sync
      final items = await repository.getCachedTransactionList();
      emit(DashboardLoaded(items));
    }
  }
}
