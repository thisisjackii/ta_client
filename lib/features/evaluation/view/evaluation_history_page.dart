// lib/features/evaluation/view/evaluation_history_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; // For DateFormat
import 'package:ta_client/app/routes/routes.dart'; // For Routes
import 'package:ta_client/core/constants/app_colors.dart';
import 'package:ta_client/core/constants/app_dimensions.dart';
import 'package:ta_client/core/constants/app_strings.dart';
import 'package:ta_client/features/evaluation/bloc/evaluation_bloc.dart';
import 'package:ta_client/features/evaluation/bloc/evaluation_event.dart'; // For EvaluationNavigateToExisting
import 'package:ta_client/features/evaluation/bloc/evaluation_state.dart';

class EvaluationHistoryPage extends StatelessWidget {
  const EvaluationHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EvaluationBloc, EvaluationState>(
      builder: (context, state) {
        if (state.loading && state.history.isEmpty) {
          // Show loading only if history is empty
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                AppStrings.evaluationHistoryTitle,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppColors.greyBackground,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (!state.loading && state.history.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                AppStrings.evaluationHistoryTitle,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppColors.greyBackground,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.history_toggle_off,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Belum Ada Riwayat Evaluasi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lakukan evaluasi keuangan terlebih dahulu untuk melihat riwayat Anda di sini.',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        Routes.evaluationDateSelection,
                        (route) => false,
                      ),
                      child: const Text('Mulai Evaluasi'),
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
              AppStrings.evaluationHistoryTitle,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.greyBackground,
          ),
          body: Padding(
            padding: const EdgeInsets.all(AppDimensions.padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  // This title is redundant if AppBar has it, but keeping as per original
                  AppStrings.evaluationHistoryTitle,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppDimensions.smallPadding),
                Expanded(
                  child: ListView.builder(
                    itemCount: state.history.length,
                    itemBuilder: (context, index) {
                      final h = state.history[index];
                      final dateFormat = DateFormat('dd MMM yyyy');
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.cardRadius,
                          ),
                        ),
                        elevation: 2,
                        child: InkWell(
                          // Wrap with InkWell for tap effect
                          onTap: () {
                            // Dispatch event to BLoC to set dates and load data for this historical period
                            context.read<EvaluationBloc>().add(
                              EvaluationNavigateToExisting(
                                start: h.start,
                                end: h.end,
                              ),
                            );
                            // Navigate to the dashboard, BLoC will ensure data is loaded/set
                            Navigator.pushNamed(
                              context,
                              Routes.evaluationDashboard,
                            );
                          },
                          borderRadius: BorderRadius.circular(
                            AppDimensions.cardRadius,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(
                              AppDimensions.padding,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined, // Changed icon
                                  size: 28, // Slightly larger icon
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 16), // Increased spacing
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${dateFormat.format(h.start)} - ${dateFormat.format(h.end)}',
                                        style: const TextStyle(
                                          fontSize: 15, // Slightly larger date
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 8,
                                      ), // Increased spacing
                                      Wrap(
                                        // Use Wrap for better responsiveness
                                        spacing: 12,
                                        runSpacing: 6, // Increased run spacing
                                        children: [
                                          _buildStatusChip(
                                            h.ideal,
                                            'Ideal',
                                            AppColors.ideal,
                                          ),
                                          _buildStatusChip(
                                            h.notIdeal,
                                            'Tidak Ideal',
                                            AppColors.notIdeal,
                                          ),
                                          _buildStatusChip(
                                            h.incomplete,
                                            'Tidak Lengkap',
                                            AppColors.incomplete,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.grey,
                                ), // Chevron
                              ],
                            ),
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

  Widget _buildStatusChip(int count, String label, Color color) {
    if (count == 0) return const SizedBox.shrink(); // Don't show if count is 0
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.3),
        child: Text(
          count.toString(),
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      label: Text(label, style: TextStyle(fontSize: 11, color: color)),
      backgroundColor: color.withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      visualDensity: VisualDensity.compact,
    );
  }
}
