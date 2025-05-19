// lib/features/transaction/bloc/dashboard_bloc.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// No longer needs Hive directly here for token, AuthState/AuthBloc would handle it
import 'package:ta_client/core/services/connectivity_service.dart'; // Still useful for BLoC decisions
import 'package:ta_client/features/transaction/models/transaction.dart';
import 'package:ta_client/features/transaction/repositories/transaction_repository.dart';
import 'package:ta_client/features/transaction/services/transaction_service.dart'
    show TransactionApiException; // For specific error handling

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({
    required this.repository,
    required this.connectivityService,
    // TransactionService is no longer directly needed by BLoC, repository uses it
  }) : super(const DashboardLoading()) {
    on<DashboardLoadRequested>(_onLoadRequested); // Renamed for clarity
    on<DashboardForceRefreshRequested>(_onForceRefreshRequested);
    // ItemAdded/Deleted events now might imply these items were already processed by TransactionBloc
    // and DashboardBloc just needs to reflect the new list.
    // Or, DashboardBloc listens to TransactionBloc.
    // For simplicity, let's keep them as explicit events that trigger a reload or smart update.
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
      ),
    ); // Show loading but keep old items if available
    try {
      final items = await repository.fetchTransactions(
        forceRefresh: forceRefresh,
      );
      emit(DashboardLoaded(items));
    } on TransactionApiException catch (e) {
      if (e.statusCode == 401) {
        // This should ideally be handled by a global AuthBloc listening to API responses
        // or by AuthenticatedClient interceptor that notifies AuthBloc.
        // For now, direct handling:
        // final box = Hive.box<String>('secureBox'); // Example, better via AuthState/AuthBloc
        // await box.delete('jwt_token');
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

  // Called when TransactionBloc successfully creates/updates/deletes a transaction
  // and we want the dashboard to reflect this without a full reload if possible.
  void _onTransactionCreated(
    DashboardTransactionCreated event,
    Emitter<DashboardState> emit,
  ) {
    if (state is DashboardLoaded) {
      final currentItems = (state as DashboardLoaded).items;
      // Add to top assuming newest first, then sort by date for consistency
      final newItems = [event.transaction, ...currentItems]
        ..sort((a, b) => b.date.compareTo(a.date));
      emit(DashboardLoaded(newItems));
    } else {
      add(DashboardLoadRequested()); // Fallback to full load
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
        add(
          DashboardLoadRequested(),
        ); // If not found (e.g. due to filter changes), reload
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
      // No need to re-sort if original list was sorted
      emit(DashboardLoaded(newItems));
    } else {
      add(DashboardLoadRequested());
    }
  }

  Future<void> _onSyncPending(
    DashboardSyncPendingRequested event,
    Emitter<DashboardState> emit,
  ) async {
    // Could show a specific "Syncing..." state or message
    emit(
      DashboardLoading(
        items: state is DashboardLoaded ? (state as DashboardLoaded).items : [],
        isSyncing: true,
      ),
    );
    try {
      await repository.syncPendingTransactions();
      // After sync, always force refresh to get the latest state from server
      add(DashboardForceRefreshRequested());
    } catch (e) {
      // Error during sync, DashboardLoaded will reflect current cache, error message can be shown
      emit(DashboardError('Sinkronisasi gagal: $e'));
      // Fallback to just loading whatever is in cache
      final items = repository.getCachedTransactionList() ?? [];
      emit(DashboardLoaded(items));
    }
  }
}
