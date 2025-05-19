// lib/features/transaction/repositories/transaction_repository.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ta_client/core/services/connectivity_service.dart';
import 'package:ta_client/core/services/service_locator.dart';
import 'package:ta_client/features/transaction/models/transaction.dart';
import 'package:ta_client/features/transaction/services/transaction_service.dart';
import 'package:uuid/uuid.dart'; // For generating local IDs

class TransactionRepository {
  TransactionRepository({required this.transactionService}) {
    _connectivityService = sl<ConnectivityService>();
    _initHiveBoxes();
  }

  final TransactionService transactionService;
  late ConnectivityService _connectivityService;
  static const Uuid _uuid = Uuid();

  static const String _transactionListBox =
      'transactionListCache_v2'; // Key for the list of all transactions
  static const String _pendingTransactionsBox =
      'pendingTransactionsQueue_v2'; // For CUD operations

  Future<void> _initHiveBoxes() async {
    if (!Hive.isBoxOpen(_transactionListBox)) {
      await Hive.openBox<String>(_transactionListBox);
    }
    if (!Hive.isBoxOpen(_pendingTransactionsBox)) {
      await Hive.openBox<Map<dynamic, dynamic>>(
        _pendingTransactionsBox,
      ); // Stores Maps
    }
  }

  // --- Caching general transaction list ---
  Future<void> _cacheTransactionList(List<Transaction> transactions) async {
    final box = Hive.box<String>(_transactionListBox);
    // Store the entire list as a single JSON string under a known key
    final jsonList = transactions.map((t) => t.toJsonForCache()).toList();
    await box.put('all_transactions', json.encode(jsonList));
    debugPrint(
      '[TransactionRepository] Cached ${transactions.length} transactions.',
    );
  }

  List<Transaction>? getCachedTransactionList() {
    final box = Hive.box<String>(_transactionListBox);
    final data = box.get('all_transactions');
    if (data != null) {
      try {
        final decodedList = json.decode(data) as List<dynamic>;
        return decodedList
            .map(
              (jsonItem) => Transaction.fromJson(
                jsonItem as Map<String, dynamic>,
                markLocal: (jsonItem['isLocal'] ?? false) == true,
              ),
            )
            .toList();
      } catch (e) {
        debugPrint(
          '[TransactionRepository] Error deserializing cached transaction list: $e. Clearing cache.',
        );
        box.delete('all_transactions'); // Clear corrupted cache
        return null;
      }
    }
    return null;
  }

  // --- Pending Operations Queue ---
  Future<void> _queuePendingOperation(
    String operationType,
    Transaction transaction,
  ) async {
    final box = Hive.box<Map<dynamic, dynamic>>(_pendingTransactionsBox);
    // Use transaction.id (even local_id) as key to allow overwriting if multiple offline edits on same item
    await box.put(transaction.id, {
      'operationType': operationType,
      'transactionData': transaction
          .toJsonForCache(), // Store full data for reconstruction
      'timestamp': DateTime.now().toIso8601String(),
    });
    debugPrint(
      '[TransactionRepository] Queued pending $operationType for transaction ${transaction.id}',
    );
  }

