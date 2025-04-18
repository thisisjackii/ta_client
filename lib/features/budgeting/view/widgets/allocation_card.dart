import 'package:flutter/material.dart';
import 'package:ta_client/app/routes/routes.dart';

class ExpandableAllocationCard extends StatefulWidget {
  const ExpandableAllocationCard({super.key});

  @override
  State<ExpandableAllocationCard> createState() => _ExpandableAllocationCardState();
}

class _ExpandableAllocationCardState extends State<ExpandableAllocationCard> {
  bool isExpanded = false;

  final List<String> subItems = [
    'Sub Item 1',
    'Sub Item 2',
    'Sub Item 3',
    'Sub Item 4',
  ];

  final Set<String> selectedSubItems = {};

  // Optional: manage subExpenses if used elsewhere
  final Map<String, Set<String>> selectedSubExpenses = {};

  final String id = 'income'; // example static ID

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isExpanded = !isExpanded;
        });
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    'Alokasi Pemasukan',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  const Text('Rp. 0'), // Placeholder value
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
                            selectedSubItems
                              ..clear()
                              ..addAll(current);
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
  }
}
