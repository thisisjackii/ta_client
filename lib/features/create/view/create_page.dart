// create_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_toggle_tab/flutter_toggle_tab.dart';
import 'package:ta_client/core/widgets/custom_category_picker.dart';
import 'package:ta_client/core/widgets/custom_date_picker.dart';
import 'package:ta_client/core/widgets/custom_text_field.dart';

class CreatePage extends StatefulWidget {
  const CreatePage({super.key});

  static Widget create() {
    return const CreatePage();
  }

  @override
  State<CreatePage> createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> {
  int _selectedIndex = 0;
  String _transactionType = 'Pemasukan';
  List<DataTab> get _listTextTabToggle => [
    DataTab(title: 'Pemasukan'),
    DataTab(title: 'Pengeluaran'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xffFBFDFF),
        automaticallyImplyLeading: false, // Removes default leading button
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                // Handle navigate back action
              },
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.info),
                onPressed: () {
                  // Handle settings action
                },
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_add),
                onPressed: () {
                  // Handle account action
                },
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: FlutterToggleTab(
                width: 90,
                borderRadius: 10,
                height: 28,
                selectedIndex: _selectedIndex,
                selectedBackgroundColors: _selectedIndex == 0
                    ? [Colors.blue, Colors.blueAccent]
                    : [Colors.red, Colors.redAccent],
                selectedTextStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,),
                unSelectedTextStyle: const TextStyle(
                    color: Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,),
                dataTabs: _listTextTabToggle,
                selectedLabelIndex: (index) {
                  setState(() {
                    _selectedIndex = index;
                    _transactionType =
                    index == 0 ? 'Pemasukan' : 'Pengeluaran';
                  });
                },
                isScroll: false,
              ),
            ),

            const CustomTextField(
              label: 'Deskripsi',
              suffixType: SuffixType.camera,
            ),
            const SizedBox(height: 4),
            const Row(children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 12,
                    fontVariations: [
                      FontVariation('wght', 600),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 35),
              // Add spacing between the text and the text field
              Expanded(
                child: CustomTextField(
                  label: 'Ketikan Total',
                ),
              ),
            ],),
            const SizedBox(height: 4),
            const Row(children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Kategori',
                  style: TextStyle(
                    fontSize: 12,
                    fontVariations: [
                      FontVariation('wght', 600),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 16),
              // Add spacing between the text and the text field
              Expanded(
                child: CustomCategoryPicker(),
              ),
            ],),
            const SizedBox(height: 4),
            const Row(children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tanggal',
                  style: TextStyle(
                    fontSize: 12,
                    fontVariations: [
                      FontVariation('wght', 600),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 18),
              // Add spacing between the text and the text field
              Expanded(
                child: CustomDatePicker(
                  label: 'Tanggal',
                  isDatePicker: true,
                ),
              ),
              Expanded(
                child: CustomDatePicker(
                  label: 'Waktu',
                  isDatePicker: false,
                ),
              ),
            ],),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              style: ButtonStyle(
                shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                    ),
                ),
                backgroundColor: WidgetStateProperty.all<Color>(
                  _selectedIndex == 0 ? Colors.blueAccent : Colors.redAccent,
                ),
                foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
              ),
              child: const Text(
                'Simpan',
                style: TextStyle(
                  fontVariations: [
                    FontVariation('wght', 700),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
