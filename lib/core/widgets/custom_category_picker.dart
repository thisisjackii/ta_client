// lib/core/widgets/custom_category_picker.dart
import 'package:flutter/material.dart';
import 'package:ta_client/core/widgets/category_modal_sheet.dart';
import 'package:ta_client/core/widgets/custom_text_field.dart';

class CustomCategoryPicker extends StatelessWidget {
  const CustomCategoryPicker({
    required this.onCategorySelected,
    super.key,
    this.selectedCategory = '',
    this.selectedSubCategory = '',
  });
  final String selectedCategory;
  final String selectedSubCategory;
  final void Function(String, String) onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet<void>(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (context) {
            return CategoryModalSheet(
              onCategorySelected: onCategorySelected,
            );
          },
        );
      },
      child: AbsorbPointer(
        child: CustomTextField(
          label: (selectedCategory.isNotEmpty && selectedSubCategory.isNotEmpty)
              ? '$selectedCategory / $selectedSubCategory'
              : 'Pilih Kategori',
          onChanged: (value) {},
          keyboardType: TextInputType.none,
        ),
      ),
    );
  }
}
