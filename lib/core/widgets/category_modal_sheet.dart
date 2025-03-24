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
            child: SingleChildScrollView(
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
                    label: 'Kas',
                    backgroundColor: const Color(0xFFD4E8E8),
                    titleColor: const Color(0xFF2A8C8B),
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryTile(
                    label: 'Piutang',
                    backgroundColor: const Color(0xFFD4E8E8),
                    titleColor: const Color(0xFF2A8C8B),
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryTile(
                    label: 'Bangunan',
                    backgroundColor: const Color(0xFFD4E8E8),
                    titleColor: const Color(0xFF2A8C8B),
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryTile(
                    label: 'Tanah',
                    backgroundColor: const Color(0xFFD4E8E8),
                    titleColor: const Color(0xFF2A8C8B),
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryTile(
                    label: 'Peralatan',
                    backgroundColor: const Color(0xFFD4E8E8),
                    titleColor: const Color(0xFF2A8C8B),
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryTile(
                    label: 'Surat Berharga',
                    backgroundColor: const Color(0xFFD4E8E8),
                    titleColor: const Color(0xFF2A8C8B),
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryTile(
                    label: 'Investasi Alternatif',
                    backgroundColor: const Color(0xFFD4E8E8),
                    titleColor: const Color(0xFF2A8C8B),
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryTile(
                    label: 'Aset Pribadi',
                    backgroundColor: const Color(0xFFD4E8E8),
                    titleColor: const Color(0xFF2A8C8B),
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryTile(
                    label: 'Hutang',
                    backgroundColor: const Color(0xFFFCD3D8),
                    titleColor: const Color(0xFFEF233C),
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryTile(
                    label: 'Perjanjian Tertulis',
                    backgroundColor: const Color(0xFFFCD3D8),
                    titleColor: const Color(0xFFEF233C),
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryTile(
                    label: 'Mortgage Payable',
                    backgroundColor: const Color(0xFFFCD3D8),
                    titleColor: const Color(0xFFEF233C),
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryTile(
                    label: 'Pendapatan Pekerjaan',
                    backgroundColor: const Color(0xFFDEDBEF),
                    titleColor: const Color(0xFF5A4CAF),
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryTile(
                    label: 'Pendapatan Investasi',
                    backgroundColor: const Color(0xFFDEDBEF),
                    titleColor: const Color(0xFF5A4CAF),
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryTile(
                    label: 'Pendapatan Bunga',
                    backgroundColor: const Color(0xFFDEDBEF),
                    titleColor: const Color(0xFF5A4CAF),
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryTile(
                    label: 'Keuntungan Aset',
                    backgroundColor: const Color(0xFFDEDBEF),
                    titleColor: const Color(0xFF5A4CAF),
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryTile(
                    label: 'Pendapatan Jasa',
                    backgroundColor: const Color(0xFFDEDBEF),
                    titleColor: const Color(0xFF5A4CAF),
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryTile(
                    label: 'Tabungan',
                    backgroundColor: const Color(0xFFF7D3EF),
                    titleColor: const Color(0xFFD623AE),
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryTile(
                    label: 'Makanan & Minuman',
                    backgroundColor: const Color(0xFFF7D3EF),
                    titleColor: const Color(0xFFD623AE),
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryTile(
                    label: 'Hadiah & Donasi',
                    backgroundColor: const Color(0xFFF7D3EF),
                    titleColor: const Color(0xFFD623AE),
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryTile(
                    label: 'Transportasi',
                    backgroundColor: const Color(0xFFF7D3EF),
                    titleColor: const Color(0xFFD623AE),
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryTile(
                    label: 'Kesehatan & Medis',
                    backgroundColor: const Color(0xFFF7D3EF),
                    titleColor: const Color(0xFFD623AE),
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryTile(
                    label: 'Perawatan & Pakaian',
                    backgroundColor: const Color(0xFFF7D3EF),
                    titleColor: const Color(0xFFD623AE),
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryTile(
                    label: 'Hiburan & Rekreasi',
                    backgroundColor: const Color(0xFFF7D3EF),
                    titleColor: const Color(0xFFD623AE),
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryTile(
                    label: 'Pendidikan',
                    backgroundColor: const Color(0xFFF7D3EF),
                    titleColor: const Color(0xFFD623AE),
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryTile(
                    label: 'Kewajiban Finansial',
                    backgroundColor: const Color(0xFFF7D3EF),
                    titleColor: const Color(0xFFD623AE),
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryTile(
                    label: 'Perumahan',
                    backgroundColor: const Color(0xFFF7D3EF),
                    titleColor: const Color(0xFFD623AE),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
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
    IconData? icon,
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
      leading: icon != null
          ? Icon(
        icon,
        color: Colors.black, // Default color if not provided
        size: 18,
      )
          : null, // No icon if null
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
    if (mainCategory == 'Kas') {
      subCategoryTiles = [
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Uang Tunai',
          icon: Icons.money_rounded,
        ),
        const SizedBox(height: 12),
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Rekening Bank',
          icon: Icons.account_balance_rounded,
        ),
        const SizedBox(height: 12),
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'E-Wallet',
          icon: Icons.wallet,
        ),
      ];
    } else if (mainCategory == 'Piutang') {
      subCategoryTiles = [
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Piutang',
          icon: Icons.balance,
        ),
      ];
    } else if (mainCategory == 'Bangunan') {
      subCategoryTiles = [
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Rumah',
          icon: Icons.house_rounded,
        ),
        const SizedBox(height: 12),
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Apartemen',
          icon: Icons.apartment_rounded,
        ),
        const SizedBox(height: 12),
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Ruko',
          icon: Icons.warehouse_rounded,
        ),
        const SizedBox(height: 12),
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Kios',
          icon: Icons.storefront_rounded,
        ),
      ];
    } else if (mainCategory == 'Tanah') {
      subCategoryTiles = [
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Properti Sewa',
          icon: Icons.vpn_key,
        ),
      ];
    } else if (mainCategory == 'Peralatan') {
      subCategoryTiles = [
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Kendaraan',
          icon: Icons.directions_car,
        ),
        const SizedBox(height: 12),
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Elektronik',
          icon: Icons.electric_bolt_rounded,
        ),
        const SizedBox(height: 12),
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Furnitur',
          icon: Icons.table_bar_rounded,
        ),
      ];
    } else if (mainCategory == 'Surat Berharga') {
      subCategoryTiles = [
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Saham',
          icon: Icons.data_thresholding,
        ),
        const SizedBox(height: 12),
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Obligasi',
          icon: Icons.account_balance_outlined,
        ),
        const SizedBox(height: 12),
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Reksadana',
          icon: Icons.attach_money,
        ),
      ];
    } else if (mainCategory == 'Investasi Alternatif') {
      subCategoryTiles = [
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Kripto',
          icon: Icons.currency_bitcoin,
        ),
      ];
    } else if (mainCategory == 'Aset Pribadi') {
      subCategoryTiles = [
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Koleksi',
          icon: Icons.shopping_bag_rounded,
        ),
        const SizedBox(height: 12),
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Perhiasan',
          icon: Icons.diamond,
        ),
      ];
    } else if (mainCategory == 'Hutang') {
      subCategoryTiles = [
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Saldo Kartu Kredit',
          icon: Icons.credit_card_outlined,
        ),
        const SizedBox(height: 12),
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Tagihan',
          icon: Icons.sticky_note_2,
        ),
        const SizedBox(height: 12),
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Cicilan',
          icon: Icons.timelapse_outlined,
        ),
        const SizedBox(height: 12),
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Pajak',
          icon: Icons.note_sharp,
        ),
      ];
    } else if (mainCategory == 'Perjanjian Tertulis') {
      subCategoryTiles = [
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Pinjaman',
          icon: Icons.key_rounded,
        ),
      ];
    } else if (mainCategory == 'Mortgage Payable') {
      subCategoryTiles = [
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Pinjaman Properti',
          icon: Icons.vpn_key_outlined,
        ),
      ];
    } else if (mainCategory == 'Pendapatan Pekerjaan') {
      subCategoryTiles = [
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Gaji',
          icon: Icons.money_rounded,
        ),
        const SizedBox(height: 12),
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Upah',
          icon: Icons.attach_money,
        ),
        const SizedBox(height: 12),
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'bonus',
          icon: Icons.add_box,
        ),
        const SizedBox(height: 12),
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'comission',
          icon: Icons.handshake_rounded,
        ),
      ];
    } else if (mainCategory == 'Pendapatan Investasi') {
      subCategoryTiles = [
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Dividen',
          icon: Icons.add_card_outlined,
        ),
      ];
    } else if (mainCategory == 'Pendapatan Bunga') {
      subCategoryTiles = [
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Dividen',
          icon: Icons.add_card_outlined,
        ),
      ];
    } else if (mainCategory == 'Keuntungan Aset') {
      subCategoryTiles = [
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Untung Modal',
          icon: Icons.monetization_on_outlined,
        ),
      ];
    } else if (mainCategory == 'Pendapatan Jasa') {
      subCategoryTiles = [
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Freelance',
          icon: Icons.monitor,
        ),
      ];
    } else if (mainCategory == 'Tabungan') {
      subCategoryTiles = [
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Tabungan',
          icon: Icons.attach_money,
        ),
      ];
    } else if (mainCategory == 'Makanan & Minuman') {
      subCategoryTiles = [
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Makanan',
          icon: Icons.food_bank,
        ),
        const SizedBox(height: 12),
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Minuman',
          icon: Icons.emoji_food_beverage,
        ),
      ];
    } else if (mainCategory == 'Hadiah & Donasi') {
      subCategoryTiles = [
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Hadiah',
          icon: Icons.card_giftcard_rounded,
        ),
        const SizedBox(height: 12),
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Donasi',
          icon: Icons.shopping_bag,
        ),
      ];
    } else if (mainCategory == 'Transportasi') {
      subCategoryTiles = [
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Kendaraan Pribadi',
          icon: Icons.directions_car,
        ),
        const SizedBox(height: 12),
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Transportasi Umum',
          icon: Icons.train_rounded,
        ),
        const SizedBox(height: 12),
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Bahan bakar',
          icon: Icons.local_gas_station_rounded,
        ),
      ];
    } else if (mainCategory == 'Kesehatan & Medis') {
      subCategoryTiles = [
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Kesehatan',
          icon: Icons.health_and_safety,
        ),
        const SizedBox(height: 12),
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Medis',
          icon: Icons.medical_information,
        ),
      ];
    } else if (mainCategory == 'Perawatan & Pakaian') {
      subCategoryTiles = [
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Perawatan Pribadi',
          icon: Icons.child_care_rounded,
        ),
        const SizedBox(height: 12),
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Pakaian',
          icon: Icons.person,
        ),
      ];
    } else if (mainCategory == 'Hiburan & Rekreasi') {
      subCategoryTiles = [
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Hiburan',
          icon: Icons.videogame_asset,
        ),
        const SizedBox(height: 12),
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Rekreasi',
          icon: Icons.sports_basketball_rounded,
        ),
      ];
    } else if (mainCategory == 'Pendidikan') {
      subCategoryTiles = [
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Pendidikan',
          icon: Icons.menu_book_rounded,
        ),
        const SizedBox(height: 12),
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Pembelajaran',
          icon: Icons.school,
        ),
      ];
    } else if (mainCategory == 'Kewajiban Finansial') {
      subCategoryTiles = [
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Bayar pinjaman',
          icon: Icons.attach_money_rounded,
        ),
        const SizedBox(height: 12),
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Bayar pajak',
          icon: Icons.monetization_on_rounded,
        ),
        const SizedBox(height: 12),
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Bayar asuransi',
          icon: Icons.shield,
        ),
      ];
    } else if (mainCategory == 'Perumahan') {
      subCategoryTiles = [
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Perumahan',
          icon: Icons.house_siding_rounded,
        ),
        const SizedBox(height: 12),
        _buildSubCategoryTile(
          mainCategory: selectedOption!,
          label: 'Kebutuhan Sehari-hari',
          icon: Icons.lightbulb,
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
    IconData? icon,
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
      leading: icon != null
          ? Icon(
        icon,
        color: Colors.black, // Default color if not provided
        size: 18,
      )
          : null, // No icon if null
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
