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
  bool _initialCategoriesLoadedForEdit = false;

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
    final transactionBloc = context.read<TransactionBloc>();

    // Stage 1: Set Account Type and trigger category loading
    if (!_accountTypesLoadedForEdit && state.accountTypes.isNotEmpty) {
      String?
      determinedAccountTypeId; // To store the ID of the determined account type
      AccountType? determinedAccountTypeObject;

      if (tx.accountTypeId != null && tx.accountTypeId!.isNotEmpty) {
        try {
          final accType = state.accountTypes.firstWhere(
            (at) => at.id == tx.accountTypeId,
          );
          determinedAccountTypeId = accType.id;
          determinedAccountTypeObject = accType;
        } catch (e) {
          debugPrint(
            'InitialLoad (Stage 1): AccountType ID ${tx.accountTypeId} not found in BLoC state.',
          );
        }
      } else if (tx.accountTypeName != null) {
        try {
          final accType = state.accountTypes.firstWhere(
            (at) => at.name.toLowerCase() == tx.accountTypeName!.toLowerCase(),
          );
          determinedAccountTypeId = accType.id;
          determinedAccountTypeObject = accType;
        } catch (e) {
          debugPrint(
            'InitialLoad (Stage 1): AccountType Name ${tx.accountTypeName} not found in BLoC state.',
          );
        }
      }

      _accountTypesLoadedForEdit =
          true; // Mark that we've attempted to load/set account type

      if (determinedAccountTypeId != null &&
          determinedAccountTypeObject != null) {
        // Only update state if it's different or not yet set, to avoid unnecessary rebuilds
        if (_selectedAccountTypeId != determinedAccountTypeId) {
          _selectedAccountTypeId = determinedAccountTypeId;
          _selectedAccountTypeObject = determinedAccountTypeObject;
          submitButtonColor = _colorForAccountType(
            determinedAccountTypeObject.name,
          );
        }
        // Crucially, dispatch to load categories for this account type
        transactionBloc.add(LoadCategoriesRequested(determinedAccountTypeId));
        // Return here; the listener will pick up the next state change when categories are loaded
        return;
      } else {
        debugPrint(
          '[Form Edit Init (Stage 1)] Could not determine AccountType from transaction. Categories/Subcategories might not pre-fill correctly.',
        );
        // If account type can't be determined, we can't reliably load categories.
        // End the multi-stage initialization here.
        _isInitializingForEditOrView = false;
        _initialCategoriesLoadedForEdit =
            true; // No categories to load based on this.
        debugPrint(
          '[Form Edit Init (Stage 1)] Initialization stopped due to AccountType not found.',
        );
        return;
      }
    }

    // Stage 2: Categories (and by extension, subcategories) are loaded.
    // Set picker names and try to match Category/Subcategory IDs.
    if (_accountTypesLoadedForEdit &&
        !_initialCategoriesLoadedForEdit &&
        (state.categories.isNotEmpty || !state.isLoadingHierarchy)) {
      // Picker names are set from `tx` in initState.
      // We need to ensure _selectedCategoryId and _selectedSubcategoryId are correctly set
      // based on the names from `tx` and the newly loaded `state.categories` and `state.subcategories`.

      if (tx.categoryName != null && _selectedAccountTypeId != null) {
        try {
          final foundCategory = state.categories.firstWhere(
            (cat) =>
                cat.name.toLowerCase() == tx.categoryName!.toLowerCase() &&
                cat.accountTypeId == _selectedAccountTypeId,
          );
          _selectedCategoryId = foundCategory.id; // Update/confirm the ID

          if (tx.subcategoryName != null && state.subcategories.isNotEmpty) {
            final foundSubcategory = state.subcategories.firstWhere(
              (sub) =>
                  sub.name.toLowerCase() == tx.subcategoryName!.toLowerCase() &&
                  sub.categoryId == foundCategory.id,
            );
            _selectedSubcategoryId =
                foundSubcategory.id; // Update/confirm the ID
          } else if (tx.subcategoryName != null &&
              state.subcategories.isEmpty &&
              !state.isLoadingHierarchy) {
            _selectedSubcategoryId =
                null; // Subcategories loaded but none match, or list is empty
            debugPrint(
              'InitialLoad (Stage 2): Subcategories loaded but empty or no match for "${tx.subcategoryName}".',
            );
          }
        } catch (e) {
          // If matching fails, the IDs initially set from `tx` (if they existed) or null will remain.
          // This is acceptable; the user can re-select from the picker if the data is inconsistent.
          debugPrint(
            'InitialLoad (Stage 2): Could not precisely match category/subcategory names from tx to loaded data: $e. Picker names are set, actual IDs might differ if user doesnt reselect.',
          );
        }
      } else if (state.categories.isEmpty && !state.isLoadingHierarchy) {
        debugPrint(
          'InitialLoad (Stage 2): Categories list is empty for selected Account Type. Picker will reflect this.',
        );
        _selectedCategoryId = null;
        _selectedSubcategoryId = null;
      }

      // Ensure picker names are definitely from the transaction at this point
      // (they are set in initState, this is a re-affirmation or update if something was missed)
      if (_pickerSelectedCategoryName != (tx.categoryName ?? '') ||
          _pickerSelectedSubcategoryName != (tx.subcategoryName ?? '')) {
        _pickerSelectedCategoryName = tx.categoryName ?? '';
        _pickerSelectedSubcategoryName = tx.subcategoryName ?? '';
      }

      _initialCategoriesLoadedForEdit = true; // Mark this stage as complete
      _isInitializingForEditOrView =
          false; // All initialization stages are now complete
      debugPrint(
        '[Form Edit Init (Stage 2)] Initialization attempt complete for categories/subcategories.',
      );
    } else if (_accountTypesLoadedForEdit &&
        !_initialCategoriesLoadedForEdit &&
        state.isLoadingHierarchy) {
      // Still loading categories/subcategories, wait for the next state update.
      debugPrint(
        '[Form Edit Init] Waiting for categories/subcategories to load...',
      );
    } else if (_accountTypesLoadedForEdit && _initialCategoriesLoadedForEdit) {
      // This means all hierarchy loading stages are done.
      _isInitializingForEditOrView = false;
      debugPrint(
        '[Form Edit Init] All stages previously completed or no further data loaded.',
      );
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
        if (_isInitializingForEditOrView) {
          // If still initializing, listen to any hierarchy data change or loading state change
          return prev.accountTypes != curr.accountTypes ||
              prev.categories != curr.categories ||
              prev.subcategories != curr.subcategories ||
              prev.isLoadingHierarchy != curr.isLoadingHierarchy;
        }
        // If not initializing, listen for other relevant operations
        return (prev.classifiedResult != curr.classifiedResult &&
                curr.operation == TransactionOperation.classify) ||
            (widget.mode == TransactionFormMode.view &&
                curr.operation == TransactionOperation.bookmark &&
                curr.isSuccess);
      },
      listener: (ctx, state) {
        if (_isInitializingForEditOrView) {
          // Call _handleInitialLoadForEditView which might change local state vars.
          // setState() here ensures the UI rebuilds to reflect those local changes immediately
          // if _handleInitialLoadForEditView itself doesn't trigger a UI-relevant state emission from BLoC.
          setState(() {
            _handleInitialLoadForEditView(state, ctx);
          });
        } else if (state.classifiedResult != null &&
            state.operation == TransactionOperation.classify) {
          setState(() {
            _handleClassificationResult(state, ctx);
          });
        }
        // No specific listener action for bookmark here, as builder reacts to lastProcessedTransaction
      },
      buildWhen: (prev, curr) =>
          prev.accountTypes != curr.accountTypes ||
          prev.categories != curr.categories || // Rebuild if categories change
          prev.subcategories !=
              curr.subcategories || // Rebuild if subcategories change
          prev.isLoadingHierarchy !=
              curr.isLoadingHierarchy || // Rebuild if loading state for hierarchy changes
          prev.classifiedResult != curr.classifiedResult ||
          (widget.mode == TransactionFormMode.view &&
              prev.lastProcessedTransaction != curr.lastProcessedTransaction),
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
                                    // Clear categories and subcategories in BLoC state if "Pilih Tipe Akun" is chosen
                                    context.read<TransactionBloc>().add(
                                      const LoadCategoriesRequested(''),
                                    ); // Pass empty or a special ID
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
                                    // *** ADD THIS LINE ***
                                    context.read<TransactionBloc>().add(
                                      LoadCategoriesRequested(
                                        foundAccountType.id,
                                      ),
                                    );
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
