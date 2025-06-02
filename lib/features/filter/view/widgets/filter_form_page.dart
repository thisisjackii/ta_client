// lib/features/filter/view/widgets/filter_form_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // For TransactionBloc
import 'package:ta_client/core/widgets/custom_date_picker.dart';
// import 'package:ta_client/core/widgets/dropdown_field.dart';
import 'package:ta_client/features/transaction/bloc/transaction_bloc.dart'; // For State & Event
import 'package:ta_client/features/transaction/models/account_type.dart'
    as ta_account_type;
import 'package:ta_client/features/transaction/models/category.dart'
    as ta_category;
import 'package:ta_client/features/transaction/models/subcategory.dart'
    as ta_subcategory;

class FilterFormPage extends StatefulWidget {
  const FilterFormPage({super.key, this.initialCriteria, this.initialMonth});

  final Map<String, dynamic>? initialCriteria;
  final DateTime? initialMonth;

  @override
  State<FilterFormPage> createState() => _FilterFormPageState();
}

class _FilterFormPageState extends State<FilterFormPage> with RouteAware {
  Color submitButtonColor = const Color(0xff2A8C8B);

  // Store IDs now for better state management with BLoC
  String? _selectedAccountTypeId;
  String? _selectedCategoryId;
  String? _selectedSubcategoryId;

  // For display in dropdowns (names)
  String? _displaySelectedAccountTypeName;
  String? _displaySelectedCategoryName;
  String? _displaySelectedSubcategoryName;

  late bool bookmarkedOnly;
  DateTime? startDate;
  DateTime? endDate;
  DateTime monthLimitStart = DateTime.now();
  DateTime monthLimitEnd = DateTime.now();

  static Color _colorForAccountType(String name) {
    switch (name.toLowerCase()) {
      case 'aset':
        return const Color(0xff2A8C8B);
      case 'liabilitas':
        return const Color(0xffEF233C);
      case 'pemasukan':
        return const Color(0xff5A4CAF);
      case 'pengeluaran':
        return const Color(0xffD623AE);
      default:
        return Colors.grey; // Default color
    }
  }

