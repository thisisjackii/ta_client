// lib/features/evaluation/utils/evaluation_calculator.dart
import 'package:ta_client/features/transaction/models/transaction.dart';

typedef RatioFn = double Function(List<Transaction> txs);
typedef IdealCheck = bool Function(double value);

/// Defines one of your six evaluation ratios.
class RatioDef {
  const RatioDef({
    required this.id,
    required this.title,
    required this.compute,
    required this.isIdeal,
    this.idealText,
  });
  final String id;
  final String title;
  final String? idealText;
  final RatioFn compute;
  final IdealCheck isIdeal;
}

/// Returns all six of your ratios with full subcategory lists.
List<RatioDef> evaluationDefinitions() {
  double sumBySubcats(List<Transaction> txs, List<String> subs) => txs
      .where((t) => subs.contains(t.subcategoryName))
      .fold(0.toDouble(), (sum, t) => sum + t.amount);

  return [
    // 0: Liquidity Ratio (months)
    RatioDef(
      id: '0',
      title: 'Rasio Likuiditas',
      idealText: '3–6 Bulan',
      compute: (txs) {
        final liquid = sumBySubcats(txs, [
          'Uang Tunai',
          'Uang Rekening Bank',
          'Uang E‑Wallet',
          'Dividen',
          'Bunga',
          'Untung Modal',
        ]);
        final expense = sumBySubcats(txs, [
          'Tabungan',
          'Makanan',
          'Minuman',
          'Hadiah',
          'Donasi',
          'Kendaraan Pribadi',
          'Transportasi Umum',
          'Bahan bakar',
          'Kesehatan',
          'Medis',
          'Perawatan Pribadi',
          'Pakaian',
          'Hiburan',
          'Rekreasi',
          'Pendidikan',
          'Pembelajaran',
          'Bayar pinjaman',
          'Bayar pajak',
          'Bayar asuransi',
          'Perumahan',
          'Kebutuhan Sehari-hari',
        ]);
        return expense > 0 ? liquid / expense : 0.0;
      },
      isIdeal: (v) => v >= 3 && v <= 6,
    ),

    // 1: Current Assets / Net Worth (%)
    RatioDef(
      id: '1',
      title: 'Aset Lancar / Kekayaan Bersih',
      idealText: '> 15%',
      compute: (txs) {
        final liquid = sumBySubcats(txs, [
          'Uang Tunai',
          'Uang Rekening Bank',
          'Uang E‑Wallet',
          'Dividen',
          'Bunga',
          'Untung Modal',
        ]);
        final nonLiquid = sumBySubcats(txs, [
          'Piutang',
          'Rumah',
          'Apartemen',
          'Ruko',
          'Gudang',
          'Kios',
          'Properti Sewa',
          'Kendaraan',
          'Elektronik',
          'Furnitur',
          'Saham',
          'Obligasi',
          'Reksadana',
          'Kripto',
          'Koleksi',
          'Perhiasan',
        ]);
        final liabilities = sumBySubcats(txs, [
          'Saldo Kartu Kredit',
          'Tagihan',
          'Cicilan',
          'Pajak',
          'Pinjaman',
          'Pinjaman Properti',
        ]);
        final netWorth = (liquid + nonLiquid) - liabilities;
        return netWorth != 0 ? (liquid / netWorth) * 100.0 : 0.0;
      },
      isIdeal: (v) => v >= 15,
    ),

    // 2: Debt-to-Asset (%)
    RatioDef(
      id: '2',
      title: 'Utang / Aset',
      idealText: '≤ 50%',
      compute: (txs) {
        final liquid = sumBySubcats(txs, [
          'Uang Tunai',
          'Uang Rekening Bank',
          'Uang E‑Wallet',
          'Dividen',
          'Bunga',
          'Untung Modal',
        ]);
        final nonLiquid = sumBySubcats(txs, [
          'Piutang',
          'Rumah',
          'Apartemen',
          'Ruko',
          'Gudang',
          'Kios',
          'Properti Sewa',
          'Kendaraan',
          'Elektronik',
          'Furnitur',
          'Saham',
          'Obligasi',
          'Reksadana',
          'Kripto',
          'Koleksi',
          'Perhiasan',
        ]);
        final liabilities = sumBySubcats(txs, [
          'Saldo Kartu Kredit',
          'Tagihan',
          'Cicilan',
          'Pajak',
          'Pinjaman',
          'Pinjaman Properti',
        ]);
        final totalAssets = liquid + nonLiquid;
        return totalAssets > 0 ? (liabilities / totalAssets) * 100.0 : 0.0;
      },
      isIdeal: (v) => v <= 50,
    ),

    // 3: Saving Ratio (%)
    RatioDef(
      id: '3',
      title: 'Rasio Tabungan',
      idealText: '≥ 10%',
      compute: (txs) {
        final savings = sumBySubcats(txs, ['Tabungan']);
        final grossIncome = sumBySubcats(txs, [
          'Gaji',
          'Upah',
          'Bonus',
          'Commission',
          'Dividen',
          'Bunga',
          'Untung Modal',
          'Freelance',
        ]);
        return grossIncome > 0 ? (savings / grossIncome) * 100.0 : 0.0;
      },
      isIdeal: (v) => v >= 10,
    ),

    // 4: Debt Service Ratio (%)
    RatioDef(
      id: '4',
      title: 'Debt Service Ratio',
      idealText: '≤ 45%',
      compute: (txs) {
        final debtPayments = sumBySubcats(txs, [
          'Cicilan',
          'Saldo Kartu Kredit',
          'Pinjaman',
          'Pinjaman Properti',
        ]);
        final grossIncome = sumBySubcats(txs, [
          'Gaji',
          'Upah',
          'Bonus',
          'Commission',
          'Dividen',
          'Bunga',
          'Untung Modal',
          'Freelance',
        ]);
        final deductions = sumBySubcats(txs, ['Pajak', 'Bayar asuransi']);
        final netIncome = grossIncome - deductions;
        return netIncome > 0 ? (debtPayments / netIncome) * 100.0 : 0.0;
      },
      isIdeal: (v) => v <= 45,
    ),

    // 5: Investasi / Net Worth (%)
    RatioDef(
      id: '5',
      title: 'Investasi / Kekayaan Bersih',
      idealText: '≥ 50%',
      compute: (txs) {
        final invested = sumBySubcats(txs, [
          'Saham',
          'Obligasi',
          'Reksadana',
          'Kripto',
          'Properti Sewa',
        ]);
        final liquid = sumBySubcats(txs, [
          'Uang Tunai',
          'Uang Rekening Bank',
          'Uang E‑Wallet',
          'Dividen',
          'Bunga',
          'Untung Modal',
        ]);
        final nonLiquid = sumBySubcats(txs, [
          'Piutang',
          'Rumah',
          'Apartemen',
          'Ruko',
          'Gudang',
          'Kios',
          'Properti Sewa',
          'Kendaraan',
          'Elektronik',
          'Furnitur',
          'Saham',
          'Obligasi',
          'Reksadana',
          'Kripto',
          'Koleksi',
          'Perhiasan',
        ]);
        final liabilities = sumBySubcats(txs, [
          'Saldo Kartu Kredit',
          'Tagihan',
          'Cicilan',
          'Pajak',
          'Pinjaman',
          'Pinjaman Properti',
        ]);
        final netWorth = (liquid + nonLiquid) - liabilities;
        return netWorth > 0 ? (invested / netWorth) * 100.0 : 0.0;
      },
      isIdeal: (v) => v >= 50,
    ),

    // 6: Solvability Ratio (%)
    RatioDef(
      id: '6',
      title: 'Rasio Solvabilitas',
      idealText: '—',
      compute: (txs) {
        final liquid = sumBySubcats(txs, [
          'Uang Tunai',
          'Uang Rekening Bank',
          'Uang E‑Wallet',
          'Dividen',
          'Bunga',
          'Untung Modal',
        ]);
        final nonLiquid = sumBySubcats(txs, [
          'Piutang',
          'Rumah',
          'Apartemen',
          'Ruko',
          'Gudang',
          'Kios',
          'Properti Sewa',
          'Kendaraan',
          'Elektronik',
          'Furnitur',
          'Saham',
          'Obligasi',
          'Reksadana',
          'Kripto',
          'Koleksi',
          'Perhiasan',
        ]);
        final liabilities = sumBySubcats(txs, [
          'Saldo Kartu Kredit',
          'Tagihan',
          'Cicilan',
          'Pajak',
          'Pinjaman',
          'Pinjaman Properti',
        ]);
        final netWorth = (liquid + nonLiquid) - liabilities;
        final totalAssets = liquid + nonLiquid;
        return totalAssets > 0 ? (netWorth / totalAssets) * 100.0 : 0.0;
      },
      isIdeal: (_) => false,
    ),
  ];
}
