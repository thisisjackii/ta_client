// lib/features/transaction/view/widgets/transaction_form.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:ta_client/core/widgets/custom_category_picker.dart'; // Your existing custom picker
import 'package:ta_client/core/widgets/custom_date_picker.dart';
import 'package:ta_client/core/widgets/custom_text_field.dart';
// Assuming DropdownItem and CustomDropdownField are still used for AccountType
import 'package:ta_client/core/widgets/dropdown_field.dart';
import 'package:ta_client/core/widgets/rupiah_formatter.dart';
import 'package:ta_client/features/transaction/bloc/transaction_bloc.dart';
import 'package:ta_client/features/transaction/models/account_type.dart';
import 'package:ta_client/features/transaction/models/category.dart';
import 'package:ta_client/features/transaction/models/subcategory.dart';
import 'package:ta_client/features/transaction/models/transaction.dart';
import 'package:ta_client/features/transaction/view/widgets/transaction_form_mode.dart';

class TransactionForm extends StatefulWidget {
  const TransactionForm({
    required this.onSubmit,
    this.onDescriptionChanged,
    super.key,
    this.mode = TransactionFormMode.create,
    this.transaction,
    this.onDelete,
  });

  final TransactionFormMode mode;
  final Transaction? transaction;
  final void Function(Transaction transaction) onSubmit;
  final VoidCallback? onDelete;
  final void Function(String description)? onDescriptionChanged;

  @override
  _TransactionFormState createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  Color submitButtonColor = const Color(0xff2A8C8B);

  // State variables from the NEWER logic (using IDs)
  String? _selectedAccountTypeId;
  AccountType? _selectedAccountTypeObject; // For display name and color
  String? _selectedCategoryId; // For submission
  String? _selectedSubcategoryId; // For submission

  // State variables to drive the UI of CustomCategoryPicker (uses names)
  String _pickerSelectedCategoryName = '';
  String _pickerSelectedSubcategoryName = '';
  bool _isClassificationSuggestion = false;

  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _maxDescriptionLength = 100;

  late TransactionFormMode _currentMode;

  bool _isInitializingForEditOrView = false;
  bool _accountTypesLoadedForEdit = false;
  // Categories and Subcategories will be implicitly handled by CustomCategoryPicker's data source

  @override
  void initState() {
    super.initState();
    _currentMode = widget.mode;
    final transactionBloc = context.read<TransactionBloc>();

    if (widget.transaction != null) {
      // Edit or View mode
      _isInitializingForEditOrView = true;
      final tx = widget.transaction!;
      _descriptionController.text = tx.description;
      _amountController.text = formatToRupiahWithoutSymbol(tx.amount);
      _selectedDate = tx.date;
      _selectedTime = TimeOfDay.fromDateTime(tx.date);

      // Store target IDs and names for initialization
      _selectedAccountTypeId =
          tx.accountTypeId; // Assuming Transaction model now has this
      _selectedCategoryId = tx.categoryId;
      _selectedSubcategoryId = tx.subcategoryId;

      _pickerSelectedCategoryName = tx.categoryName ?? '';
      _pickerSelectedSubcategoryName = tx.subcategoryName ?? '';
    }

    transactionBloc.add(
      LoadAccountTypesRequested(),
    ); // Always load account types
    _descriptionController.addListener(_onDescriptionChanged);
  }

