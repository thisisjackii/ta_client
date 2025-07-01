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
import 'package:ta_client/features/evaluation/utils/evaluation_calculator.dart';

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
      // This might happen if user proceeded with a date range that had no data,
      // or if coming from history to a period that now has no data (e.g. tx deleted)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
          debugPrint(
            '[EvaluationDashboardPage] Warning: Dashboard items empty. User might need to re-select dates or data changed.',
          );
          // Optionally show a snackbar or just let it display empty state.
          // Forcing back to date selection might be too aggressive if it's a valid empty state.
          // For now, let it display. If this is undesirable, redirect:
          // Navigator.pushReplacementNamed(context, Routes.evaluationDateSelection);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EvaluationBloc, EvaluationState>(
      // Changed to BlocConsumer for SnackBar
      listener: (context, state) {
        // Handle any general errors or info messages that might pop up on the dashboard
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!), backgroundColor: Colors.red),
          );
          context.read<EvaluationBloc>().add(EvaluationClearError());
        }
      },
      builder: (context, state) {
        // Renamed context to builderContext for clarity
        if (state.evaluationStartDate == null ||
            state.evaluationEndDate == null) {
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
                      context, // Use builderContext here
                      Routes.evaluationDateSelection,
                    ),
                    child: const Text('Pilih Periode'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state.loading && state.dashboardItems.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(AppStrings.evaluationDashboardTitle),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // If not loading AND dashboard items are empty (e.g., after calculation or from history)
        if (!state.loading && state.dashboardItems.isEmpty) {
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      AppStrings.noDataTitle, // "Oops! Belum ada data..."
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings
                          .noDataSubtitle, // "Pastikan Anda sudah mencatat transaksi..."
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pushReplacementNamed(
                        context,
                        Routes.evaluationDateSelection,
                      ),
                      child: const Text('Pilih Periode Lain'),
                    ),
                  ],
                ),
              ),
            ),
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
                        '${state.evaluationStartDate?.day ?? '-'}/${state.evaluationStartDate?.month ?? '-'}/${state.evaluationStartDate?.year ?? '-'} - ${state.evaluationEndDate?.day ?? '-'}/${state.evaluationEndDate?.month ?? '-'}/${state.evaluationEndDate?.year ?? '-'}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.padding),
              if (state.loading && state.dashboardItems.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ...state.dashboardItems.map((item) {
                return GestureDetector(
                  onTap: () {
                    String? detailClientRatioId;
                    if (item.backendEvaluationResultId == null &&
                        item.backendRatioCode != null) {
                      detailClientRatioId = getClientRatioIdFromBackendCode(
                        item.backendRatioCode!,
                      );
                      if (detailClientRatioId == null) {
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
                                            '${item.backendRatioCode == 'LIQUIDITY_RATIO' ? formatMonths(item.yourValue) : formatPercent(item.yourValue)} ${item.backendRatioCode != 'SOLVENCY_RATIO' ? (item.status == EvaluationStatusModel.ideal ? '(Ideal)' : '(Tidak Ideal)') : ''}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  item.status ==
                                                      EvaluationStatusModel
                                                          .ideal
                                                  ? AppColors
                                                        .ideal // Use AppColors
                                                  : item.status ==
                                                        EvaluationStatusModel
                                                            .incomplete
                                                  ? AppColors
                                                        .notIdeal // Use AppColors
                                                  : AppColors
                                                        .notIdeal, // Use AppColors
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (item.idealText != null &&
                                        item.idealText !=
                                            '-') // Hide for Solvency
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
