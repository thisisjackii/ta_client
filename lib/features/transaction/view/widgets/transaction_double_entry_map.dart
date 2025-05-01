// lib/features/transaction/view/widgets/transaction_double_entry_map.dart
import 'package:ta_client/features/transaction/models/transaction.dart';

class Sums {
  double asset = 0;
  double liability = 0;
  double income = 0;
  double expense = 0;
}

Map<DateTime, Map<String, Sums>> groupTransactions(List<Transaction> txns) {
  final ret = <DateTime, Map<String, Sums>>{};
  for (final t in txns) {
    final day = DateTime(t.date.year, t.date.month, t.date.day);
    final byCat = ret.putIfAbsent(day, () => {});
    final sums = byCat.putIfAbsent(t.categoryName, Sums.new);

    switch (t.accountType.toLowerCase()) {
      case 'aset':
        sums.asset += t.amount;
      case 'liabilitas':
        sums.liability += t.amount;
      case 'pemasukan':
      case 'income':
        sums.income += t.amount;
      case 'pengeluaran':
      case 'expense':
        sums.expense += t.amount;
    }
  }
  return ret;
}
