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

class EvaluationDashboardPage extends StatefulWidget {
  const EvaluationDashboardPage({super.key});

  @override
  State<EvaluationDashboardPage> createState() =>
      _EvaluationDashboardPageState();
}

class _EvaluationDashboardPageState extends State<EvaluationDashboardPage>
    with RouteAware {
  @override
  void initState() {
    super.initState();
    // if we already have dates, automatically load
    final bloc = context.read<EvaluationBloc>();
    if (bloc.state.start != null && bloc.state.end != null) {
      debugPrint('▶️ initState: dispatching LoadDashboard');
      bloc.add(LoadDashboard());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EvaluationBloc, EvaluationState>(
      builder: (c, s) {
        if (s.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Log the full list once when it arrives
        debugPrint('📊 Dashboard items (${s.dashboardItems.length}):');
        for (final item in s.dashboardItems) {
          debugPrint(
            '  • [${item.id}] ${item.title}: value=${item.yourValue} '
            '${item.idealText != null ? "(ideal ${item.idealText})" : ""}',
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              AppStrings.evaluationDashboardTitle,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.greyBackground,
            actions: [
              IconButton(
                icon: const Icon(Icons.history),
                onPressed: () {
                  debugPrint('🔄 tapping history button, dispatch LoadHistory');
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
                        '${s.start != null ? '${s.start!.day}/${s.start!.month}/${s.start!.year}' : '--'} - '
                        '${s.end != null ? '${s.end!.day}/${s.end!.month}/${s.end!.year}' : '--'}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.padding),
              ...s.dashboardItems.map((item) {
                // Log each tile as it's built
                debugPrint('🔹 rendering tile for [${item.id}] ${item.title}');
                return GestureDetector(
                  onTap: () {
                    debugPrint(
                      '➡️ tapped item [${item.id}] ${item.title}, '
                      'dispatching LoadDetail',
                    );
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
                                // 1) Title sits on its own row
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // 2) now this Row lines up both "your" and "ideal" labels/values
                                Row(
                                  children: [
                                    // Your Ratio block
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            AppStrings.yourRatioLabel,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${item.id == '0' ? formatMonths(item.yourValue) : formatPercent(item.yourValue)}'
                                            ' ${item.id != '6'
                                                ? item.isIdeal
                                                      ? '(Ideal)'
                                                      : '(Not Ideal)'
                                                : ''}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: item.isIdeal
                                                  ? Colors.green[700]
                                                  : Colors.red[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Ideal Ratio block (if any)
                                    if (item.idealText != null)
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