  @override
  void dispose() {
    _descriptionController.removeListener(_onDescriptionChanged);
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onDescriptionChanged() {
    if (_currentMode != TransactionFormMode.view &&
        widget.onDescriptionChanged != null) {
      final description = _descriptionController.text;
      if (description.trim().isNotEmpty) {
        context.read<TransactionBloc>().add(
          ClassifyTransactionRequested(description),
        );
      }
    }
  }

  // This function tries to set the Account Type dropdown based on a category name
  void _syncAccountTypeFromCategoryName(
    String categoryName,
    TransactionState state,
  ) {
    if (categoryName.isEmpty) return;

    Category? foundCategory;
    // Search through all categories in the state (assuming they might be loaded for various account types)
    for (final cat in state.categories) {
      if (cat.name.toLowerCase() == categoryName.toLowerCase()) {
        foundCategory = cat;
        break;
      }
    }

    if (foundCategory != null &&
        foundCategory.accountTypeId != _selectedAccountTypeId) {
      try {
        final accType = state.accountTypes.firstWhere(
          (at) => at.id == foundCategory!.accountTypeId,
        );
        setState(() {
          _selectedAccountTypeId = accType.id;
          _selectedAccountTypeObject = accType;
          submitButtonColor = _colorForAccountType(accType.name);
        });
      } catch (e) {
        debugPrint(
          'Error syncing account type: AccountType for category ${foundCategory.name} not found.',
        );
      }
    }
  }

  void _handleInitialLoadForEditView(
    TransactionState state,
    BuildContext context,
  ) {
    if (!_isInitializingForEditOrView || widget.transaction == null) return;

    final tx = widget.transaction!;

    // Step 1: Set Account Type
    if (!_accountTypesLoadedForEdit && state.accountTypes.isNotEmpty) {
      if (tx.accountTypeId != null && tx.accountTypeId!.isNotEmpty) {
        try {
          final accType = state.accountTypes.firstWhere(
            (at) => at.id == tx.accountTypeId,
          );
          _selectedAccountTypeId = accType.id;
          _selectedAccountTypeObject = accType;
          submitButtonColor = _colorForAccountType(accType.name);
        } catch (e) {
          debugPrint(
            'InitialLoad: AccountType ID ${tx.accountTypeId} not found.',
          );
        }
      } else if (tx.accountTypeName != null) {
        // Fallback to name if ID not on transaction
        try {
          final accType = state.accountTypes.firstWhere(
            (at) => at.name.toLowerCase() == tx.accountTypeName!.toLowerCase(),
          );
          _selectedAccountTypeId = accType.id;
          _selectedAccountTypeObject = accType;
          submitButtonColor = _colorForAccountType(accType.name);
        } catch (e) {
          debugPrint(
            'InitialLoad: AccountType Name ${tx.accountTypeName} not found.',
          );
        }
      }
      _accountTypesLoadedForEdit = true; // Mark as attempted/done
    }

    // Step 2 & 3: Set Category and Subcategory names for the picker
    // The actual IDs (_selectedCategoryId, _selectedSubcategoryId) are already set from tx in initState.
    // The picker displays names. The BLoC handles loading the full hierarchy for the picker.
    // If the names are different from what's in BLoC state after initial load, update them.
    if (_pickerSelectedCategoryName != tx.categoryName ||
        _pickerSelectedSubcategoryName != tx.subcategoryName) {
      _pickerSelectedCategoryName = tx.categoryName ?? '';
      _pickerSelectedSubcategoryName = tx.subcategoryName ?? '';
    }

    // If all necessary initial values from transaction are processed
    if (_accountTypesLoadedForEdit) {
      // Simplified condition
      _isInitializingForEditOrView = false;
      debugPrint('[Form Edit Init] Initialization attempt complete.');
    }
  }

  void _handleClassificationResult(
    TransactionState state,
    BuildContext context,
  ) {
    if (state.classifiedResult == null ||
        _currentMode == TransactionFormMode.view) {
      return;
    }

    final result = state.classifiedResult!;
    // final transactionBloc = BlocProvider.of<TransactionBloc>(context);

    final classifiedSubcategoryId = result['subcategoryId'] as String?;
    final classifiedSubcategoryName =
        result['subcategoryName'] as String?; // ML suggestion
    final classifiedCategoryId = result['categoryId'] as String?;
    final classifiedCategoryName = result['categoryName'] as String?;
    final classifiedAccountTypeId = result['accountTypeId'] as String?;
    // final classifiedAccountTypeName = result['accountTypeName'] as String?;

    var changed = false;

    if (classifiedAccountTypeId != null &&
        _selectedAccountTypeId != classifiedAccountTypeId) {
      try {
        final accType = state.accountTypes.firstWhere(
          (at) => at.id == classifiedAccountTypeId,
        );
        _selectedAccountTypeId = accType.id;
        _selectedAccountTypeObject = accType;
        submitButtonColor = _colorForAccountType(accType.name);
        changed = true;
      } catch (e) {
        /* ignore if not found */
      }
    }

    if (classifiedCategoryId != null &&
        _selectedCategoryId != classifiedCategoryId) {
      _selectedCategoryId = classifiedCategoryId;
      changed = true;
    }
    if (classifiedSubcategoryId != null &&
        _selectedSubcategoryId != classifiedSubcategoryId) {
      _selectedSubcategoryId = classifiedSubcategoryId;
      changed = true;
    }

    // Update names for the picker
    if (classifiedCategoryName != null &&
        _pickerSelectedCategoryName != classifiedCategoryName) {
      _pickerSelectedCategoryName = classifiedCategoryName;
      changed = true;
    }
    if (classifiedSubcategoryName != null) {
      final subNameWithEmoji = '$classifiedSubcategoryName ✨';
      if (_pickerSelectedSubcategoryName != subNameWithEmoji) {
        _pickerSelectedSubcategoryName = subNameWithEmoji;
        _isClassificationSuggestion =
            true; // Mark that current picker subcat name is a suggestion
        changed = true;
      }
    }

    if (changed) {
      setState(() {}); // Rebuild to show updated selections/picker text
    }
    // No need to clear classifiedResult here, TransactionBloc should handle it or have a specific event.
  }

  @override
  Widget build(BuildContext context) {
    final isReadOnly = _currentMode == TransactionFormMode.view;

    return BlocConsumer<TransactionBloc, TransactionState>(
      listenWhen: (prev, curr) {
        var shouldListen = false;
        if (_isInitializingForEditOrView &&
            prev.accountTypes != curr.accountTypes) {
          shouldListen =
              true; // For edit/view mode initialization for account types
        }
        // For classification results, if not initializing
        if (!_isInitializingForEditOrView &&
            prev.classifiedResult != curr.classifiedResult &&
            curr.operation == TransactionOperation.classify) {
          shouldListen = true;
        }
        if (widget.mode == TransactionFormMode.view &&
            curr.operation == TransactionOperation.bookmark &&
            curr.isSuccess) {
          shouldListen = true;
        }
        return shouldListen;
      },
      listener: (ctx, state) {
        if (_isInitializingForEditOrView && state.accountTypes.isNotEmpty) {
          // This setState is crucial to trigger a rebuild after account types are loaded,
          // allowing _handleInitialLoadForEditView to correctly find and set the account type.
          setState(() {
            _handleInitialLoadForEditView(state, ctx);
          });
        } else if (!_isInitializingForEditOrView &&
            state.classifiedResult != null &&
            state.operation == TransactionOperation.classify) {
          setState(() {
            // Rebuild to reflect classification
            _handleClassificationResult(state, ctx);
          });
        }
      },
      buildWhen: (prev, curr) =>
          prev.accountTypes !=
          curr.accountTypes, // Only rebuild UI for account type list changes
      builder: (ctx, state) {
        // Prepare data for CustomDropdownField (Account Type)
        final accountTypeDropdownItems = [
          DropdownItem(
            label: 'Pilih Tipe Akun',
            icon: Icons.help_outline,
            color: Colors.grey,
          ),
          ...state.accountTypes.map(
            (t) => DropdownItem(
              label: t.name,
              icon: Icons.account_balance_wallet,
              color: _colorForAccountType(t.name),
            ),
          ),
        ];
        final displayedAccountTypeValue =
            _selectedAccountTypeObject?.name ?? 'Pilih Tipe Akun';

        // Prepare data for CustomCategoryPicker (needs Map<String, List<String>>)
        // This is the complex part: transforming API data to the picker's expected format.
        // This should ideally be done more efficiently, perhaps with a helper or memoization.
        final categoryPickerData = <String, List<String>>{};
        if (state.accountTypes.isNotEmpty &&
            state.categories.isNotEmpty &&
            state.subcategories.isNotEmpty) {
          for (final cat in state.categories) {
            // Only include categories that belong to the currently selected account type,
            // OR all categories if no account type is selected yet (might be too broad).
            // For now, let's assume we only show categories for the *selected* account type in the modal.
            // This means the modal itself might need to be more dynamic or CustomCategoryPicker enhanced.
            // OR, the `categoryMapping` passed to CustomCategoryPicker is filtered here.
            if (_selectedAccountTypeId == null ||
                cat.accountTypeId == _selectedAccountTypeId) {
              final subs = state.subcategories
                  .where((s) => s.categoryId == cat.id)
                  .map((s) => s.name)
                  .toList();
              if (subs.isNotEmpty) {
                categoryPickerData[cat.name] = subs;
              }
            }
          }
        }
        // If no account type selected, show all categories (could be overwhelming)
        if (_selectedAccountTypeId == null &&
            categoryPickerData.isEmpty &&
            state.categories.isNotEmpty) {
          for (final cat in state.categories) {
            final subs = state.subcategories
                .where((s) => s.categoryId == cat.id)
                .map((s) => s.name)
                .toList();
            if (subs.isNotEmpty) {
              categoryPickerData[cat.name] = subs;
            }
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Description
                CustomTextField(
                  label: 'Deskripsi',
                  controller: _descriptionController,
                  isEnabled: !isReadOnly,
                  onTap: isReadOnly ? _switchToEdit : null,
                  validator: (value) => (value?.isEmpty ?? true)
                      ? 'Deskripsi tidak boleh kosong'
                      : null,
                  maxLength: _maxDescriptionLength,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                ),
                const SizedBox(height: 16),

                // Dropdown: Account Type
                Row(
                  children: [
                    const Text(
                      'Tipe Akun',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: CustomDropdownField(
                        items: accountTypeDropdownItems,
                        selectedValue: displayedAccountTypeValue,
                        onChanged: isReadOnly
                            ? (item) {}
                            : (item) {
                                setState(() {
                                  _pickerSelectedCategoryName =
                                      ''; // Reset category picker
                                  _pickerSelectedSubcategoryName = '';
                                  _selectedCategoryId = null;
                                  _selectedSubcategoryId = null;
                                  _isClassificationSuggestion = false;

                                  if (item.label == 'Pilih Tipe Akun') {
                                    _selectedAccountTypeId = null;
                                    _selectedAccountTypeObject = null;
                                    submitButtonColor = Colors.grey;
                                  } else {
                                    final foundAccountType = state.accountTypes
                                        .firstWhere(
                                          (t) => t.name == item.label,
                                        );
                                    _selectedAccountTypeId =
                                        foundAccountType.id;
                                    _selectedAccountTypeObject =
                                        foundAccountType;
                                    submitButtonColor = item.color;
                                  }
                                });
                              },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Amount
                Row(
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: CustomTextField(
                        label: 'Masukkan Total',
                        controller: _amountController,
                        isEnabled: !isReadOnly,
                        onTap: isReadOnly ? _switchToEdit : null,
                        keyboardType: TextInputType.number,
                        inputFormatters: [RupiahInputFormatter()],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Total tidak boleh kosong';
                          }
                          final rawAmount = value.replaceAll(
                            RegExp('[^0-9]'),
                            '',
                          );
                          final parsedAmount =
                              double.tryParse(rawAmount) ?? 0.0;
                          if (parsedAmount <= 0) {
                            return 'Total harus lebih dari 0';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Category / Subcategory picker
                Row(
                  children: [
                    const Text(
                      'Kategori',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: CustomCategoryPicker(
                        categories:
                            categoryPickerData, // Use dynamically generated data
                        selectedCategory: _pickerSelectedCategoryName,
                        selectedSubCategory: _pickerSelectedSubcategoryName,
                        onCategorySelected: isReadOnly
                            ? (cat, subCat) {}
                            : (catName, subCatName) {
                                setState(() {
                                  _pickerSelectedCategoryName = catName;
                                  _pickerSelectedSubcategoryName = subCatName;
                                  _isClassificationSuggestion =
                                      false; // User manually selected

                                  // Find IDs for submission
                                  try {
                                    final foundCat = state.categories
                                        .firstWhere(
                                          (c) =>
                                              c.name.toLowerCase() ==
                                                  catName.toLowerCase() &&
                                              (_selectedAccountTypeId == null ||
                                                  c.accountTypeId ==
                                                      _selectedAccountTypeId),
                                        );
                                    _selectedCategoryId = foundCat.id;
                                    // Sync account type if not already matching
                                    if (_selectedAccountTypeId !=
                                        foundCat.accountTypeId) {
                                      final accType = state.accountTypes
                                          .firstWhere(
                                            (at) =>
                                                at.id == foundCat.accountTypeId,
                                          );
                                      _selectedAccountTypeId = accType.id;
                                      _selectedAccountTypeObject = accType;
                                      submitButtonColor = _colorForAccountType(
                                        accType.name,
                                      );
                                    }
                                    final foundSub = state.subcategories
                                        .firstWhere(
                                          (s) =>
                                              s.name.toLowerCase() ==
                                                  subCatName.toLowerCase() &&
                                              s.categoryId == foundCat.id,
                                        );
                                    _selectedSubcategoryId = foundSub.id;
                                  } catch (e) {
                                    debugPrint(
                                      'Error finding IDs for picker selection: $catName / $subCatName. Error: $e',
                                    );
                                    _selectedCategoryId =
                                        null; // Clear if not found
                                    _selectedSubcategoryId = null;
                                  }
                                });
                              },
                        validator: (_) {
                          // CustomCategoryPicker itself handles the FormField
                          if (_pickerSelectedCategoryName.isEmpty ||
                              _pickerSelectedSubcategoryName.isEmpty) {
                            return 'Kategori harus dipilih';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Date & Time
                Row(
                  children: [
                    const Text(
                      'Waktu',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: CustomDatePicker(
                        label: 'Tanggal',
                        isDatePicker: true,
                        selectedDate: _selectedDate,
                        initialDate: _selectedDate ?? DateTime.now(),
                        onDateChanged: isReadOnly
                            ? null
                            : (date) => setState(() => _selectedDate = date),
                        validator: (v) => _selectedDate == null
                            ? 'Tanggal harus dipilih'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomDatePicker(
                        label: 'Waktu',
                        isDatePicker: false,
                        initialTime: _selectedTime ?? TimeOfDay.now(),
                        onTimeChanged: isReadOnly
                            ? null
                            : (time) => setState(() => _selectedTime = time),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (_currentMode != TransactionFormMode.view)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: submitButtonColor,
                      ),
                      onPressed: state.isLoadingHierarchy ? null : _onSubmit,
                      child: Text(
                        _currentMode == TransactionFormMode.edit
                            ? 'Konfirmasi Edit'
                            : 'Simpan Transaksi',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                if (_currentMode == TransactionFormMode.view &&
                    widget.onDelete != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                      ),
                      onPressed: widget.onDelete,
                      child: const Text(
                        'Hapus Transaksi',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                if (_currentMode == TransactionFormMode.view)
                  Center(
                    child: TextButton(
                      onPressed: _switchToEdit,
                      child: const Text('Ubah Transaksi'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _switchToEdit() {
    if (_currentMode == TransactionFormMode.view) {
      setState(() {
        _currentMode = TransactionFormMode.edit;
        // When switching to edit, ensure picker names are clean (no emoji)
        _pickerSelectedSubcategoryName = _pickerSelectedSubcategoryName
            .replaceAll(' ✨', '');
        _isClassificationSuggestion = false;
      });
    }
  }

  String formatToRupiahWithoutSymbol(double value) {
    final formatter = NumberFormat('#,##0', 'id_ID');
    return formatter.format(value);
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap isi semua field yang wajib dengan benar.'),
        ),
      );
      return;
    }
    if (_selectedDate == null ||
        _selectedSubcategoryId == null ||
        _selectedCategoryId == null ||
        _selectedAccountTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Harap lengkapi pilihan tipe akun, kategori, dan subkategori.',
          ),
        ),
      );
      return;
    }

    final rawAmount = _amountController.text.replaceAll(RegExp('[^0-9]'), '');
    final parsedAmount = double.tryParse(rawAmount) ?? 0.0;

    final combinedDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime?.hour ?? DateTime.now().hour,
      _selectedTime?.minute ?? DateTime.now().minute,
    );

    // Get names from selected objects for the Transaction model
    final subcatObj = context
        .read<TransactionBloc>()
        .state
        .subcategories
        .firstWhere(
          (s) => s.id == _selectedSubcategoryId,
          orElse: () => Subcategory(
            id: '',
            name: _pickerSelectedSubcategoryName.replaceAll(' ✨', ''),
            categoryId: '',
          ),
        );
    final catObj = context.read<TransactionBloc>().state.categories.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => Category(
        id: '',
        name: _pickerSelectedCategoryName,
        accountTypeId: '',
      ),
    );
    final accTypeObj =
        _selectedAccountTypeObject ??
        const AccountType(id: '', name: 'Unknown');

    final tx = Transaction(
      id:
          widget.transaction?.id ??
          (_currentMode == TransactionFormMode.create
              ? ''
              : 'error_missing_id_on_edit'),
      description: _descriptionController.text,
      amount: parsedAmount,
      date: combinedDateTime,
      subcategoryId: _selectedSubcategoryId!,
      categoryId: _selectedCategoryId, // Populate with actual ID
      accountTypeId: _selectedAccountTypeId, // Populate with actual ID
      isBookmarked: widget.transaction?.isBookmarked ?? false,
      userId: widget.transaction?.userId,
      subcategoryName: subcatObj.name, // Use name from object
      categoryName: catObj.name,
      accountTypeName: accTypeObj.name,
    );

    widget.onSubmit(tx);
  }

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
        return Colors.grey;
    }
  }
}
