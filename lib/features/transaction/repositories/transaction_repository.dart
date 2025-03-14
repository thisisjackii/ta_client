// lib/features/transaction/repositories/transaction_repository.dart
import 'package:hive/hive.dart';
import 'package:ta_client/features/transaction/models/transaction.dart';
import 'package:ta_client/features/transaction/services/transaction_service.dart';

class TransactionRepository {
  TransactionRepository({required this.transactionService});
  final TransactionService transactionService;
  static const String _boxName = 'transactionBox';

  Future<List<Transaction>> fetchTransactions({required bool isOnline}) async {
    if (isOnline) {
      final transactions = await transactionService.fetchTransactions();
      await cacheTransactions(transactions);
      return transactions;
    } else {
      return getCachedTransactions() ?? [];
    }
  }

  Future<void> createTransaction(Transaction transaction, {required bool isOnline}) async {
    if (isOnline) {
      await transactionService.createTransaction(transaction);
      final transactions = await transactionService.fetchTransactions();
      await cacheTransactions(transactions);
    } else {
      // Cache pending transaction data (as a Map)
      await cachePendingTransaction(transaction.toJson());
    }
  }

  Future<void> updateTransaction(Transaction transaction, {required bool isOnline}) async {
    if (isOnline) {
      await transactionService.updateTransaction(transaction);
      final transactions = await transactionService.fetchTransactions();
      await cacheTransactions(transactions);
    } else {
      await cachePendingTransaction(transaction.toJson());
    }
  }

  Future<void> deleteTransaction(String transactionId, {required bool isOnline}) async {
    if (isOnline) {
      await transactionService.deleteTransaction(transactionId);
      final transactions = await transactionService.fetchTransactions();
      await cacheTransactions(transactions);
    } else {
      throw Exception('Delete not supported offline');
    }
  }

  Future<void> cacheTransactions(List<Transaction> transactions) async {
    final box = Hive.box<dynamic>(_boxName);
    final jsonList = transactions.map((t) => t.toJson()).toList();
    await box.put('transactions', jsonList);
  }

  List<Transaction>? getCachedTransactions() {
    final box = Hive.box<dynamic>(_boxName);
    final data = box.get('transactions');
    if (data != null) {
      return (data as List)
          .map((json) => Transaction.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return null;
  }

  Future<void> clearCachedTransactions() async {
    final box = Hive.box<dynamic>(_boxName);
    await box.delete('transactions');
  }

  // Pending transaction (for offline create/update)
  Future<void> cachePendingTransaction(
      Map<String, dynamic> transactionData,) async {
    final box = Hive.box<dynamic>(_boxName);
    await box.put('pending_transaction', transactionData);
  }

  Map<String, dynamic>? getCachedPendingTransaction() {
    final box = Hive.box<dynamic>(_boxName);
    final data = box.get('pending_transaction');
    if (data != null) {
      return Map<String, dynamic>.from(data as Map<dynamic, dynamic>);
    }
    return null;
  }

  Future<void> clearCachedPendingTransaction() async {
    final box = Hive.box<dynamic>(_boxName);
    await box.delete('pending_transaction');
  }

  // Sync pending transaction when connectivity is restored.
  Future<void> syncPendingTransaction() async {
    final pending = getCachedPendingTransaction();
    if (pending != null) {
      try {
        final transaction = Transaction.fromJson(pending);
        // For simplicity, if transaction.id is empty, we treat it as create; otherwise update.
        if (transaction.id.isEmpty) {
          await transactionService.createTransaction(transaction);
        } else {
          await transactionService.updateTransaction(transaction);
        }
        await clearCachedPendingTransaction();
        // Optionally refresh the full list in cache.
      } catch (e) {
        throw Exception('Failed to sync pending transaction: $e');
      }
    }
  }
}
