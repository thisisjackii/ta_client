// lib/features/evaluation/view/evaluation_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/core/constants/app_colors.dart';
import 'package:ta_client/core/constants/app_dimensions.dart';
import 'package:ta_client/core/constants/app_strings.dart';
import 'package:ta_client/core/utils/calculations.dart';
import 'package:ta_client/features/evaluation/bloc/evaluation_bloc.dart';
import 'package:ta_client/features/evaluation/bloc/evaluation_state.dart';
import 'package:ta_client/features/evaluation/models/evaluation.dart';
import 'package:ta_client/features/evaluation/view/widgets/custom_slider_double_range.dart';
import 'package:ta_client/features/evaluation/view/widgets/custom_slider_single_range.dart';
import 'package:ta_client/features/evaluation/view/widgets/evaluation_detail_card.dart';
import 'package:ta_client/features/evaluation/view/widgets/formula_explanation_dialog.dart';
import 'package:ta_client/features/evaluation/view/widgets/slider_limit_type.dart';

class EvaluationDetailPage extends StatelessWidget {
  const EvaluationDetailPage({required this.id, super.key});
  final String id;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EvaluationBloc, EvaluationState>(
      builder: (context, state) {
        if (state.loading || state.detailItem == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final item = state.detailItem!;

        // helper to pull breakdown entries by key
        List<Map<String, String>> entries(String key) {
          return item.breakdown
                  ?.where((e) => e.name == key)
                  .map(
                    (e) => {'label': e.name, 'value': formatToRupiah(e.value)},
                  )
                  .toList() ??
              [];
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              AppStrings.ratioSummaryTitle,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.greyBackground,
            actions: item.id == '6'
                ? []
                : [
                    IconButton(
                      icon: const Icon(Icons.info_rounded),
                      onPressed: () {
                        final keys = _ratioInputs[item.id] ?? [];

                        final breakdownMap =
                            (item.breakdown ?? {}) as Map<String, double>;

                        final numerator = breakdownMap[keys[0]] ?? 0.0;
                        final denominator = breakdownMap[keys[1]] ?? 1.0;

                        showDialog<void>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.cardRadius,
                              ),
                            ),
                            title: const Text('Penjelasan Rasio'),
                            content: FormulaExplanationDialog(
                              id: item.id,
                              numerator: numerator,
                              denominator: denominator,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text(AppStrings.cancel),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + Status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    if (item.id != '6')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: item.status == EvaluationStatusModel.ideal
                              ? Colors.green[50]
                              : Colors.red[50],
                          border: Border.all(
                            color: item.status == EvaluationStatusModel.ideal
                                ? Colors.green
                                : Colors.red,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.cardRadius,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withAlpha(50),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          item.status == EvaluationStatusModel.ideal
                              ? 'Ideal'
                              : 'Tidak Ideal',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: item.status == EvaluationStatusModel.ideal
                                ? Colors.green[800]
                                : Colors.red[800],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 32),

                // ID == 0: double‐range slider
                if (item.id == '0') ...[
                  const CustomSliderDoubleRange(),
                  const SizedBox(height: 32),

                  // Aset Likuid vs Pengeluaran Bulanan
                  StatExpandableCard(
                    title: 'Aset Likuid',
                    icon: Icons.bar_chart,
                    valuesAboveDivider: entries('Aset Likuid'),
                    valuesBelowDivider: entries('Pengeluaran Bulanan'),
                  ),

                  // other IDs (1–5): single‐range slider + breakdown
                ] else if (item.id != '6') ...[
                  CustomSliderSingleRange(
                    limit: _getLimit(item.id),
                    limitType: _getLimitType(item.id),
                  ),
                  const SizedBox(height: 32),

                  // for each ratio we show its two inputs + total/net
                  // e.g. for id '1': Aset Likuid / Net Worth
                  StatExpandableCard(
                    title: _ratioTitles[item.id]!,
                    icon: Icons.bar_chart,
                    valuesAboveDivider: entries(_ratioInputs[item.id]![0]),
                    valuesBelowDivider: entries(_ratioInputs[item.id]![1]),
                  ),

                  // ID == 6: solvency ratio
                ] else ...[
                  const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Rasio solvabilitas ini menunjukkan (dalam persentase) seberapa rentan terhadap risiko kebangkrutan.',
                          style: TextStyle(fontSize: 14),
                        ),
                        SizedBox(height: 16),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  StatExpandableCard(
                    title: 'Total Kekayaan Bersih',
                    icon: Icons.bar_chart,
                    valuesAboveDivider: entries('Total Kekayaan Bersih'),
                    valuesBelowDivider: entries('Total Aset'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  static const Map<String, String> _ratioTitles = {
    '1': 'Aset Lancar vs Kekayaan Bersih',
    '2': 'Utang vs Aset',
    '3': 'Total Tabungan vs Penghasilan Kotor',
    '4': 'Pembayaran Utang vs Penghasilan Bersih',
    '5': 'Investasi vs Kekayaan Bersih',
  };

  static const Map<String, List<String>> _ratioInputs = {
    '1': ['Aset Likuid', 'Total Kekayaan Bersih'],
    '2': ['Total Utang', 'Total Aset'],
    '3': ['Total Tabungan', 'Penghasilan Kotor'],
    '4': ['Total Pembayaran Utang', 'Penghasilan Bersih'],
    '5': ['Total Aset Diinvestasikan', 'Total Kekayaan Bersih'],
  };

  double _getLimit(String id) {
    return <String, double>{'1': 15, '2': 50, '3': 10, '4': 45, '5': 50}[id]!;
  }

  SliderLimitType _getLimitType(String id) {
    return <String, SliderLimitType>{
      '1': SliderLimitType.moreThanEqual,
      '2': SliderLimitType.lessThanEqual,
      '3': SliderLimitType.moreThanEqual,
      '4': SliderLimitType.lessThan,
      '5': SliderLimitType.moreThanEqual,
    }[id]!;
  }
}
