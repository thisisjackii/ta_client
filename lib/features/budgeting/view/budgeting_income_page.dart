import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ta_client/app/routes/routes.dart';

class BudgetingIncome extends StatefulWidget {
  const BudgetingIncome({super.key});

  @override
  State<BudgetingIncome> createState() => _BudgetingIncomeState();
}

class _BudgetingIncomeState extends State<BudgetingIncome> {
  final incomeData = <Map<String, String>>[
    {'id': '0', 'Title': 'Gaji', 'Value': 'Rp. 1.500.000'},
    {'id': '1', 'Title': 'Upah', 'Value': 'Rp. 500.000'},
    {'id': '2', 'Title': 'Bonus', 'Value': 'Rp. 700.000'},
  ];

  final Set<String> selectedIds = {};

  int _parseRupiah(String value) {
    final digitsOnly = value.replaceAll(RegExp('[^0-9]'), '');
    return int.tryParse(digitsOnly) ?? 0;
  }

  String _formatToRupiah(int value) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp. ',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  int get totalSelected => incomeData
      .where((item) => selectedIds.contains(item['id']))
      .fold(0, (sum, item) => sum + _parseRupiah(item['Value'] ?? '0'));

  @override
  Widget build(BuildContext context) {
    const submitButtonColor = Color(0xff237BF5);
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Budgeting',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded),
            onPressed: () async {
              final result =
                  await Navigator.pushNamed(context, Routes.evaluationHistory);
              debugPrint('Returned from EvaluationIntro: $result');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // [ADDITIONAL TEXT]
          const Text(
            'Pilih Kategori Pemasukanmu untuk Budgeting',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          const SizedBox(height: 16),

          // [LOOP OF THE CARDS]
          ListView.builder(
            itemCount: incomeData.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final data = incomeData[index];
              final isSelected = selectedIds.contains(data['id']);

              return Column(
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          // Left column (icon + title, then value)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.attach_money,
                                      size: 14,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      data['Title'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data['Value'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Right column (radio-style checkbox)
                          Checkbox(
                            value: isSelected,
                            shape: const CircleBorder(),
                            onChanged: (value) {
                              setState(() {
                                if (value!) {
                                  selectedIds.add(data['id']!);
                                } else {
                                  selectedIds.remove(data['id']);
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),

          // Total Card
          if (selectedIds.isNotEmpty)
            Card(
              color: Colors.blue.shade50,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      _formatToRupiah(totalSelected),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const Text(
            'Perhitungan anggaran dalam penelitian ini merujuk pada standar yang ditetapkan oleh Kapoor et al. (2015), yang didasarkan pada data dari lembaga statistik Amerika.',
            style: TextStyle(fontSize: 8, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: submitButtonColor,
              ),
              onPressed: () async {
                await Navigator.pushNamed(
                  context,
                  Routes.budgetingAllocationDate,
                );
              },
              child: const Text(
                'Mulai',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
