import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:ta_client/features/transaction/models/transaction.dart';

class Sums {
  double asset = 0;
  double liability = 0;
  double income = 0;
  double expense = 0;
}

// Define keyword sets for each account type
const Set<String> assetKeywords = {'aset', 'asset', 'aktiva'};
const Set<String> liabilityKeywords = {
  'liabilitas',
  'liability',
  'kewajiban',
  'hutang',
  'utang',
};
const Set<String> incomeKeywords = {
  'pemasukan',
  'income',
  'pendapatan',
  'penghasilan',
};
const Set<String> expenseKeywords = {
  'pengeluaran',
  'expense',
  'beban',
  'biaya',
};

// Helper function to normalize and check keywords
bool _matchesAccountType(String? typeName, Set<String> keywords) {
  if (typeName == null || typeName.trim().isEmpty) {
    return false;
  }
  final normalizedName = typeName.trim().toLowerCase();
  for (final keyword in keywords) {
    if (normalizedName.contains(keyword)) {
      // Use 'contains' for flexibility
      return true;
    }
  }
  return false;
}

Map<DateTime, Map<String, Sums>> groupTransactions(List<Transaction> txns) {
  final ret = <DateTime, Map<String, Sums>>{};

  if (txns.isEmpty) {
    debugPrint('[groupTransactions] Received empty transaction list.');
    return ret;
  }

  for (final t in txns) {
    final categoryName = t.categoryName ?? 'Uncategorized';
    final day = DateTime(t.date.year, t.date.month, t.date.day);
    final byCat = ret.putIfAbsent(day, () => <String, Sums>{});
    final sums = byCat.putIfAbsent(categoryName, Sums.new);

    final accountTypeName = t.accountTypeName;

    // Apply double-entry logic based on the primary account type of the transaction
    // Using the flexible keyword matching.

    if (_matchesAccountType(accountTypeName, incomeKeywords)) {
      // Rule 3: User Input: Pemasukan (Kredit) -> System Handling: Aset (Debit)
      sums.income += t.amount;
      sums.asset += t.amount;
      // debugPrint('  Processed as INCOME: TxID ${t.id}, Amount ${t.amount}, Income: ${sums.income}, Asset: ${sums.asset}');
    } else if (_matchesAccountType(accountTypeName, expenseKeywords)) {
      // Rule 4: User Input: Pengeluaran (Debit) -> System Handling: Aset (Kredit - means Aset decreases)
      sums.expense += t.amount;
      sums.asset -= t.amount;
      // debugPrint('  Processed as EXPENSE: TxID ${t.id}, Amount ${t.amount}, Expense: ${sums.expense}, Asset: ${sums.asset}');
    } else if (_matchesAccountType(accountTypeName, assetKeywords)) {
      // Rule 1: User Input: Aset (Debit) -> System Handling: Pemasukan (Kredit)
      // This rule assumes an asset increase is generally funded by income if not specified otherwise.
      sums.asset += t.amount;
      sums.income += t
          .amount; // If it's an asset appreciation that counts as income, or cash received
      // debugPrint('  Processed as ASSET (Rule 1): TxID ${t.id}, Amount ${t.amount}, Asset: ${sums.asset}, Income: ${sums.income}');
    } else if (_matchesAccountType(accountTypeName, liabilityKeywords)) {
      // Rule 2: User Input: Liabilitas (Kredit) -> System Handling: Aset (Debit)
      sums.liability += t.amount;
      sums.asset += t.amount;
      // debugPrint('  Processed as LIABILITY: TxID ${t.id}, Amount ${t.amount}, Liability: ${sums.liability}, Asset: ${sums.asset}');
    } else {
      debugPrint(
        '[groupTransactions] Unhandled accountTypeName: "$accountTypeName" for transaction ID ${t.id}. Amount ${t.amount} not applied.',
      );
    }
  }
  return ret;
}
