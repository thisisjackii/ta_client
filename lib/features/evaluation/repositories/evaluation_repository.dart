// lib/features/evaluation/repositories/evaluation_repository.dart
import 'package:flutter/foundation.dart';
import 'package:ta_client/core/services/connectivity_service.dart'; // Import
import 'package:ta_client/core/services/service_locator.dart'; // Import for sl
import 'package:ta_client/features/evaluation/models/evaluation.dart';
import 'package:ta_client/features/evaluation/models/history.dart';
import 'package:ta_client/features/evaluation/services/evaluation_service.dart';
// Import client-side calculator and transaction dependencies for offline mode
import 'package:ta_client/features/evaluation/utils/evaluation_calculator.dart';
import 'package:ta_client/features/transaction/models/transaction.dart';
import 'package:ta_client/features/transaction/repositories/transaction_repository.dart'; // For offline transactions

// Re-define _TxSums here or import if it's moved to a shared location
class _TxSumsOffline {
  _TxSumsOffline({
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

// Re-define _computeSumsOffline or import
_TxSumsOffline _computeConceptualSumsOfflineImpl(List<Transaction> txs) {
  const liquidCats = [
    'Uang Tunai',
    'Uang Rekening Bank',
    'Uang E-Wallet',
    'Dividen',
    'Bunga',
    'Untung Modal',
  ];
  const nonLiquidCats = [
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
  const liabilitiesCats = [
    'Saldo Kartu Kredit',
    'Tagihan',
    'Cicilan',
    'Pajak',
    'Pinjaman',
    'Pinjaman Properti',
  ];
  const expenseCats = [
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
  const incomeCats = [
    'Gaji',
    'Upah',
    'Bonus',
    'Commission',
    'Dividen',
    'Bunga',
    'Untung Modal',
    'Freelance',
  ];
  const savingsCats = ['Tabungan'];
  const debtPaymentsCats = [
    'Cicilan',
    'Saldo Kartu Kredit',
    'Pinjaman',
    'Pinjaman Properti',
    'Bayar pinjaman',
  ];
  const deductionsCats = ['Pajak', 'Bayar asuransi'];
  const investedCats = [
    'Saham',
    'Obligasi',
    'Reksadana',
    'Kripto',
    'Properti Sewa',
  ];

  double sumBy(List<String> cats) => txs
      .where((t) => cats.contains(t.subcategoryName))
      .fold(0, (sum, t) => sum + t.amount);

  return _TxSumsOffline(
    liquid: sumBy(liquidCats),
    nonLiquid: sumBy(nonLiquidCats),
    liabilities: sumBy(liabilitiesCats),
    expense: sumBy(expenseCats),
    income: sumBy(incomeCats),
    savings: sumBy(savingsCats),
    debtPayments: sumBy(debtPaymentsCats),
    deductions: sumBy(deductionsCats),
    invested: sumBy(investedCats),
  );
}

class EvaluationRepository {
  EvaluationRepository(this._service, this._transactionRepository) {
    _connectivityService =
        sl<ConnectivityService>(); // Get from Service Locator
  }

  final EvaluationService _service;
  final TransactionRepository
  _transactionRepository; // To get cached transactions
  late ConnectivityService _connectivityService;

  // This method now decides online/offline path
  Future<List<Evaluation>> getDashboardItems({
    required DateTime startDate,
    required DateTime endDate,
    String? periodId, // For online, if period is already defined
  }) async {
    final isOnline = await _connectivityService.isOnline;
    if (isOnline) {
      debugPrint(
        '[EvaluationRepository] Online: Calling service to calculate/fetch evaluations.',
      );
      return _service.calculateAndFetchEvaluationsForPeriod(
        periodId: periodId, // Pass periodId if available
        startDate: startDate,
        endDate: endDate,
      );
    } else {
      debugPrint(
        '[EvaluationRepository] Offline: Calculating evaluations locally.',
      );
      final cachedTransactions =
          _transactionRepository.getCachedTransactionList() ?? [];
      final inRange = cachedTransactions
          .where((t) => !t.date.isBefore(startDate) && !t.date.isAfter(endDate))
          .toList();

      if (inRange.isEmpty) {
        debugPrint(
          '[EvaluationRepository-OFFLINE] No cached transactions in range for dashboard.',
        );
      }
      return evaluationDefinitions().map((def) {
        // Uses client-side evaluationDefinitions
        final v = def.compute(inRange);
        return Evaluation(
          id: def.id, // Client-side ID '0', '1', etc.
          title: def.title,
          yourValue: v,
          idealText: def.idealText,
          isIdeal: def.isIdeal(v),
        );
      }).toList();
    }
  }

  Future<Evaluation> getDetail({
    required DateTime startDate, // Needed for offline calculation context,
    required DateTime
    endDate, // Needed for offline calculation context, String?
    String?
    evaluationResultDbId, // For online mode: ID of the EvaluationResult record
    String? clientRatioId, // For offline mode: client-side ID '0', '1'
  }) async {
    final isOnline = await _connectivityService.isOnline;
    if (isOnline && evaluationResultDbId != null) {
      debugPrint(
        '[EvaluationRepository] Online: Calling service for evaluation detail.',
      );
      return _service.fetchEvaluationDetail(evaluationResultDbId);
    } else if (!isOnline && clientRatioId != null) {
      debugPrint(
        '[EvaluationRepository] Offline: Calculating evaluation detail locally for ratio $clientRatioId.',
      );
      final cachedTransactions =
          _transactionRepository.getCachedTransactionList() ?? [];
      final inRange = cachedTransactions
          .where((t) => !t.date.isBefore(startDate) && !t.date.isAfter(endDate))
          .toList();

      final ratioDef = evaluationDefinitions().firstWhere(
        (def) => def.id == clientRatioId,
        orElse: () => throw Exception(
          'Offline: Client-side RatioDef not found for ID $clientRatioId',
        ),
      );

      final value = ratioDef.compute(inRange);
      final conceptualSums = _computeConceptualSumsOfflineImpl(inRange);
      final breakdown = <ConceptualComponentValue>[];
      // Map conceptual sums to breakdown based on clientRatioId (similar to service's offline detail)
      if (clientRatioId == '0') {
        // Rasio Likuiditas
        breakdown.add(
          ConceptualComponentValue(
            name: 'Total Aset Likuid (Numerator)',
            value: conceptualSums.liquid,
          ),
        );
        breakdown.add(
          ConceptualComponentValue(
            name: 'Total Pengeluaran Bulanan (Denominator)',
            value: conceptualSums.expense,
          ),
        );
      } else if (clientRatioId == '1') {
        // Aset Lancar / Kekayaan Bersih
        breakdown.add(
          ConceptualComponentValue(
            name: 'Total Aset Likuid (Numerator)',
            value: conceptualSums.liquid,
          ),
        );
        breakdown.add(
          ConceptualComponentValue(
            name: 'Total Kekayaan Bersih (Denominator)',
            value: conceptualSums.netWorth,
          ),
        );
      } // ... ADD ALL OTHER MAPPINGS FOR clientRatioId '2' through '6' ...
      else if (clientRatioId == '2') {
        breakdown.add(
          ConceptualComponentValue(
            name: 'Total Utang (Numerator)',
            value: conceptualSums.liabilities,
          ),
        );
        breakdown.add(
          ConceptualComponentValue(
            name: 'Total Aset (Denominator)',
            value: conceptualSums.totalAssets,
          ),
        );
      } else if (clientRatioId == '3') {
        breakdown.add(
          ConceptualComponentValue(
            name: 'Total Tabungan (Numerator)',
            value: conceptualSums.savings,
          ),
        );
        breakdown.add(
          ConceptualComponentValue(
            name: 'Penghasilan Kotor (Denominator)',
            value: conceptualSums.income,
          ),
        );
      } else if (clientRatioId == '4') {
        breakdown.add(
          ConceptualComponentValue(
            name: 'Total Pembayaran Utang Bulanan (Numerator)',
            value: conceptualSums.debtPayments,
          ),
        );
        breakdown.add(
          ConceptualComponentValue(
            name: 'Penghasilan Bersih (Denominator)',
            value: conceptualSums.netIncome,
          ),
        );
      } else if (clientRatioId == '5') {
        breakdown.add(
          ConceptualComponentValue(
            name: 'Total Aset Diinvestasikan (Numerator)',
            value: conceptualSums.invested,
          ),
        );
        breakdown.add(
          ConceptualComponentValue(
            name: 'Total Kekayaan Bersih (Denominator)',
            value: conceptualSums.netWorth,
          ),
        );
      } else if (clientRatioId == '6') {
        breakdown.add(
          ConceptualComponentValue(
            name: 'Total Kekayaan Bersih (Numerator)',
            value: conceptualSums.netWorth,
          ),
        );
        breakdown.add(
          ConceptualComponentValue(
            name: 'Total Aset (Denominator)',
            value: conceptualSums.totalAssets,
          ),
        );
      }

      return Evaluation(
        id: ratioDef.id,
        title: ratioDef.title,
        yourValue: value,
        isIdeal: ratioDef.isIdeal(value),
        idealText: ratioDef.idealText,
        breakdown: breakdown,
      );
    } else {
      throw Exception(
        'Cannot get detail: Insufficient parameters for current online/offline state.',
      );
    }
  }

  // History is usually an online-only feature, as it implies persisted, official results.
  Future<List<History>> getEvaluationHistory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final isOnline = await _connectivityService.isOnline;
    if (isOnline) {
      debugPrint(
        '[EvaluationRepository] Online: Calling service for evaluation history.',
      );
      return _service.fetchEvaluationHistory(
        startDate: startDate,
        endDate: endDate,
      );
    } else {
      debugPrint(
        '[EvaluationRepository] Offline: Evaluation history not available.',
      );
      // For offline, you could return an empty list or a message indicating it's an online feature.
      // Or, if you were to cache online history results, you could return cached history.
      return [];
    }
  }
}
