// lib/core/widgets/category_modal_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ta_client/core/widgets/custom_text_field.dart';

class CategoryModalSheet extends StatefulWidget {
  const CategoryModalSheet({required this.onCategorySelected, super.key});
  final void Function(String, String) onCategorySelected;

  @override
  _CategoryModalSheetState createState() => _CategoryModalSheetState();
}

class _CategoryModalSheetState extends State<CategoryModalSheet> {
  String? selectedOption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 300,
      child: Row(
        children: [
          // Column 1: Main Categories
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
                _buildCategoryTile(
                  label: 'Aset',
                  backgroundColor: const Color(0xFFD4E8E8),
                  titleColor: const Color(0xFF2A8C8B),
                  iconAsset: 'assets/icons/mdi_property-tag.svg',
                ),
                const SizedBox(height: 12),
                _buildCategoryTile(
                  label: 'Hutang',
                  backgroundColor: const Color(0xFFFCD3D8),
                  titleColor: const Color(0xFFEF233C),
                  iconAsset: 'assets/icons/material-symbols_credit-card.svg',
                ),
                const SizedBox(height: 12),
                _buildCategoryTile(
                  label: 'Lainnya',
                  backgroundColor: const Color(0xFFDEDBEF),
                  titleColor: const Color(0xFF5A4CAF),
                  iconAsset: 'assets/icons/mdi_dots-horizontal.svg',
                  onTap: () {
                    _showCustomCategoryDialog(context);
                  },
                ),
              ],
            ),
          ),
          const VerticalDivider(),
          // Column 2: Sub-categories for selected main category
          if (selectedOption != null)
            Expanded(
              child: _buildSubCategories(context, selectedOption!),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile({
    required String label,
    required Color backgroundColor,
    required Color titleColor,
    required String iconAsset,
    VoidCallback? onTap,
  }) {
    return ListTile(
      dense: true,
      tileColor: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: titleColor,
        ),
      ),
      leading: SvgPicture.asset(
        iconAsset,
        width: 18,
        height: 18,
      ),
      trailing: const Icon(
        Icons.navigate_next,
        color: Colors.black,
        size: 16,
      ),
      onTap: onTap ??
          () {
            setState(() {
              selectedOption = label;
            });
          },
    );
  }

  Widget _buildSubCategories(BuildContext context, String mainCategory) {
    var subCategoryTiles = <Widget>[];
    if (mainCategory == 'Aset') {
      subCategoryTiles = [
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Tabungan Tunai',
          iconAsset: 'assets/icons/material-symbols_savings-rounded.svg',
        ),
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Uang di Dompet',
          iconAsset: 'assets/icons/material-symbols_wallet.svg',
        ),
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Investasi',
          iconAsset: 'assets/icons/material-symbols_money-bag-rounded.svg',
        ),
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Kendaraan',
          iconAsset: 'assets/icons/mdi_car-sports-utility-vehicle.svg',
        ),
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Mainan',
          iconAsset: 'assets/icons/material-symbols_smart-toy-rounded.svg',
        ),
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Lainnya',
          iconAsset: '',
          onTap: () {
            _showCustomCategoryDialog(context);
          },
        ),
      ];
    } else if (mainCategory == 'Hutang') {
      subCategoryTiles = [
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Kartu Kredit',
          iconAsset: 'assets/icons/material-symbols_credit-card-blk.svg',
        ),
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Hutang Teman',
          iconAsset: 'assets/icons/mdi_people.svg',
        ),
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Cicilan Kendaraan',
          iconAsset:
              'assets/icons/fluent_vehicle-car-profile-ltr-clock-16-filled.svg',
        ),
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Lainnya',
          iconAsset: '',
          onTap: () {
            _showCustomCategoryDialog(context);
          },
        ),
      ];
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$mainCategory Details',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          ...subCategoryTiles,
        ],
      ),
    );
  }

  Widget _buildSubCategoryTile({
    required String mainCategory,
    required String label,
    required String iconAsset,
    VoidCallback? onTap,
  }) {
    return ListTile(
      dense: true,
      tileColor: const Color(0xFFECECEC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      leading: iconAsset.isNotEmpty
          ? SvgPicture.asset(
              iconAsset,
              width: 18,
              height: 18,
            )
          : null,
      trailing: const Icon(
        Icons.navigate_next,
        color: Colors.black87,
        size: 16,
      ),
      onTap: () {
        widget.onCategorySelected(mainCategory, label);
        Navigator.pop(context);
      },
    );
  }

  void _showCustomCategoryDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Lainnya'),
          content: const SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'Nama Kategori',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(width: 35),
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
  }
}
