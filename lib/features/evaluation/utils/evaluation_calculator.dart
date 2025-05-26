import 'package:ta_client/features/transaction/models/transaction.dart';

typedef RatioFn = double Function(List<Transaction> txs);
typedef IdealCheck = bool Function(double value);

/// Defines one of your evaluation ratios.
class RatioDef {
  const RatioDef({
    required this.id, // This is the client-side numeric ID (e.g., '0', '1')
    required this.title,
    required this.compute,
    required this.isIdeal,
    required this.backendCode, // Add this field to link to backend, this.idealText,
    this.idealText,
  });

  final String id;
  final String title;
  final String? idealText;
  final RatioFn compute;
  final IdealCheck isIdeal;
  final String
  backendCode; // Backend-defined ratio code (e.g., 'LIQUIDITY_RATIO')
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
      .fold(0, (sum, t) => sum + t.amount);

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
      backendCode: 'LIQUIDITY_RATIO', // Add backend code here
      compute: (txs) {
        final s = _computeSums(txs);
        return s.expense > 0 ? s.liquid / s.expense : 0.0;
      },
      isIdeal: (v) => v >= 3 && v <= 6,
    ),

    // 1: Current Assets / Net Worth (%)
    RatioDef(
      id: '1',
      title:
          'Rasio aset lancar terhadap kekayaan bersih', // Update title to match dashboard exactly
      idealText: '>= 15% dan <= 100%', // Update ideal text
      backendCode: 'LIQUID_ASSETS_TO_NET_WORTH_RATIO', // Add backend code here
      compute: (txs) {
        final s = _computeSums(txs);
        // Correcting the ideal text interpretation and calculation for consistency
        return s.netWorth != 0 ? (s.liquid / s.netWorth) * 100 : 0.0;
      },
      isIdeal: (v) => v >= 15 && v <= 100, // Updated ideal check
    ),

    // 2: Debt-to-Asset (%)
    RatioDef(
      id: '2',
      title:
          'Rasio utang terhadap aset', // Update title to match dashboard exactly
      idealText: '>= 0% dan <= 50%', // Update ideal text
      backendCode: 'DEBT_TO_ASSET_RATIO', // Add backend code here
      compute: (txs) {
        final s = _computeSums(txs);
        return s.totalAssets > 0 ? (s.liabilities / s.totalAssets) * 100 : 0.0;
      },
      isIdeal: (v) => v >= 0 && v <= 50, // Updated ideal check
    ),

    // 3: Saving Ratio (%)
    RatioDef(
      id: '3',
      title: 'Rasio Tabungan',
      idealText: '>= 10% dan <= 100%', // Update ideal text
      backendCode: 'SAVING_RATIO', // Add backend code here
      compute: (txs) {
        final s = _computeSums(txs);
        return s.income > 0 ? (s.savings / s.income) * 100 : 0.0;
      },
      isIdeal: (v) => v >= 10 && v <= 100, // Updated ideal check
    ),

    // 4: Debt Service Ratio (%)
    RatioDef(
      id: '4',
      title:
          'Rasio kemampuan pelunasan hutang', // Update title to match dashboard exactly
      idealText: '>= 0% dan <= 45%', // Update ideal text
      backendCode: 'DEBT_SERVICE_RATIO', // Add backend code here
      compute: (txs) {
        final s = _computeSums(txs);
        return s.netIncome > 0 ? (s.debtPayments / s.netIncome) * 100 : 0.0;
      },
      isIdeal: (v) => v >= 0 && v <= 45, // Updated ideal check
    ),

    // 5: Investasi / Net Worth (%)
    RatioDef(
      id: '5',
      title:
          'Aset investasi terhadap nilai bersih kekayaan', // Update title to match dashboard exactly
      idealText: '>= 50% dan <= 100%', // Update ideal text
      backendCode:
          'INVESTMENT_ASSETS_TO_NET_WORTH_RATIO', // Add backend code here
      compute: (txs) {
        final s = _computeSums(txs);
        return s.netWorth > 0 ? (s.invested / s.netWorth) * 100 : 0.0;
      },
      isIdeal: (v) => v >= 50 && v <= 100, // Updated ideal check
    ),

    // 6: Solvability Ratio (%)
    RatioDef(
      id: '6',
      title: 'Rasio solvabilitas', // Update title to match dashboard exactly
      idealText: '>= 0.00001% dan <= 100%', // Update ideal text for consistency
      backendCode: 'SOLVENCY_RATIO', // Add backend code here
      compute: (txs) {
        final s = _computeSums(txs);
        return s.totalAssets > 0 ? (s.netWorth / s.totalAssets) * 100 : 0.0;
      },
      isIdeal: (v) => v >= 0.00001 && v <= 100, // Updated ideal check
    ),
  ];
}

// Helper function to map backend ratio code to client-side numeric ID
String? getClientRatioIdFromBackendCode(String backendCode) {
  final ratioDef = evaluationDefinitions().firstWhere(
    (def) => def.backendCode == backendCode,
    orElse: () => null!, // Using null! for brevity assuming you handle null
  );
  return ratioDef.id;
}

// Helper function to map client-side numeric ID to backend ratio code
String? getBackendRatioCodeFromClientRatioId(String clientRatioId) {
  final ratioDef = evaluationDefinitions().firstWhere(
    (def) => def.id == clientRatioId,
    orElse: () => null!, // Using null! for brevity assuming you handle null
  );
  return ratioDef.backendCode;
}
