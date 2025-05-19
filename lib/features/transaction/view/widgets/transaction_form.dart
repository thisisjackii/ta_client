import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/core/utils/calculations.dart';
import 'package:ta_client/core/widgets/custom_date_picker.dart';
import 'package:ta_client/core/widgets/custom_text_field.dart';
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

  late String selectedAccountTypeId;
  AccountType? selectedAccountType;
  Category? selectedCategory;
  Subcategory? selectedSubcategory;

  late String transactionType;
  late String selectedValue;

  final _formKey = GlobalKey<FormState>();
  final descriptionController = TextEditingController();
  final amountController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  final maxDescriptionLength = 100;

  late TransactionFormMode mode;

  @override
  void initState() {
    super.initState();
    mode = widget.mode;
    context.read<TransactionBloc>().add(LoadAccountTypesRequested());

    if (widget.transaction != null) {
      // prefill for edit/view
      final tx = widget.transaction!;
      descriptionController.text = tx.description;
      amountController.text = formatToRupiah(tx.amount);
      selectedDate = tx.date;
      selectedTime = TimeOfDay.fromDateTime(tx.date);
      transactionType = tx.accountTypeName ?? '';
      selectedValue = tx.accountTypeName ?? '';
      // categories/subcategories will be set after load
    } else {
      selectedValue = 'Pilih Tipe Akun';
      transactionType = '';
    }
    descriptionController.addListener(_onDescriptionChanged);
  }

  void _onDescriptionChanged() {
    if (widget.onDescriptionChanged != null) {
      widget.onDescriptionChanged?.call(descriptionController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReadOnly = mode == TransactionFormMode.view;

    return BlocConsumer<TransactionBloc, TransactionState>(
      listenWhen: (prev, curr) =>
          prev.classifiedResult != curr.classifiedResult ||
          curr.errorMessage != null,
      listener: (ctx, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(
            ctx,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        } else if (state.classifiedResult?.isNotEmpty ?? false) {
          // handle auto-classification if needed
        }
      },
      buildWhen: (prev, curr) =>
          prev.accountTypes != curr.accountTypes ||
          prev.categories != curr.categories ||
          prev.subcategories != curr.subcategories,
      builder: (ctx, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                CustomTextField(
                  label: 'Deskripsi',
                  controller: descriptionController,
                  isEnabled: !isReadOnly,
                  maxLength: maxDescriptionLength,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  validator: (v) =>
                      (v?.isEmpty ?? true) ? 'Field cannot be empty' : null,
                ),
                const SizedBox(height: 16),

                // Account Type Dropdown
                const Text(
                  'Tipe Akun',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                CustomDropdownField(
                  items: [
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
                  ],
                  selectedValue: selectedValue,
                  onChanged: (item) {
                    setState(() {
                      selectedValue = item.label;
                      transactionType = item.label;
                      submitButtonColor = item.color;
                      selectedAccountType = state.accountTypes.firstWhere(
                        (t) => t.name == item.label,
                      );
                      selectedAccountTypeId = selectedAccountType!.id;
                      selectedCategory = null;
                      selectedSubcategory = null;
                    });
                    ctx.read<TransactionBloc>().add(
                      LoadCategoriesRequested(selectedAccountTypeId),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Category Dropdown
                const Text(
                  'Kategori',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                DropdownButtonFormField<Category>(
                  value: selectedCategory,
                  items: state.categories
                      .map(
                        (c) => DropdownMenuItem(value: c, child: Text(c.name)),
                      )
                      .toList(),
                  onChanged: isReadOnly
                      ? null
                      : (c) {
                          setState(() {
                            selectedCategory = c;
                            selectedSubcategory = null;
                          });
                          ctx.read<TransactionBloc>().add(
                            LoadSubcategoriesRequested(c!.id),
                          );
                        },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Subcategory Dropdown
                const Text(
                  'Subkategori',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                DropdownButtonFormField<Subcategory>(
                  value: selectedSubcategory,
                  items: state.subcategories
                      .map(
                        (s) => DropdownMenuItem(value: s, child: Text(s.name)),
                      )
                      .toList(),
                  onChanged: isReadOnly
                      ? null
                      : (s) => setState(() {
                          selectedSubcategory = s;
                        }),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Amount
                const Text(
                  'Total',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                CustomTextField(
                  label: 'Enter Total',
                  controller: amountController,
                  isEnabled: !isReadOnly,
                  keyboardType: TextInputType.number,
                  inputFormatters: [RupiahInputFormatter()],
                  validator: (v) =>
                      (v?.isEmpty ?? true) ? 'Field cannot be empty' : null,
                ),
                const SizedBox(height: 16),

                // Date & Time pickers
                const Text(
                  'Waktu',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    Expanded(
                      child: CustomDatePicker(
                        label: 'Tanggal',
                        isDatePicker: true,
                        selectedDate: selectedDate,
                        onDateChanged: isReadOnly
                            ? null
                            : (d) => setState(() => selectedDate = d),
                        validator: (v) =>
                            v?.isEmpty ?? true ? 'Required' : null,
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
                            : (t) => setState(() => selectedTime = t),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Submit/Delete button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: submitButtonColor,
                    ),
                    onPressed: isReadOnly ? widget.onDelete : _onSubmit,
                    child: Text(
                      mode == TransactionFormMode.edit
                          ? 'Confirm Edit'
                          : widget.onDelete != null
                          ? 'Delete'
                          : 'Submit',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate() ||
        selectedDate == null ||
        selectedSubcategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pastikan semua field yang wajib diisi sudah terisi dengan benar.',
          ),
        ),
      );
      return;
    }
    final rawAmount = amountController.text.replaceAll(RegExp('[^0-9]'), '');
    final parsedAmount = double.tryParse(rawAmount) ?? 0.0;

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
      accountTypeName: transactionType,
      description: descriptionController.text,
      date: combinedDate,
      categoryId: selectedCategory!.id,
      categoryName: selectedCategory!.name,
      subcategoryId: selectedSubcategory!.id,
      subcategoryName: selectedSubcategory!.name,
      amount: parsedAmount,
      isBookmarked: widget.transaction?.isBookmarked ?? false,
    );

    widget.onSubmit(tx);
    if (mode == TransactionFormMode.edit) {
      setState(() => mode = TransactionFormMode.view);
    }
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

  @override
  void dispose() {
    descriptionController.dispose();
    amountController.dispose();
    super.dispose();
  }
}
