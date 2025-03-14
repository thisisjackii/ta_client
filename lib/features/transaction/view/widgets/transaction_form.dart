// lib/features/transaction/view/widgets/transaction_form.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ta_client/core/widgets/custom_category_picker.dart';
import 'package:ta_client/core/widgets/custom_date_picker.dart';
import 'package:ta_client/core/widgets/custom_text_field.dart';
import 'package:ta_client/features/transaction/models/transaction.dart';
import 'package:ta_client/features/transaction/view/widgets/transaction_form_mode.dart';
import 'package:ta_client/features/transaction/view/widgets/transaction_type_toggle.dart';

class TransactionForm extends StatefulWidget {
  const TransactionForm({
    required this.onSubmit,
    super.key,
    this.mode = TransactionFormMode.create,
    this.transaction,
    this.onDelete,
  });

  final TransactionFormMode mode;
  final Transaction? transaction;
  final void Function(Transaction transaction) onSubmit;
  final VoidCallback? onDelete;

  @override
  _TransactionFormState createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  late TransactionFormMode mode;
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  String transactionType = 'Pemasukan';
  String category = '';
  String subcategory = '';
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  @override
  void initState() {
    super.initState();
    mode = widget.mode;
    if (widget.transaction != null) {
      transactionType = widget.transaction!.type;
      descriptionController.text = widget.transaction!.description;
      amountController.text = widget.transaction!.amount.toString();
      category = widget.transaction!.category;
      subcategory = widget.transaction!.subcategory;
      selectedDate = widget.transaction!.date;
      selectedTime = TimeOfDay.fromDateTime(widget.transaction!.date);
    }
  }

  @override
  void dispose() {
    descriptionController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final isReadOnly = mode == TransactionFormMode.view;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Transaction type toggle
          Center(
            child: TransactionTypeToggle(
              selectedIndex: transactionType == 'Pemasukan' ? 0 : 1,
              onToggle: isReadOnly
                  ? (_) {}
                  : (index) {
                      setState(() {
                        transactionType =
                            index == 0 ? 'Pemasukan' : 'Pengeluaran';
                      });
                    },
            ),
          ),
          const SizedBox(height: 4),
          CustomTextField(
            label: 'Deskripsi',
            controller: descriptionController,
            readOnly: isReadOnly,
            onTap: isReadOnly ? _switchToEdit : null,
            suffixType: SuffixType.camera,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Amount',
                  style: TextStyle(
                    fontSize: 12,
                    fontVariations: [FontVariation('wght', 600)],
                  ),
                ),
              ),
              const SizedBox(width: 35),
              Expanded(
                child: CustomTextField(
                  label: 'Enter Amount',
                  controller: amountController,
                  readOnly: isReadOnly,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onTap: isReadOnly ? _switchToEdit : null,
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
              const SizedBox(width: 16),
              Expanded(
                child: CustomCategoryPicker(
                  selectedCategory: category,
                  selectedSubCategory: subcategory,
                  onCategorySelected: isReadOnly
                      ? (cat, subCat) {}
                      : (cat, subCat) {
                          setState(() {
                            category = cat;
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
              const SizedBox(width: 18),
              Expanded(
                child: CustomDatePicker(
                  label: 'Tanggal',
                  isDatePicker: true,
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
            // In view mode, no submit button – tapping a field switches to edit.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Optionally add a Delete button.
                ElevatedButton(
                  onPressed: widget.onDelete,
                  child: const Text('Delete'),
                ),
              ],
            )
          else
            ElevatedButton(
              onPressed: () {
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
                final transaction = Transaction(
                  id: widget.transaction?.id ?? '',
                  type: transactionType,
                  description: descriptionController.text,
                  date: combinedDate,
                  category: category,
                  subcategory: subcategory,
                  amount: double.tryParse(amountController.text) ?? 0.0,
                );
                widget.onSubmit(transaction);
                if (mode == TransactionFormMode.edit) {
                  setState(() {
                    mode = TransactionFormMode.view;
                  });
                }
              },
              child: Text(
                mode == TransactionFormMode.edit ? 'Confirm Edit' : 'Submit',
              ),
            ),
        ],
      ),
    );
  }
}
