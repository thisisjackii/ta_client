import 'package:another_xlider/another_xlider.dart';
import 'package:flutter/material.dart';
import 'package:ta_client/app/routes/routes.dart';
import 'package:intl/intl.dart';
import 'package:ta_client/features/budgeting/view/widgets/allocation_card.dart';

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
    '0': 0.0,
    '1': 150000.0,
    '2': 150000.0,
  };

  final Map<String, double> allocationTargets = {
    '0': 3500000.0,
    '1': 750000.0,
    '2': 150000.0,
  };

  final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp. ',
    decimalDigits: 0,
  );

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
          ExpandableAllocationCard(),
          // Title
          Center(
            child: Card(
              elevation: 2, // <- subtle shadow
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min, // <- hugs the content width
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    Icon(Icons.date_range, size: 16, color: Colors.grey),
                    SizedBox(width: 6),
                    Text(
                      '{tanggal mulai} - {tanggal akhir}', // Placeholder
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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

              final currentValue = allocationValues[id] ?? 0.0;
              final targetValue = allocationTargets[id] ?? 0.0;
              final targetMaxPercent = 35.0;

              final valueRatio = (targetValue == 0.0) ? 0.0 : (currentValue / targetValue);
              final currentPercentage = targetMaxPercent * valueRatio;
              final targetPercentage = targetMaxPercent;

              final subItems = ['Expense 1', 'Expense 2', 'Expense 3', 'Expense 4'];
              final selectedSubItems = selectedSubExpenses[id] ?? <String>{};
              final isExpanded = expandedCardIds.contains(id);

              Color getProgressColor(double percent) {
                if (percent <= targetMaxPercent * 0.32) return Colors.green;
                if (percent <= targetMaxPercent * 0.65) return Colors.orange;
                return Colors.red;
              }

              return Dismissible(
                key: Key(id),
                direction: DismissDirection.horizontal,
                confirmDismiss: (direction) async {
                  if (valueRatio > 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Alokasi '$title' tidak bisa dihapus karena masih memiliki persentase.")),
                    );
                    return false;
                  }

                  return await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Hapus Alokasi?'),
                      content: Text("Apakah kamu yakin ingin menghapus '$title'?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Hapus'),
                        ),
                      ],
                    ),
                  );
                },

                onDismissed: (direction) {
                  setState(() {
                    allocationData.removeAt(index);
                    allocationValues.remove(id);
                    selectedSubExpenses.remove(id);
                    expandedCardIds.remove(id);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("'$title' telah dihapus")),
                  );
                },
                child: GestureDetector(
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
                          // --- Your card content remains unchanged ---
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
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${currencyFormatter.format(currentValue)} /',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w300,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        ' ${currencyFormatter.format(targetValue)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text('(${currentPercentage.toStringAsFixed(1)}% / ${targetPercentage.toStringAsFixed(1)}%)',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              LinearProgressIndicator(
                                value: valueRatio.clamp(0.0, 1.0),
                                minHeight: 18,
                                borderRadius: BorderRadius.circular(6),
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation(getProgressColor(currentPercentage)),
                              ),
                              Text(
                                '${(valueRatio * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),

                            ],
                          ),

                          // --- Expanded content ---
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
                                    onChanged: (valueRatio > 0)
                                        ? null // disabled
                                        : (val) {
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
                                    onPressed: (valueRatio > 0)
                                        ? null // disabled
                                        : () {
                                      debugPrint('Saved selections for $id: ${selectedSubItems.join(', ')}');
                                    },
                                    icon: const Icon(Icons.save_alt_rounded, size: 18),
                                    label: const Text('Save'),
                                  ),
                                ),
                                if (valueRatio > 0)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Text(
                                      'Edit dinonaktifkan karena alokasi belum 0%',
                                      style: TextStyle(fontSize: 12, color: Colors.red[400]),
                                    ),
                                  ),

                              ],
                            ),
                          ],

                        ],
                      ),
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
