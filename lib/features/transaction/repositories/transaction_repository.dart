// lib/features/transaction/repositories/transaction_repository.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:ta_client/core/services/connectivity_service.dart';
import 'package:ta_client/core/services/hive_service.dart'; // Import HiveService
import 'package:ta_client/core/services/service_locator.dart';
import 'package:ta_client/features/transaction/models/transaction.dart';
import 'package:ta_client/features/transaction/services/transaction_service.dart';
import 'package:uuid/uuid.dart';

enum OfflineOperationType { create, update, delete }

class TransactionRepository {
  TransactionRepository({required this.transactionService})
    : _connectivityService = sl<ConnectivityService>(),
      _hiveService = sl<HiveService>();
  final TransactionService transactionService;
  final ConnectivityService _connectivityService;
  final HiveService _hiveService;
  static const Uuid _uuid = Uuid();

  static const String transactionListBoxName = 'transactionListCache_v2';
  static const String transactionListKey = 'all_transactions';
  static const String pendingTransactionsBoxName =
      'pendingTransactionsQueue_v2';

  Future<List<Transaction>> getCachedTransactionList() async {
    final listJson = await _hiveService.getJsonString(
      transactionListBoxName,
      transactionListKey,
    );
    if (listJson != null && listJson.isNotEmpty) {
      try {
        final decodedList = json.decode(listJson) as List<dynamic>;
        return decodedList
            .map(
              (jsonItem) => Transaction.fromJson(
                jsonItem as Map<String, dynamic>,
                // markLocal is implicit in the 'isLocal' field from toJsonForCache
              ),
            )
            .toList();
      } catch (e) {
        debugPrint(
          '[TransactionRepository] Error deserializing cached transaction list: $e. Returning empty and clearing corrupted cache.',
        );
        await _hiveService.delete(transactionListBoxName, transactionListKey);
        return [];
      }
    }
    return [];
  }

  Future<void> _saveDecodedTransactionListToCache(
    List<Transaction> transactions,
  ) async {
    transactions.sort((a, b) => b.date.compareTo(a.date));
    await _hiveService.putListAsJsonStringKey<Transaction>(
      transactionListBoxName,
      transactionListKey,
      transactions,
      (transaction) => transaction.toJsonForCache(),
    );
  }

  Future<void> _queuePendingOperation(
    OfflineOperationType operationType,
    Transaction
    transaction, // This transaction should have its isLocal flag set appropriately
  ) async {
    // Use a consistent key for pending ops related to a specific transaction ID,
    // especially for updates/deletes to avoid multiple pending ops for the same item.
    // For creates with local_ ID, the local_ ID itself can be part of the key.
    final operationKeySuffix = transaction.id.startsWith('local_')
        ? transaction
              .id // Use local ID for create/update of local
        : 'backend_${transaction.id}'; // Use backend ID for update/delete of synced

    final operationKey = 'op_${operationType.name}_$operationKeySuffix';

    final operationData = <String, dynamic>{
      'operationType': operationType.toString(),
      'transactionData': transaction
          .toJsonForCache(), // Ensure isLocal is correctly set in transaction before calling this
      'timestamp': DateTime.now().toIso8601String(),
      'originalTransactionId': transaction.id, // Store the ID used for queueing
    };
    await _hiveService.putJsonString(
      pendingTransactionsBoxName,
      operationKey, // This allows overwriting if multiple offline updates happen for the same item
      json.encode(operationData),
    );
    debugPrint(
      '[TransactionRepository] Queued $operationType for tx id ${transaction.id} with key $operationKey',
    );
  }

