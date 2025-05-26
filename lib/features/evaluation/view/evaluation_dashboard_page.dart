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
    // No automatic load here anymore, as navigation logic handles it.
    // If evaluationStartDate and evaluationEndDate are null when this page is built,
    // it will redirect to date selection.
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EvaluationBloc, EvaluationState>(
      builder: (c, s) {
        // --- START OF ADDED/MODIFIED CODE ---
        if (s.evaluationStartDate == null || s.evaluationEndDate == null) {
          // If this page is reached without dates set in the BLoC state
          // (e.g., direct navigation after "intro seen" and "data exists" checks pass),
          // then redirect to the date selection page.
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
          // Show a temporary loading/message while redirecting
          return const Scaffold(
            body: Center(child: Text('Mengalihkan ke pemilihan tanggal...')),
          );
        }
        // --- END OF ADDED/MODIFIED CODE ---

        // Original loading check remains
        if (s.loading && s.dashboardItems.isEmpty) {
          // Only show full loading if items are empty
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Check if dashboardItems are empty AFTER dates are confirmed and not loading
        if (!s.loading &&
            s.dashboardItems.isEmpty &&
            s.evaluationStartDate != null &&
            s.evaluationEndDate != null) {
          // This implies calculation happened but yielded no items (e.g., no transactions in period)
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                AppStrings.evaluationDashboardTitle,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppColors.greyBackground,
              leading: IconButton(
                // Add back button if needed when no data
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
                      // Display selected date range
                      'Periode: ${s.evaluationStartDate != null ? '${s.evaluationStartDate!.day}/${s.evaluationStartDate!.month}/${s.evaluationStartDate!.year}' : '--'} s/d ${s.evaluationEndDate != null ? '${s.evaluationEndDate!.day}/${s.evaluationEndDate!.month}/${s.evaluationEndDate!.year}' : '--'}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: AppDimensions.padding),
                    ElevatedButton(
                      onPressed: () {
                        // Navigate back to date selection to try a different range
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

        // Log the full list once when it arrives
        // This debug print can be noisy, consider removing or conditionalizing it
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
            // Add a leading back button that goes to date selection or intro if appropriate
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                // Decide where to pop: to date selection or further back if needed
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
                        // Ensure s.evaluationStartDate and s.evaluationEndDate are not null here
                        '${s.evaluationStartDate!.day}/${s.evaluationStartDate!.month}/${s.evaluationStartDate!.year} - ${s.evaluationEndDate!.day}/${s.evaluationEndDate!.month}/${s.evaluationEndDate!.year}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.padding),
              if (s.loading &&
                  s
                      .dashboardItems
                      .isNotEmpty) // Show inline loading if refreshing
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
                    context.read<EvaluationBloc>().add(
                      EvaluationLoadDetailRequested(
                        evaluationResultDbId: item.backendEvaluationResultId,
                        clientRatioId: item.backendEvaluationResultId == null
                            ? item
                                  .id // Use client-side ID if no backend ID (offline/not yet synced)
                            : null, // Don't pass clientRatioId if backend ID exists
                      ),
                    );
                    Navigator.pushNamed(
                      context,
                      Routes.evaluationDetail,
                      // Pass the item.id which is the Ratio.id (or client-side '0'-'6')
                      // The detail page will use this to fetch or identify the correct item.
                      // If backendEvaluationResultId is available, that's more specific for backend-sourced items.
                      arguments: item.backendEvaluationResultId ?? item.id,
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
