// lib/features/transaction/services/transaction_sync_service.dart
import 'dart:async'; // For StreamSubscription

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
// Import other repositories that need syncing
import 'package:ta_client/features/budgeting/repositories/budgeting_repository.dart';
import 'package:ta_client/features/transaction/repositories/transaction_repository.dart';

class TransactionSyncService {
  TransactionSyncService({
    required this.transactionRepository,
    required this.budgetingRepository,
    // required AuthState authState // If userId is needed for sync methods
  }) {
    // _authState = authState; // If needed
  }

  final TransactionRepository transactionRepository;
  final BudgetingRepository budgetingRepository;
  // late AuthState _authState;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  void startListening() {
    if (_connectivitySubscription != null) {
      debugPrint('[SyncService] Already listening to connectivity changes.');
      return;
    }
    debugPrint('[SyncService] Starting to listen for connectivity changes.');
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      // The result is a list because on some platforms multiple results can be emitted
      // For example, on Android both Wifi and Mobile connectivity can be true
      final isConnected = !results.contains(ConnectivityResult.none);

      if (isConnected) {
        debugPrint(
          '[SyncService] Connectivity restored. Triggering sync for all pending data...',
        );
        _syncAllPendingData();
      } else {
        debugPrint('[SyncService] Connectivity lost.');
      }
    });
    // Initial check
    Connectivity().checkConnectivity().then((results) {
      final isConnected = !results.contains(ConnectivityResult.none);
      if (isConnected) {
        debugPrint('[SyncService] Initial check: Connected. Triggering sync.');
        _syncAllPendingData();
      } else {
        debugPrint('[SyncService] Initial check: Offline.');
      }
    });
  }

  Future<void> _syncAllPendingData() async {
    // final currentUserId = _authState.currentUser?.id; // Get current user ID if sync methods require it
    // For now, assuming sync methods in repositories don't need explicit userId if JWT handles it or it's not needed.
    // If periodRepository.syncPendingPeriods needs userId, it would be passed from here.

    debugPrint('[SyncService] Attempting to sync pending transactions...');
    await transactionRepository.syncPendingTransactions().catchError((e) {
      debugPrint('[SyncService] Error syncing transactions: $e');
    });

    debugPrint('[SyncService] Attempting to sync pending budget plans...');
    await budgetingRepository.syncPendingBudgetPlans().catchError((e) {
      debugPrint('[SyncService] Error syncing budget plans: $e');
    });

    // debugPrint('[SyncService] Attempting to sync pending periods...');
    // Assuming PeriodRepository needs userId for context if creating periods for a specific user
    // This requires AuthState to be accessible or userId to be stored reliably.
    // For simplicity, if syncPendingPeriods can operate without explicit userId (e.g. on globally pending items
    // or if it fetches userId internally from a secure source), then no need to pass it.
    // String? currentUserId = sl<AuthState>().isLoggedIn ? sl<AuthState>().user!.id : null; // Example
    // if(currentUserId != null) {
    //    await periodRepository.syncPendingPeriods(currentUserId).catchError((e) {
    //        debugPrint('[SyncService] Error syncing periods: $e');
    //    });
    // } else {
    //    debugPrint('[SyncService] Cannot sync periods: user not logged in.');
    // }
    // await periodRepository.syncPendingPeriods().catchError((Object e) {
    //   // Placeholder for userId
    //   debugPrint('[SyncService] Error syncing periods: $e');
    // });

    debugPrint('[SyncService] All sync attempts finished.');
    // Optionally, trigger a global event or BLoC update to refresh UIs
    // e.g. context.read<DashboardBloc>().add(DashboardForceRefreshRequested()); (but can't access context here)
    // Better: BLoCs listen to a stream from this service or a global "sync_completed" event.
    // Or, individual repositories' sync methods could return a flag indicating if data changed,
    // and the BLoC that called sync can decide to refresh.
  }

  void dispose() {
    debugPrint('[SyncService] Disposing connectivity listener.');
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }
}
