// lib/features/transaction/bloc/transaction_bloc.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:ta_client/features/transaction/repositories/transaction_repository.dart';

class TransactionSyncService {
  TransactionSyncService({required this.repository});
  final TransactionRepository repository;

  void startListening() {
    Connectivity().onConnectivityChanged.listen((result) {
      if (!result.contains(ConnectivityResult.none)) {
        debugPrint('Connectivity restored, syncing pending transaction...');
        repository.syncPendingTransaction();
      }
    });
  }
}
