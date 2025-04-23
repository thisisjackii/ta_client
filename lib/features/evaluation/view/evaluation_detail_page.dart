import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_math_fork/flutter_math.dart';
import 'package:ta_client/core/constants/app_dimensions.dart';
import 'package:ta_client/core/constants/app_strings.dart';
import 'package:ta_client/features/evaluation/bloc/evaluation_bloc.dart';
import 'package:ta_client/features/evaluation/bloc/evaluation_state.dart';
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
        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.ratioSummaryTitle),
            actions: item.id == '6'
                ? []
                : [
                    IconButton(
                      icon: const Icon(Icons.info_rounded),
                      onPressed: () {
                        showDialog<void>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.cardRadius,
                              ),
                            ),
                            title: const Text('Penjelasan Rasio'),
                            content: FormulaExplanationDialog(id: item.id),
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
                          color: Colors.white,
                          border: Border.all(color: Colors.grey),
                          borderRadius:
                              BorderRadius.circular(AppDimensions.cardRadius),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withAlpha(50),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Status',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 32),
                if (item.id == '0') ...[
                  const CustomSliderDoubleRange(),
                  const SizedBox(height: 32),
                  const StatExpandableCard(
                    title: 'Aset Likuid',
                    icon: Icons.bar_chart,
                    valuesAboveDivider: [
                      {'label': 'Gaji', 'value': '15000'},
                      {'label': 'Uang di Bank', 'value': '5400'},
                    ],
                    valuesBelowDivider: [
                      {'label': 'Total', 'value': '19400'},
                    ],
                  ),
                  const StatExpandableCard(
                    title: 'Rata-rata pengeluaran bulanan',
                    icon: Icons.bar_chart,
                    valuesAboveDivider: [
                      {'label': 'Gaji', 'value': '15000'},
                      {'label': 'Uang di Bank', 'value': '5400'},
                    ],
                    valuesBelowDivider: [
                      {'label': 'Total', 'value': '19400'},
                    ],
                  ),
                ] else if (item.id != '6') ...[
                  CustomSliderSingleRange(
                    limit: _getLimit(item.id),
                    limitType: _getLimitType(item.id),
                  ),
                  const SizedBox(height: 32),
                  // Additional StatExpandableCard widgets per ratio...
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
                        // Math.tex(
                        //   r'\frac{Total Kekayaan Bersih}{Total Aset} \times 100\%',
                        //   textStyle: const TextStyle(fontSize: 18),
                        // ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const StatExpandableCard(
                    title: 'Total Kekayaan Bersih',
                    icon: Icons.bar_chart,
                    valuesAboveDivider: [
                      {'label': 'Saham', 'value': '15000'},
                      {'label': 'Properti investasi', 'value': '5400'},
                    ],
                    valuesBelowDivider: [
                      {'label': 'Total', 'value': '19400'},
                    ],
                  ),
                  const StatExpandableCard(
                    title: 'Total Aset',
                    icon: Icons.bar_chart,
                    valuesAboveDivider: [
                      {'label': 'Pendapatan bulanan', 'value': '-'},
                      {'label': 'Gaji', 'value': '-'},
                    ],
                    valuesBelowDivider: [
                      {'label': 'Total', 'value': '-'},
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  double _getLimit(String id) {
    return <String, double>{
      '1': 15,
      '2': 50,
      '3': 10,
      '4': 45,
      '5': 50,
    }[id]!;
  }

  SliderLimitType _getLimitType(String id) {
    return <String, SliderLimitType>{
      '1': SliderLimitType.moreThan,
      '2': SliderLimitType.lessThanEqual,
      '3': SliderLimitType.moreThanEqual,
      '4': SliderLimitType.moreThan,
      '5': SliderLimitType.moreThanEqual,
    }[id]!;
  }
}
