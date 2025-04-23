// lib/features/evaluation/view/evaluation_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/app/routes/routes.dart';
import 'package:ta_client/core/constants/app_colors.dart';
import 'package:ta_client/core/constants/app_dimensions.dart';
import 'package:ta_client/core/constants/app_strings.dart';
import 'package:ta_client/core/utils/calculations.dart';
import 'package:ta_client/features/evaluation/bloc/evaluation_bloc.dart';
import 'package:ta_client/features/evaluation/bloc/evaluation_event.dart';
import 'package:ta_client/features/evaluation/bloc/evaluation_state.dart';

class EvaluationDashboardPage extends StatelessWidget {
  const EvaluationDashboardPage({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EvaluationBloc, EvaluationState>(
      builder: (c, s) {
        if (s.loading) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()),);
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.evaluationDashboardTitle),
            actions: [
              IconButton(
                icon: const Icon(Icons.restart_alt_rounded),
                onPressed: () {
                  context.read<EvaluationBloc>().add(LoadHistory());
                  Navigator.pushNamed(context, Routes.evaluationHistory);
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppDimensions.padding),
            children: [
              const Text(
                AppStrings.evaluationDashboardSubtitle,
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: AppDimensions.smallPadding),
              Card(
                color: AppColors.dateCardBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.smallPadding),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.date_range,
                        size: AppDimensions.iconSize,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: AppDimensions.smallPadding),
                      Text(
                        '${s.start != null ? '${s.start!.day}/${s.start!.month}/${s.start!.year}' : '--'} - ${s.end != null ? '${s.end!.day}/${s.end!.month}/${s.end!.year}' : '--'}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.padding),
              ...s.dashboardItems.map((item) {
                return GestureDetector(
                  onTap: () {
                    context.read<EvaluationBloc>().add(LoadDetail(item.id));
                    Navigator.pushNamed(
                      context,
                      Routes.evaluationDetail,
                      arguments: item.id,
                    );
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.smallPadding,
                      ),
                    ),
                    elevation: 2,
                    margin: const EdgeInsets.only(
                      bottom: AppDimensions.smallPadding,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.padding),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  AppStrings.yourRatioLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formatPercent(item.yourValue),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (item.idealText != null)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    AppStrings.idealRatioLabel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.idealText!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
