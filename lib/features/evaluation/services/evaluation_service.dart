// lib/features/evaluation/services/evaluation_service.dart
import 'package:flutter/material.dart';
import 'package:ta_client/features/evaluation/models/evaluation.dart';
import 'package:ta_client/features/evaluation/models/history.dart';
import 'package:ta_client/features/transaction/models/transaction.dart';
import 'package:ta_client/features/transaction/services/transaction_service.dart';

class EvaluationService {
  EvaluationService({required this.transactionService});
  final TransactionService transactionService;

  /// 1) fetch *all* transactions, then 2) filter by date-range in Dart
  Future<List<Transaction>> _loadTxns(DateTime start, DateTime end) async {
    final all = await transactionService.fetchTransactions();
    return all.where((t) {
      return !t.date.isBefore(start) && !t.date.isAfter(end);
    }).toList();
  }

  /// Load all transactions in [start..end]
  Future<List<Evaluation>> fetchDashboard(DateTime start, DateTime end) async {
    final txs = await _loadTxns(start, end);

    // helper to sum by a list of subcategory names
    double sumSubcats(List<String> subcats) => txs
        .where((t) => subcats.contains(t.subcategoryName))
        .fold<double>(0, (s, t) => s + t.amount);

    // 1) Aset Likuid = ["Uang Tunai", "Uang Rekening Bank", "Uang E-Wallet", "Dividen", "Bunga", "Untung Modal"]
    final liquidAssets = sumSubcats([
      'Uang Tunai',
      'Uang Rekening Bank',
      'Uang E-Wallet',
      'Dividen',
      'Bunga',
      'Untung Modal',
    ]);

    // Pengeluaran bulanan = all Pengeluaran subcats
    final allExpenseSubcats = [
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
    final monthlyExpense = sumSubcats(allExpenseSubcats);

    // 2) Aset Non-Liquid = all other Aset subcats minus liquid ones
    final nonLiquid = sumSubcats([
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

    // Liabilitas = all Utang subcategories
    final liabilities = sumSubcats([
      'Saldo Kartu Kredit',
      'Tagihan',
      'Cicilan',
      'Pajak',
      'Pinjaman',
      'Pinjaman Properti',
    ]);

    // 3) Total Utang Pembayaran Bulanan – for Debt Service Ratio:
    //    same as liabilities here (or you could drill down only on those with “Cicilan” etc.)
    final debtPayments = sumSubcats([
      'Cicilan',
      'Saldo Kartu Kredit',
      'Pinjaman',
      'Pinjaman Properti',
    ]);

    // 4) Tabungan subcat
    final savings = sumSubcats(['Tabungan']);

    // 5) Penghasilan Kotor – all Pemasukan subcats
    final grossIncome = sumSubcats([
      'Gaji',
      'Upah',
      'Bonus',
      'Commission',
      'Dividen',
      'Bunga',
      'Untung Modal',
      'Freelance',
    ]);

    final deductions = sumSubcats([
      'Pajak', // Pengeluaran → Utang → Pajak
      'Bayar asuransi', // Pengeluaran → Kewajiban Finansial → Bayar asuransi
    ]);

    // 6) Net Income – assume “Gaji” + “Upah” + “Bonus” are net;
    //    for demo we’ll treat all Pemasukan same as gross
    final netIncome = grossIncome - deductions;

    // 7) Investasi = investment subcats
    final invested = sumSubcats([
      'Saham',
      'Obligasi',
      'Reksadana',
      'Kripto',
      'Properti Sewa',
    ]);

    final netWorth = (liquidAssets + nonLiquid) - liabilities;
    final totalAssets = liquidAssets + nonLiquid;

    debugPrint(
      '— Computed: '
      'liquid=$liquidAssets, '
      'expense=$monthlyExpense, '
      'nonLiquid=$nonLiquid, '
      'liab=$liabilities, '
      'savings=$savings, '
      'income=$grossIncome, '
      'invested=$invested, '
      'netWorth=$netWorth, '
      'totalAssets=$totalAssets',
    );

    bool inRange(double v, double? low, double? high) {
      if (low != null && v < low) return false;
      if (high != null && v > high) return false;
      return true;
    }

    // Build each Evaluation, matching your UI ids:
    return [
      // 0: Liquidity Ratio (months)
      Evaluation(
        id: '0',
        title: 'Rasio Likuiditas',
        yourValue: monthlyExpense > 0 ? liquidAssets / monthlyExpense : 0.0,
        idealText: '3–6 Bulan',
        isIdeal: inRange(
          monthlyExpense > 0 ? liquidAssets / monthlyExpense : 0.0,
          3.0,
          6.0,
        ),
        breakdown: {
          'Aset Likuid': liquidAssets,
          'Pengeluaran Bulanan': monthlyExpense,
        },
      ),

      // 1: Current Assets / Net Worth (%)
      Evaluation(
        id: '1',
        title: 'Aset Lancar / Kekayaan Bersih',
        yourValue: netWorth != 0 ? (liquidAssets / netWorth) * 100 : 0.0,
        idealText: '> 15%',
        isIdeal: (netWorth != 0 ? (liquidAssets / netWorth) * 100 : 0.0) >= 15,
        breakdown: {'Aset Likuid': liquidAssets, 'Kekayaan Bersih': netWorth},
      ),

      // 2: Debt-to-Asset (%)
      Evaluation(
        id: '2',
        title: 'Utang / Aset',
        yourValue: totalAssets > 0 ? (liabilities / totalAssets) * 100 : 0.0,
        idealText: '≤ 50%',
        isIdeal:
            (totalAssets > 0 ? (liabilities / totalAssets) * 100 : 0.0) <= 50,
        breakdown: {'Total Utang': liabilities, 'Total Aset': totalAssets},
      ),

      // 3: Saving Ratio (%)
      Evaluation(
        id: '3',
        title: 'Rasio Tabungan',
        yourValue: grossIncome > 0 ? (savings / grossIncome) * 100 : 0.0,
        idealText: '≥ 10%',
        isIdeal: (grossIncome > 0 ? (savings / grossIncome) * 100 : 0.0) >= 10,
        breakdown: {'Tabungan': savings, 'Pendapatan Kotor': grossIncome},
      ),

      // 4: Debt Service Ratio (%)
      Evaluation(
        id: '4',
        title: 'Debt Service Ratio',
        yourValue: netIncome > 0 ? (debtPayments / netIncome) * 100 : 0.0,
        idealText: '≤ 45%',
        isIdeal: (netIncome > 0 ? (debtPayments / netIncome) * 100 : 0.0) <= 45,
        breakdown: {
          'Pembayaran Utang': debtPayments,
          'Pendapatan Bersih': netIncome,
        },
      ),

      // 5: Investasi / Net Worth (%)
      Evaluation(
        id: '5',
        title: 'Investasi / Kekayaan Bersih',
        yourValue: netWorth > 0 ? (invested / netWorth) * 100 : 0.0,
        idealText: '≥ 50%',
        isIdeal: (netWorth > 0 ? (invested / netWorth) * 100 : 0.0) >= 50,
        breakdown: {'Investasi': invested, 'Kekayaan Bersih': netWorth},
      ),

      // 6: Solvability Ratio (%)
      Evaluation(
        id: '6',
        title: 'Rasio Solvabilitas',
        yourValue: totalAssets > 0 ? (netWorth / totalAssets) * 100 : 0.0,
        idealText: '—',
        isIdeal: false,
        breakdown: {'Kekayaan Bersih': netWorth, 'Total Aset': totalAssets},
      ),
    ];
  }

  Future<Evaluation> fetchDetail(DateTime start, DateTime end, String id) {
    return fetchDashboard(
      start,
      end,
    ).then((list) => list.firstWhere((e) => e.id == id));
  }

  Future<List<History>> fetchHistory() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return [
      History(
        start: DateTime(2024),
        end: DateTime(2024, 3, 31),
        ideal: 3,
        notIdeal: 2,
        incomplete: 1,
      ),
      History(
        start: DateTime(2024, 4),
        end: DateTime(2024, 6, 30),
        ideal: 5,
        notIdeal: 0,
        incomplete: 1,
      ),
      History(
        start: DateTime(2024, 7),
        end: DateTime(2024, 9, 30),
        ideal: 2,
        notIdeal: 4,
        incomplete: 0,
      ),
    ];
  }
}
