// lib/core/widgets/custom_category_picker.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ta_client/core/widgets/custom_text_field.dart';

class CustomCategoryPicker extends StatefulWidget {
  const CustomCategoryPicker({super.key});

  @override
  State<CustomCategoryPicker> createState() => _CustomCategoryPickerState();
}

class _CustomCategoryPickerState extends State<CustomCategoryPicker> {
  final TextEditingController _controller = TextEditingController();
  String? selectedOption; // To track which option in Column 1 is selected

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  height: 300,
                  child: Row(
                    children: [
                      // Column 1
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Kategori',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ListTile(
                              dense: true,
                              tileColor: const Color(0xFFD4E8E8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              title: const Text(
                                'Aset',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2A8C8B),
                                ),
                              ),
                              leading: SvgPicture.asset(
                                'assets/icons/mdi_property-tag.svg',
                                width: 18,
                                height: 18,
                              ),
                              trailing: const Icon(
                                Icons.navigate_next,
                                color: Color(0xFF2A8C8B),
                                size: 16,
                              ),
                              onTap: () {
                                // Update selectedOption in the modal state
                                setModalState(() {
                                  selectedOption = 'Aset';
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            ListTile(
                              dense: true,
                              tileColor: const Color(0xFFFCD3D8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              title: const Text(
                                'Hutang',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFEF233C),
                                ),
                              ),
                              leading: SvgPicture.asset(
                                'assets/icons/material-symbols_credit-card.svg',
                                width: 18,
                                height: 18,
                              ),
                              trailing: const Icon(
                                Icons.navigate_next,
                                color: Color(0xFFEF233C),
                                size: 16,
                              ),
                              onTap: () {
                                // Update selectedOption in the modal state
                                setModalState(() {
                                  selectedOption = 'Hutang';
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            ListTile(
                              dense: true,
                              tileColor: const Color(0xFFDEDBEF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              title: const Text(
                                'Lainnya',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF5A4CAF),
                                ),
                              ),
                              leading: SvgPicture.asset(
                                'assets/icons/mdi_dots-horizontal.svg',
                                width: 18,
                                height: 18,
                              ),
                              trailing: const Icon(
                                Icons.navigate_next,
                                color: Color(0xFF5A4CAF),
                                size: 16,
                              ),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('Lainnya'),
                                      content: const Expanded(
                                        child: SingleChildScrollView(
                                          child: Column(
                                            children: [
                                              Row(
                                                children: [
                                                  Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Text(
                                                      'Nama Kategori',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontVariations: [
                                                          FontVariation(
                                                              'wght', 600,),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: 35),
                                                  // Add spacing between the text and the text field
                                                  Expanded(
                                                    child: CustomTextField(
                                                      label: 'Nama Kategori',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Close'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const VerticalDivider(), // Divider between columns
                      // Column 2 (conditionally displayed)
                      if (selectedOption != null)
                        Expanded(
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$selectedOption Details',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (selectedOption == 'Aset') ...[
                                    ListTile(
                                      dense: true,
                                      tileColor: const Color(0xFFECECEC),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      title: const Text(
                                        'Tabungan Tunai',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      leading: SvgPicture.asset(
                                        'assets/icons/material-symbols_savings-rounded.svg',
                                        width: 18,
                                        height: 18,
                                      ),
                                      trailing: const Icon(
                                        Icons.navigate_next,
                                        color: Colors.black87,
                                        size: 16,
                                      ),
                                      onTap: () {
                                        setState(() {
                                          _controller.text = 'Option 1-A';
                                        });
                                        Navigator.pop(context);
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    ListTile(
                                      dense: true,
                                      tileColor: const Color(0xFFECECEC),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      title: const Text(
                                        'Uang di Dompet',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      leading: SvgPicture.asset(
                                        'assets/icons/material-symbols_wallet.svg',
                                        width: 18,
                                        height: 18,
                                      ),
                                      trailing: const Icon(
                                        Icons.navigate_next,
                                        color: Colors.black87,
                                        size: 16,
                                      ),
                                      onTap: () {
                                        setState(() {
                                          _controller.text = 'Option 1-A';
                                        });
                                        Navigator.pop(context);
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    ListTile(
                                      dense: true,
                                      tileColor: const Color(0xFFECECEC),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      title: const Text(
                                        'Investasi',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      leading: SvgPicture.asset(
                                        'assets/icons/material-symbols_money-bag-rounded.svg',
                                        width: 18,
                                        height: 18,
                                      ),
                                      trailing: const Icon(
                                        Icons.navigate_next,
                                        color: Colors.black87,
                                        size: 16,
                                      ),
                                      onTap: () {
                                        setState(() {
                                          _controller.text = 'Option 1-A';
                                        });
                                        Navigator.pop(context);
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    ListTile(
                                      dense: true,
                                      tileColor: const Color(0xFFECECEC),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      title: const Text(
                                        'Kendaraan',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      leading: SvgPicture.asset(
                                        'assets/icons/mdi_car-sports-utility-vehicle.svg',
                                        width: 18,
                                        height: 18,
                                      ),
                                      trailing: const Icon(
                                        Icons.navigate_next,
                                        color: Colors.black87,
                                        size: 16,
                                      ),
                                      onTap: () {
                                        setState(() {
                                          _controller.text = 'Option 1-A';
                                        });
                                        Navigator.pop(context);
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    ListTile(
                                      dense: true,
                                      tileColor: const Color(0xFFECECEC),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      title: const Text(
                                        'Mainan',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      leading: SvgPicture.asset(
                                        'assets/icons/material-symbols_smart-toy-rounded.svg',
                                        width: 18,
                                        height: 18,
                                      ),
                                      trailing: const Icon(
                                        Icons.navigate_next,
                                        color: Colors.black87,
                                        size: 16,
                                      ),
                                      onTap: () {
                                        setState(() {
                                          _controller.text = 'Option 1-A';
                                        });
                                        Navigator.pop(context);
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    ListTile(
                                      dense: true,
                                      tileColor: const Color(0xFFECECEC),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      title: const Text(
                                        'Lainnya',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      trailing: const Icon(
                                        Icons.navigate_next,
                                        color: Colors.black87,
                                        size: 16,
                                      ),
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: const Text('Lainnya'),
                                              content: const Expanded(
                                                child: SingleChildScrollView(
                                                  child: Column(
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Align(
                                                            alignment: Alignment
                                                                .centerLeft,
                                                            child: Text(
                                                              'Nama Kategori',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                fontVariations: [
                                                                  FontVariation(
                                                                      'wght',
                                                                      600,),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(width: 35),
                                                          // Add spacing between the text and the text field
                                                          Expanded(
                                                            child:
                                                                CustomTextField(
                                                              label:
                                                                  'Nama Kategori',
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text('Close'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ] else if (selectedOption == 'Hutang') ...[
                                    ListTile(
                                      dense: true,
                                      tileColor: const Color(0xFFECECEC),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      title: const Text(
                                        'Kartu Kredit',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      leading: SvgPicture.asset(
                                        'assets/icons/material-symbols_credit-card-blk.svg',
                                        width: 18,
                                        height: 18,
                                      ),
                                      trailing: const Icon(
                                        Icons.navigate_next,
                                        color: Colors.black87,
                                        size: 16,
                                      ),
                                      onTap: () {
                                        setState(() {
                                          _controller.text = 'Option 1-A';
                                        });
                                        Navigator.pop(context);
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    ListTile(
                                      dense: true,
                                      tileColor: const Color(0xFFECECEC),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      title: const Text(
                                        'Hutang Teman',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      leading: SvgPicture.asset(
                                        'assets/icons/mdi_people.svg',
                                        width: 18,
                                        height: 18,
                                      ),
                                      trailing: const Icon(
                                        Icons.navigate_next,
                                        color: Colors.black87,
                                        size: 16,
                                      ),
                                      onTap: () {
                                        setState(() {
                                          _controller.text = 'Option 1-A';
                                        });
                                        Navigator.pop(context);
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    ListTile(
                                      dense: true,
                                      tileColor: const Color(0xFFECECEC),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      title: const Text(
                                        'Cicilan Kendaraan',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      leading: SvgPicture.asset(
                                        'assets/icons/fluent_vehicle-car-profile-ltr-clock-16-filled.svg',
                                        width: 18,
                                        height: 18,
                                      ),
                                      trailing: const Icon(
                                        Icons.navigate_next,
                                        color: Colors.black87,
                                        size: 16,
                                      ),
                                      onTap: () {
                                        setState(() {
                                          _controller.text = 'Option 1-A';
                                        });
                                        Navigator.pop(context);
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    ListTile(
                                      dense: true,
                                      tileColor: const Color(0xFFECECEC),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      title: const Text(
                                        'Lainnya',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      trailing: const Icon(
                                        Icons.navigate_next,
                                        color: Colors.black87,
                                        size: 16,
                                      ),
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: const Text('Lainnya'),
                                              content: const Expanded(
                                                child: SingleChildScrollView(
                                                  child: Column(
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Align(
                                                            alignment: Alignment
                                                                .centerLeft,
                                                            child: Text(
                                                              'Nama Kategori',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                fontVariations: [
                                                                  FontVariation(
                                                                      'wght',
                                                                      600,),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(width: 35),
                                                          // Add spacing between the text and the text field
                                                          Expanded(
                                                            child:
                                                                CustomTextField(
                                                              label:
                                                                  'Nama Kategori',
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text('Close'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
      child: AbsorbPointer(
        child: CustomTextField(
          label: 'Pilih Kategori',
          onChanged: (value) {}, // Prevent direct input
          keyboardType: TextInputType.none,
        ),
      ),
    );
  }
}
