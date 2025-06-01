import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ta_client/core/utils/calculations.dart'; // Assuming formatToRupiah is here
import 'package:ta_client/features/transaction/models/transaction.dart';
import 'package:ta_client/features/transaction/view/widgets/transaction_double_entry_map.dart';

// Define cell styles for consistency
const TextStyle _headerStyle = TextStyle(
  fontWeight: FontWeight.bold,
  fontSize: 12,
);
const TextStyle _cellStyle = TextStyle(fontSize: 11);
const TextStyle _boldCellStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.bold,
);
const EdgeInsets _cellPadding = EdgeInsets.symmetric(
  horizontal: 6,
  vertical: 8,
);

class DoubleEntryRecapPage extends StatelessWidget {
  const DoubleEntryRecapPage({required this.transactions, super.key});
  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    final groupedSumsByDateAndCat =
        groupTransactions(transactions);
    final displayRows = <_DisplayRow>[];
    final dayMonthYearFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm:ss');

    final sortedDates = groupedSumsByDateAndCat.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final grandTotalSums = Sums();

    for (final dateKey in sortedDates) {
      final transactionsOnThisDate = transactions.where((t) {
        final txDateOnly = DateTime(t.date.year, t.date.month, t.date.day);
        return txDateOnly.isAtSameMomentAs(dateKey);
      }).toList()..sort((a, b) => a.date.compareTo(b.date));

      final dateSubtotalSums = Sums();
      var isFirstTransactionOfDate = true;

      for (final txn in transactionsOnThisDate) {
        final categoryName = txn.categoryName ?? 'Uncategorized';
        // final sumsForTxnCategoryOnDate = groupedSumsByDateAndCat[dateKey]?[categoryName]; // Not directly used for effects

        double assetEffect = 0;
        double liabilityEffect = 0;
        double incomeEffect = 0;
        double expenseEffect = 0;

        // Use txn.accountTypeName directly here
        if (_matchesAccountType(txn.accountTypeName, incomeKeywords)) {
          incomeEffect = txn.amount;
          assetEffect = txn.amount;
        } else if (_matchesAccountType(txn.accountTypeName, expenseKeywords)) {
          expenseEffect = txn.amount;
          assetEffect = -txn.amount;
        } else if (_matchesAccountType(txn.accountTypeName, assetKeywords)) {
          assetEffect = txn.amount;
          incomeEffect = txn.amount;
        } else if (_matchesAccountType(
          txn.accountTypeName,
          liabilityKeywords,
        )) {
          liabilityEffect = txn.amount;
          assetEffect = txn.amount;
        }

        displayRows.add(
          _DisplayRow(
            date: isFirstTransactionOfDate
                ? dayMonthYearFormat.format(txn.date)
                : null,
            time: timeFormat.format(txn.date),
            category: categoryName,
            asset: assetEffect,
            liability: liabilityEffect,
            income: incomeEffect,
            expense: expenseEffect,
            type: _DisplayRowType.transaction,
          ),
        );
        isFirstTransactionOfDate = false;

        dateSubtotalSums.asset += assetEffect;
        dateSubtotalSums.liability += liabilityEffect;
        dateSubtotalSums.income += incomeEffect;
        dateSubtotalSums.expense += expenseEffect;
      }

      if (transactionsOnThisDate.isNotEmpty) {
        displayRows.add(
          _DisplayRow(
            category: 'Subtotal ${dayMonthYearFormat.format(dateKey)}',
            asset: dateSubtotalSums.asset,
            liability: dateSubtotalSums.liability,
            income: dateSubtotalSums.income,
            expense: dateSubtotalSums.expense,
            type: _DisplayRowType.subtotal,
          ),
        );
        grandTotalSums.asset += dateSubtotalSums.asset;
        grandTotalSums.liability += dateSubtotalSums.liability;
        grandTotalSums.income += dateSubtotalSums.income;
        grandTotalSums.expense += dateSubtotalSums.expense;
      }
    }

