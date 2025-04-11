import 'package:flutter/material.dart';
import 'package:ta_client/app/routes/routes.dart';

class EvaluationIntro extends StatelessWidget {
  const EvaluationIntro({super.key});

  @override
  Widget build(BuildContext context) {
    Color submitButtonColor = const Color(0xff237BF5);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xffA7D1FF),
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Text(
                  'Evaluasi Keuangan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Top Half: Full-width image (no padding)
          Expanded(
            flex: 1,
            child: Image.asset(
              'assets/img/10078322.png',
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          // Bottom Half: Centered texts & button, spaced around
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bagaimana Kondisi Keuanganmu? Cek Kesehatan Keuanganmu Yuk!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Ingin tahu ke mana uangmu pergi? Cek kesehatan keuanganmu dengan mencatat transaksi secara rutin. Dijamin gak ribet!',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: submitButtonColor,
                      ),
                      onPressed: () async {
                        await Navigator.pushNamed(context, Routes.evaluationDateSelection);
                      },
                      child: const Text(
                        'Mulai',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
