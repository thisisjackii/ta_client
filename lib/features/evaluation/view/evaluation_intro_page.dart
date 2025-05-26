// lib/features/evaluation/view/evaluation_intro_page.dart
import 'package:flutter/material.dart';
import 'package:ta_client/app/routes/routes.dart';
import 'package:ta_client/core/constants/app_colors.dart';
import 'package:ta_client/core/constants/app_dimensions.dart';
import 'package:ta_client/core/constants/app_strings.dart';
import 'package:ta_client/core/services/first_launch_service.dart';
import 'package:ta_client/core/services/service_locator.dart';

class EvaluationIntroPage extends StatelessWidget {
  const EvaluationIntroPage({super.key});
  @override
  Widget build(BuildContext context) {
    final firstLaunchService = sl<FirstLaunchService>(); // Get instance

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.info,
        // automaticallyImplyLeading: false,
        // title: const Text(AppStrings.evaluationIntroTitle),
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const Text(
              AppStrings.evaluationIntroTitle,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Image.asset(
              'assets/img/10078322.png',
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
                children: [
                  const Text(
                    'Bagaimana Kondisi Keuanganmu? Cek Kesehatan Keuanganmu Yuk!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const Text(
                    AppStrings.evaluationIntroSubtitle,
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    onPressed: () async {
                      // Make onPressed async
                      await firstLaunchService.setEvaluationIntroSeen(
                        true,
                      ); // Set flag
                      if (context.mounted) {
                        await Navigator.pushNamed(
                          context,
                          Routes.evaluationDateSelection,
                        );
                      }
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