  // --- Main Data Operations ---

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
        await _cacheTransactionList(transactions);
        return transactions;
      } catch (e) {
        debugPrint(
          '[TransactionRepository] Online fetch failed during force refresh: $e. Returning cached if available.',
        );
        return getCachedTransactionList() ?? []; // Fallback to cache on error
      }
    } else if (isOnline) {
      // Online but no force refresh, try cache first for speed
      final cached = getCachedTransactionList();
      if (cached != null && cached.isNotEmpty) {
        debugPrint(
          '[TransactionRepository] Online: Returning cached transactions.',
        );
        // Optionally, trigger a background sync/fetch here without blocking UI
        // transactionService.fetchTransactions().then(_cacheTransactionList).catchError((_){});
        return cached;
      }
      debugPrint(
        '[TransactionRepository] Online: Cache empty/invalid, fetching from service.',
      );
      try {
        final transactions = await transactionService.fetchTransactions();
        await _cacheTransactionList(transactions);
        return transactions;
      } catch (e) {
        debugPrint('[TransactionRepository] Online fetch failed: $e.');
        if (e is TransactionApiException && e.statusCode == 401) {
          rethrow; // Propagate auth error
        }
        return []; // Return empty on other errors if no cache
      }
    } else {
      // Offline
      debugPrint(
        '[TransactionRepository] Offline: Returning cached transactions.',
      );
      return getCachedTransactionList() ?? [];
    }
  }

  Future<Transaction> createTransaction(Transaction transactionInput) async {
    final isOnline = await _connectivityService.isOnline;
    // Assign a temporary local ID for offline tracking and optimistic UI updates
    final localTransaction =
        transactionInput.id.isEmpty || !transactionInput.id.startsWith('local_')
        ? transactionInput.copyWith(id: 'local_${_uuid.v4()}', isLocal: true)
        : transactionInput.copyWith(isLocal: true);

    if (isOnline) {
      try {
        debugPrint(
          '[TransactionRepository] Online: Creating transaction via service.',
        );
        final createdTransaction = await transactionService.createTransaction(
          localTransaction,
        ); // Send local with subcategoryId
        // Update cache after successful online creation
        final currentCached = getCachedTransactionList() ?? [];
        await _cacheTransactionList([...currentCached, createdTransaction]);
        return createdTransaction;
      } catch (e) {
        debugPrint('[TransactionRepository] Online create failed, queuing: $e');
        await _queuePendingOperation('create', localTransaction);
        if (e is TransactionApiException && e.statusCode == 401) rethrow;
        // For other errors, return the local optimistic version
        return localTransaction; // Optimistic update for UI
      }
    } else {
      // Offline
      debugPrint(
        '[TransactionRepository] Offline: Queuing create transaction.',
      );
      await _queuePendingOperation('create', localTransaction);
      // Optimistically update local cache for immediate UI feedback
      final currentCached = getCachedTransactionList() ?? [];
      await _cacheTransactionList([...currentCached, localTransaction]);
      return localTransaction;
    }
  }

  Future<Transaction> updateTransaction(Transaction transaction) async {
    final isOnline = await _connectivityService.isOnline;
    final transactionToUpdate = transaction.copyWith(
      isLocal: true,
    ); // Mark as local until synced

    if (isOnline) {
      try {
        // If the transaction.id is a 'local_' ID, it means it was created offline and not yet synced.
        // We can't "update" it on the backend yet. It should be part of the create queue.
        // If it's a real backend ID, then proceed with API update.
        if (transaction.id.startsWith('local_')) {
          debugPrint(
            '[TransactionRepository] Online: Queuing update for locally created (unsynced) transaction ${transaction.id}.',
          );
          await _queuePendingOperation(
            'update',
            transactionToUpdate,
          ); // This effectively overwrites any pending 'create'
          // Update cache optimistically
          final currentCached = getCachedTransactionList() ?? [];
          final index = currentCached.indexWhere((t) => t.id == transaction.id);
          if (index != -1) {
            currentCached[index] = transactionToUpdate;
          } else {
            currentCached.add(
              transactionToUpdate,
            ); // Should not happen if it was local
          }
          await _cacheTransactionList(currentCached);
          return transactionToUpdate;
        }

        debugPrint(
          '[TransactionRepository] Online: Updating transaction ${transaction.id} via service.',
        );
        final updatedTransaction = await transactionService.updateTransaction(
          transaction,
        );
        // Update cache
        final currentCached = getCachedTransactionList() ?? [];
        final index = currentCached.indexWhere(
          (t) => t.id == updatedTransaction.id,
        );
        if (index != -1) {
          currentCached[index] = updatedTransaction;
        } else {
          currentCached.add(updatedTransaction); // Should replace if ID matched
        }
        await _cacheTransactionList(currentCached);
        // Clear from pending queue if it was there for an update that failed previously
        await Hive.box<Map<dynamic, dynamic>>(
          _pendingTransactionsBox,
        ).delete(updatedTransaction.id);
        return updatedTransaction;
      } catch (e) {
        debugPrint(
          '[TransactionRepository] Online update for ${transaction.id} failed, queuing: $e',
        );
        await _queuePendingOperation('update', transactionToUpdate);
        if (e is TransactionApiException && e.statusCode == 401) rethrow;
        return transactionToUpdate; // Optimistic UI
      }
    } else {
      // Offline
      debugPrint(
        '[TransactionRepository] Offline: Queuing update for transaction ${transaction.id}.',
      );
      await _queuePendingOperation('update', transactionToUpdate);
      // Optimistic cache update
      final currentCached = getCachedTransactionList() ?? [];
      final index = currentCached.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        currentCached[index] = transactionToUpdate;
      } else {
        currentCached.add(
          transactionToUpdate,
        ); // If somehow not in cache but being updated offline
      }
      await _cacheTransactionList(currentCached);
      return transactionToUpdate;
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    final isOnline = await _connectivityService.isOnline;

    if (isOnline) {
      try {
        // If it's a local_id, it was never synced, so just remove from pending and cache.
        if (transactionId.startsWith('local_')) {
          debugPrint(
            '[TransactionRepository] Online: Deleting unsynced local transaction $transactionId from queue and cache.',
          );
          await Hive.box<Map<dynamic, dynamic>>(
            _pendingTransactionsBox,
          ).delete(transactionId);
        } else {
          debugPrint(
            '[TransactionRepository] Online: Deleting transaction $transactionId via service.',
          );
          await transactionService.deleteTransaction(transactionId);
          // Also remove from pending queue if it was an update that failed and then deleted
          await Hive.box<Map<dynamic, dynamic>>(
            _pendingTransactionsBox,
          ).delete(transactionId);
        }
      } catch (e) {
        debugPrint(
          '[TransactionRepository] Online delete for $transactionId failed, queuing delete operation: $e',
        );
        // If online delete fails, queue a 'delete' operation.
        // Need a placeholder Transaction object if only ID is known for queueing.
        // This is tricky. Simplest is to assume it was deleted locally and will be hard deleted on sync.
        if (!transactionId.startsWith('local_')) {
          // Only queue if it was a backend ID
          final placeholderForDelete = Transaction(
            id: transactionId,
            description: 'PENDING_DELETE',
            amount: 0,
            date: DateTime.now(),
            subcategoryId: '',
          );
          await _queuePendingOperation('delete', placeholderForDelete);
        }
        if (e is TransactionApiException && e.statusCode == 401) rethrow;
        // Don't throw for other errors if we queued it; local removal is the optimistic step.
      }
    } else {
      // Offline
      debugPrint(
        '[TransactionRepository] Offline: Queuing delete for transaction $transactionId.',
      );
      final placeholderForDelete = Transaction(
        id: transactionId,
        description: 'PENDING_DELETE',
        amount: 0,
        date: DateTime.now(),
        subcategoryId: '',
      );
      await _queuePendingOperation('delete', placeholderForDelete);
    }

    // Optimistic local cache removal for both online (after success or queue on fail) and offline
    final currentCached = getCachedTransactionList() ?? [];
    currentCached.removeWhere((t) => t.id == transactionId);
    await _cacheTransactionList(currentCached);
  }

  Future<Transaction> toggleBookmark(String transactionId) async {
    final isOnline = await _connectivityService.isOnline;
    Transaction? locallyModifiedTx;

    // Optimistically update local cache first
    final currentCached = getCachedTransactionList() ?? [];
    final index = currentCached.indexWhere((t) => t.id == transactionId);
    if (index != -1) {
      locallyModifiedTx = currentCached[index].copyWith(
        isBookmarked: !currentCached[index].isBookmarked,
        isLocal: true,
      );
      currentCached[index] = locallyModifiedTx;
      await _cacheTransactionList(currentCached);
    } else {
      throw Exception(
        'Transaction $transactionId not found in cache for bookmarking.',
      );
    }

    if (isOnline) {
      try {
        if (transactionId.startsWith('local_')) {
          // Unsynced transaction
          debugPrint(
            '[TransactionRepository] Online: Queuing bookmark toggle for locally created (unsynced) transaction $transactionId.',
          );
          await _queuePendingOperation(
            'update',
            locallyModifiedTx,
          ); // Treat as an update
          return locallyModifiedTx;
        }
        debugPrint(
          '[TransactionRepository] Online: Toggling bookmark for $transactionId via service.',
        );
        final updatedOnlineTx = await transactionService.toggleBookmark(
          transactionId,
        );
        // Sync back the server's version to the cache
        currentCached[index] = updatedOnlineTx; // Server is source of truth
        await _cacheTransactionList(currentCached);
        // If this was pending, ensure it's updated or handled correctly.
        // For simplicity, successful online op means we can remove a specific 'bookmark_pending' if such existed.
        // Or ensure the general 'update' queue reflects this latest state.
        return updatedOnlineTx;
      } catch (e) {
        debugPrint(
          '[TransactionRepository] Online bookmark toggle for $transactionId failed, change is cached and will be queued as update: $e',
        );
        await _queuePendingOperation(
          'update',
          locallyModifiedTx,
        ); // Queue the optimistic local change
        if (e is TransactionApiException && e.statusCode == 401) rethrow;
        return locallyModifiedTx; // Return optimistic change
      }
    } else {
      // Offline
      debugPrint(
        '[TransactionRepository] Offline: Queuing bookmark toggle as update for transaction $transactionId.',
      );
      await _queuePendingOperation('update', locallyModifiedTx);
      return locallyModifiedTx;
    }
  }

  // --- Syncing Logic ---
  Future<void> syncPendingTransactions() async {
    final pendingBox = Hive.box<Map<dynamic, dynamic>>(_pendingTransactionsBox);
    if (pendingBox.isEmpty) {
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
      '[TransactionRepository] Syncing ${pendingBox.length} pending transactions.',
    );
    final successfullySyncedKeys = <String>[];

    // It's safer to iterate over a copy of keys if modifying the box during iteration
    final pendingKeys = List<dynamic>.from(pendingBox.keys);

    for (final key in pendingKeys) {
      final pendingOpData = pendingBox.get(key);
      if (pendingOpData == null) continue;

      final operationType = pendingOpData['operationType'] as String;
      final transactionDataMap =
          pendingOpData['transactionData'] as Map<String, dynamic>;
      // Use markLocal: true because this data was from cache, which should denote its local status
      final transaction = Transaction.fromJson(
        transactionDataMap,
        markLocal: true,
      );

      try {
        debugPrint(
          '[TransactionRepository] Attempting to sync $operationType for tx id ${transaction.id}',
        );
        if (operationType == 'create') {
          // For create, the original transaction.id was 'local_...'
          // The backend will assign a new UUID. We need to update our local cache.
          final createdTx = await transactionService.createTransaction(
            transaction.copyWith(id: ''),
          ); // Send without local_ id
          // Update local cache: remove local_id version, add backend version
          final currentCached = getCachedTransactionList() ?? [];
          currentCached.removeWhere(
            (t) => t.id == transaction.id,
          ); // Remove local_
          currentCached.add(createdTx);
          await _cacheTransactionList(currentCached);
          // TODO: If other parts of app hold reference to 'local_id', they need to be updated to new backend ID.
          // This is a common challenge in offline-first sync.
          debugPrint(
            '[TransactionRepository] Synced CREATE for local ${transaction.id} to backend ${createdTx.id}',
          );
        } else if (operationType == 'update') {
          if (transaction.id.startsWith('local_')) {
            // This was an offline create, then an offline update. Sync as create with latest data.
            final createdTx = await transactionService.createTransaction(
              transaction.copyWith(id: ''),
            );
            final currentCached = getCachedTransactionList() ?? [];
            currentCached.removeWhere((t) => t.id == transaction.id);
            currentCached.add(createdTx);
            await _cacheTransactionList(currentCached);
            debugPrint(
              '[TransactionRepository] Synced offline UPDATE (originally offline CREATE) for local ${transaction.id} to backend ${createdTx.id}',
            );
          } else {
            await transactionService.updateTransaction(transaction);
            debugPrint(
              '[TransactionRepository] Synced UPDATE for ${transaction.id}',
            );
          }
        } else if (operationType == 'delete') {
          if (!transaction.id.startsWith('local_')) {
            // Only delete from backend if it was a synced ID
            await transactionService.deleteTransaction(transaction.id);
            debugPrint(
              '[TransactionRepository] Synced DELETE for ${transaction.id}',
            );
          } else {
            debugPrint(
              '[TransactionRepository] Local transaction ${transaction.id} marked for delete was never synced. Removed from queue.',
            );
          }
        }
        successfullySyncedKeys.add(key as String);
      } catch (e) {
        debugPrint(
          '[TransactionRepository] Failed to sync $operationType for tx ${transaction.id}: $e',
        );
        if (e is TransactionApiException && e.statusCode == 401) {
          debugPrint('Auth error during sync, stopping sync.');
          break; // Stop sync on auth error
        }
        // For other errors (e.g., 400 bad request due to stale data, 404 not found),
        // the item remains in queue. More sophisticated error handling could mark it as "sync_failed".
      }
    }

    for (final key in successfullySyncedKeys) {
      await pendingBox.delete(key);
    }
    if (successfullySyncedKeys.isNotEmpty) {
      debugPrint(
        '[TransactionRepository] Cleaned ${successfullySyncedKeys.length} synced transactions from queue.',
      );
      // After a successful sync, it's a good idea to fetch fresh list from server to resolve any conflicts
      // or get latest state if server made changes (e.g. last write wins on server).
      // This can be done by the BLoC that triggers the sync.
    }
  }
}