  Future<List<Transaction>> fetchTransactions({
    bool forceRefresh = false,
  }) async {
    final isOnline = await _connectivityService.isOnline;
    if (isOnline && forceRefresh) {
      debugPrint(
        '[TransactionRepository] Online & Force Refresh: Fetching transactions from service.',
      );
      try {
        final transactions = await transactionService.fetchTransactions();
        await _saveDecodedTransactionListToCache(
          transactions.map((t) => t.copyWith(isLocal: false)).toList(),
        );
        return transactions;
      } catch (e) {
        debugPrint(
          '[TransactionRepository] Online fetch failed during force refresh: $e. Returning cached if available.',
        );
        return getCachedTransactionList();
      }
    } else if (isOnline) {
      final cached = await getCachedTransactionList();
      if (cached.isNotEmpty) {
        debugPrint(
          '[TransactionRepository] Online: Returning cached transactions, with background refresh.',
        );
        // Fire and forget background refresh
        transactionService
            .fetchTransactions()
            .then(
              (freshTransactions) => _saveDecodedTransactionListToCache(
                freshTransactions
                    .map((t) => t.copyWith(isLocal: false))
                    .toList(),
              ),
            )
            .catchError(
              (Object err) => debugPrint(
                '[TransactionRepository] Background refresh failed: $err',
              ),
            );
        return cached;
      }
      debugPrint(
        '[TransactionRepository] Online: Cache empty, fetching from service.',
      );
      try {
        final transactions = await transactionService.fetchTransactions();
        await _saveDecodedTransactionListToCache(
          transactions.map((t) => t.copyWith(isLocal: false)).toList(),
        );
        return transactions;
      } catch (e) {
        debugPrint('[TransactionRepository] Online fetch failed: $e.');
        if (e is TransactionApiException && e.statusCode == 401) rethrow;
        return []; // Return empty list on other errors
      }
    } else {
      debugPrint(
        '[TransactionRepository] Offline: Returning cached transactions.',
      );
      return getCachedTransactionList();
    }
  }

  Future<Transaction> createTransaction(Transaction transactionInput) async {
    final isOnline = await _connectivityService.isOnline;
    // Ensure it has a local ID if it's a new creation
    final localTransaction =
        (transactionInput.id.isEmpty ||
            !transactionInput.id.startsWith('local_'))
        ? transactionInput.copyWith(id: 'local_${_uuid.v4()}', isLocal: true)
        : transactionInput.copyWith(isLocal: true); // Ensure isLocal is true

    final currentCachedList = await getCachedTransactionList();
    currentCachedList
      ..removeWhere((t) => t.id == localTransaction.id)
      ..add(localTransaction);
    await _saveDecodedTransactionListToCache(currentCachedList);

    if (isOnline) {
      try {
        debugPrint(
          '[TransactionRepository] Online: Creating transaction via service for local ID ${localTransaction.id}.',
        );
        final transactionDataForApi = localTransaction.copyWith(id: '');
        final createdTransactionFromApi = await transactionService
            .createTransaction(transactionDataForApi);

        final updatedList =
            await getCachedTransactionList(); // Re-fetch for atomicity
        updatedList
          ..removeWhere((t) => t.id == localTransaction.id)
          ..add(createdTransactionFromApi.copyWith(isLocal: false));
        await _saveDecodedTransactionListToCache(updatedList);

        // If this local ID was somehow in the pending queue, attempt to remove its operation key
        final pendingOpKey =
            'op_${OfflineOperationType.create.name}_${localTransaction.id}';
        await _hiveService.delete(pendingTransactionsBoxName, pendingOpKey);

        return createdTransactionFromApi;
      } catch (e) {
        debugPrint(
          '[TransactionRepository] Online create failed for local ID ${localTransaction.id}, queuing: $e',
        );
        await _queuePendingOperation(
          OfflineOperationType.create,
          localTransaction, // Queue the version with local_ ID and isLocal:true
        );
        if (e is TransactionApiException && e.statusCode == 401) rethrow;
        return localTransaction;
      }
    } else {
      debugPrint(
        '[TransactionRepository] Offline: Queuing create transaction for local ID ${localTransaction.id}.',
      );
      await _queuePendingOperation(
        OfflineOperationType.create,
        localTransaction,
      );
      return localTransaction;
    }
  }

