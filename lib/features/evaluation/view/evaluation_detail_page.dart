import 'package:flutter/material.dart';
import 'package:ta_client/features/evaluation/view/widgets/custom_slider_double_range.dart';
import 'package:ta_client/features/evaluation/view/widgets/custom_slider_single_range.dart';
import 'package:ta_client/features/evaluation/view/widgets/slider_limit_type.dart';

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
      yourRatioValue = 3;
    } else {
      yourRatioValue = 45; // fallback or other values
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailContent = {
      '0': 'Detail for Rasio Keuangan 1',
      '1': 'Detail for Rasio Keuangan 2',
      '2': 'Detail for Rasio Keuangan 3',
      '3': 'Detail for Rasio Keuangan 4',
      '4': 'Detail for Rasio Keuangan 5',
      '5': 'Detail for Rasio Keuangan 6',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Rasio ${int.parse(widget.id) + 1}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              detailContent[widget.id] ?? 'No data available',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            if (widget.id == '0') ...[
              CustomSliderDoubleRange(
                id: widget.id,
                yourRatioValue: yourRatioValue,
              ),
            ]
            else if (widget.id == '1') ...[
              CustomSliderSingleRange(
                yourRatio: yourRatioValue,
                limit: 50,
                limitType: SliderLimitType.lessThanEqual,
              ),
            ],

            const SizedBox(height: 32),

            /// Expandable Card Here
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() => isExpanded = !isExpanded);
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.bar_chart),
                              SizedBox(width: 8),
                              Text('Statistik Rasio', style: TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Icon(
                                isExpanded ? Icons.expand_less : Icons.expand_more,
                                color: Colors.grey[600],
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Expanded Content
                      if (isExpanded) ...[
                        const SizedBox(height: 16),
                        const Divider(),

                        const SizedBox(height: 8),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Jumlah Transaksi', style: TextStyle(fontSize: 14)),
                            Text('42 transaksi', style: TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Rata-rata Per Bulan', style: TextStyle(fontSize: 14)),
                            Text('14 transaksi', style: TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
