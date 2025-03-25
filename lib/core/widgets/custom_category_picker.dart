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
    this.validator,
  });
  final String selectedCategory;
  final String selectedSubCategory;
  final void Function(String, String) onCategorySelected;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: validator, // Attach validator here
      builder: (FormFieldState<String> field) {
        return GestureDetector(
          onTap: () {
            showModalBottomSheet<void>(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (context) {
                return CategoryModalSheet(
                  onCategorySelected: (cat, subCat) {
                    onCategorySelected(cat, subCat);
                    field.didChange(cat); // Notify the form field that value changed
                  },
                );
              },
            );
          },
          child: AbsorbPointer(
            child: CustomTextField(
              label: (selectedCategory.isNotEmpty && selectedSubCategory.isNotEmpty)
                  ? '$selectedCategory / $selectedSubCategory'
                  : 'Pilih Kategori',
              onChanged: (value) {}, // No need to change manually
              keyboardType: TextInputType.none,
              validator: (_) => field.errorText, // Display error if invalid
            ),
          ),
        );
      },
    );
  }

}
