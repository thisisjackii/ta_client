// lib/features/evaluation/view/widgets/formula_explanation_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class FormulaExplanationDialog extends StatelessWidget {
  const FormulaExplanationDialog({
    required this.id,
    this.numerator,
    this.denominator,
    super.key,
  });

  final String id;
  final double? numerator;
  final double? denominator;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Formula:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _formulaWidget(showActualValues: false),
          const SizedBox(height: 16),
          const Text('Perhitungan:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _formulaWidget(showActualValues: true),
          const SizedBox(height: 16),
          Text(
            _description(),
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _formulaWidget({required bool showActualValues}) {
    final rawFormulas = {
      '0': r'\frac{Aset Likuid}{Pengeluaran bulanan}',
      '1': r'\frac{Aset Likuid}{Total Kekayaan Bersih} \times 100\%',
      '2': r'\frac{Total Utang}{Total Aset} \times 100\%',
      '3': r'\frac{Total Tabungan}{Penghasilan Kotor} \times 100\%',
      '4': r'\frac{Total Pembayaran Utang}{Penghasilan Bersih} \times 100\%',
      '5': r'\frac{Total Aset Diinvestasikan}{Total Kekayaan Bersih} \times 100\%',
    };

    final fraction = showActualValues && numerator != null && denominator != null
        ? r'\frac{' +
        numerator!.toStringAsFixed(0) +
        r'}{' +
        denominator!.toStringAsFixed(0) +
        r'}' +
        (id == '0' ? '' : r' \times 100\%')
        : rawFormulas[id] ?? '';

    return Math.tex(
      fraction,
      textStyle: const TextStyle(fontSize: 18),
    );
  }

  String _description() {
    final desc = {
      '0':
          'Rasio ini berfungsi untuk mengukur seberapa mudah mendapatkan uang tunai saat menghadapi kondisi darurat.',
      '1':
          'Rasio ini memperlihatkan indikasi terhadap berapa banyak jumlah nilai bersih kekayaan seseorang dalam bentuk kas atau setara kas.',
      '2':
          'Rasio ini adalah cara yang lebih luas untuk menghitung tingkat likuiditas.',
      '3':
          'Sebuah indikator yang menyatakan berapa persen dari pendapatan kotor yang disisihkan untuk penggunaan/konsumsi di masa depan dalam bentuk simpanan/tabungan.',
      '4':
          'Rasio ini mengindikasikan apakah dapat mempertahankan (memenuhi dan memelihara) kewajiban utang.',
      '5':
          'Rasio ini membandingkan nilai aset untuk investasi dengan total nilai bersih kekayaan.',
    };
    return desc[id] ?? 'Belum ada penjelasan untuk rasio ini.';
  }
}
