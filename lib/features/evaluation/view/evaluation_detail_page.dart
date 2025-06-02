// C:\Users\PONGO\RemoteProjects\ta_client\lib\features\evaluation\view\evaluation_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/core/constants/app_colors.dart';
import 'package:ta_client/core/constants/app_dimensions.dart';
import 'package:ta_client/core/constants/app_strings.dart';
import 'package:ta_client/core/utils/calculations.dart';
import 'package:ta_client/features/evaluation/bloc/evaluation_bloc.dart';
import 'package:ta_client/features/evaluation/bloc/evaluation_state.dart';
import 'package:ta_client/features/evaluation/models/evaluation.dart';
import 'package:ta_client/features/evaluation/utils/evaluation_calculator.dart';
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
        final String ratioIdentifierForLogic = item.backendRatioCode ?? item.id;

        final isLiquidityRatio = ratioIdentifierForLogic == 'LIQUIDITY_RATIO';
        final isSolvencyRatio = ratioIdentifierForLogic == 'SOLVENCY_RATIO';

        bool isDataEffectivelyEmpty =
            item.status == EvaluationStatusModel.incomplete &&
            item.yourValue == 0.0 &&
            (item.breakdown == null ||
                item.breakdown!.every((b) => b.value == 0.0));

        RatioDef? clientRatioDef;
        try {
          clientRatioDef = evaluationDefinitions().firstWhere(
            (def) =>
                def.backendCode == ratioIdentifierForLogic ||
                def.id == ratioIdentifierForLogic,
          );
        } catch (_) {
          debugPrint(
            "Could not find client RatioDef for identifier: $ratioIdentifierForLogic for detail page logic.",
          );
        }

        // This string is now PRIMARILY for the StatExpandableCard if needed,
        // or any text OTHER than the one inside CustomSliderSingleRange.
        // CustomSliderSingleRange will format its own display.
        final String displayValueStringForCardOrOtherText;
        if (isLiquidityRatio) {
          displayValueStringForCardOrOtherText = formatMonths(item.yourValue);
        } else {
          String formattedPercentage = item.yourValue.toStringAsFixed(
            item.yourValue.truncateToDouble() == item.yourValue ? 0 : 2,
          );
          if (formattedPercentage.endsWith(".00")) {
            formattedPercentage = formattedPercentage.substring(
              0,
              formattedPercentage.length - 3,
            );
          } else if (formattedPercentage.endsWith(".0")) {
            formattedPercentage = formattedPercentage.substring(
              0,
              formattedPercentage.length - 2,
            );
          }
          displayValueStringForCardOrOtherText = '$formattedPercentage%';
        }

        List<Map<String, String>> getSingleBreakdownEntry(
          String conceptualNameKey,
        ) {
          final entryValueObj = item.breakdown?.firstWhere(
            (e) => e.name == conceptualNameKey,
            orElse: () =>
                ConceptualComponentValue(name: conceptualNameKey, value: 0.0),
          );
          return entryValueObj != null
              ? [
                  {
                    'label': conceptualNameKey,
                    'value': formatToRupiah(entryValueObj.value),
                  },
                ]
              : [];
        }

        final List<String> currentRatioInputKeys = _getRatioInputKeys(
          clientRatioDef?.id ?? item.id,
        );
        final String numeratorConceptualKey = currentRatioInputKeys.isNotEmpty
            ? currentRatioInputKeys[0]
            : "Numerator N/A";
        final String denominatorConceptualKey = currentRatioInputKeys.length > 1
            ? currentRatioInputKeys[1]
            : "Denominator N/A";

        return Scaffold(
          appBar: AppBar(
            /* ... Same AppBar ... */
            title: const Text(
              AppStrings.ratioSummaryTitle,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.greyBackground,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: isSolvencyRatio
                ? []
                : [
                    IconButton(
                      icon: const Icon(Icons.info_rounded),
                      onPressed: () {
                        final numForFormula = item.calculatedNumerator ?? 0.0;
                        final denForFormula = item.calculatedDenominator ?? 1.0;

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
                              id: clientRatioDef?.id ?? item.id,
                              numerator: numForFormula,
                              denominator: denForFormula,
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
                Row(
                  /* ... Status Badge ... */
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    if (!isSolvencyRatio ||
                        (isSolvencyRatio &&
                            item.status != EvaluationStatusModel.ideal &&
                            item.status != EvaluationStatusModel.incomplete &&
                            item.yourValue != 0))
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: item.status == EvaluationStatusModel.ideal
                              ? Colors.green[50]
                              : (item.status == EvaluationStatusModel.notIdeal
                                    ? Colors.red[50]
                                    : Colors.grey[200]),
                          border: Border.all(
                            color: item.status == EvaluationStatusModel.ideal
                                ? Colors.green
                                : (item.status == EvaluationStatusModel.notIdeal
                                      ? Colors.red
                                      : Colors.grey),
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
                              : item.status == EvaluationStatusModel.notIdeal
                              ? 'Tidak Ideal'
                              : 'Tidak Lengkap',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: item.status == EvaluationStatusModel.ideal
                                ? Colors.green[800]
                                : item.status == EvaluationStatusModel.notIdeal
                                ? Colors.red[800]
                                : Colors.grey[700],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 32),

                if (isDataEffectivelyEmpty && !isSolvencyRatio)
                  Padding(
                    /* ... existing empty data message ... */
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                    child: Center(
                      child: Text(
                        'Data tidak cukup untuk menghitung rasio "${item.title}". Pastikan ada transaksi yang relevan pada periode terpilih.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.orange[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  )
                else if (clientRatioDef != null) ...[
                  // Pass item.yourValue and item.idealText to CustomSliderSingleRange
                  if (isLiquidityRatio) ...[
                    CustomSliderSingleRange(
                      currentValue: item.yourValue,
                      idealText:
                          item.idealText ?? clientRatioDef.idealText ?? "N/A",
                      limit: 3, // Specific for Liquidity
                      limitType: SliderLimitType
                          .moreThanEqual, // Specific for Liquidity
                      isMonthValue:
                          true, // Indicate this slider value is in months
                    ),
                    // REMOVE the redundant Text widget that was here
                    const SizedBox(height: 24),
                    StatExpandableCard(
                      title: _getRatioTitleForCard(clientRatioDef.id),
                      icon: Icons.bar_chart,
                      valuesAboveDivider: getSingleBreakdownEntry(
                        numeratorConceptualKey,
                      ),
                      valuesBelowDivider: getSingleBreakdownEntry(
                        denominatorConceptualKey,
                      ),
                    ),
                  ] else if (!isSolvencyRatio) ...[
                    CustomSliderSingleRange(
                      currentValue: item.yourValue,
                      idealText:
                          item.idealText ?? clientRatioDef.idealText ?? "N/A",
                      limit: _getLimitFromRatioDef(clientRatioDef),
                      limitType: _getLimitTypeFromRatioDef(clientRatioDef),
                      isMonthValue: false, // Default is percentage
                    ),
                    // REMOVE the redundant Text widget that was here
                    const SizedBox(height: 24),
                    StatExpandableCard(
                      title: _getRatioTitleForCard(clientRatioDef.id),
                      icon: Icons.bar_chart,
                      valuesAboveDivider: getSingleBreakdownEntry(
                        numeratorConceptualKey,
                      ),
                      valuesBelowDivider: getSingleBreakdownEntry(
                        denominatorConceptualKey,
                      ),
                    ),
                  ] else ...[
                    // Solvency Ratio
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
                    const SizedBox(height: 24),
                    StatExpandableCard(
                      title: _getRatioTitleForCard(clientRatioDef.id),
                      icon: Icons.bar_chart,
                      valuesAboveDivider: getSingleBreakdownEntry(
                        numeratorConceptualKey,
                      ),
                      valuesBelowDivider: getSingleBreakdownEntry(
                        denominatorConceptualKey,
                      ),
                    ),
                  ],
                ] else ...[
                  const Center(
                    child: Text(
                      "Detail rasio tidak dapat ditampilkan (definisi tidak ditemukan).",
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // Updated keys to NOT include (Numerator)/(Denominator)
  static const Map<String, String> _ratioCardTitles = {
    '0': 'Aset Likuid vs Pengeluaran Bulanan',
    '1': 'Aset Lancar vs Kekayaan Bersih',
    '2': 'Utang vs Aset',
    '3': 'Total Tabungan vs Penghasilan Kotor',
    '4': 'Pembayaran Utang vs Penghasilan Bersih',
    '5': 'Aset Investasi vs Kekayaan Bersih',
    '6': 'Total Kekayaan Bersih vs Total Aset',
  };

  static const Map<String, List<String>> _ratioInputKeysMap = {
    '0': ['Total Aset Likuid', 'Total Pengeluaran Bulanan'],
    '1': ['Total Aset Likuid', 'Total Kekayaan Bersih'],
    '2': ['Total Utang', 'Total Aset'],
    '3': ['Total Tabungan', 'Penghasilan Kotor'],
    '4': ['Total Pembayaran Utang Bulanan', 'Penghasilan Bersih'],
    '5': ['Total Aset Diinvestasikan', 'Total Kekayaan Bersih'],
    '6': ['Total Kekayaan Bersih', 'Total Aset'],
  };

  String _getRatioTitleForCard(String clientRatioDefId) {
    return _ratioCardTitles[clientRatioDefId] ?? 'Detail Rasio Tidak Diketahui';
  }

  List<String> _getRatioInputKeys(String clientRatioDefId) {
    return _ratioInputKeysMap[clientRatioDefId] ?? ['Data N/A', 'Data N/A'];
  }

  double _getLimitFromRatioDef(RatioDef def) {
    final textToParse = def.idealText ?? "";
    if (textToParse.startsWith("≥") ||
        textToParse.startsWith("≤") ||
        textToParse.startsWith(">") ||
        textToParse.startsWith("<")) {
      final match = RegExp(
        r'(\d+(\.\d+)?)',
      ).firstMatch(textToParse.substring(1));
      return match != null ? (double.tryParse(match.group(1)!) ?? 0) : 0;
    }
    final rangeMatch = RegExp(
      r'(\d+(\.\d+)?)%? - (\d+(\.\d+)?)%?',
    ).firstMatch(textToParse);
    if (rangeMatch != null) {
      return double.tryParse(rangeMatch.group(1)!) ?? 0;
    }
    return 0;
  }

  SliderLimitType _getLimitTypeFromRatioDef(RatioDef def) {
    final textToParse = def.idealText ?? "";
    if (textToParse.contains(" - ")) {
      return SliderLimitType.moreThanEqual;
    }
    if (textToParse.startsWith("≥")) return SliderLimitType.moreThanEqual;
    if (textToParse.startsWith("≤")) return SliderLimitType.lessThanEqual;
    if (textToParse.startsWith(">")) return SliderLimitType.moreThan;
    if (textToParse.startsWith("<")) return SliderLimitType.lessThan;
    return SliderLimitType.moreThanEqual;
  }
}
