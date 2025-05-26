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
import 'package:ta_client/features/evaluation/models/evaluation.dart';
import 'package:ta_client/features/evaluation/utils/evaluation_calculator.dart'; // Import the new helpers

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
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EvaluationBloc, EvaluationState>(
      builder: (c, s) {
        if (s.evaluationStartDate == null || s.evaluationEndDate == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
              debugPrint(
                '[EvaluationDashboardPage] No dates found in state, redirecting to date selection.',
              );
              Navigator.pushReplacementNamed(
                context,
                Routes.evaluationDateSelection,
              );
            }
          });
          return const Scaffold(
            body: Center(child: Text('Mengalihkan ke pemilihan tanggal...')),
          );
        }

        if (s.loading && s.dashboardItems.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!s.loading &&
            s.dashboardItems.isEmpty &&
            s.evaluationStartDate != null &&
            s.evaluationEndDate != null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                AppStrings.evaluationDashboardTitle,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppColors.greyBackground,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.history),
                  onPressed: () {
                    context.read<EvaluationBloc>().add(
                      const EvaluationLoadHistoryRequested(),
                    );
                    Navigator.pushNamed(context, Routes.evaluationHistory);
                  },
                ),
              ],
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.padding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      AppStrings.noDataTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimensions.smallPadding),
                    const Text(
                      AppStrings.noDataSubtitle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimensions.padding),
                    Text(
                      'Periode: ${s.evaluationStartDate != null ? '${s.evaluationStartDate!.day}/${s.evaluationStartDate!.month}/${s.evaluationStartDate!.year}' : '--'} s/d ${s.evaluationEndDate != null ? '${s.evaluationEndDate!.day}/${s.evaluationEndDate!.month}/${s.evaluationEndDate!.year}' : '--'}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: AppDimensions.padding),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                          context,
                          Routes.evaluationDateSelection,
                        );
                      },
                      child: const Text('Pilih Periode Lain'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pushReplacementNamed(
                  context,
                  Routes.evaluationDateSelection,
                );
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.history),
                onPressed: () {
                  debugPrint('🔄 tapping history button, dispatch LoadHistory');
                  context.read<EvaluationBloc>().add(
                    const EvaluationLoadHistoryRequested(),
                  );
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
                        '${s.evaluationStartDate!.day}/${s.evaluationStartDate!.month}/${s.evaluationStartDate!.year} - ${s.evaluationEndDate!.day}/${s.evaluationEndDate!.month}/${s.evaluationEndDate!.year}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.padding),
              if (s.loading && s.dashboardItems.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ...s.dashboardItems.map((item) {
                debugPrint('🔹 rendering tile for [${item.id}] ${item.title}');
                return GestureDetector(
                  onTap: () {
                    debugPrint(
                      '➡️ tapped item [${item.id}] ${item.title}, '
                      'dispatching LoadDetail',
                    );

                    String? detailClientRatioId;
                    // If no backend ID, it means it's a client-side (offline) calculated item
                    if (item.backendEvaluationResultId == null) {
                      // Use the backendRatioCode to get the client-side numeric ID
                      detailClientRatioId = getClientRatioIdFromBackendCode(
                        item.backendRatioCode!,
                      );
                      if (detailClientRatioId == null) {
                        debugPrint(
                          'ERROR: Could not map backendRatioCode ${item.backendRatioCode} to a clientRatioId.',
                        );
                        // Handle error, e.g., show a dialog, prevent navigation
                        return;
                      }
                    }

                    context.read<EvaluationBloc>().add(
                      EvaluationLoadDetailRequested(
                        evaluationResultDbId: item.backendEvaluationResultId,
                        clientRatioId:
                            detailClientRatioId, // Pass the mapped ID here
                      ),
                    );
                    Navigator.pushNamed(
                      context,
                      Routes.evaluationDetail,
                      // The argument passed to the detail page should be the one used for fetching
                      // which is either the backend ID or the client-side numeric ID.
                      arguments:
                          item.backendEvaluationResultId ?? detailClientRatioId,
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
                                const SizedBox(height: 8),
                                Row(
                                  children: [
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
                                            '${item.id == '0' ? formatMonths(item.yourValue) : formatPercent(item.yourValue)} ${item.id != '6' ? (item.status == EvaluationStatusModel.ideal ? '(Ideal)' : '(Tidak Ideal)') : ''}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  item.status ==
                                                      EvaluationStatusModel
                                                          .ideal
                                                  ? Colors.green[700]
                                                  : Colors.red[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
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
