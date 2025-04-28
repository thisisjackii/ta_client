// totals_summary.dart

import 'package:flutter/material.dart';

class TransactionTotalsSummary extends StatelessWidget {
  const TransactionTotalsSummary({
    required this.pemasukan,
    required this.pengeluaran,
    required this.total,
    super.key,
  });
  final String pemasukan;
  final String pengeluaran;
  final String total;

  Widget _col(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _col('Total Pemasukan', pemasukan),
          _col('Total Pengeluaran', pengeluaran),
          _col('Total', total),
        ],
      ),
    );
  }
}
