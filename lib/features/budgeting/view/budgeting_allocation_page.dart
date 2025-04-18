import 'package:another_xlider/another_xlider.dart';
import 'package:flutter/material.dart';
import 'package:ta_client/app/routes/routes.dart';
import 'package:intl/intl.dart';

class BudgetingAllocation extends StatefulWidget {
  const BudgetingAllocation({super.key});

  @override
  State<BudgetingAllocation> createState() => _BudgetingAllocationState();
}

class _BudgetingAllocationState extends State<BudgetingAllocation> {
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

  double get totalAllocation {
    return selectedIds.fold(0.0, (sum, id) => sum + (allocationValues[id] ?? 0));
  }


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
            'Berdasarkan data yang telah dimasukkan, kamu dapat melihat kemampuan dan keadaan keuanganmu secara menyeluruh.',
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
              final isSelected = selectedIds.contains(id);
              double _getMaxFor(String id) {
                double othersTotal = selectedIds
                    .where((otherId) => otherId != id)
                    .fold(0.0, (sum, otherId) => sum + (allocationValues[otherId] ?? 0.0));

                return (100.0 - othersTotal).clamp(0.0, 100.0);
              }
              return Card(
                color: isSelected ? Colors.white : Colors.grey[200],
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  selectedIds.add(id);
                                } else {
                                  selectedIds.remove(id);
                                  allocationValues[id] = 0;
                                }
                              });
                            },
                          ),
                          Opacity(
                            opacity: isSelected ? 1.0 : 0.5,
                            child: const Icon(Icons.monetization_on_outlined),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Opacity(
                              opacity: isSelected ? 1.0 : 0.5,
                              child: Text(
                                data['Title']!,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                          Opacity(
                            opacity: isSelected ? 1.0 : 0.5,
                            child: Text(
                              "${allocationValues[id]!.toStringAsFixed(0)}%",
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      FlutterSlider(
                        values: [allocationValues[id]!],
                        max: 100, // Always 100 visually
                        min: 0,
                        disabled: !isSelected,
                        onDragging: (handlerIndex, lowerValue, upperValue) {
                          setState(() {
                            final newValue = (lowerValue as num).toDouble();

                            final othersTotal = selectedIds
                                .where((otherId) => otherId != id)
                                .fold(0.0, (sum, otherId) => sum + (allocationValues[otherId] ?? 0));

                            final maxAvailableForThis = (100.0 - othersTotal).clamp(0.0, 100.0);

                            if (newValue > maxAvailableForThis) {
                              // Show snackbar only if exceeding
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text("⚠️ Tidak dapat melebihi total di atas 100%"),
                                  backgroundColor: Colors.red[400],
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }

                            // Clamp the value regardless
                            allocationValues[id] = newValue.clamp(0.0, maxAvailableForThis);
                          });
                        },



                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          Card(
            color: Colors.blue.shade50,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Alokasi',
                      style:
                      TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  Text("${totalAllocation.toStringAsFixed(0)}%",
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold)),
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
                Navigator.pushNamed(context, Routes.budgetingAllocationExpense);
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
