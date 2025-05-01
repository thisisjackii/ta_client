// lib/features/transaction/view/widgets/double_entry_recap_page.dart
import 'package:flutter/material.dart';
import 'package:ta_client/features/transaction/models/transaction.dart';
import 'package:ta_client/features/transaction/view/widgets/transaction_double_entry_map.dart';

class DoubleEntryRecapPage extends StatelessWidget {
  const DoubleEntryRecapPage({required this.transactions, super.key});
  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    final grouped = groupTransactions(transactions);

    // Flatten into rows
    final rows = <_Row>[];
    grouped.forEach((date, byCat) {
      byCat.forEach((cat, sums) {
        rows.add(_Row(date: date, category: cat, sums: sums));
      });
      // Add a subtotal row per date
      final subtotal = Sums();
      for (final s in byCat.values) {
        subtotal
          ..asset += s.asset
          ..liability += s.liability
          ..income += s.income
          ..expense += s.expense;
      }
      rows.add(
        _Row(
          date: date,
          category: 'Subtotal',
          sums: subtotal,
          isSubtotal: true,
        ),
      );
    });

    // Grand totals
    final grand = Sums();
    rows.where((r) => !r.isSubtotal).forEach((r) {
      grand
        ..asset += r.sums.asset
        ..liability += r.sums.liability
        ..income += r.sums.income
        ..expense += r.sums.expense;
    });
    rows.add(
      _Row(date: null, category: 'Grand Total', sums: grand, isSubtotal: true),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Double‐Entry Recap')),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.resolveWith(
            (_) => Colors.blue[100],
          ),
          columns: const [
            DataColumn(label: Text('Tanggal')),
            DataColumn(label: Text('Kategori')),
            DataColumn(label: Text('Aset')),
            DataColumn(label: Text('Liabilitas')),
            DataColumn(label: Text('Pendapatan (+)')),
            DataColumn(label: Text('Beban (−)')),
          ],
          rows: rows.map((r) {
            final dateText = r.date != null
                ? '${r.date!.day}/${r.date!.month}/${r.date!.year}'
                : '';
            final style = r.isSubtotal
                ? const TextStyle(fontWeight: FontWeight.bold)
                : null;
            return DataRow(
              cells: [
                DataCell(Text(dateText, style: style)),
                DataCell(Text(r.category, style: style)),
                DataCell(Text(r.sums.asset.toStringAsFixed(0), style: style)),
                DataCell(
                  Text(r.sums.liability.toStringAsFixed(0), style: style),
                ),
                DataCell(Text(r.sums.income.toStringAsFixed(0), style: style)),
                DataCell(Text(r.sums.expense.toStringAsFixed(0), style: style)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// Helper row
class _Row {
  _Row({
    required this.date,
    required this.category,
    required this.sums,
    this.isSubtotal = false,
  });
  final DateTime? date;
  final String category;
  final Sums sums;
  final bool isSubtotal;
}