    displayRows.add(
      _DisplayRow(
        category: 'Grand Total',
        asset: grandTotalSums.asset,
        liability: grandTotalSums.liability,
        income: grandTotalSums.income,
        expense: grandTotalSums.expense,
        type: _DisplayRowType.grandTotal,
      ),
    );
    final totalLiabilitiesAndEquity =
        grandTotalSums.liability +
        (grandTotalSums.income - grandTotalSums.expense);
    displayRows.add(
      _DisplayRow(
        category: 'TOTAL (Aset vs Liabilitas + Ekuitas)',
        asset: grandTotalSums.asset,
        liability: null,
        income: null,
        expense: totalLiabilitiesAndEquity,
        type: _DisplayRowType.balanceTotal,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Double-Entry Recap'),
        backgroundColor: Colors.deepPurple[100],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Table(
              border: TableBorder.all(color: Colors.grey[300]!),
              columnWidths: const <int, TableColumnWidth>{
                0: FixedColumnWidth(100), // Tanggal
                1: FixedColumnWidth(80), // Waktu
                2: IntrinsicColumnWidth(), // Kategori
                3: FixedColumnWidth(100), // Aset
                4: FixedColumnWidth(30), // =
                5: FixedColumnWidth(100), // Liabilitas
                6: FixedColumnWidth(120), // Pendapatan
                7: FixedColumnWidth(100), // Beban
              },
              children: [
                _buildHeaderRow(),
                ...displayRows.map(_buildDataRow),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TableRow _buildHeaderRow() {
    return TableRow(
      decoration: BoxDecoration(color: Colors.blue[100]),
      children: [
        _tableCell('Tanggal', style: _headerStyle, isHeader: true),
        _tableCell('Waktu', style: _headerStyle, isHeader: true),
        _tableCell('Kategori', style: _headerStyle, isHeader: true),
        _tableCell(
          'Aset',
          style: _headerStyle,
          alignment: TextAlign.right,
          isHeader: true,
        ),
        _tableCell(
          '=',
          style: _headerStyle,
          alignment: TextAlign.center,
          isHeader: true,
        ),
        _tableCell(
          'Liabilitas',
          style: _headerStyle,
          alignment: TextAlign.right,
          isHeader: true,
        ),
        _tableCell(
          'Pendapatan (+)',
          style: _headerStyle,
          alignment: TextAlign.right,
          isHeader: true,
        ),
        _tableCell(
          'Beban (-)',
          style: _headerStyle,
          alignment: TextAlign.right,
          isHeader: true,
        ),
      ],
    );
  }

  TableRow _buildDataRow(_DisplayRow rowData) {
    final isTotalRow =
        rowData.type == _DisplayRowType.subtotal ||
        rowData.type == _DisplayRowType.grandTotal ||
        rowData.type == _DisplayRowType.balanceTotal;
    final style = isTotalRow ? _boldCellStyle : _cellStyle;

    if (rowData.type == _DisplayRowType.balanceTotal) {
      return TableRow(
        decoration: BoxDecoration(
          color: isTotalRow ? Colors.blueGrey[50] : null,
        ),
        children: [
          _tableCell('', colSpan: 3, style: style),
          _tableCell(
            rowData.asset != null
                ? formatToRupiah(rowData.asset!)
                : '', // Use your currency formatter
            style: style,
            alignment: TextAlign.right,
          ),
          _tableCell('=', style: style, alignment: TextAlign.center),
          _tableCell('', colSpan: 2, style: style),
          _tableCell(
            rowData.expense != null
                ? formatToRupiah(rowData.expense!)
                : '', // This holds L+I-E
            style: style,
            alignment: TextAlign.right,
          ),
        ],
      );
    }

    return TableRow(
      decoration: BoxDecoration(color: isTotalRow ? Colors.grey[200] : null),
      children: [
        _tableCell(rowData.date ?? '', style: style),
        _tableCell(rowData.time ?? '', style: style),
        _tableCell(
          rowData.category,
          style: style,
          isCategory: rowData.type == _DisplayRowType.transaction,
        ),
        _tableCell(
          rowData.asset != null && (rowData.asset != 0 || isTotalRow)
              ? formatToRupiah(rowData.asset!)
              : '',
          style: style,
          alignment: TextAlign.right,
        ),
        _tableCell(
          rowData.type == _DisplayRowType.transaction ? '=' : '',
          style: style,
          alignment: TextAlign.center,
        ),
        _tableCell(
          rowData.liability != null && (rowData.liability != 0 || isTotalRow)
              ? formatToRupiah(rowData.liability!)
              : '',
          style: style,
          alignment: TextAlign.right,
        ),
        _tableCell(
          rowData.income != null && (rowData.income != 0 || isTotalRow)
              ? formatToRupiah(rowData.income!)
              : '',
          style: style,
          alignment: TextAlign.right,
        ),
        _tableCell(
          rowData.expense != null && (rowData.expense != 0 || isTotalRow)
              ? formatToRupiah(rowData.expense!)
              : '',
          style: style,
          alignment: TextAlign.right,
        ),
      ],
    );
  }

  Widget _tableCell(
    String text, {
    TextStyle? style,
    TextAlign alignment = TextAlign.left,
    bool isHeader = false,
    bool isCategory = false,
    int colSpan = 1,
  }) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Container(
        padding: _cellPadding,
        alignment: alignment == TextAlign.right
            ? Alignment.centerRight
            : alignment == TextAlign.center
            ? Alignment.center
            : Alignment.centerLeft,
        child: Text(text, style: style ?? _cellStyle, textAlign: alignment),
      ),
    );
  }
}

enum _DisplayRowType { transaction, subtotal, grandTotal, balanceTotal }

class _DisplayRow {

  _DisplayRow({
    required this.category, required this.type, this.date,
    this.time,
    this.asset = 0.0, // Keep default for easier construction if value is 0
    this.liability = 0.0,
    this.income = 0.0,
    this.expense = 0.0,
  });
  final String? date;
  final String? time;
  final String category;
  final double? asset; // Make them nullable
  final double? liability;
  final double? income;
  final double? expense;
  final _DisplayRowType type;
}

// These should be accessible (either here or imported)
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

bool _matchesAccountType(String? typeName, Set<String> keywords) {
  if (typeName == null || typeName.trim().isEmpty) return false;
  final normalizedName = typeName.trim().toLowerCase();
  for (final keyword in keywords) {
    if (normalizedName.contains(keyword)) return true;
  }
  return false;
}
