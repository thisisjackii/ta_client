// lib/features/budgeting/view/budgeting_intro_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/app/routes/routes.dart';
import 'package:ta_client/core/constants/app_colors.dart';
import 'package:ta_client/core/constants/app_dimensions.dart';
import 'package:ta_client/core/constants/app_strings.dart';
import 'package:ta_client/core/services/first_launch_service.dart';
import 'package:ta_client/core/services/service_locator.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_bloc.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_event.dart';

class BudgetingIntro extends StatelessWidget {
  const BudgetingIntro({super.key});

  @override
  Widget build(BuildContext context) {
    final firstLaunchService = sl<FirstLaunchService>(); // Get instance

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.info,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const Text(
              AppStrings.budgetingTitle,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
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
                    'Kelola anggaran sesuai dengan pekerjaanmu. Atur pengeluaran berdasarkan kategori yang benar-benar kamu butuhkan.',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    onPressed: () async {
                      // Make onPressed async
                      await firstLaunchService.setBudgetingIntroSeen(
                        true,
                      ); // Set flag
                      // Reset BudgetingBloc state for a fresh start
                      context.read<BudgetingBloc>().add(BudgetingResetState());
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
