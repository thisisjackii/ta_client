// lib/features/transaction/view/widgets/transaction_form.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/core/constants/category_mapping.dart';
import 'package:ta_client/core/utils/calculations.dart';
import 'package:ta_client/core/widgets/custom_category_picker.dart';
import 'package:ta_client/core/widgets/custom_date_picker.dart';
import 'package:ta_client/core/widgets/custom_text_field.dart';
import 'package:ta_client/core/widgets/dropdown_field.dart';
import 'package:ta_client/core/widgets/rupiah_formatter.dart';
import 'package:ta_client/features/transaction/bloc/transaction_bloc.dart';
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

class _TransactionFormState extends State<TransactionForm> with RouteAware {
  Color submitButtonColor = const Color(0xff2A8C8B);

  final List<DropdownItem> dropdownItems = [
    DropdownItem(
      label: 'Pilih Tipe Akun', // Placeholder text
      icon: Icons.help_outline,
      color: Colors.grey,
    ),
    DropdownItem(
      label: 'Aset',
      icon: Icons.account_balance_wallet,
      color: const Color(0xff2A8C8B),
    ),
    DropdownItem(
      label: 'Liabilitas',
      icon: Icons.account_balance,
      color: const Color(0xffEF233C),
    ),
    DropdownItem(
      label: 'Pemasukan',
      icon: Icons.add_card_rounded,
      color: const Color(0xff5A4CAF),
    ),
    DropdownItem(
      label: 'Pengeluaran',
      icon: Icons.local_activity_rounded,
      color: const Color(0xffD623AE),
    ),
  ];

  late String transactionType;
  late String selectedValue;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  String rawPredictedCategory = '';
  String subcategory = '';

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  final int maxDescriptionLength = 100;

  @override
  void initState() {
    super.initState();

    // Initialize mode & fields
    mode = widget.mode;

    // Build the list of allowed dropdown labels
    final allowedLabels = dropdownItems.map((d) => d.label).toList();

    if (widget.transaction != null) {
      // Only accept accountType if it's one of our labels
      final acct = widget.transaction!.accountType;
      selectedValue = allowedLabels.contains(acct) ? acct : allowedLabels.first;
      transactionType = selectedValue;

      // Pre-fill all other controllers
      descriptionController.text = widget.transaction!.description;
      amountController.text = formatToRupiah(widget.transaction!.amount);
      rawPredictedCategory = widget.transaction!.categoryName;
      subcategory = widget.transaction!.subcategoryName;
      selectedDate = widget.transaction!.date;
      selectedTime = TimeOfDay.fromDateTime(widget.transaction!.date);
    } else {
      selectedValue = 'Pilih Tipe Akun';
      transactionType = selectedValue;
    }

    descriptionController.addListener(_onDescriptionChanged);
  }

  void _onDescriptionChanged() {
    final text = descriptionController.text;
    if (text.trim().isNotEmpty && widget.onDescriptionChanged != null) {
      widget.onDescriptionChanged!(text);
    }
  }

  late TransactionFormMode mode;

