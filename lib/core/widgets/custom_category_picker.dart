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
  final String? Function(String?)? validator; // Validator provided from outside

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      // Use the validator passed into the CustomCategoryPicker widget.
      // This validator will be called by Form.validate() or field.validate().
      validator: validator,
      builder: (FormFieldState<String> field) {
        return GestureDetector(
          onTap: () {
            showModalBottomSheet<void>(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (_) => CategoryModalSheet(
                // Changed builder argument name to avoid conflict
                categories: categories, // pass it along
                onCategorySelected: (cat, subCat) {
                  // Call the external onCategorySelected callback provided to the widget
                  onCategorySelected(cat, subCat);
                  // Notify the FormField that the value has changed, which can trigger re-validation.
                  // The actual string value here ('$cat / $subCat') can be used by the validator if needed,
                  // but typically the validator will check the component's state (selectedCategory/selectedSubCategory props).
                  field.didChange('$cat / $subCat');
                },
              ),
            );
          },
          child: AbsorbPointer(
            child: CustomTextField(
              label:
                  (selectedCategory.isNotEmpty &&
                      selectedSubCategory.isNotEmpty)
                  ? '$selectedCategory / $selectedSubCategory'
                  : 'Pilih Kategori',
              onChanged: (value) {}, // Not directly editable, changed via modal
              keyboardType: TextInputType.none,
              // This validator for CustomTextField simply displays the error text from the FormField.
              validator: (value) => field.errorText,
            ),
          ),
        );
      },
    );
  }
}
