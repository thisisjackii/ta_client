import 'package:flutter/material.dart';

class EvaluationHistoryPage extends StatelessWidget {
  const EvaluationHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample dummy history list
    final historyList = [
      {
        'startDate': '01 Jan 2024',
        'endDate': '31 Mar 2024',
        'ideal': 3,
        'notIdeal': 2,
        'incomplete': 1,
      },
      {
        'startDate': '01 Apr 2024',
        'endDate': '30 Jun 2024',
        'ideal': 5,
        'notIdeal': 0,
        'incomplete': 1,
      },
      {
        'startDate': '01 Jul 2024',
        'endDate': '30 Sep 2024',
        'ideal': 2,
        'notIdeal': 4,
        'incomplete': 0,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Evaluasi'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Riwayat Evaluasi Keuangan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: historyList.length,
                itemBuilder: (context, index) {
                  final item = historyList[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.date_range, size: 24, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item['startDate']} - ${item['endDate']}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                      '${item['ideal']} Ideal',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF2A8C8B),
                                      ),
                                    ),
                                    Text(
                                      '${item['notIdeal']} Tidak Ideal',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFFEF233C),
                                      ),
                                    ),
                                    Text(
                                      '${item['incomplete']} Tidak Lengkap',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[700],
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
