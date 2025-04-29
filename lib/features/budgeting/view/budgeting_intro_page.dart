// lib/features/budgeting/view/budgeting_intro_page.dart
import 'package:flutter/material.dart';
import 'package:ta_client/app/routes/routes.dart';
import 'package:ta_client/core/constants/app_colors.dart';
import 'package:ta_client/core/constants/app_dimensions.dart';
import 'package:ta_client/core/constants/app_strings.dart';

class BudgetingIntro extends StatelessWidget {
  const BudgetingIntro({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
        title: const Text(AppStrings.budgetingTitle),
      ),
      body: Column(
        children: [
          Expanded(
            child: Image.asset(
              'assets/img/budgeting_background.png',
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.padding,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Raih Tujuan Keuanganmu dengan Budgeting yang Tepat!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const Text(
                    'Kelola anggaran sesuai dengan profesimu. Atur pengeluaran berdasarkan kategori yang benar-benar kamu butuhkan.',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, Routes.budgetingIncomeDate);
                    },
                    child: const Text(
                      AppStrings.start,
                      style: TextStyle(color: Colors.white),
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