  @override
  Widget build(BuildContext context) {
    final isReadOnly = mode == TransactionFormMode.view;

    return BlocListener<TransactionBloc, TransactionState>(
      listener: (context, state) {
        if (state.classifiedCategory != null &&
            state.classifiedCategory!.isNotEmpty) {
          final predictedSub = state.classifiedCategory!;
          final predictedParent = findParentCategory(predictedSub);
          setState(() {
            rawPredictedCategory = predictedParent;
            subcategory = '$predictedSub ✨';
          });
        } else {
          setState(() {
            rawPredictedCategory = '';
            subcategory = '';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'The system is not confident with the auto-classification. Please select a category manually.',
              ),
            ),
          );
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Description
              CustomTextField(
                label: 'Deskripsi',
                controller: descriptionController,
                isEnabled: !isReadOnly,
                onTap: isReadOnly ? _switchToEdit : null,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Field cannot be empty';
                  }
                  return null;
                },
                maxLength: maxDescriptionLength,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
              ),
              const SizedBox(height: 16),

              // Dropdown: Account Type
              CustomDropdownField(
                items: dropdownItems,
                selectedValue: selectedValue,
                onChanged: (item) {
                  setState(() {
                    selectedValue = item.label;
                    transactionType = item.label;
                    submitButtonColor = item.color;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Amount
              Row(
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: CustomTextField(
                      label: 'Enter Total',
                      controller: amountController,
                      isEnabled: !isReadOnly,
                      onTap: isReadOnly ? _switchToEdit : null,
                      keyboardType: TextInputType.number,
                      inputFormatters: [RupiahInputFormatter()],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Field cannot be empty';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Category / Subcategory picker
              CustomCategoryPicker(
                categories: categoryMapping,
                selectedCategory: rawPredictedCategory,
                selectedSubCategory: subcategory,
                onCategorySelected: isReadOnly
                    ? (a, b) {}
                    : (cat, subCat) {
                        setState(() {
                          rawPredictedCategory = cat;
                          subcategory = subCat;
                        });
                      },
              ),
              const SizedBox(height: 16),

              // Date & Time
              Row(
                children: [
                  Expanded(
                    child: CustomDatePicker(
                      label: 'Tanggal',
                      isDatePicker: true,
                      selectedDate: selectedDate,
                      onDateChanged: isReadOnly
                          ? null
                          : (date) {
                              setState(() {
                                selectedDate = date;
                              });
                            },
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomDatePicker(
                      label: 'Waktu',
                      isDatePicker: false,
                      initialTime: selectedTime,
                      onTimeChanged: isReadOnly
                          ? null
                          : (time) {
                              setState(() {
                                selectedTime = time;
                              });
                            },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Delete or Submit
              if (isReadOnly)
                ElevatedButton(
                  onPressed: widget.onDelete,
                  child: const Text('Delete'),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: submitButtonColor,
                    ),
                    onPressed: _onSubmit,
                    child: Text(
                      mode == TransactionFormMode.edit
                          ? 'Confirm Edit'
                          : 'Submit',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate() || selectedDate == null) return;
    if (transactionType == '' || transactionType == 'Pilih Tipe Akun') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid account type.')),
      );
      return;
    }
    final rawAmount = amountController.text.replaceAll(RegExp('[^0-9]'), '');
    final parsedAmount = double.tryParse(rawAmount) ?? 0.0;
    final cleanSub = subcategory.replaceAll(' ✨', '');

    final combinedDate = selectedTime == null
        ? selectedDate!
        : DateTime(
            selectedDate!.year,
            selectedDate!.month,
            selectedDate!.day,
            selectedTime!.hour,
            selectedTime!.minute,
          );

    final tx = Transaction(
      id: widget.transaction?.id ?? '',
      categoryId:
          '', // <-- you’ll populate this from your picker’s internal lookup
      accountType: transactionType,
      description: descriptionController.text,
      date: combinedDate,
      categoryName: rawPredictedCategory,
      subcategoryName: cleanSub,
      amount: parsedAmount,
      isBookmarked: widget.transaction?.isBookmarked ?? false,
    );

    widget.onSubmit(tx);

    if (mode == TransactionFormMode.edit) {
      setState(() => mode = TransactionFormMode.view);
    }
  }

  String findParentCategory(String sub) {
    for (final entry in categoryMapping.entries) {
      if (entry.value.map((s) => s.toLowerCase()).contains(sub.toLowerCase())) {
        return entry.key;
      }
    }
    return '';
  }

  void _switchToEdit() {
    if (mode == TransactionFormMode.view) {
      setState(() => mode = TransactionFormMode.edit);
    }
  }

  @override
  void dispose() {
    descriptionController
      ..removeListener(_onDescriptionChanged)
      ..dispose();
    amountController.dispose();
    super.dispose();
  }
}
