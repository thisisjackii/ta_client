// lib/features/filter/view/widgets/filter_form_page.dart
import 'package:flutter/material.dart';
import 'package:ta_client/core/widgets/custom_date_picker.dart';
import 'package:ta_client/core/widgets/dropdown_field.dart';

class FilterFormPage extends StatefulWidget {
  const FilterFormPage({super.key, this.initialCriteria, this.initialMonth});

  final Map<String, dynamic>? initialCriteria;
  final DateTime? initialMonth;

  @override
  State<FilterFormPage> createState() => _FilterFormPageState();
}

class _FilterFormPageState extends State<FilterFormPage> with RouteAware {
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

  final Map<String, List<String>> childItemsMap = {
    'Aset': [
      'Kas',
      'Piutang',
      'Bangunan',
      'Tanah',
      'Peralatan',
      'Surat Berharga',
      'Investasi Alternatif',
      'Aset Pribadi',
    ],
    'Liabilitas': ['Hutang', 'Perjanjian Tertulis', 'Mortgage Payable'],
    'Pemasukan': [
      'Pendapatan Pekerjaan',
      'Pendapatan Investasi',
      'Pendapatan Bunga',
      'Keuntungan Aset',
      'Pendapatan Jasa',
    ],
    'Pengeluaran': [
      'Tabungan',
      'Makanan & Minuman',
      'Hadiah & Donasi',
      'Transportasi',
      'Kesehatan & Medis',
      'Perawatan & Pakaian',
      'Hiburan & Rekreasi',
      'Pendidikan',
      'Kewajiban Finansial',
      'Perumahan',
    ],
  };

  // Use two date pickers for a date range.
  late bool bookmarkedOnly;
  String? selectedValue;
  String? selectedChild;
  DateTime? startDate;
  DateTime? endDate;
  DateTime monthLimitStart = DateTime.now();
  DateTime monthLimitEnd = DateTime.now();
  List<String> filteredChildItems = [];

  @override
  void initState() {
    super.initState();

    // 1) Load last‐used criteria, or defaults
    final crit = widget.initialCriteria ?? {};
    bookmarkedOnly = crit['bookmarked'] as bool? ?? false;
    selectedValue = crit['parent'] as String?;
    selectedChild = crit['child'] as String?;
    startDate = crit['startDate'] as DateTime?;
    endDate = crit['endDate'] as DateTime?;

    // 2) Compute month bounds
    final m = widget.initialMonth ?? DateTime.now();
    monthLimitStart = DateTime(m.year, m.month);
    monthLimitEnd = DateTime(m.year, m.month + 1, 0); // last day of month
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Parent category dropdown.
          CustomDropdownField(
            label: 'Tipe Akun',
            items: dropdownItems,
            selectedValue: selectedValue,
            onChanged: (item) {
              setState(() {
                selectedValue = item.label;
                submitButtonColor = item.color;
                filteredChildItems = childItemsMap[selectedValue!] ?? [];
                selectedChild = null;
              });
            },
          ),
          const SizedBox(height: 24),
          // Child category dropdown.
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  'Pilih Kategori',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.zero,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey, width: 1.5),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          hint: const Text('-- Pilih Kategori --'),
                          value: selectedChild,
                          isExpanded: true,
                          items:
                              (filteredChildItems.isNotEmpty
                                      ? filteredChildItems
                                      : childItemsMap.values
                                            .expand((e) => e)
                                            .toList())
                                  .map((child) {
                                    return DropdownMenuItem<String>(
                                      value: child,
                                      child: Text(child),
                                    );
                                  })
                                  .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedChild = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                      firstDate: monthLimitStart,
                      lastDate: monthLimitEnd,
                      onDateChanged: (date) => setState(() => startDate = date),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomDatePicker(
                      label: 'End Date',
                      isDatePicker: true,
                      initialDate: endDate ?? monthLimitEnd,
                      firstDate: monthLimitStart,
                      lastDate: monthLimitEnd,
                      onDateChanged: (date) => setState(() => endDate = date),
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
          // Submit button returns the filter criteria.
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: submitButtonColor,
              ),
              onPressed: () {
                final filters = {
                  'parent': selectedValue,
                  'child': selectedChild,
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
  }
}
