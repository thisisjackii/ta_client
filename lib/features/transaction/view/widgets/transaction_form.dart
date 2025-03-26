// lib/features/transaction/view/widgets/transaction_form.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:ta_client/core/constants/category_mapping.dart'; // New mapping file
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

class _TransactionFormState extends State<TransactionForm> {
  Color submitButtonColor = const Color(0xff2A8C8B);
  final List<DropdownItem> dropdownItems = [
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
  String transactionType = '';
  String? selectedValue;
  final _formKey = GlobalKey<FormState>();
  late TransactionFormMode mode;
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  // Parent category field
  String rawPredictedCategory = '';
  // Subcategory field
  String subcategory = '';
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  final int maxDescriptionLength = 100;

  final NumberFormat _rupiahFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp. ',
    decimalDigits: 0,
  );

  // This getter builds the display label based on the parent and subcategory.
  String get displayCategory {
    if (rawPredictedCategory.isNotEmpty) {
      if (subcategory.isNotEmpty) {
        return '$rawPredictedCategory / $subcategory';
      }
      return rawPredictedCategory;
    }
    return 'Pilih Kategori';
  }

  @override
  void initState() {
    super.initState();
    mode = widget.mode;
    if (widget.transaction != null) {
      transactionType = widget.transaction!.type;
      selectedValue = widget.transaction!.type;
      descriptionController.text = widget.transaction!.description;
      amountController.text =
          _rupiahFormatter.format(widget.transaction!.amount.toInt());
      rawPredictedCategory = widget.transaction!.category;
      subcategory = widget.transaction!.subcategory;
      selectedDate = widget.transaction!.date;
      selectedTime = TimeOfDay.fromDateTime(widget.transaction!.date);
    } else {
      transactionType = dropdownItems.first.label;
      selectedValue = dropdownItems.first.label;
    }
    descriptionController.addListener(_onDescriptionChanged);
  }

  void _onDescriptionChanged() {
    final text = descriptionController.text;
    if (text.trim().isNotEmpty && widget.onDescriptionChanged != null) {
      widget.onDescriptionChanged!(text);
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

  // Switch to edit mode when a read-only field is tapped.
  void _switchToEdit() {
    if (mode == TransactionFormMode.view) {
      setState(() {
        mode = TransactionFormMode.edit;
      });
    }
  }

  /// Helper function: Given a subcategory string, return its parent category
  /// by scanning through the categoryMapping.
  String findParentCategory(String sub) {
    final normalizedSub = sub.trim().toLowerCase();
    for (final entry in categoryMapping.entries) {
      for (final cat in entry.value) {
        if (cat.trim().toLowerCase() == normalizedSub) {
          return entry.key;
        }
      }
    }
    debugPrint('No parent found for subcategory: "$sub"');
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final isReadOnly = mode == TransactionFormMode.view;
    return BlocListener<TransactionBloc, TransactionState>(
        listener: (context, state) {
          if (state.classifiedCategory != null &&
              state.classifiedCategory!.isNotEmpty) {
            final predictedSub = state.classifiedCategory!;
            debugPrint('Raw classification result: "$predictedSub"');
            final predictedParent = findParentCategory(predictedSub);
            debugPrint('Found parent category: "$predictedParent" for "$predictedSub"');
            setState(() {
              rawPredictedCategory = predictedParent;
              subcategory = '$predictedSub ✨';
            });
          }
        },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomDropdownField(
                items: dropdownItems,
                selectedValue: transactionType,
                onChanged: (item) {
                  setState(() {
                    selectedValue = item.label;
                    transactionType = item.label;
                    submitButtonColor = item.color;
                  });
                },
              ),
              const SizedBox(height: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(
                    label: 'Deskripsi',
                    controller: descriptionController,
                    readOnly: isReadOnly,
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
                  const SizedBox(height: 4),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 12,
                        fontVariations: [FontVariation('wght', 600)],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: CustomTextField(
                      label: 'Enter Total',
                      controller: amountController,
                      readOnly: isReadOnly,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        RupiahInputFormatter(),
                      ],
                      onTap: isReadOnly ? _switchToEdit : null,
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
              const SizedBox(height: 4),
              Row(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Kategori',
                      style: TextStyle(
                        fontSize: 12,
                        fontVariations: [FontVariation('wght', 600)],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: CustomCategoryPicker(
                      selectedCategory: rawPredictedCategory,
                      selectedSubCategory: subcategory,
                      onCategorySelected: isReadOnly
                          ? (cat, subCat) {}
                          : (cat, subCat) {
                        // When manually selected, update without appending sparkle.
                        setState(() {
                          rawPredictedCategory = cat;
                          subcategory = subCat;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Tanggal',
                      style: TextStyle(
                        fontSize: 12,
                        fontVariations: [FontVariation('wght', 600)],
                      ),
                    ),
                  ),
                  const SizedBox(width: 22),
                  Expanded(
                    child: CustomDatePicker(
                      label: 'Tanggal',
                      isDatePicker: true,
                      initialDate: selectedDate,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Field cannot be empty';
                        }
                        return null;
                      },
                      onDateChanged: isReadOnly
                          ? null
                          : (date) {
                        setState(() {
                          selectedDate = date;
                        });
                      },
                    ),
                  ),
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
              if (isReadOnly)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: widget.onDelete,
                      child: const Text('Delete'),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: submitButtonColor,
                    ),
                    onPressed: () {
                      if (!_formKey.currentState!.validate()) {
                        return;
                      }

                      if (selectedDate == null) return;

                      DateTime combinedDate;
                      if (selectedTime != null) {
                        combinedDate = DateTime(
                          selectedDate!.year,
                          selectedDate!.month,
                          selectedDate!.day,
                          selectedTime!.hour,
                          selectedTime!.minute,
                        );
                      } else {
                        combinedDate = selectedDate!;
                      }

                      final rawAmount = amountController.text
                          .replaceAll(RegExp('[^0-9]'), '');
                      final parsedAmount =
                          double.tryParse(rawAmount) ?? 0.0;

                      // Remove sparkle before sending the transaction.
                      final cleanSubcategory =
                      subcategory.replaceAll(' ✨', '');

                      final transaction = Transaction(
                        id: widget.transaction?.id ?? '',
                        type: transactionType,
                        description: descriptionController.text,
                        date: combinedDate,
                        category: rawPredictedCategory,
                        subcategory: cleanSubcategory,
                        amount: parsedAmount,
                      );

                      widget.onSubmit(transaction);

                      if (mode == TransactionFormMode.edit) {
                        setState(() {
                          mode = TransactionFormMode.view;
                        });
                      }
                    },
                    child: Text(
                      mode == TransactionFormMode.edit
                          ? 'Confirm Edit'
                          : 'Submit',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
