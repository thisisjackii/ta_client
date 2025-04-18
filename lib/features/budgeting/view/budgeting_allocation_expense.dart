import 'package:another_xlider/another_xlider.dart';
import 'package:flutter/material.dart';
import 'package:ta_client/app/routes/routes.dart';
import 'package:intl/intl.dart';

class BudgetingAllocationExpense extends StatefulWidget {
  const BudgetingAllocationExpense({super.key});

  @override
  State<BudgetingAllocationExpense> createState() => _BudgetingAllocationExpenseState();
}

class _BudgetingAllocationExpenseState extends State<BudgetingAllocationExpense> {
  final Set<String> expandedIds = {};
  final Map<String, Set<String>> selectedSubExpenses = {};
  final allocationData = [
    {'id': '0', 'Title': 'Rumah'},
    {'id': '1', 'Title': 'Sosial'},
    {'id': '2', 'Title': 'Tabungan'},
  ];

  final Map<String, double> allocationValues = {
    '0': 0.0,
    '1': 0.0,
    '2': 0.0,
  };
  final Set<String> selectedIds = {};

  double get totalAllocation => allocationValues.entries
      .where((entry) => selectedIds.contains(entry.key))
      .fold(0.0, (sum, entry) => sum + entry.value);

  @override
  Widget build(BuildContext context) {
    const submitButtonColor = Color(0xff237BF5);
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
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
            icon: const Icon(Icons.info_rounded),
            onPressed: () async {

            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Alokasi Anggaran',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pilih kategori pengeluaran sesuai dengan alokasi dana yang telah ditetapkan sebelumnya.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 8),

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

          const SizedBox(height: 8),
          ListView.builder(
            itemCount: allocationData.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final data = allocationData[index];
              final id = data['id']!;
              final isExpanded = expandedIds.contains(id); // Set<String>
              final selectedSubItems = selectedSubExpenses[id] ?? <String>{}; // Map<String, Set<String>>

              final subItems = List.generate(4, (i) => 'Expense ${i + 1}');

              return GestureDetector(
                onTap: () {
                  setState(() {
                    isExpanded ? expandedIds.remove(id) : expandedIds.add(id);
                  });
                },
                child: Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.monetization_on_outlined),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                data['Title']!,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            Text(
                              "${allocationValues[id]!.toStringAsFixed(0)}%",
                              style: const TextStyle(fontSize: 14),
                            ),
                            Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                            ),
                          ],
                        ),

                        if (isExpanded) const SizedBox(height: 12),

                        // Expanded content
                        if (isExpanded)
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
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: submitButtonColor,
              ),
              onPressed: () async {
                await Navigator.pushNamed(context, Routes.budgetingDashboard);
              },
              child: const Text(
                'Simpan',
                style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.white,),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
