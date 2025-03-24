import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ta_client/core/widgets/custom_date_picker.dart';
import 'package:ta_client/core/widgets/dropdown_field.dart';

class FilterFormPage extends StatefulWidget {
  const FilterFormPage({super.key});

  @override
  State<FilterFormPage> createState() => _FilterFormPageState();
}

class _FilterFormPageState extends State<FilterFormPage> {
  Color submitButtonColor = const Color(0xff2A8C8B);
  final List<DropdownItem> dropdownItems = [
    DropdownItem(
      label: 'Asset',
      icon: Icons.account_balance_wallet,
      color: const Color(0xff2A8C8B),),
    DropdownItem(
      label: 'Liability',
      icon: Icons.account_balance,
      color: const Color(0xffEF233C),),
    DropdownItem(
      label: 'Pemasukan',
      icon: Icons.add_card_rounded,
      color: const Color(0xff5A4CAF),),
    DropdownItem(
      label: 'Pengeluaran',
      icon: Icons.local_activity_rounded,
      color: const Color(0xffD623AE),),
  ];

  final Map<String, List<String>> childItemsMap = {
    'Asset': ['Kas', 'Piutang', 'Bangunan', 'Tanah', 'Peralatan', 'Surat Berharga', 'Investasi Alternatif', 'Aset Pribadi'],
    'Liability': ['Hutang', 'Perjanjian Tertulis', 'Mortgage Payable'],
    'Pemasukan': ['Pendapatan Pekerjaan', 'Pendapatan Investasi', 'Pendapatan Bunga', 'Keuntungan Aset', 'Pendapatan Jasa'],
    'Pengeluaran': ['Tabungan', 'Makanan & Minuman', 'Hadiah & Donasi', 'Transportasi', 'Kesehatan & Medis', 'Perawatan & Pakaian', 'Hiburan & Rekreasi', 'Pendidikan', 'Kewajiban Finansial', 'Perumahan'],
  };

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String? selectedValue;
  List<String> filteredChildItems = [];
  String? selectedChild;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CustomDropdownField(
            label: "Tipe Akun",
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

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  'Pilih Kategori',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey, // Underline color
                      width: 1.5,
                    ),
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
                          items: (filteredChildItems.isNotEmpty
                              ? filteredChildItems
                              : childItemsMap.values.expand((e) => e).toList()
                          ).map((child) {
                            return DropdownMenuItem<String>(
                              value: child,
                              child: Text(child),
                            );
                          }).toList(),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  'Tanggal',
                  style: const TextStyle(
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
                      label: 'Tanggal',
                      isDatePicker: true,
                      onDateChanged: (date) {
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
                      onTimeChanged: (time) {
                        setState(() {
                          selectedTime = time;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, // Makes the button take up full width
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: submitButtonColor,
              ),
              onPressed: () {
              },
              child: Text(
                'Filter',
                style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.white,),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
