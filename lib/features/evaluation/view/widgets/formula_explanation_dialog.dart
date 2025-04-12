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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
                child: Math.tex(
                  r'\frac{\textit{Aset Likuid}}{\textit{Pengeluaran bulanan}}',
                  textStyle: const TextStyle(fontSize: 18),
                  mathStyle: MathStyle.display,
                ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Hasil Anda:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Math.tex(
                r'\frac{\textit{Aset Likuid}}{\textit{Pengeluaran bulanan}}',
                textStyle: const TextStyle(fontSize: 18),
                mathStyle: MathStyle.display,
              ),
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
      case '2':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Formula:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Math.tex(
                r'\frac{\textit{Total Utang}}{\textit{Total Aset}} \times 100\%',
                textStyle: const TextStyle(fontSize: 18),
                mathStyle: MathStyle.display,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Hasil Anda:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Math.tex(
                r'\frac{\textit{Total Utang}}{\textit{Total Aset}} \times 100\%',
                textStyle: const TextStyle(fontSize: 18),
                mathStyle: MathStyle.display,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Rasio ini adalah cara yang lebih luas untuk menghitung tingkat likuiditas.',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        );
      case '3':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Formula:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Math.tex(
                r'\frac{\textit{Total Tabungan}}{\textit{Penghasilan Kotor}} \times 100\%',
                textStyle: const TextStyle(fontSize: 18),
                mathStyle: MathStyle.display,
              ),
            ),

            const SizedBox(height: 16),
            const Text(
              'Hasil Anda:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Math.tex(
                r'\frac{\textit{Total Tabungan}}{\textit{Penghasilan Kotor}} \times 100\%',
                textStyle: const TextStyle(fontSize: 18),
                mathStyle: MathStyle.display,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sebuah indikator yang menyatakan berapa persen dari pendapatan kotor yang disisihkan untuk penggunaan/konsumsi di masa depan dalam bentuk simpanan/tabungan.',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        );
      case '4':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Formula:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Math.tex(
                r'\frac{\textit{Total Pembayaran Utang}}{\textit{Penghasilan Bersih}} \times 100\%',
                textStyle: const TextStyle(fontSize: 18),
                mathStyle: MathStyle.display,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Hasil Anda:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Math.tex(
                r'\frac{\textit{Total Pembayaran Utang}}{\textit{Penghasilan Bersih}} \times 100\%',
                textStyle: const TextStyle(fontSize: 18),
                mathStyle: MathStyle.display,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Rasio ini mengindikasikan apakah dapat mempertahankan (memenuhi dan memelihara) kewajiban utang.',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        );
      case '5':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Formula:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Math.tex(
                r'\frac{\textit{Total Aset Diinvestasikan}}{\textit{Total Kekayaan Bersih}} \times 100\%',
                textStyle: const TextStyle(fontSize: 18),
                mathStyle: MathStyle.display,
              ),
            ),

            const SizedBox(height: 16),
            const Text(
              'Hasil Anda:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Math.tex(
                r'\frac{\textit{Total Aset Diinvestasikan}}{\textit{Total Kekayaan Bersih}} \times 100\%',
                textStyle: const TextStyle(fontSize: 18),
                mathStyle: MathStyle.display,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Rasio ini membandingkan nilai aset untuk investasi dengan total nilai bersih kekayaan.',
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
