import 'package:flutter/material.dart';
import 'package:ta_client/features/evaluation/view/widgets/custom_slider_double_range.dart';
import 'package:ta_client/features/evaluation/view/widgets/custom_slider_single_range.dart';
import 'package:ta_client/features/evaluation/view/widgets/slider_limit_type.dart';
import 'package:ta_client/features/evaluation/view/widgets/evaluation_detail_card.dart';
import 'package:ta_client/features/evaluation/view/widgets/formula_explanation_dialog.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class EvaluationDetailPage extends StatefulWidget {

  const EvaluationDetailPage({required this.id, super.key});
  final String id;

  @override
  State<EvaluationDetailPage> createState() => _EvaluationDetailPageState();
}

class _EvaluationDetailPageState extends State<EvaluationDetailPage> {
  late double yourRatioValue;
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    // Sample logic based on ID – can be dynamic later
    if (widget.id == '0') {
      yourRatioValue = 4;
    } else if (widget.id == '1') {
      yourRatioValue = 8; // fallback or other values
    } else if (widget.id == '2') {
      yourRatioValue = 75; // fallback or other values
    } else if (widget.id == '3') {
      yourRatioValue = 51; // fallback or other values
    } else if (widget.id == '4') {
      yourRatioValue = 92; // fallback or other values
    } else if (widget.id == '5') {
      yourRatioValue = 36; // fallback or other values
    }  else if (widget.id == '6') {
      yourRatioValue = 36; // fallback or other values
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailContent = {
      '0': 'Rasio Likuiditas',
      '1': 'Rasio aset lancar terhadap kekayaan bersih',
      '2': 'Rasio utang terhadap aset',
      '3': 'Rasio Tabungan',
      '4': 'Rasio kemampuan pelunasan hutang',
      '5': 'Aset investasi terhadap nilai bersih kekayaan',
      '6': 'Rasio Solvabilitas',
    };

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ringkasan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: widget.id == '6' ? [] : [
          IconButton(
            icon: const Icon(Icons.info_rounded),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('Penjelasan Rasio'),
                    content: FormulaExplanationDialog(id: widget.id),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Tutup'),
                      ),
                    ],
                  );
                },
              );
            },

          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left Text
                Expanded(
                  child: Text(
                    detailContent[widget.id] ?? '',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),

                const SizedBox(width: 12),

                // Right Hugging Card
                widget.id == '6'
                    ? const SizedBox.shrink()
                    : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey), // customize color
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
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
            if (widget.id == '0') ...[
              CustomSliderDoubleRange(
                id: widget.id,
                yourRatioValue: yourRatioValue,
              ),
              const SizedBox(height: 32),
              StatExpandableCard(
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
              StatExpandableCard(
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
            ] else if (widget.id == '1') ...[
              CustomSliderSingleRange(
                yourRatio: yourRatioValue,
                limit: 15,
                limitType: SliderLimitType.moreThan,
              ),
              const SizedBox(height: 32),
              StatExpandableCard(
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
              StatExpandableCard(
                title: 'Aset Non-Likuid',
                icon: Icons.bar_chart,
                valuesAboveDivider: [
                  {'label': 'Aset Non-Likuid 1', 'value': '-'},
                  {'label': 'Aset Non-Likuid 2', 'value': '-'},
                ],
                valuesBelowDivider: [
                  {'label': 'Total', 'value': '-'},
                ],
              ),
              StatExpandableCard(
                title: 'Kewajiban (Liabilitas)',
                icon: Icons.bar_chart,
                valuesAboveDivider: [
                  {'label': 'Contoh Kewajiban 1', 'value': '-'},
                  {'label': 'Contoh Kewajiban 2', 'value': '-'},
                ],
                valuesBelowDivider: [
                  {'label': 'Total', 'value': '-'},
                ],
              ),
            ] else if (widget.id == '2') ...[
              CustomSliderSingleRange(
                yourRatio: yourRatioValue,
                limit: 50,
                limitType: SliderLimitType.lessThanEqual,
              ),
              const SizedBox(height: 32),
              StatExpandableCard(
                title: 'Utang',
                icon: Icons.bar_chart,
                valuesAboveDivider: [
                  {'label': 'Utang 1', 'value': '15000'},
                  {'label': 'Utang 2', 'value': '5400'},
                ],
                valuesBelowDivider: [
                  {'label': 'Total', 'value': '19400'},
                ],
              ),
              StatExpandableCard(
                title: 'Aset',
                icon: Icons.bar_chart,
                valuesAboveDivider: [
                  {'label': 'Aset 1', 'value': '-'},
                  {'label': 'Aset 2', 'value': '-'},
                ],
                valuesBelowDivider: [
                  {'label': 'Total', 'value': '-'},
                ],
              ),
            ] else if (widget.id == '3') ...[
              CustomSliderSingleRange(
                yourRatio: yourRatioValue,
                limit: 10,
                limitType: SliderLimitType.moreThanEqual,
              ),
              const SizedBox(height: 32),
              StatExpandableCard(
                title: 'Tabungan',
                icon: Icons.bar_chart,
                valuesAboveDivider: [
                  {'label': 'Rekening tabungan', 'value': '15000'},
                  {'label': 'Deposito', 'value': '5400'},
                ],
                valuesBelowDivider: [
                  {'label': 'Total', 'value': '19400'},
                ],
              ),
              StatExpandableCard(
                title: 'Penghasilan Kotor',
                icon: Icons.bar_chart,
                valuesAboveDivider: [
                  {'label': 'Gaji', 'value': '-'},
                  {'label': 'Pendapatan bulanan', 'value': '-'},
                ],
                valuesBelowDivider: [
                  {'label': 'Total', 'value': '-'},
                ],
              ),
            ] else if (widget.id == '4') ...[
              CustomSliderSingleRange(
                yourRatio: yourRatioValue,
                limit: 45,
                limitType: SliderLimitType.moreThan,
              ),
              const SizedBox(height: 32),
              StatExpandableCard(
                title: 'Pembayaran Utang',
                icon: Icons.bar_chart,
                valuesAboveDivider: [
                  {'label': 'Rekening tabungan', 'value': '15000'},
                  {'label': 'Kartu kredit', 'value': '5400'},
                ],
                valuesBelowDivider: [
                  {'label': 'Total', 'value': '19400'},
                ],
              ),
              StatExpandableCard(
                title: 'Penghasilan Bersih',
                icon: Icons.bar_chart,
                valuesAboveDivider: [
                  {'label': 'Pendapatan bulanan', 'value': '-'},
                  {'label': 'Gaji', 'value': '-'},
                ],
                valuesBelowDivider: [
                  {'label': 'Total', 'value': '-'},
                ],
              ),
            ] else if (widget.id == '5') ...[
              CustomSliderSingleRange(
                yourRatio: yourRatioValue,
                limit: 50,
                limitType: SliderLimitType.moreThanEqual,
              ),
              const SizedBox(height: 32),
              StatExpandableCard(
                title: 'Pembayaran Utang',
                icon: Icons.bar_chart,
                valuesAboveDivider: [
                  {'label': 'Saham', 'value': '15000'},
                  {'label': 'Properti investasi', 'value': '5400'},
                ],
                valuesBelowDivider: [
                  {'label': 'Total', 'value': '19400'},
                ],
              ),
              StatExpandableCard(
                title: 'Nilai Bersih Kekayaan',
                icon: Icons.bar_chart,
                valuesAboveDivider: [
                  {'label': 'Pendapatan bulanan', 'value': '-'},
                  {'label': 'Gaji', 'value': '-'},
                ],
                valuesBelowDivider: [
                  {'label': 'Total', 'value': '-'},
                ],
              ),
            ] else if (widget.id == '6') ...[
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Rasio solvabilitas ini menunjukkan (dalam persentase) seberapa rentan terhadap risiko kebangkrutan.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Math.tex(
                      r'\frac{\textit{Total Kekayaan Bersih}}{\textit{Total Aset}} \times 100\%',
                      textStyle: const TextStyle(fontSize: 18),
                      mathStyle: MathStyle.display,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              StatExpandableCard(
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
              StatExpandableCard(
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
            ]  else ...[
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.do_not_disturb_on_rounded, size: 124, color: Colors.grey),
                    const SizedBox(height: 24),
                    const Text(
                      'Oops! Belum ada data keuangan yang bisa dievaluasi.',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Pastikan Anda sudah mencatat transaksi terlebih dahulu',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
