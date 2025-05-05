// lib/features/evaluation/utils/evaluation_calculator.dart
import 'package:ta_client/features/transaction/models/transaction.dart';

typedef RatioFn = double Function(List<Transaction> txs);
typedef IdealCheck = bool Function(double value);

/// Defines one of your evaluation ratios.
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

/// Category group definitions
const _liquidCats = [
  'Uang Tunai',
  'Uang Rekening Bank',
  'Uang E‑Wallet',
  'Dividen',
  'Bunga',
  'Untung Modal',
];
const _nonLiquidCats = [
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
];
const _liabilitiesCats = [
  'Saldo Kartu Kredit',
  'Tagihan',
  'Cicilan',
  'Pajak',
  'Pinjaman',
  'Pinjaman Properti',
];
const _expenseCats = [
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
];
const _incomeCats = [
  'Gaji',
  'Upah',
  'Bonus',
  'Commission',
  'Dividen',
  'Bunga',
  'Untung Modal',
  'Freelance',
];
const _savingsCats = ['Tabungan'];
const _debtPaymentsCats = [
  'Cicilan',
  'Saldo Kartu Kredit',
  'Pinjaman',
  'Pinjaman Properti',
];
const _deductionsCats = ['Pajak', 'Bayar asuransi'];
const _investedCats = [
  'Saham',
  'Obligasi',
  'Reksadana',
  'Kripto',
  'Properti Sewa',
];

/// Internal sums holder
class _TxSums {
  _TxSums({
    required this.liquid,
    required this.nonLiquid,
    required this.liabilities,
    required this.expense,
    required this.income,
    required this.savings,
    required this.debtPayments,
    required this.deductions,
    required this.invested,
  });

  final double liquid;
  final double nonLiquid;
  final double liabilities;
  final double expense;
  final double income;
  final double savings;
  final double debtPayments;
  final double deductions;
  final double invested;

  double get netWorth => (liquid + nonLiquid) - liabilities;
  double get totalAssets => liquid + nonLiquid;
  double get netIncome => income - deductions;
}

/// Helper: compute all sums for given transactions
_TxSums _computeSums(List<Transaction> txs) {
  double sumBy(List<String> cats) => txs
      .where((t) => cats.contains(t.subcategoryName))
      .fold(0.0, (sum, t) => sum + t.amount);

  return _TxSums(
    liquid: sumBy(_liquidCats),
    nonLiquid: sumBy(_nonLiquidCats),
    liabilities: sumBy(_liabilitiesCats),
    expense: sumBy(_expenseCats),
    income: sumBy(_incomeCats),
    savings: sumBy(_savingsCats),
    debtPayments: sumBy(_debtPaymentsCats),
    deductions: sumBy(_deductionsCats),
    invested: sumBy(_investedCats),
  );
}

/// Returns all six of your ratios.
List<RatioDef> evaluationDefinitions() {
  return [
    // 0: Liquidity Ratio (months)
    RatioDef(
      id: '0',
      title: 'Rasio Likuiditas',
      idealText: '3–6 Bulan',
      compute: (txs) {
        final s = _computeSums(txs);
        return s.expense > 0 ? s.liquid / s.expense : 0.0;
      },
      isIdeal: (v) => v >= 3 && v <= 6,
    ),

    // 1: Current Assets / Net Worth (%)
    RatioDef(
      id: '1',
      title: 'Aset Lancar / Kekayaan Bersih',
      idealText: '> 15%',
      compute: (txs) {
        final s = _computeSums(txs);
        return s.netWorth != 0 ? (s.liquid / s.netWorth) * 100 : 0.0;
      },
      isIdeal: (v) => v >= 15,
    ),

    // 2: Debt-to-Asset (%)
    RatioDef(
      id: '2',
      title: 'Utang / Aset',
      idealText: '≤ 50%',
      compute: (txs) {
        final s = _computeSums(txs);
        return s.totalAssets > 0 ? (s.liabilities / s.totalAssets) * 100 : 0.0;
      },
      isIdeal: (v) => v <= 50,
    ),

    // 3: Saving Ratio (%)
    RatioDef(
      id: '3',
      title: 'Rasio Tabungan',
      idealText: '≥ 10%',
      compute: (txs) {
        final s = _computeSums(txs);
        return s.income > 0 ? (s.savings / s.income) * 100 : 0.0;
      },
      isIdeal: (v) => v >= 10,
    ),

    // 4: Debt Service Ratio (%)
    RatioDef(
      id: '4',
      title: 'Debt Service Ratio',
      idealText: '≤ 45%',
      compute: (txs) {
        final s = _computeSums(txs);
        return s.netIncome > 0 ? (s.debtPayments / s.netIncome) * 100 : 0.0;
      },
      isIdeal: (v) => v <= 45,
    ),

    // 5: Investasi / Net Worth (%)
    RatioDef(
      id: '5',
      title: 'Investasi / Kekayaan Bersih',
      idealText: '≥ 50%',
      compute: (txs) {
        final s = _computeSums(txs);
        return s.netWorth > 0 ? (s.invested / s.netWorth) * 100 : 0.0;
      },
      isIdeal: (v) => v >= 50,
    ),

    // 6: Solvability Ratio (%)
    RatioDef(
      id: '6',
      title: 'Rasio Solvabilitas',
      idealText: '—',
      compute: (txs) {
        final s = _computeSums(txs);
        return s.totalAssets > 0 ? (s.netWorth / s.totalAssets) * 100 : 0.0;
      },
      isIdeal: (_) => false,
    ),
  ];
}
