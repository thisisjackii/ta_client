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
    // Data should be loaded by the time we reach this page,
    // or a redirect should have happened from EvaluationDatePage if dates are missing.
    // We can add a safety check here, though ideally EvaluationDatePage handles all prerequisites.
    final blocState = context.read<EvaluationBloc>().state;
    if (blocState.evaluationStartDate == null ||
        blocState.evaluationEndDate == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
          debugPrint(
            '[EvaluationDashboardPage] Critical: Dates missing. Redirecting to date selection.',
          );
          Navigator.pushReplacementNamed(
            context,
            Routes.evaluationDateSelection,
          );
        }
      });
    } else if (blocState.dashboardItems.isEmpty && !blocState.loading) {
      // This case should ideally be caught by EvaluationDatePage showing a SnackBar and keeping user there.
      // But as a fallback, if we reach here with empty items, redirect.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
          debugPrint(
            '[EvaluationDashboardPage] Critical: Dashboard items empty. Redirecting to date selection.',
          );
          Navigator.pushReplacementNamed(
            context,
            Routes.evaluationDateSelection,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EvaluationBloc, EvaluationState>(
      builder: (c, s) {
        // Check if dates are somehow null - this is a safeguard.
        // Primary guard is in EvaluationDatePage and initState of this page.
        if (s.evaluationStartDate == null || s.evaluationEndDate == null) {
          // This should ideally not be hit if routing is correct.
          return Scaffold(
            appBar: AppBar(
              title: const Text(AppStrings.evaluationDashboardTitle),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Periode evaluasi belum diatur.'),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(
                      context,
                      Routes.evaluationDateSelection,
                    ),
                    child: const Text('Pilih Periode'),
                  ),
                ],
              ),
            ),
          );
        }

        // If loading AND dashboard items are empty (initial load for this period)
        if (s.loading && s.dashboardItems.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(AppStrings.evaluationDashboardTitle),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // If NOT loading AND dashboard items are STILL empty after attempting to load
        // This case is now primarily handled by EvaluationDatePage showing a SnackBar
        // and keeping the user there. This block becomes a fallback or for edge cases
        // if the user somehow lands here.
        // For robustness, we can keep a simpler message or redirect.
        // However, the prompt explicitly said to revert it, assuming EvaluationDatePage handles it.
        // So, we assume s.dashboardItems will NOT be empty here due to prior page logic.

        // THE "Oops! Belum ada data..." UI BLOCK IS REMOVED FROM HERE.
        // We now expect dashboardItems to be populated if we reach this point without loading.

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
                // When going back, go to date selection to allow changing period
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
                        // Added null checks for safety, though they should be set
                        '${s.evaluationStartDate?.day ?? '-'}/${s.evaluationStartDate?.month ?? '-'}/${s.evaluationStartDate?.year ?? '-'} - ${s.evaluationEndDate?.day ?? '-'}/${s.evaluationEndDate?.month ?? '-'}/${s.evaluationEndDate?.year ?? '-'}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.padding),
              // Show loading indicator if we are reloading/recalculating but already have some items
              if (s.loading && s.dashboardItems.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
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
                    if (item.backendEvaluationResultId == null &&
                        item.backendRatioCode != null) {
                      detailClientRatioId = getClientRatioIdFromBackendCode(
                        item.backendRatioCode!,
                      );
                      if (detailClientRatioId == null) {
                        debugPrint(
                          'ERROR: Could not map backendRatioCode ${item.backendRatioCode} to a clientRatioId.',
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Error: Konfigurasi rasio tidak ditemukan.',
                            ),
                          ),
                        );
                        return;
                      }
                    } else if (item.backendEvaluationResultId == null &&
                        item.backendRatioCode == null) {
                      // This case indicates a client-side only item where its 'id' IS the clientRatioId
                      detailClientRatioId = item.id;
                    }

                    context.read<EvaluationBloc>().add(
                      EvaluationLoadDetailRequested(
                        evaluationResultDbId: item.backendEvaluationResultId,
                        clientRatioId: detailClientRatioId,
                      ),
                    );
                    Navigator.pushNamed(
                      context,
                      Routes.evaluationDetail,
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
                                            // OLD: '${item.id == '0' ? formatMonths(item.yourValue) : formatPercent(item.yourValue)} ${item.id != '6' ? (item.status == EvaluationStatusModel.ideal ? '(Ideal)' : '(Tidak Ideal)') : ''}',
                                            // NEW:
                                            '${item.backendRatioCode == 'LIQUIDITY_RATIO' ? formatMonths(item.yourValue) : formatPercent(item.yourValue)} ${item.backendRatioCode != 'SOLVENCY_RATIO' ? (item.status == EvaluationStatusModel.ideal ? '(Ideal)' : '(Tidak Ideal)') : ''}',
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
