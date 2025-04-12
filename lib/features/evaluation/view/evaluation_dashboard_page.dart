import 'package:flutter/material.dart';
import 'package:ta_client/app/routes/routes.dart';

class EvaluationDashboard extends StatelessWidget {
  const EvaluationDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final evaluationData = <Map<String, String>>[
      {'id': '0', 'yourRatio': '3 Bulan', 'idealRatio': '3 - 6 Bulan'},
      {'id': '1', 'yourRatio': '8%', 'idealRatio': '> 15%'},
      {'id': '2', 'yourRatio': '75%', 'idealRatio': '≤ 50%'},
      {'id': '3', 'yourRatio': '51%', 'idealRatio': '≥ 10%'},
      {'id': '4', 'yourRatio': '92%', 'idealRatio': '> 45%'},
      {'id': '5', 'yourRatio': '36%', 'idealRatio': '≥ 50%'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Evaluasi',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded),
            onPressed: () async {
              final result = await Navigator.pushNamed(context, Routes.evaluationHistory);
              print('Returned from EvaluationIntro: $result');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // [ADDITIONAL TEXT]
          const Text(
            'Berdasarkan data yang telah dimasukkan, kamu dapat melihat kemampuan dan keadaan keuanganmu secara menyeluruh.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),

          // [THE DATE RANGE WITH ICON]
          const Row(
            children: [
              Icon(Icons.date_range, size: 16, color: Colors.grey),
              SizedBox(width: 4),
              Text(
                '{tanggal mulai} - {tanggal akhir}', // Placeholder
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // [LOOP OF THE CARDS]
          ListView.builder(
            itemCount: evaluationData.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final data = evaluationData[index];

              final ratioLabels = <String>[
                'Rasio Likuiditas',
                'Rasio aset lancar terhadap kekayaan bersih',
                'Rasio utang terhadap aset',
                'Rasio Tabungan',
                'Rasio kemampuan pelunasan hutang',
                'Aset investasi terhadap nilai bersih kekayaan',
              ];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ratioLabels[index],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        Routes.evaluationDetail,
                        arguments: data['id'],
                      );
                    },
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Row(
                          children: [
                            // Your Ratio
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Your Ratio',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    data['yourRatio'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Ideal Ratio
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Ideal Ratio',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    data['idealRatio'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        ],
      ),


    );
  }
}
