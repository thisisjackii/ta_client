import 'package:another_xlider/another_xlider.dart';
import 'package:flutter/material.dart';
import 'package:ta_client/app/routes/routes.dart';
import 'package:intl/intl.dart';

class BudgetingDashboard extends StatefulWidget {
  const BudgetingDashboard({super.key});

  @override
  State<BudgetingDashboard> createState() => _BudgetingDashboardState();
}

class _BudgetingDashboardState extends State<BudgetingDashboard> {
  Set<String> expandedCardIds = {};
  Map<String, Set<String>> selectedSubExpenses = {};

  final allocationData = [
    {'id': '0', 'Title': 'Rumah'},
    {'id': '1', 'Title': 'Sosial'},
    {'id': '2', 'Title': 'Tabungan'},
  ];

  final Map<String, double> allocationValues = {
    '0': 20.0,
    '1': 10.0,
    '2': 35.0,
  };

  final Map<String, double> allocationTargets = {
    '0': 35.0,
    '1': 35.0,
    '2': 35.0,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Alokasi Keuanganmu',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_rounded),
            onPressed: () async {

            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Allocation Funds Card
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Allocation Funds',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  const Text('Rp. 0'), // Placeholder value
                ],
              ),
            ),
          ),

          // Title
          const Text(
            'February 2025',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Cards from allocationData
          ListView.builder(
            itemCount: allocationData.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final data = allocationData[index];
              final id = data['id']!;
              final title = data['Title']!;
              final value = allocationValues[id] ?? 0.0;
              final target = 35.0;
              final percentage = ((value / target) * 100).toDouble();

              final subItems = ['Expense 1', 'Expense 2', 'Expense 3', 'Expense 4'];
              final selectedSubItems = selectedSubExpenses[id] ?? <String>{};
              final isExpanded = expandedCardIds.contains(id);

              Color getProgressColor(double percent) {
                if (percent <= 32) return Colors.green;
                if (percent <= 65) return Colors.orange;
                return Colors.red;
              }

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      expandedCardIds.remove(id);
                    } else {
                      expandedCardIds.add(id);
                    }
                  });
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.category),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Rp ${value.toStringAsFixed(0)}'),
                                Text('${value.toStringAsFixed(0)}% / ${target.toStringAsFixed(0)}%',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            LinearProgressIndicator(
                              value: (percentage / 100),
                              minHeight: 18,
                              borderRadius: BorderRadius.circular(6),
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation(getProgressColor(percentage)),
                            ),
                            Text(
                              '${percentage.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),

                        if (isExpanded) ...[
                          const SizedBox(height: 12),
                          Column(
                            children: [
                              ...subItems.map((item) {
                                final isSelected = selectedSubItems.contains(item);
                                return CheckboxListTile(
                                  value: isSelected,
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  controlAffinity: ListTileControlAffinity.leading,
                                  title: Text(item),
                                  onChanged: (val) {
                                    setState(() {
                                      final current = selectedSubExpenses[id] ?? <String>{};
                                      if (val == true) {
                                        current.add(item);
                                      } else {
                                        current.remove(item);
                                      }
                                      selectedSubExpenses[id] = current;
                                    });
                                  },
                                );
                              }).toList(),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () {
                                    debugPrint('Saved selections for $id: ${selectedSubItems.join(', ')}');
                                  },
                                  icon: const Icon(Icons.save_alt_rounded, size: 18),
                                  label: const Text('Save'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

        ],
      ),
    );
  }
}
