import 'package:flutter/material.dart';
import 'package:ta_client/app/routes/routes.dart';

class BudgetingIntro extends StatelessWidget {
  const BudgetingIntro({super.key});

  @override
  Widget build(BuildContext context) {
    const submitButtonColor = Color(0xff237BF5);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff81B7F3),
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
                  'Budgeting',
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
            child: Image.asset(
              'assets/img/budgeting_background.png',
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          // Bottom Half: Centered texts & button, spaced around
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Raih Tujuan Keuanganmu dengan Budgeting yang Tepat!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Text(
                    'Kelola anggaran sesuai dengan profesimu. Atur pengeluaran berdasarkan kategori yang benar-benar kamu butuhkan.',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: submitButtonColor,
                      ),
                      onPressed: () async {
                        await Navigator.pushNamed(context, Routes.budgetingIncomeDate);
                      },
                      child: const Text(
                        'Mulai',
                        style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white,),
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
