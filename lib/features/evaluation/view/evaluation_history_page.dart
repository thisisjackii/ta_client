import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/core/constants/app_colors.dart';
import 'package:ta_client/core/constants/app_dimensions.dart';
import 'package:ta_client/core/constants/app_strings.dart';
import 'package:ta_client/features/evaluation/bloc/evaluation_bloc.dart';
import 'package:ta_client/features/evaluation/bloc/evaluation_state.dart';

class EvaluationHistoryPage extends StatelessWidget {
  const EvaluationHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EvaluationBloc, EvaluationState>(
      builder: (context, state) {
        if (state.loading) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()),);
        }
        return Scaffold(
          appBar: AppBar(title: const Text(AppStrings.evaluationHistoryTitle)),
          body: Padding(
            padding: const EdgeInsets.all(AppDimensions.padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.evaluationHistoryTitle,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppDimensions.smallPadding),
                Expanded(
                  child: ListView.builder(
                    itemCount: state.history.length,
                    itemBuilder: (context, index) {
                      final h = state.history[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimensions.cardRadius),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(AppDimensions.padding),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.date_range,
                                size: 24,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${h.start.day}/${h.start.month}/${h.start.year}'
                                      ' - '
                                      '${h.end.day}/${h.end.month}/${h.end.year}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 4,
                                      children: [
                                        Text(
                                          '${h.ideal} Ideal',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.ideal,
                                          ),
                                        ),
                                        Text(
                                          '${h.notIdeal} Tidak Ideal',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.notIdeal,
                                          ),
                                        ),
                                        Text(
                                          '${h.incomplete} Tidak Lengkap',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.incomplete,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
