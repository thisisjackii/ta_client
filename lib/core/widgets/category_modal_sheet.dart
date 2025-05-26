// lib/core/widgets/category_modal_sheet.dart
import 'package:flutter/material.dart';

class CategoryModalSheet extends StatefulWidget {
  const CategoryModalSheet({
    required this.categories,
    required this.onCategorySelected,
    super.key,
  });

  /// NEW: all available parent→sub mappings
  final Map<String, List<String>> categories;

  /// Called when the user picks a parent/sub pair.
  final void Function(String parent, String sub) onCategorySelected;

  @override
  _CategoryModalSheetState createState() => _CategoryModalSheetState();
}

class _CategoryModalSheetState extends State<CategoryModalSheet> {
  String? _selectedParent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 300,
      child: Row(
        children: [
          // Left column: Parent categories
          Expanded(
            child: ListView.builder(
              itemCount: widget.categories.keys.length,
              itemBuilder: (ctx, idx) {
                final parent = widget.categories.keys.elementAt(idx);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    dense: true,
                    tileColor: Colors.grey.shade200,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: Text(
                      parent,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: const Icon(Icons.navigate_next, size: 16),
                    onTap: () => setState(() => _selectedParent = parent),
                  ),
                );
              },
            ),
          ),

          const VerticalDivider(),

          // Right column: Subcategories of the selected parent
          Expanded(
            child: _selectedParent == null
                ? const Center(
                    child: Text('Select a category to view subcategories'),
                  )
                : ListView.builder(
                    itemCount: widget.categories[_selectedParent]!.length,
                    itemBuilder: (ctx, idx) {
                      final sub = widget.categories[_selectedParent]![idx];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          dense: true,
                          tileColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          title: Text(
                            sub,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: const Icon(Icons.check, size: 16),
                          onTap: () {
                            widget.onCategorySelected(_selectedParent!, sub);
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
