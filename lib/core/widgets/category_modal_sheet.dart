// lib/core/widgets/category_modal_sheet.dart
import 'package:flutter/material.dart';
import 'package:ta_client/core/constants/category_mapping.dart';

class CategoryModalSheet extends StatefulWidget {
  const CategoryModalSheet({required this.onCategorySelected, Key? key})
      : super(key: key);
  final void Function(String, String) onCategorySelected;

  @override
  _CategoryModalSheetState createState() => _CategoryModalSheetState();
}

class _CategoryModalSheetState extends State<CategoryModalSheet> {
  String? selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 300,
      child: Row(
        children: [
          // Left column: Parent (Level 1) categories.
          Expanded(
            child: ListView.builder(
              itemCount: categoryMapping.keys.length,
              itemBuilder: (context, index) {
                final parentCategory = categoryMapping.keys.elementAt(index);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    dense: true,
                    tileColor: Colors.grey.shade200,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: Text(
                      parentCategory,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.navigate_next,
                      size: 16,
                    ),
                    onTap: () {
                      setState(() {
                        selectedCategory = parentCategory;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          const VerticalDivider(),
          // Right column: Subcategories for the selected parent.
          Expanded(
            child: selectedCategory == null
                ? const Center(child: Text('Select a Category'))
                : ListView.builder(
              itemCount: categoryMapping[selectedCategory]!.length,
              itemBuilder: (context, index) {
                final subCategory =
                categoryMapping[selectedCategory]![index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    dense: true,
                    tileColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: Text(
                      subCategory,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.navigate_next,
                      size: 16,
                    ),
                    onTap: () {
                      widget.onCategorySelected(selectedCategory!, subCategory);
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