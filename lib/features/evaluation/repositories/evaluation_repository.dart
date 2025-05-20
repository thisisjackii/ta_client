// lib/features/evaluation/repositories/evaluation_repository.dart
import 'dart:convert';
import 'package:collection/collection.dart'; // For groupBy
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:ta_client/core/services/connectivity_service.dart'; // Import
import 'package:ta_client/core/services/hive_service.dart';
import 'package:ta_client/core/services/service_locator.dart'; // Import for sl
import 'package:ta_client/features/budgeting/repositories/period_repository.dart';
import 'package:ta_client/features/evaluation/models/evaluation.dart';
import 'package:ta_client/features/evaluation/models/history.dart';
import 'package:ta_client/features/evaluation/services/evaluation_service.dart';
// Import client-side calculator and transaction dependencies for offline mode
import 'package:ta_client/features/evaluation/utils/evaluation_calculator.dart';
import 'package:ta_client/features/transaction/models/transaction.dart';
import 'package:ta_client/features/transaction/repositories/transaction_repository.dart'; // For offline transactions

// Re-define _TxSums here or import if it's moved to a shared location
class _EvaluationTxSums {
  _EvaluationTxSums({
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

_EvaluationTxSums _computeEvaluationConceptualSums(List<Transaction> txs) {
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
      .where(
        (t) => t.subcategoryName != null && cats.contains(t.subcategoryName),
      )
      .fold(0.toDouble(), (sum, t) => sum + t.amount);

  return _EvaluationTxSums(
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
  // Injected
  // final PeriodRepository _periodRepository; // Inject if needed for offline period context

  EvaluationRepository(
    this._service,
    this._transactionRepository,
    this._periodRepository,
  ) : _connectivityService = sl<ConnectivityService>(),
      _hiveService = sl<HiveService>() {
    // Hive boxes are opened in bootstrap.dart
  }
  final EvaluationService _service;
  final TransactionRepository _transactionRepository;
  final PeriodRepository _periodRepository;
  final ConnectivityService _connectivityService;
  final HiveService _hiveService;

  static const String evaluationDashboardCacheBoxName =
      'evaluationDashboardCache_v1';
  static const String evaluationResultsCacheBoxName =
      'evaluationResultsCache_v1'; // For individual results for history

  // Helper to generate a cache key for a given date range
  String _getDashboardCacheKey(DateTime startDate, DateTime endDate) {
    // Normalize dates to avoid issues with time components
    final startKey = DateFormat('yyyy-MM-dd').format(startDate);
    final endKey = DateFormat('yyyy-MM-dd').format(endDate);
    return 'eval_dashboard_${startKey}_to_$endKey';
  }

  Future<List<Evaluation>> getDashboardItems({
    required DateTime startDate, // Still needed for offline path
    required DateTime endDate, // Still needed for offline path
    required String periodId, // Now required for online path
  }) async {
    final isOnline = await _connectivityService.isOnline;
    final cacheKey = _getDashboardCacheKey(startDate, endDate);

    if (isOnline) {
      try {
        if (periodId.isEmpty) {
          throw ArgumentError(
            'Period ID is required for online evaluation dashboard fetch.',
          );
        }
        debugPrint(
          '[EvaluationRepository] Online: Calling service to calculate/fetch evaluations for periodId: $periodId.',
        );
        final evaluations = await _service
            .calculateAndFetchEvaluationsForPeriod(
              periodId: periodId,
              // startDate: startDate,
              // endDate: endDate,
            );
        // Cache the results from online fetch
        await _hiveService.putJsonString(
          evaluationDashboardCacheBoxName,
          cacheKey,
          json.encode(evaluations.map((e) => e.toJson()).toList()),
        );
        return evaluations;
      } catch (e) {
        debugPrint(
          '[EvaluationRepository] Online fetch failed for evaluations, trying cache: $e',
        );
        final cachedJson = await _hiveService.getJsonString(
          evaluationDashboardCacheBoxName,
          cacheKey,
        );
        if (cachedJson != null) {
          try {
            final decodedList = json.decode(cachedJson) as List<dynamic>;
            return decodedList
                .map(
                  (item) => Evaluation.fromJson(item as Map<String, dynamic>),
                )
                .toList();
          } catch (parseError) {
            debugPrint(
              '[EvaluationRepository] Error parsing cached evaluations: $parseError. Returning empty.',
            );
            return [];
          }
        }
        if (e is EvaluationApiException) rethrow;
        throw EvaluationApiException(
          'Failed online, no cache for evaluations: $e',
        );
      }
    } else {
      // OFFLINE
      debugPrint(
        '[EvaluationRepository] Offline: Attempting to read/calculate evaluations.',
      );
      final cachedJson = await _hiveService.getJsonString(
        evaluationDashboardCacheBoxName,
        cacheKey,
      );
      if (cachedJson != null) {
        debugPrint(
          '[EvaluationRepository] Offline: Found cached evaluations for range.',
        );
        try {
          final decodedList = json.decode(cachedJson) as List<dynamic>;
          return decodedList
              .map((item) => Evaluation.fromJson(item as Map<String, dynamic>))
              .toList();
        } catch (parseError) {
          debugPrint(
            '[EvaluationRepository] Error parsing cached evaluations (offline): $parseError. Recalculating.',
          );
          // Fall through to recalculate if cache is corrupt
        }
      }

      debugPrint(
        '[EvaluationRepository] Offline: No valid cache. Calculating evaluations locally.',
      );
      final cachedTransactions = await _transactionRepository
          .getCachedTransactionList();
      final inRange = cachedTransactions
          .where(
            (t) =>
                !t.date.isBefore(startDate) &&
                !t.date.isAfter(
                  endDate
                      .add(const Duration(days: 1))
                      .subtract(const Duration(microseconds: 1)),
                ),
          )
          .toList();

      if (inRange.isEmpty && cachedTransactions.isNotEmpty) {
        debugPrint(
          '[EvaluationRepository-OFFLINE] No cached transactions in the selected date range for dashboard.',
        );
      } else if (cachedTransactions.isEmpty) {
        debugPrint(
          '[EvaluationRepository-OFFLINE] No cached transactions available at all.',
        );
      }

      final offlineEvaluations = evaluationDefinitions().map((def) {
        final v = def.compute(
          inRange,
        ); // Uses client-side evaluation_calculator
        return Evaluation(
          id: def.id, // Client-side ID '0', '1', etc.
          title: def.title,
          yourValue: v,
          idealText: def.idealText,
          status: def.isIdeal(v)
              ? EvaluationStatusModel.ideal
              : EvaluationStatusModel.notIdeal,
          calculatedAt: DateTime.now(),
          // backendRatioCode and backendEvaluationResultId will be null for offline calculated
        );
      }).toList();

      // Cache these offline calculated results
      await _hiveService.putJsonString(
        evaluationDashboardCacheBoxName,
        cacheKey,
        json.encode(offlineEvaluations.map((e) => e.toJson()).toList()),
      );
      debugPrint(
        '[EvaluationRepository-OFFLINE] Calculated and cached ${offlineEvaluations.length} items.',
      );
      return offlineEvaluations;
    }
  }

  Future<Evaluation> getDetail({
    required DateTime startDate,
    required DateTime endDate, // Context for offline calculation
    String?
    evaluationResultDbId, // For online: ID of the EvaluationResult record from DB
    String?
    clientRatioId, // For offline: client-side ID '0', '1', etc. from RatioDef
  }) async {
    final isOnline = await _connectivityService.isOnline;
    if (isOnline && evaluationResultDbId != null) {
      debugPrint(
        '[EvaluationRepository] Online: Calling service for evaluation detail ID: $evaluationResultDbId.',
      );
      // No caching for individual detail here, assumes it's always fetched if online.
      // Could cache if details are frequently accessed and rarely change.
      return _service.fetchEvaluationDetail(evaluationResultDbId);
    } else if (!isOnline && clientRatioId != null) {
      debugPrint(
        '[EvaluationRepository] Offline: Calculating evaluation detail locally for ratio $clientRatioId.',
      );
      final cachedTransactions = await _transactionRepository
          .getCachedTransactionList();
      final inRange = cachedTransactions
          .where(
            (t) =>
                !t.date.isBefore(startDate) &&
                !t.date.isAfter(
                  endDate
                      .add(const Duration(days: 1))
                      .subtract(const Duration(microseconds: 1)),
                ),
          )
          .toList();

      final ratioDef = evaluationDefinitions().firstWhere(
        (def) => def.id == clientRatioId,
        orElse: () => throw Exception(
          'Offline: Client-side RatioDef not found for ID $clientRatioId',
        ),
      );

      final value = ratioDef.compute(inRange);
      final conceptualSums = _computeEvaluationConceptualSums(inRange);
      final breakdown = <ConceptualComponentValue>[];
      // Mapping logic for breakdown based on clientRatioId (as detailed in previous response)
      if (clientRatioId == '0') {
        breakdown
          ..add(
            ConceptualComponentValue(
              name: 'Total Aset Likuid (Numerator)',
              value: conceptualSums.liquid,
            ),
          )
          ..add(
            ConceptualComponentValue(
              name: 'Total Pengeluaran Bulanan (Denominator)',
              value: conceptualSums.expense,
            ),
          );
      } else if (clientRatioId == '1') {
        breakdown
          ..add(
            ConceptualComponentValue(
              name: 'Total Aset Likuid (Numerator)',
              value: conceptualSums.liquid,
            ),
          )
          ..add(
            ConceptualComponentValue(
              name: 'Total Kekayaan Bersih (Denominator)',
              value: conceptualSums.netWorth,
            ),
          );
      } else if (clientRatioId == '2') {
        breakdown
          ..add(
            ConceptualComponentValue(
              name: 'Total Utang (Numerator)',
              value: conceptualSums.liabilities,
            ),
          )
          ..add(
            ConceptualComponentValue(
              name: 'Total Aset (Denominator)',
              value: conceptualSums.totalAssets,
            ),
          );
      } else if (clientRatioId == '3') {
        breakdown
          ..add(
            ConceptualComponentValue(
              name: 'Total Tabungan (Numerator)',
              value: conceptualSums.savings,
            ),
          )
          ..add(
            ConceptualComponentValue(
              name: 'Penghasilan Kotor (Denominator)',
              value: conceptualSums.income,
            ),
          );
      } else if (clientRatioId == '4') {
        breakdown
          ..add(
            ConceptualComponentValue(
              name: 'Total Pembayaran Utang Bulanan (Numerator)',
              value: conceptualSums.debtPayments,
            ),
          )
          ..add(
            ConceptualComponentValue(
              name: 'Penghasilan Bersih (Denominator)',
              value: conceptualSums.netIncome,
            ),
          );
      } else if (clientRatioId == '5') {
        breakdown
          ..add(
            ConceptualComponentValue(
              name: 'Total Aset Diinvestasikan (Numerator)',
              value: conceptualSums.invested,
            ),
          )
          ..add(
            ConceptualComponentValue(
              name: 'Total Kekayaan Bersih (Denominator)',
              value: conceptualSums.netWorth,
            ),
          );
      } else if (clientRatioId == '6') {
        breakdown
          ..add(
            ConceptualComponentValue(
              name: 'Total Kekayaan Bersih (Numerator)',
              value: conceptualSums.netWorth,
            ),
          )
          ..add(
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
        idealText: ratioDef.idealText,
        breakdown: breakdown,
        status: ratioDef.isIdeal(value)
            ? EvaluationStatusModel.ideal
            : EvaluationStatusModel.notIdeal,
        calculatedAt: DateTime.now(),
      );
    } else {
      throw Exception(
        'Cannot get detail: Insufficient parameters for current online/offline state, or evaluationResultDbId missing for online mode.',
      );
    }
  }

  Future<List<History>> getEvaluationHistory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final isOnline = await _connectivityService.isOnline;
    // Cache key for raw EvaluationResult data (list of EvaluationModel)
    // A simple key for "all history" or date-range based if feasible. For now, one key.
    const historyCacheKey = 'all_evaluation_results_for_history_v1';

    var allHistoricalResults = <Evaluation>[];

    if (isOnline) {
      try {
        debugPrint(
          '[EvaluationRepository] Online: Calling service for raw evaluation history results.',
        );
        // This service call should ideally fetch ALL EvaluationResult items for the user,
        // or those within a broad default range if not specified.
        // The backend endpoint /evaluations/history should return List<PopulatedEvaluationResult>
        allHistoricalResults = await _service
            .fetchRawEvaluationResultsForHistory(
              // NEW SERVICE METHOD
              startDate: startDate,
              endDate: endDate,
            );

        // Cache these raw results
        await _hiveService.putJsonString(
          evaluationResultsCacheBoxName,
          historyCacheKey,
          json.encode(allHistoricalResults.map((e) => e.toJson()).toList()),
        );
      } catch (e) {
        debugPrint(
          '[EvaluationRepository] Online fetch for history results failed, trying cache: $e',
        );
        final cachedJson = await _hiveService.getJsonString(
          evaluationResultsCacheBoxName,
          historyCacheKey,
        );
        if (cachedJson != null) {
          try {
            final decodedList = json.decode(cachedJson) as List<dynamic>;
            allHistoricalResults = decodedList
                .map(
                  (item) => Evaluation.fromJson(item as Map<String, dynamic>),
                )
                .toList();
          } catch (parseError) {
            debugPrint('Error parsing cached history results: $parseError');
          }
        }
        if (allHistoricalResults.isEmpty && e is EvaluationApiException) {
          rethrow;
        }
        if (allHistoricalResults.isEmpty) {
          throw EvaluationApiException(
            'Failed online, no cache for history data.',
          );
        }
      }
    } else {
      debugPrint(
        '[EvaluationRepository] Offline: Reading raw evaluation history results from cache.',
      );
      final cachedJson = await _hiveService.getJsonString(
        evaluationResultsCacheBoxName,
        historyCacheKey,
      );
      if (cachedJson != null) {
        try {
          final decodedList = json.decode(cachedJson) as List<dynamic>;
          allHistoricalResults = decodedList
              .map((item) => Evaluation.fromJson(item as Map<String, dynamic>))
              .toList();
        } catch (parseError) {
          debugPrint(
            'Error parsing cached history results (offline): $parseError',
          );
        }
      }
      if (allHistoricalResults.isEmpty) {
        debugPrint(
          '[EvaluationRepository] Offline: No cached evaluation results for history.',
        );
        return [];
      }
    }

    // Now, aggregate `allHistoricalResults` (List<EvaluationModel>) into List<HistoryModel>
    if (allHistoricalResults.isEmpty) return [];

    // Group by periodId
    final groupedByPeriod = groupBy<Evaluation, String>(
      allHistoricalResults,
      (result) => result.periodId ?? '',
    );

    final historySummaries = <History>[];

    for (final periodIdEntry in groupedByPeriod.entries) {
      final periodId = periodIdEntry.key;
      final resultsForPeriod = periodIdEntry.value;
      if (resultsForPeriod.isEmpty) continue;

      // Fetch period details for start/end dates (must be cached by PeriodRepository)
      final periodDetails = await _periodRepository.getCachedPeriodById(
        periodId,
      );
      if (periodDetails == null) {
        debugPrint(
          '[EvaluationRepository] Warning: Period details for $periodId not found in cache. Skipping history entry.',
        );
        continue;
      }

      var idealCount = 0;
      var notIdealCount = 0;
      var incompleteCount = 0;

      for (final result in resultsForPeriod) {
        switch (result.status) {
          case EvaluationStatusModel.ideal:
            idealCount++;
          case EvaluationStatusModel.notIdeal:
            notIdealCount++;
          case EvaluationStatusModel.incomplete:
            incompleteCount++;
        }
      }
      historySummaries.add(
        History(
          start: periodDetails.startDate,
          end: periodDetails.endDate,
          ideal: idealCount,
          notIdeal: notIdealCount,
          incomplete: incompleteCount,
        ),
      );
    }

    historySummaries.sort(
      (a, b) => b.start.compareTo(a.start),
    ); // Sort by period start date, newest first
    return historySummaries;
  }
}
