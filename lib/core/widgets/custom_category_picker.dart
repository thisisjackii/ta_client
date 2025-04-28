// lib/core/widgets/custom_category_picker.dart
import 'package:flutter/material.dart';
import 'package:ta_client/core/widgets/category_modal_sheet.dart';
import 'package:ta_client/core/widgets/custom_text_field.dart';

class CustomCategoryPicker extends StatelessWidget {
  const CustomCategoryPicker({
    required this.categories,
    required this.onCategorySelected,
    super.key,
    this.selectedCategory = '',
    this.selectedSubCategory = '',
    this.validator,
  });

  /// NEW: all available parent→sub mappings
  final Map<String, List<String>> categories;

  final String selectedCategory;
  final String selectedSubCategory;
  final void Function(String, String) onCategorySelected;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: (_) {
        if (selectedCategory.isEmpty || selectedSubCategory.isEmpty) {
          return 'Field cannot be empty';
        }
        return null;
      },
      builder: (FormFieldState<String> field) {
        return GestureDetector(
          onTap: () {
            showModalBottomSheet<void>(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (_) => CategoryModalSheet(
                categories: categories, // pass it along
                onCategorySelected: (cat, subCat) {
                  onCategorySelected(cat, subCat);
                  field.didChange(cat);
                },
              ),
            );
          },
          child: AbsorbPointer(
            child: CustomTextField(
              label: (selectedCategory.isNotEmpty &&
                      selectedSubCategory.isNotEmpty)
                  ? '$selectedCategory / $selectedSubCategory'
                  : 'Pilih Kategori',
              onChanged: (_) {},
              keyboardType: TextInputType.none,
              validator: (_) => field.errorText,
            ),
          ),
        );
      },
    );
  }
}
