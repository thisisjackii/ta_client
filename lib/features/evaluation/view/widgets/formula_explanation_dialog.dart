import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class FormulaExplanationDialog extends StatelessWidget {
  final String id;

  const FormulaExplanationDialog({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    switch (id) {
      case '0':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Formula:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Math.tex(
              r'\frac{\textit{Aset Likuid}}{\textit{Pengeluaran bulanan}}',
              textStyle: const TextStyle(fontSize: 18),
              mathStyle: MathStyle.display,
            ),
            const SizedBox(height: 16),
            const Text(
              'Hasil Anda:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Math.tex(
              r'\frac{\textit{Aset Likuid}}{\textit{Pengeluaran bulanan}}',
              textStyle: const TextStyle(fontSize: 18),
              mathStyle: MathStyle.display,
            ),
            const SizedBox(height: 16),
            const Text(
              'Rasio ini berfungsi untuk mengukur seberapa mudah mendapatkan uang tunai saat menghadapi kondisi darurat.',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        );
      case '1':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Formula:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Math.tex(
              r'\frac{\textit{Aset Likuid}}{\textit{Total Kekayaan Bersih}} \times 100\%',
              textStyle: const TextStyle(fontSize: 18),
              mathStyle: MathStyle.display,
            ),
            const SizedBox(height: 16),
            const Text(
              'Hasil Anda:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Math.tex(
              r'\frac{\textit{Aset Likuid}}{\textit{Total Kekayaan Bersih}} \times 100\%',
              textStyle: const TextStyle(fontSize: 18),
              mathStyle: MathStyle.display,
            ),
            const SizedBox(height: 16),
            const Text(
              'Rasio ini memperlihatkan indikasi terhadap berapa banyak jumlah nilai bersih kekayaan seseorang dalam bentuk kas atau setara kas.',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        );
      default:
        return const Text('Belum ada penjelasan untuk rasio ini.');
    }
  }
}