  Future<Transaction> updateTransaction(Transaction transaction) async {
    final isOnline = await _connectivityService.isOnline;
    // Ensure isLocal is true for optimistic update / offline queueing
    final transactionToProcess = transaction.copyWith(isLocal: true);

    final currentCachedList = await getCachedTransactionList();
    final index = currentCachedList.indexWhere(
      (t) => t.id == transactionToProcess.id,
    );
    if (index != -1) {
      currentCachedList[index] = transactionToProcess;
    } else {
      // This case (updating a non-existent item) should be rare if UI flows correctly
      currentCachedList.add(transactionToProcess);
    }
    await _saveDecodedTransactionListToCache(currentCachedList);

    if (isOnline) {
      try {
        // If it's an update to an offline-created, unsynced transaction
        if (transactionToProcess.id.startsWith('local_')) {
          debugPrint(
            '[TransactionRepository] Online: Queuing update for unsynced local transaction ${transactionToProcess.id}.',
          );
          // The pending queue key for a local_ ID update should be distinct from its create op, or handled by sync logic
          await _queuePendingOperation(
            OfflineOperationType.update,
            transactionToProcess,
          );
          return transactionToProcess;
        }
        // It's an update to an already synced transaction
        debugPrint(
          '[TransactionRepository] Online: Updating transaction ${transactionToProcess.id} via service.',
        );
        final updatedTransactionFromApi = await transactionService
            .updateTransaction(
              transactionToProcess.copyWith(isLocal: false),
            ); // Send isLocal:false version

        final updatedList = await getCachedTransactionList();
        final apiIndex = updatedList.indexWhere(
          (t) => t.id == updatedTransactionFromApi.id,
        );
        if (apiIndex != -1) {
          updatedList[apiIndex] = updatedTransactionFromApi.copyWith(
            isLocal: false,
          );
        } else {
          updatedList.add(updatedTransactionFromApi.copyWith(isLocal: false));
        }
        await _saveDecodedTransactionListToCache(updatedList);

        // Remove pending operation for this backend ID if it existed
        final pendingOpKey =
            'op_${OfflineOperationType.update.name}_backend_${transactionToProcess.id}';
        await _hiveService.delete(pendingTransactionsBoxName, pendingOpKey);
        return updatedTransactionFromApi;
      } catch (e) {
        debugPrint(
          '[TransactionRepository] Online update for ${transactionToProcess.id} failed, queuing: $e',
        );
        await _queuePendingOperation(
          OfflineOperationType.update,
          transactionToProcess,
        );
        if (e is TransactionApiException && e.statusCode == 401) rethrow;
        return transactionToProcess;
      }
    } else {
      debugPrint(
        '[TransactionRepository] Offline: Queuing update for transaction ${transactionToProcess.id}.',
      );
      await _queuePendingOperation(
        OfflineOperationType.update,
        transactionToProcess,
      );
      return transactionToProcess;
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    final isOnline = await _connectivityService.isOnline;
    final currentCachedList = await getCachedTransactionList();
    Transaction? transactionToDeleteData;

    final originalLength = currentCachedList.length;
    currentCachedList.removeWhere((t) {
      if (t.id == transactionId) {
        transactionToDeleteData = t;
        return true;
      }
      return false;
    });

    if (currentCachedList.length < originalLength) {
      // Item was found and removed
      await _saveDecodedTransactionListToCache(currentCachedList);
    }

    if (isOnline) {
      try {
        final pendingOpKeyCreate =
            'op_${OfflineOperationType.create.name}_$transactionId'; // For local_ IDs
        final pendingOpKeyUpdate =
            'op_${OfflineOperationType.update.name}_${transactionId.startsWith("local_") ? transactionId : "backend_$transactionId"}';

        if (transactionId.startsWith('local_')) {
          debugPrint(
            '[TransactionRepository] Online: Removing unsynced local transaction $transactionId from pending queue.',
          );
          // If it was a pending create, remove that. If it was a pending update to a local, remove that too.
          await _hiveService.delete(
            pendingTransactionsBoxName,
            pendingOpKeyCreate,
          );
          await _hiveService.delete(
            pendingTransactionsBoxName,
            pendingOpKeyUpdate,
          );
        } else {
          debugPrint(
            '[TransactionRepository] Online: Deleting transaction $transactionId via service.',
          );
          await transactionService.deleteTransaction(transactionId);
          // Also remove from pending queue if it was an update/delete that failed and then user decided to delete
          await _hiveService.delete(
            pendingTransactionsBoxName,
            pendingOpKeyUpdate,
          );
          final pendingOpKeyDelete =
              'op_${OfflineOperationType.delete.name}_backend_$transactionId';
          await _hiveService.delete(
            pendingTransactionsBoxName,
            pendingOpKeyDelete,
          );
        }
      } catch (e) {
        debugPrint(
          '[TransactionRepository] Online delete for $transactionId failed, queuing delete operation: $e',
        );
        // Only queue delete for backend IDs if the online delete failed and we have the data
        if (!transactionId.startsWith('local_') &&
            transactionToDeleteData != null) {
          await _queuePendingOperation(
            OfflineOperationType.delete,
            transactionToDeleteData!.copyWith(isLocal: true),
          );
        }
        if (e is TransactionApiException && e.statusCode == 401) rethrow;
      }
    } else {
      debugPrint(
        '[TransactionRepository] Offline: Queuing delete for transaction $transactionId.',
      );
      final dataToQueue =
          transactionToDeleteData ??
          Transaction(
            id: transactionId,
            description: 'PENDING_DELETE',
            amount: 0,
            date: DateTime.now(),
            subcategoryId: '',
            isLocal: true,
          );
      await _queuePendingOperation(
        OfflineOperationType.delete,
        dataToQueue.copyWith(isLocal: true),
      );
    }
  }

  Future<Transaction> toggleBookmark(String transactionId) async {
    final currentCachedList = await getCachedTransactionList();
    final index = currentCachedList.indexWhere((t) => t.id == transactionId);

    if (index == -1) {
      throw Exception(
        'Transaction $transactionId not found in cache for bookmarking.',
      );
    }

    final transactionToToggle = currentCachedList[index];
    final optimisticallyUpdatedTx = transactionToToggle.copyWith(
      isBookmarked: !transactionToToggle.isBookmarked,
      isLocal: true, // Mark as needing sync because bookmark status changed
    );
    currentCachedList[index] = optimisticallyUpdatedTx;
    await _saveDecodedTransactionListToCache(currentCachedList);

    final isOnline = await _connectivityService.isOnline;
    if (isOnline) {
      try {
        // If it's a local (unsynced) transaction, just update its pending operation (or create one)
        if (transactionId.startsWith('local_')) {
          debugPrint(
            '[TransactionRepository] Online: Queuing bookmark toggle (as update) for local tx $transactionId.',
          );
          await _queuePendingOperation(
            OfflineOperationType.update,
            optimisticallyUpdatedTx,
          );
          return optimisticallyUpdatedTx;
        }
        debugPrint(
          '[TransactionRepository] Online: Toggling bookmark for $transactionId via service.',
        );
        final serverUpdatedTx = await transactionService.toggleBookmark(
          transactionId,
        );

        final updatedList =
            await getCachedTransactionList(); // Re-fetch for atomicity
        final serverIndex = updatedList.indexWhere(
          (t) => t.id == serverUpdatedTx.id,
        );
        if (serverIndex != -1) {
          updatedList[serverIndex] = serverUpdatedTx.copyWith(isLocal: false);
        } else {
          updatedList.add(serverUpdatedTx.copyWith(isLocal: false));
        }
        await _saveDecodedTransactionListToCache(updatedList);

        final pendingOpKey =
            'op_${OfflineOperationType.update.name}_backend_$transactionId';
        await _hiveService.delete(pendingTransactionsBoxName, pendingOpKey);

        return serverUpdatedTx;
      } catch (e) {
        debugPrint(
          '[TransactionRepository] Online bookmark toggle for $transactionId failed, change cached and queued: $e',
        );
        await _queuePendingOperation(
          OfflineOperationType.update,
          optimisticallyUpdatedTx,
        );
        if (e is TransactionApiException && e.statusCode == 401) rethrow;
        return optimisticallyUpdatedTx;
      }
    } else {
      debugPrint(
        '[TransactionRepository] Offline: Queuing bookmark toggle (as update) for transaction $transactionId.',
      );
      await _queuePendingOperation(
        OfflineOperationType.update,
        optimisticallyUpdatedTx,
      );
      return optimisticallyUpdatedTx;
    }
  }

  Future<void> syncPendingTransactions() async {
    final pendingBoxMap = _hiveService.getBoxEntries<String>(
      pendingTransactionsBoxName,
    );
    if (pendingBoxMap.isEmpty) {
      debugPrint('[TransactionRepository] No pending transactions to sync.');
      return;
    }
    final isOnline = await _connectivityService.isOnline;
    if (!isOnline) {
      debugPrint(
        '[TransactionRepository] Offline, cannot sync pending transactions.',
      );
      return;
    }

    debugPrint(
      '[TransactionRepository] Syncing ${pendingBoxMap.length} pending transaction operations.',
    );
    final successfulKeys = <String>[];
    final mainCache = await getCachedTransactionList(); // Load once

    // Sort operations by timestamp to process them in order
    final sortedOpEntries = pendingBoxMap.entries.toList()
      ..sort((a, b) {
        try {
          final dataA = json.decode(a.value) as Map<String, dynamic>;
          final dataB = json.decode(b.value) as Map<String, dynamic>;
          final timeA = DateTime.tryParse(dataA['timestamp'] as String? ?? '');
          final timeB = DateTime.tryParse(dataB['timestamp'] as String? ?? '');
          if (timeA != null && timeB != null) return timeA.compareTo(timeB);
          return 0;
        } catch (_) {
          return 0;
        }
      });

    for (final entry in sortedOpEntries) {
      final opKey = entry.key as String;
      final operationJson = entry.value;

      try {
        final operationData =
            json.decode(operationJson) as Map<String, dynamic>;
        final typeString = operationData['operationType'] as String;
        final payloadJson =
            operationData['transactionData'] as Map<String, dynamic>;
        // The 'originalTransactionId' is the ID used when this op was queued (local_ or backend)
        final originalTransactionId =
            operationData['originalTransactionId'] as String? ??
            (payloadJson['id'] as String);

        // Deserialize with markLocal: true as it's from the pending queue
        final pendingTransaction = Transaction.fromJson(
          payloadJson,
          markLocal: true,
        );

        debugPrint(
          '[TransactionRepository] Attempting to sync $typeString for original tx id $originalTransactionId (current payload id: ${pendingTransaction.id})',
        );

        if (typeString == OfflineOperationType.create.toString()) {
          // For create, always send without ID as backend assigns it.
          final createdTxFromApi = await transactionService.createTransaction(
            pendingTransaction.copyWith(id: ''), // Send blank ID for create
          );
          // Update cache: remove original local_, add backend version
          mainCache.removeWhere(
            (t) => t.id == originalTransactionId,
          ); // Use original ID for removal
          mainCache.add(createdTxFromApi.copyWith(isLocal: false));
          debugPrint(
            '[TransactionRepository] Synced CREATE for local $originalTransactionId to backend ${createdTxFromApi.id}',
          );
        } else if (typeString == OfflineOperationType.update.toString()) {
          if (originalTransactionId.startsWith('local_')) {
            // This was an item created offline and then potentially updated offline.
            // It should be synced as a 'create' operation with its latest data.
            final createdTxFromApi = await transactionService.createTransaction(
              pendingTransaction.copyWith(
                id: '',
              ), // Send latest data, backend assigns ID
            );
            mainCache.removeWhere((t) => t.id == originalTransactionId);
            mainCache.add(createdTxFromApi.copyWith(isLocal: false));
            debugPrint(
              '[TransactionRepository] Synced offline UPDATE (orig. offline CREATE) for local $originalTransactionId to backend ${createdTxFromApi.id}',
            );
          } else {
            // This was an update to an already synced (backend) ID.
            final updatedTxFromApi = await transactionService.updateTransaction(
              pendingTransaction.copyWith(
                id: originalTransactionId,
                isLocal: false,
              ), // Ensure using backend ID
            );
            final idx = mainCache.indexWhere(
              (t) => t.id == updatedTxFromApi.id,
            );
            if (idx != -1) {
              mainCache[idx] = updatedTxFromApi.copyWith(isLocal: false);
            } else {
              mainCache.add(
                updatedTxFromApi.copyWith(isLocal: false),
              ); // Should replace
            }
            debugPrint(
              '[TransactionRepository] Synced UPDATE for backend ID $originalTransactionId',
            );
          }
        } else if (typeString == OfflineOperationType.delete.toString()) {
          if (!originalTransactionId.startsWith('local_')) {
            // Only send delete to backend if it's a backend ID
            await transactionService.deleteTransaction(originalTransactionId);
            debugPrint(
              '[TransactionRepository] Synced DELETE for backend ID $originalTransactionId',
            );
          } else {
            debugPrint(
              '[TransactionRepository] Local transaction $originalTransactionId marked for delete was never synced to backend. Removed from queue.',
            );
          }
          // Remove from local cache regardless
          mainCache.removeWhere((t) => t.id == originalTransactionId);
        }
        successfulKeys.add(opKey);
        debugPrint(
          '[TransactionRepository] Successfully synced operation $opKey.',
        );
      } catch (e) {
        debugPrint(
          '[TransactionRepository] Failed to sync operation $opKey: $e',
        );
        if (e is TransactionApiException && e.statusCode == 401) {
          debugPrint('Auth error during sync, stopping sync for transactions.');
          break; // Stop further sync attempts on auth error
        }
        // For other errors, continue to next pending item
      }
    }

    // Batch delete successful operations from Hive
    if (successfulKeys.isNotEmpty) {
      final box = await _hiveService.getOpenBox<String>(
        pendingTransactionsBoxName,
      );
      await box.deleteAll(successfulKeys);
      debugPrint(
        '[TransactionRepository] Cleaned ${successfulKeys.length} synced transaction operations from queue.',
      );
    }
    // Save the potentially modified main cache after all operations
    await _saveDecodedTransactionListToCache(mainCache);

    if (successfulKeys.isNotEmpty &&
        successfulKeys.length < sortedOpEntries.length) {
      debugPrint(
        '[TransactionRepository] Some operations failed to sync and remain in queue.',
      );
    } else if (successfulKeys.isEmpty && sortedOpEntries.isNotEmpty) {
      debugPrint(
        '[TransactionRepository] No operations were successfully synced.',
      );
    }
  }
}
