import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/core/services/connectivity_service.dart';
import 'package:ta_client/features/transaction/bloc/dashboard_event.dart';
import 'package:ta_client/features/transaction/bloc/dashboard_state.dart';
import 'package:ta_client/features/transaction/models/transaction.dart';
import 'package:ta_client/features/transaction/repositories/transaction_repository.dart';
import 'package:ta_client/features/transaction/services/transaction_service.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({
    required this.repository,
    required this.connectivityService,
    required this.transactionService,
  }) : super(DashboardLoading()) {
    on<DashboardReloadRequested>(_onReload);
    on<DashboardItemDeleted>(_onItemDeleted);

    // Load initial data
    add(DashboardReloadRequested());
  }

  final TransactionRepository repository;
  final ConnectivityService connectivityService;
  final TransactionService transactionService;

  Future<void> _onReload(
    DashboardReloadRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      final online = await connectivityService.isOnline;
      debugPrint(
        "DashboardBloc: Connectivity is ${online ? 'online' : 'offline'}",
      );
      List<Transaction> items;
      if (online) {
        items = await transactionService.fetchTransactions();
        await repository.cacheTransactions(items);
      } else {
        items = repository.getCachedTransactions() ?? [];
      }
      emit(DashboardLoaded(items));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  void _onItemDeleted(
    DashboardItemDeleted event,
    Emitter<DashboardState> emit,
  ) {
    final currentState = state;
    if (currentState is DashboardLoaded) {
      final updatedItems = List.of(currentState.items)..remove(event.item);
      emit(DashboardLoaded(updatedItems));
    }
  }
}
