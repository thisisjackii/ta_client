// lib/features/evaluation/utils/evaluation_calculator.dart
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
    RatioDef(
      id: '0',
      title: 'Rasio Likuiditas',
      idealText: '≥ 3 Bulan',
      backendCode: 'LIQUIDITY_RATIO',
      compute: (txs) {
        final s = _computeSums(txs);
        if (s.expense == 0) return s.liquid > 0 ? double.infinity : 0.0;
        return s.liquid / s.expense;
      },
      isIdeal: (v) => v >= 3,
    ),
    RatioDef(
      id: '1',
      title: 'Rasio aset lancar terhadap kekayaan bersih',
      idealText: '15% - 100%',
      backendCode: 'LIQUID_ASSETS_TO_NET_WORTH_RATIO',
      compute: (txs) {
        final s = _computeSums(txs);
        if (s.netWorth == 0)
          return s.liquid == 0
              ? 0.0
              : (s.liquid > 0 ? double.infinity : double.negativeInfinity);
        return (s.liquid / s.netWorth) * 100;
      },
      isIdeal: (v) => v >= 15 && v <= 100,
    ),
    RatioDef(
      id: '2',
      title: 'Rasio utang terhadap aset',
      idealText: '≤ 50%', // From seed, only upper bound for this one
      backendCode: 'DEBT_TO_ASSET_RATIO',
      compute: (txs) {
        final s = _computeSums(txs);
        if (s.totalAssets == 0)
          return s.liabilities > 0 ? double.infinity : 0.0;
        return (s.liabilities / s.totalAssets) * 100;
      },
      isIdeal: (v) =>
          v <=
          50, // Assuming implicit lower bound of 0 is acceptable. If strictly 0-50: v >= 0 && v <= 50
    ),
    RatioDef(
      id: '3',
      title: 'Rasio Tabungan',
      idealText: '≥ 10%', // From seed, only lower bound
      backendCode: 'SAVING_RATIO',
      compute: (txs) {
        final s = _computeSums(txs);
        if (s.income == 0)
          return s.savings > 0
              ? double.infinity
              : 0.0; // Or -infinity if savings < 0
        return (s.savings / s.income) * 100;
      },
      isIdeal: (v) =>
          v >=
          10, // Assuming implicit upper bound of 100. If strictly 10-100: v >= 10 && v <= 100
    ),
    RatioDef(
      id: '4',
      title: 'Rasio kemampuan pelunasan hutang',
      idealText: '≤ 45%', // From seed
      backendCode: 'DEBT_SERVICE_RATIO',
      compute: (txs) {
        final s = _computeSums(txs);
        if (s.netIncome == 0) return s.debtPayments > 0 ? double.infinity : 0.0;
        return (s.debtPayments / s.netIncome) * 100;
      },
      isIdeal: (v) => v <= 45, // Assuming implicit lower bound of 0.
    ),
    RatioDef(
      id: '5',
      title: 'Aset investasi terhadap nilai bersih kekayaan',
      idealText: '≥ 50%', // From seed
      backendCode: 'INVESTMENT_ASSETS_TO_NET_WORTH_RATIO',
      compute: (txs) {
        final s = _computeSums(txs);
        if (s.netWorth == 0)
          return s.invested == 0
              ? 0.0
              : (s.invested > 0 ? double.infinity : double.negativeInfinity);
        return (s.invested / s.netWorth) * 100;
      },
      isIdeal: (v) => v >= 50, // Assuming implicit upper bound of 100.
    ),
    RatioDef(
      id: '6',
      title: 'Rasio solvabilitas',
      idealText: '-',
      backendCode: 'SOLVENCY_RATIO',
      compute: (txs) {
        final s = _computeSums(txs);
        if (s.totalAssets == 0)
          return s.netWorth == 0
              ? 0.0
              : (s.netWorth > 0 ? double.infinity : double.negativeInfinity);
        return (s.netWorth / s.totalAssets) * 100;
      },
      isIdeal: (v) => v > 0, // Ideal if positive
    ),
  ];
}

// Helper function to map backend ratio code to client-side numeric ID
String? getClientRatioIdFromBackendCode(String backendCode) {
  final ratioDef = evaluationDefinitions().firstWhere(
    (def) => def.backendCode == backendCode,
    orElse: () =>
        throw Exception('No RatioDef found for backendCode: $backendCode'),
  );
  return ratioDef.id;
}

// Helper function to map client-side numeric ID to backend ratio code
String? getBackendRatioCodeFromClientRatioId(String clientRatioId) {
  final ratioDef = evaluationDefinitions().firstWhere(
    (def) => def.id == clientRatioId,
    orElse: () =>
        throw Exception('No RatioDef found for clientRatioId: $clientRatioId'),
  );
  return ratioDef.backendCode;
}
