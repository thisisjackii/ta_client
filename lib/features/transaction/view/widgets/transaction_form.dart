import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:ta_client/core/widgets/custom_category_picker.dart';
import 'package:ta_client/core/widgets/custom_date_picker.dart';
import 'package:ta_client/core/widgets/custom_text_field.dart';
// Assuming DropdownItem and CustomDropdownField are defined in dropdown_field.dart
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
  String? _displaySelectedAccountTypeName;
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
      // _selectedAccountTypeId will be used by _handleInitialLoadForEditView to find _selectedAccountTypeObject
      _selectedAccountTypeId = tx.accountTypeId;
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

  void _syncAccountTypeFromCategoryName(
    String categoryName,
    TransactionState state,
  ) {
    if (categoryName.isEmpty) return;

    Category? foundCategory;
    // Search through all categories in the state
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
          // When account type changes due to category sync, reload categories for the new account type.
          // This ensures the category picker data is consistent.
          context.read<TransactionBloc>().add(
            LoadCategoriesRequested(accType.id),
          );
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
      var determinedAccountTypeId = tx.accountTypeId;
      AccountType? determinedAccountTypeObject;

      // Try to find by ID first (which was set in initState)
      if (determinedAccountTypeId != null &&
          determinedAccountTypeId.isNotEmpty) {
        try {
          final accType = state.accountTypes.firstWhere(
            (at) => at.id == determinedAccountTypeId,
          );
          determinedAccountTypeObject = accType;
        } catch (e) {
          debugPrint(
            'InitialLoad (Stage 1 - ID): AccountType ID ${tx.accountTypeId} not found in BLoC state. Will try by name if available.',
          );
          // Keep determinedAccountTypeId as is from tx, but object is null
        }
      }

      // If not found by ID, or no ID, try by name
      if (determinedAccountTypeObject == null &&
          tx.accountTypeName != null &&
          tx.accountTypeName!.isNotEmpty) {
        try {
          final accType = state.accountTypes.firstWhere(
            (at) => at.name.toLowerCase() == tx.accountTypeName!.toLowerCase(),
          );
          determinedAccountTypeId = accType.id; // Update ID if found by name
          determinedAccountTypeObject = accType;
        } catch (e) {
          debugPrint(
            'InitialLoad (Stage 1 - Name): AccountType Name ${tx.accountTypeName} not found in BLoC state.',
          );
        }
      }

      _accountTypesLoadedForEdit =
          true; // Mark that we've processed account types from BLoC state.

      if (determinedAccountTypeId != null &&
          determinedAccountTypeObject != null) {
        // Update local state for Account Type. This will reflect in the dropdown.
        // No need for setState here as this function is called within a listener's setState.
        _selectedAccountTypeId = determinedAccountTypeId;
        _selectedAccountTypeObject = determinedAccountTypeObject;
        submitButtonColor = _colorForAccountType(
          determinedAccountTypeObject.name,
        );

        // Crucially, dispatch to load categories for this account type
        transactionBloc.add(LoadCategoriesRequested(determinedAccountTypeId));
        // Return here; the listener will pick up the next state change when categories are loaded
        return;
      } else {
        debugPrint(
          '[Form Edit Init (Stage 1)] Could not determine AccountType from transaction. Categories/Subcategories might not pre-fill correctly.',
        );
        _isInitializingForEditOrView = false;
        _initialCategoriesLoadedForEdit = true;
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
      if (tx.categoryName != null && _selectedAccountTypeId != null) {
        try {
          final foundCategory = state.categories.firstWhere(
            (cat) =>
                cat.name.toLowerCase() == tx.categoryName!.toLowerCase() &&
                cat.accountTypeId == _selectedAccountTypeId,
          );
          _selectedCategoryId = foundCategory.id;

          if (tx.subcategoryName != null && state.subcategories.isNotEmpty) {
            final foundSubcategory = state.subcategories.firstWhere(
              (sub) =>
                  sub.name.toLowerCase() == tx.subcategoryName!.toLowerCase() &&
                  sub.categoryId == foundCategory.id,
            );
            _selectedSubcategoryId = foundSubcategory.id;
          } else if (tx.subcategoryName != null &&
              state.subcategories.isEmpty &&
              !state.isLoadingHierarchy) {
            _selectedSubcategoryId = null;
            debugPrint(
              'InitialLoad (Stage 2): Subcategories loaded but empty or no match for "${tx.subcategoryName}".',
            );
          }
        } catch (e) {
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

      if (_pickerSelectedCategoryName != (tx.categoryName ?? '') ||
          _pickerSelectedSubcategoryName != (tx.subcategoryName ?? '')) {
        _pickerSelectedCategoryName = tx.categoryName ?? '';
        _pickerSelectedSubcategoryName = tx.subcategoryName ?? '';
      }

      _initialCategoriesLoadedForEdit = true;
      _isInitializingForEditOrView = false;
      debugPrint(
        '[Form Edit Init (Stage 2)] Initialization attempt complete for categories/subcategories.',
      );
    } else if (_accountTypesLoadedForEdit &&
        !_initialCategoriesLoadedForEdit &&
        state.isLoadingHierarchy) {
      debugPrint(
        '[Form Edit Init] Waiting for categories/subcategories to load...',
      );
    } else if (_accountTypesLoadedForEdit && _initialCategoriesLoadedForEdit) {
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
      debugPrint(
        "[TransactionForm._handleClassificationResult] No classified result or in view mode. Skipping.",
      );
      return;
    }

    final Map<String, dynamic> classificationData = state.classifiedResult!;

    final bool isKnownSubcategoryByMl =
        classificationData['isKnownSubcategory'] as bool? ?? false;
    final double confidence =
        (classificationData['confidence'] as num?)?.toDouble() ?? 0.0;

    debugPrint(
      "[TransactionForm._handleClassificationResult] Received classificationData: $classificationData",
    );
    debugPrint(
      "[TransactionForm._handleClassificationResult] Parsed: isKnownSubcategoryByMl=$isKnownSubcategoryByMl, confidence=$confidence",
    );

    // Only check isKnownSubcategoryByMl from the data object
    if (!isKnownSubcategoryByMl) {
      if (_isClassificationSuggestion) {
        _pickerSelectedSubcategoryName = _pickerSelectedSubcategoryName
            .replaceAll(' ✨', '');
        _isClassificationSuggestion = false;
      }
      debugPrint(
        '[TransactionForm] Classification not applied: isKnownSubcategoryByMl=false',
      );
      return;
    }

    debugPrint(
      "[TransactionForm._handleClassificationResult] Applying known classification...",
    );

    // ... THE REST OF YOUR FIELD EXTRACTION AND LOGIC FROM LINE 327 of your screenshot onwards should now execute correctly ...
    // (i.e., final classifiedSubcategoryId = classificationData['subcategoryId'] as String?; etc.)
    // Make sure this logic correctly uses `context.read<TransactionBloc>().state.accountTypes` etc.
    // if it needs to look up names from IDs, as `classificationData` already provides names.

    // --- Re-integrating your existing logic for updating form state ---
    final classifiedSubcategoryId =
        classificationData['subcategoryId'] as String?;
    final classifiedSubcategoryName =
        classificationData['subcategoryName'] as String?;
    final classifiedCategoryId = classificationData['categoryId'] as String?;
    final classifiedCategoryName =
        classificationData['categoryName'] as String?;
    final classifiedAccountTypeId =
        classificationData['accountTypeId'] as String?;
    final classifiedAccountTypeName =
        classificationData['accountTypeName'] as String?;

    bool accountTypeActuallyChangedByThisClassification = false;
    bool categoryActuallyChangedByThisClassification = false;

    // 1. Process Account Type
    if (classifiedAccountTypeId != null &&
        _selectedAccountTypeId != classifiedAccountTypeId) {
      try {
        final accType = context
            .read<TransactionBloc>()
            .state
            .accountTypes
            .firstWhere((at) => at.id == classifiedAccountTypeId);
        _selectedAccountTypeId = accType.id;
        _selectedAccountTypeObject = accType;
        _displaySelectedAccountTypeName = accType.name;
        submitButtonColor = _colorForAccountType(accType.name);

        _selectedCategoryId = null;
        _pickerSelectedCategoryName = '';
        _selectedSubcategoryId = null;
        _pickerSelectedSubcategoryName = '';
        _isClassificationSuggestion = false;

        accountTypeActuallyChangedByThisClassification = true;
        debugPrint(
          "[TransactionForm] Classification updated AccountType to: ${accType.name}. Requesting categories.",
        );
        context.read<TransactionBloc>().add(
          LoadCategoriesRequested(accType.id),
        );
        return;
      } catch (e) {
        debugPrint(
          "[TransactionForm] Error finding classified AccountType ID $classifiedAccountTypeId in BLoC state: $e",
        );
        return;
      }
    } else if (classifiedAccountTypeName != null &&
        _displaySelectedAccountTypeName != classifiedAccountTypeName &&
        _selectedAccountTypeId != null) {
      _displaySelectedAccountTypeName = classifiedAccountTypeName;
      try {
        _selectedAccountTypeObject = context
            .read<TransactionBloc>()
            .state
            .accountTypes
            .firstWhere((at) => at.id == _selectedAccountTypeId);
        submitButtonColor = _colorForAccountType(
          _selectedAccountTypeObject!.name,
        );
      } catch (_) {}
    }

    // 2. Process Category
    if (!accountTypeActuallyChangedByThisClassification &&
        classifiedCategoryId != null &&
        _selectedCategoryId != classifiedCategoryId) {
      try {
        final cat = context.read<TransactionBloc>().state.categories.firstWhere(
          (c) =>
              c.id == classifiedCategoryId &&
              c.accountTypeId == _selectedAccountTypeId,
        );
        _selectedCategoryId = cat.id;
        _pickerSelectedCategoryName = cat.name;

        _selectedSubcategoryId = null;
        _pickerSelectedSubcategoryName = '';
        _isClassificationSuggestion = false;

        categoryActuallyChangedByThisClassification = true;
        debugPrint(
          "[TransactionForm] Classification updated CategoryId to: $classifiedCategoryId. Requesting subcategories.",
        );
        context.read<TransactionBloc>().add(LoadSubcategoriesRequested(cat.id));
        return;
      } catch (e) {
        debugPrint(
          "[TransactionForm] Error finding/validating classified Category ID $classifiedCategoryId: $e",
        );
        return;
      }
    } else if (!accountTypeActuallyChangedByThisClassification &&
        classifiedCategoryName != null &&
        _pickerSelectedCategoryName != classifiedCategoryName) {
      _pickerSelectedCategoryName = classifiedCategoryName;
      if (_selectedCategoryId == null && _selectedAccountTypeId != null) {
        try {
          final catByName = context
              .read<TransactionBloc>()
              .state
              .categories
              .firstWhere(
                (c) =>
                    c.name == classifiedCategoryName &&
                    c.accountTypeId == _selectedAccountTypeId,
              );
          _selectedCategoryId = catByName.id;
        } catch (_) {}
      }
    }

    // 3. Process Subcategory
    if (!accountTypeActuallyChangedByThisClassification &&
        !categoryActuallyChangedByThisClassification &&
        classifiedSubcategoryId != null &&
        _selectedSubcategoryId != classifiedSubcategoryId) {
      try {
        // Ensure the suggested subcategory belongs to the currently selected category
        final subcat = context
            .read<TransactionBloc>()
            .state
            .subcategories
            .firstWhere(
              (s) =>
                  s.id == classifiedSubcategoryId &&
                  s.categoryId == _selectedCategoryId,
            );
        _selectedSubcategoryId = subcat.id;
        _pickerSelectedSubcategoryName =
            '${subcat.name} ✨'; // Use name from loaded data + emoji
        _isClassificationSuggestion = true;
        debugPrint(
          "[TransactionForm] Classification updated SubcategoryId to: $classifiedSubcategoryId",
        );
      } catch (e) {
        debugPrint(
          "[TransactionForm] Error finding/validating classified Subcategory ID $classifiedSubcategoryId: $e",
        );
        if (classifiedSubcategoryName != null) {
          _pickerSelectedSubcategoryName = '$classifiedSubcategoryName ✨';
          _isClassificationSuggestion = true;
        } else {
          _pickerSelectedSubcategoryName = _pickerSelectedSubcategoryName
              .replaceAll(' ✨', '');
          _isClassificationSuggestion = false;
        }
        _selectedSubcategoryId = null; // Could not confirm ID
      }
    } else if (!accountTypeActuallyChangedByThisClassification &&
        !categoryActuallyChangedByThisClassification &&
        classifiedSubcategoryName != null) {
      final subNameWithEmoji = '$classifiedSubcategoryName ✨';
      if (_pickerSelectedSubcategoryName != subNameWithEmoji) {
        _pickerSelectedSubcategoryName = subNameWithEmoji;
        _isClassificationSuggestion = true;
      }
      if (_selectedSubcategoryId == null && _selectedCategoryId != null) {
        try {
          final subByName = context
              .read<TransactionBloc>()
              .state
              .subcategories
              .firstWhere(
                (s) =>
                    s.name == classifiedSubcategoryName &&
                    s.categoryId == _selectedCategoryId,
              );
          _selectedSubcategoryId = subByName.id;
        } catch (_) {}
      }
    } else if (classifiedSubcategoryName == null &&
        _isClassificationSuggestion) {
      _pickerSelectedSubcategoryName = _pickerSelectedSubcategoryName
          .replaceAll(' ✨', '');
      _isClassificationSuggestion = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReadOnly = _currentMode == TransactionFormMode.view;

    return BlocConsumer<TransactionBloc, TransactionState>(
      listenWhen: (prev, curr) {
        // Always listen if initializing for edit/view to load hierarchy
        if (_isInitializingForEditOrView) {
          return prev.accountTypes != curr.accountTypes ||
              prev.categories != curr.categories ||
              prev.subcategories != curr.subcategories ||
              prev.isLoadingHierarchy != curr.isLoadingHierarchy;
        }
        // Listen for classification results
        return (prev.classifiedResult !=
                    curr.classifiedResult && // Result changed
                curr.classifiedResult != null && // New result is not null
                curr.operation ==
                    TransactionOperation.classify) || // Operation was classify
            // Listen for bookmark updates if in view mode
            (widget.mode == TransactionFormMode.view &&
                curr.operation == TransactionOperation.bookmark &&
                curr.isSuccess) ||
            // Listen for hierarchy changes if they happen for other reasons (e.g. background refresh)
            prev.accountTypes != curr.accountTypes ||
            prev.categories != curr.categories ||
            prev.subcategories != curr.subcategories;
      },
      listener: (ctx, state) {
        if (_isInitializingForEditOrView) {
          // Call setState directly here because _handleInitialLoadForEditView
          // might dispatch new BLoC events (LoadCategoriesRequested), and we want
          // the UI to reflect the current state of loading/data before those complete.
          // The subsequent BLoC state updates from those events will be caught
          // by this listener again.
          setState(() {
            _handleInitialLoadForEditView(state, ctx);
          });
        } else if (state.classifiedResult != null &&
            state.operation == TransactionOperation.classify) {
          // Apply classification result
          setState(() {
            // Ensure UI updates after applying classification
            _handleClassificationResult(state, ctx);
          });
        }
        // Potentially handle bookmark success if needed, though often just a visual change handled by BlocBuilder
      },
      buildWhen: (prev, curr) =>
          prev.accountTypes != curr.accountTypes ||
          prev.categories != curr.categories ||
          prev.subcategories != curr.subcategories ||
          prev.isLoadingHierarchy != curr.isLoadingHierarchy ||
          prev.classifiedResult != curr.classifiedResult ||
          (widget.mode == TransactionFormMode.view &&
              prev.lastProcessedTransaction != curr.lastProcessedTransaction),
      builder: (ctx, state) {
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

        final categoryPickerData = <String, List<String>>{};
        if (_selectedAccountTypeId != null && state.categories.isNotEmpty) {
          for (final cat in state.categories) {
            if (cat.accountTypeId == _selectedAccountTypeId) {
              final subs = state.subcategories
                  .where((s) => s.categoryId == cat.id)
                  .map((s) => s.name)
                  .toList();
              if (subs.isNotEmpty) {
                categoryPickerData[cat.name] = subs;
              } else {
                // Add category even if it has no subcategories for the picker to show it
                categoryPickerData[cat.name] = [];
              }
            }
          }
        } else if (_selectedAccountTypeId == null &&
            categoryPickerData.isEmpty &&
            state.categories.isNotEmpty &&
            !state.isLoadingHierarchy) {
          // Show all categories if no account type selected (less ideal, but a fallback)
          // This case should be less common if account type selection drives category loading
          for (final cat in state.categories) {
            final subs = state.subcategories
                .where((s) => s.categoryId == cat.id)
                .map((s) => s.name)
                .toList();
            if (subs.isNotEmpty) {
              categoryPickerData[cat.name] = subs;
            } else {
              categoryPickerData[cat.name] = [];
            }
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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

                const Text(
                  'Tipe Akun',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                FormField<String>(
                  validator: (value) {
                    if (_selectedAccountTypeId == null && !isReadOnly) {
                      return 'Tipe Akun harus dipilih';
                    }
                    return null;
                  },
                  builder: (FormFieldState<String> field) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomDropdownField(
                          // No label prop needed here as we have a Text widget above
                          items: accountTypeDropdownItems,
                          selectedValue: displayedAccountTypeValue,
                          onChanged: isReadOnly
                              ? (item) {}
                              : (item) {
                                  setState(() {
                                    _pickerSelectedCategoryName = '';
                                    _pickerSelectedSubcategoryName = '';
                                    _selectedCategoryId = null;
                                    _selectedSubcategoryId = null;
                                    _isClassificationSuggestion = false;

                                    if (item.label == 'Pilih Tipe Akun') {
                                      _selectedAccountTypeId = null;
                                      _selectedAccountTypeObject = null;
                                      submitButtonColor = Colors.grey;
                                      context.read<TransactionBloc>().add(
                                        const LoadCategoriesRequested(
                                          '',
                                        ), // Clear/load empty categories
                                      );
                                      field.didChange(null); // For validation
                                    } else {
                                      final foundAccountType = state
                                          .accountTypes
                                          .firstWhere(
                                            (t) => t.name == item.label,
                                          );
                                      _selectedAccountTypeId =
                                          foundAccountType.id;
                                      _selectedAccountTypeObject =
                                          foundAccountType;
                                      submitButtonColor = item.color;
                                      context.read<TransactionBloc>().add(
                                        LoadCategoriesRequested(
                                          foundAccountType.id,
                                        ),
                                      );
                                      field.didChange(
                                        item.label,
                                      ); // For validation
                                    }
                                  });
                                },
                        ),
                        if (field.hasError)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 5,
                            ), // Aligned with dropdown
                            child: Text(
                              field.errorText!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),

                const Text(
                  'Total',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                CustomTextField(
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
                    final rawAmount = value.replaceAll(RegExp('[^0-9]'), '');
                    final parsedAmount = double.tryParse(rawAmount) ?? 0.0;
                    if (parsedAmount <= 0) {
                      return 'Total harus lebih dari 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                const Text(
                  'Kategori',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                CustomCategoryPicker(
                  categories: categoryPickerData,
                  selectedCategory: _pickerSelectedCategoryName,
                  selectedSubCategory: _pickerSelectedSubcategoryName,
                  onCategorySelected: isReadOnly
                      ? (cat, subCat) {}
                      : (catName, subCatName) {
                          setState(() {
                            _pickerSelectedCategoryName = catName;
                            _pickerSelectedSubcategoryName = subCatName;
                            _isClassificationSuggestion = false;

                            try {
                              final foundCat = state.categories.firstWhere(
                                (c) =>
                                    c.name.toLowerCase() ==
                                        catName.toLowerCase() &&
                                    (_selectedAccountTypeId == null ||
                                        c.accountTypeId ==
                                            _selectedAccountTypeId),
                              );
                              _selectedCategoryId = foundCat.id;

                              // Sync account type if not already matching AND if it's a valid type
                              if (_selectedAccountTypeId !=
                                  foundCat.accountTypeId) {
                                _syncAccountTypeFromCategoryName(
                                  catName,
                                  state,
                                );
                              }

                              final foundSub = state.subcategories.firstWhere(
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
                              _selectedCategoryId = null;
                              _selectedSubcategoryId = null;
                            }
                          });
                        },
                  validator: (String? value) {
                    // Signature matches FormField validator
                    if (_pickerSelectedCategoryName.isEmpty ||
                        _pickerSelectedSubcategoryName.isEmpty && !isReadOnly) {
                      return 'Kategori harus dipilih';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: CustomDatePicker(
                        label: 'Tanggal',
                        isDatePicker: true,
                        selectedDate: _selectedDate,
                        initialDate: _selectedDate ?? DateTime.now(),
                        onDateChanged: isReadOnly
                            ? null
                            : (date) => setState(() => _selectedDate = date),
                        validator: (v) => _selectedDate == null && !isReadOnly
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
                        // Time is optional for validation, but not null in model
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
        _pickerSelectedSubcategoryName = _pickerSelectedSubcategoryName
            .replaceAll(' ✨', '');
        _isClassificationSuggestion = false;
        // Re-trigger initial data load for edit to ensure everything is fresh for editing
        // and categories are loaded for the current account type.
        // This is important if the view mode didn't fully load/display everything.
        _isInitializingForEditOrView = true;
        _accountTypesLoadedForEdit =
            false; // Reset flag to allow re-processing of account type
        _initialCategoriesLoadedForEdit = false; // Reset flag for categories

        // Request account types again, which will cascade to category loading in _handleInitialLoadForEditView
        context.read<TransactionBloc>().add(LoadAccountTypesRequested());
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
    // The individual field validators (now including Account Type) handle mandatory checks.
    // _selectedAccountTypeId check is now part of the FormField validator.
    // We still need to ensure category/subcategory IDs are resolved.
    if (_selectedSubcategoryId == null || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kategori atau Subkategori belum teridentifikasi. Harap pilih kembali.',
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

    final subcatObj = context
        .read<TransactionBloc>()
        .state
        .subcategories
        .firstWhere(
          (s) => s.id == _selectedSubcategoryId,
          orElse: () => Subcategory(
            id: _selectedSubcategoryId!, // Should not be null if validated
            name: _pickerSelectedSubcategoryName.replaceAll(' ✨', ''),
            categoryId: _selectedCategoryId!, // Should not be null
          ),
        );
    final catObj = context.read<TransactionBloc>().state.categories.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => Category(
        id: _selectedCategoryId!, // Should not be null
        name: _pickerSelectedCategoryName,
        accountTypeId: _selectedAccountTypeId!, // Should not be null
      ),
    );
    final accTypeObj =
        _selectedAccountTypeObject ?? // Should be set if _selectedAccountTypeId is not null
        AccountType(id: _selectedAccountTypeId!, name: 'Unknown');

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
      categoryId: _selectedCategoryId,
      accountTypeId: _selectedAccountTypeId,
      isBookmarked: widget.transaction?.isBookmarked ?? false,
      userId: widget.transaction?.userId,
      subcategoryName: subcatObj.name,
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

// The DropdownItem class and _CustomDropdownFieldState (if defined in this file)
// would remain the same. Assuming they are in 'dropdown_field.dart' as per the import.
// If CustomDropdownField is in the same file as the original problem, it does not need changes
// based on the problem description for these specific issues.