  @override
  void initState() {
    super.initState();
    final crit = widget.initialCriteria ?? {};
    bookmarkedOnly = crit['bookmarked'] as bool? ?? false;

    // Initialize IDs from criteria if they exist
    _selectedAccountTypeId = crit['accountTypeId'] as String?;
    _selectedCategoryId = crit['categoryId'] as String?;
    _selectedSubcategoryId = crit['subcategoryId'] as String?;

    // Initialize display names (if criteria provided display names, or derive later from IDs)
    _displaySelectedAccountTypeName =
        crit['parent'] as String?; // 'parent' was old key
    _displaySelectedCategoryName =
        crit['child'] as String?; // 'child' was old key
    _displaySelectedSubcategoryName = crit['subcategoryName'] as String?;

    startDate = crit['startDate'] as DateTime?;
    endDate = crit['endDate'] as DateTime?;

    final m = widget.initialMonth ?? DateTime.now();
    monthLimitStart = DateTime(m.year, m.month);
    monthLimitEnd = DateTime(m.year, m.month + 1, 0);

    // Initial data load for dropdowns
    final transactionBloc = context.read<TransactionBloc>();
    transactionBloc.add(LoadAccountTypesRequested());
    if (_selectedAccountTypeId != null) {
      transactionBloc.add(LoadCategoriesRequested(_selectedAccountTypeId!));
    }
    if (_selectedCategoryId != null) {
      transactionBloc.add(LoadSubcategoriesRequested(_selectedCategoryId!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        // Update display names if IDs are set and corresponding objects are found
        if (_selectedAccountTypeId != null && state.accountTypes.isNotEmpty) {
          final accType = state.accountTypes
              .where((at) => at.id == _selectedAccountTypeId)
              .cast<ta_account_type.AccountType?>()
              .firstWhere((at) => at != null, orElse: () => null);
          _displaySelectedAccountTypeName = accType?.name;
        }
        if (_selectedCategoryId != null && state.categories.isNotEmpty) {
          final cat = state.categories
              .where((c) => c.id == _selectedCategoryId)
              .cast<ta_category.Category?>()
              .firstWhere((c) => c != null, orElse: () => null);
          _displaySelectedCategoryName = cat?.name;
        }
        if (_selectedSubcategoryId != null && state.subcategories.isNotEmpty) {
          final subcat = state.subcategories
              .where((sc) => sc.id == _selectedSubcategoryId)
              .cast<ta_subcategory.Subcategory?>()
              .firstWhere((sc) => sc != null, orElse: () => null);
          _displaySelectedSubcategoryName = subcat?.name;
        }

        final accountTypeDropdownItems = [
          DropdownMenuItem<String>(
            child: Text(
              '-- Pilih Tipe Akun --',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
          ...state.accountTypes.map(
            (ta_account_type.AccountType accType) => DropdownMenuItem<String>(
              value: accType.id,
              child: Text(accType.name),
            ),
          ),
        ];

        // Filter categories based on selected account type
        final categoriesForSelectedAccountType = _selectedAccountTypeId == null
            ? <ta_category.Category>[]
            : state.categories
                  .where((cat) => cat.accountTypeId == _selectedAccountTypeId)
                  .toList();

        final categoryDropdownItems = [
          DropdownMenuItem<String>(
            child: Text(
              '-- Pilih Kategori --',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
          ...categoriesForSelectedAccountType.map(
            (ta_category.Category cat) =>
                DropdownMenuItem<String>(value: cat.id, child: Text(cat.name)),
          ),
        ];

        // Filter subcategories based on selected category
        final subcategoriesForSelectedCategory = _selectedCategoryId == null
            ? <ta_subcategory.Subcategory>[]
            : state.subcategories
                  .where((sub) => sub.categoryId == _selectedCategoryId)
                  .toList();

        final subcategoryDropdownItems = [
          DropdownMenuItem<String>(
            child: Text(
              '-- Pilih Subkategori --',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
          ...subcategoriesForSelectedCategory.map(
            (ta_subcategory.Subcategory sub) =>
                DropdownMenuItem<String>(value: sub.id, child: Text(sub.name)),
          ),
        ];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Account Type Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Tipe Akun'),
                value: _selectedAccountTypeId,
                items: accountTypeDropdownItems,
                onChanged: (value) {
                  setState(() {
                    _selectedAccountTypeId = value;
                    _selectedCategoryId = null; // Reset category
                    _displaySelectedCategoryName = null;
                    _selectedSubcategoryId = null; // Reset subcategory
                    _displaySelectedSubcategoryName = null;

                    if (value != null) {
                      context.read<TransactionBloc>().add(
                        LoadCategoriesRequested(value),
                      );
                      // Update color based on selected account type
                      final selectedAccTypeObj = state.accountTypes.firstWhere(
                        (at) => at.id == value,
                        orElse: () => const ta_account_type.AccountType(
                          id: '_',
                          name: 'Default',
                        ),
                      );
                      submitButtonColor = _colorForAccountType(
                        selectedAccTypeObj.name,
                      );
                    } else {
                      context.read<TransactionBloc>().add(
                        const LoadCategoriesRequested(''),
                      ); // Load empty
                      submitButtonColor = Colors.grey;
                    }
                  });
                },
              ),
              const SizedBox(height: 24),

              // Category Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Kategori'),
                value: _selectedCategoryId,
                items: categoryDropdownItems,
                disabledHint: _selectedAccountTypeId == null
                    ? const Text('Pilih Tipe Akun dulu')
                    : null,
                onChanged: _selectedAccountTypeId == null
                    ? null
                    : (value) {
                        setState(() {
                          _selectedCategoryId = value;
                          _selectedSubcategoryId = null; // Reset subcategory
                          _displaySelectedSubcategoryName = null;
                          if (value != null) {
                            context.read<TransactionBloc>().add(
                              LoadSubcategoriesRequested(value),
                            );
                          } else {
                            context.read<TransactionBloc>().add(
                              const LoadSubcategoriesRequested(''),
                            ); // Load empty
                          }
                        });
                      },
              ),
              const SizedBox(height: 24),

              // Subcategory Dropdown (NEW)
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Subkategori'),
                value: _selectedSubcategoryId,
                items: subcategoryDropdownItems,
                disabledHint: _selectedCategoryId == null
                    ? const Text('Pilih Kategori dulu')
                    : null,
                onChanged: _selectedCategoryId == null
                    ? null
                    : (value) {
                        setState(() {
                          _selectedSubcategoryId = value;
                          _displaySelectedSubcategoryName = value != null
                              ? state.subcategories
                                    .firstWhere((s) => s.id == value)
                                    .name
                              : null;
                        });
                      },
              ),
              const SizedBox(height: 24),

              // Date range picker: Start Date and End Date.
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Pilih Rentang Tanggal',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: CustomDatePicker(
                          label: 'Start Date',
                          isDatePicker: true,
                          initialDate: startDate ?? monthLimitStart,
                          selectedDate:
                              startDate, // Pass current selected date to picker
                          firstDate: monthLimitStart,
                          lastDate: monthLimitEnd,
                          onDateChanged: (date) =>
                              setState(() => startDate = date),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomDatePicker(
                          label: 'End Date',
                          isDatePicker: true,
                          initialDate: endDate ?? monthLimitEnd,
                          selectedDate: endDate, // Pass current selected date
                          firstDate:
                              startDate ??
                              monthLimitStart, // End date cannot be before start date
                          lastDate: monthLimitEnd,
                          onDateChanged: (date) =>
                              setState(() => endDate = date),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              CheckboxListTile(
                title: const Text('Hanya Bookmark'),
                value: bookmarkedOnly,
                onChanged: (v) => setState(() => bookmarkedOnly = v!),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: submitButtonColor,
                  ),
                  onPressed: () {
                    final filters = {
                      'accountTypeId': _selectedAccountTypeId,
                      'categoryId': _selectedCategoryId,
                      'subcategoryId':
                          _selectedSubcategoryId, // Pass subcategoryId
                      // For display or if backend uses names for some reason
                      'parent': _displaySelectedAccountTypeName,
                      'child': _displaySelectedCategoryName,
                      'subcategoryName': _displaySelectedSubcategoryName,
                      'startDate': startDate,
                      'endDate': endDate,
                      'bookmarked': bookmarkedOnly,
                    };
                    Navigator.pop(context, filters);
                  },
                  child: const Text(
                    'Filter',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
