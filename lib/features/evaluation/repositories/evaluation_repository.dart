// lib/features/evaluation/repositories/evaluation_repository.dart
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:ta_client/core/services/connectivity_service.dart';
import 'package:ta_client/core/services/hive_service.dart';
import 'package:ta_client/core/services/service_locator.dart';
// No longer need PeriodRepository here if evaluations are purely ad-hoc by date
// import 'package:ta_client/features/budgeting/repositories/period_repository.dart';
import 'package:ta_client/features/evaluation/models/evaluation.dart';
import 'package:ta_client/features/evaluation/models/history.dart';
import 'package:ta_client/features/evaluation/services/evaluation_service.dart';
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
  EvaluationRepository(this._service, this._transactionRepository)
    : _connectivityService = sl<ConnectivityService>(),
      _hiveService = sl<HiveService>();

  final EvaluationService _service;
  final TransactionRepository _transactionRepository;
  final ConnectivityService _connectivityService;
  final HiveService _hiveService;

  static const String evaluationDashboardCacheBoxName =
      'evaluationDashboardCache_v2';
  static const String evaluationResultsCacheBoxName =
      'evaluationResultsCache_v2';

  String _getDashboardCacheKey(DateTime startDate, DateTime endDate) {
    final startKey = DateFormat('yyyy-MM-dd').format(startDate);
    final endKey = DateFormat('yyyy-MM-dd').format(endDate);
    return 'eval_dashboard_${startKey}_to_$endKey';
  }

  Future<List<Evaluation>> getDashboardItems({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final isOnline = await _connectivityService.isOnline;
    final cacheKey = _getDashboardCacheKey(startDate, endDate);

    if (isOnline) {
      try {
        debugPrint(
          '[EvaluationRepository] Online: Calling service to calculate/fetch evaluations for dates: $startDate - $endDate.',
        );
        final evaluations = await _service
            .calculateAndFetchEvaluationsForDateRange(
              startDate: startDate,
              endDate: endDate,
            );

        // NEW: Check if all returned evaluations are essentially "empty"
        final allAreEffectivelyEmpty =
            evaluations.isNotEmpty &&
            evaluations.every(
              (e) =>
                  e.yourValue == 0.0 &&
                  e.status == EvaluationStatusModel.incomplete,
            );
        // You might need a more robust check for "effectively empty" based on how backend signals this.
        // For instance, if backend always returns 7 items even with no data, and they all have value 0 and status INCOMPLETE/NOT_IDEAL,
        // then this condition could work.

        if (allAreEffectivelyEmpty) {
          debugPrint(
            '[EvaluationRepository] Online: Backend returned evaluations, but all appear to be zero/incomplete. Treating as no data for this period.',
          );
          await _hiveService.putJsonString(
            evaluationDashboardCacheBoxName,
            cacheKey,
            json.encode([]), // Cache an empty list
          );
          return []; // Return empty list
        }

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
      // OFFLINE LOGIC
      debugPrint(
        '[EvaluationRepository] Offline: Attempting to read/calculate evaluations for $startDate - $endDate.',
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
        '[EvaluationRepository] Offline: No valid cache or cache parsing failed. Calculating evaluations locally.',
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

      if (inRange.isEmpty) {
        debugPrint(
          '[EvaluationRepository-OFFLINE] No transactions found in the selected date range ($startDate - $endDate). Returning empty dashboard items and caching empty list for this range.',
        );
        // Cache an empty list for this range to reflect no data for this period
        await _hiveService.putJsonString(
          evaluationDashboardCacheBoxName,
          cacheKey,
          json.encode([]), // Cache empty list
        );
        return []; // Return empty list
      }

      // If inRange is not empty, proceed to calculate
      final offlineEvaluations = evaluationDefinitions().map((def) {
        final v = def.compute(inRange);
        return Evaluation(
          id: def.id, // This is the client-side numeric ID (e.g., '0', '1')
          title: def.title,
          yourValue: v,
          idealText: def.idealText,
          isIdeal: def.isIdeal(v),
          status: def.isIdeal(v)
              ? EvaluationStatusModel.ideal
              : EvaluationStatusModel.notIdeal,
          calculatedAt: DateTime.now(),
          startDate: startDate,
          endDate: endDate,
          backendRatioCode: def.backendCode,
        );
      }).toList();
      await _hiveService.putJsonString(
        evaluationDashboardCacheBoxName,
        cacheKey,
        json.encode(offlineEvaluations.map((e) => e.toJson()).toList()),
      );
      debugPrint(
        '[EvaluationRepository-OFFLINE] Calculated and cached ${offlineEvaluations.length} items for range $startDate - $endDate.',
      );
      return offlineEvaluations;
    }
  }

  Future<Evaluation> getDetail({
    required DateTime startDate, // For offline context
    required DateTime endDate, // For offline context
    String? evaluationResultDbId, // Backend ID of an EvaluationResult
    String? clientRatioId, // Client-side '0'-'6' (Ratio.id)
  }) async {
    final isOnline = await _connectivityService.isOnline;

    // Prioritize online fetch if a backend ID is available
    if (evaluationResultDbId != null) {
      if (isOnline) {
        debugPrint(
          '[EvaluationRepository] Online: Calling service for evaluation detail (DB ID): $evaluationResultDbId.',
        );
        return _service.fetchEvaluationDetail(evaluationResultDbId);
      } else {
        debugPrint(
          '[EvaluationRepository] Offline: Trying to find cached detail for DB ID: $evaluationResultDbId.',
        );
        final cachedDashboardJson = await _hiveService.getJsonString(
          evaluationDashboardCacheBoxName,
          _getDashboardCacheKey(startDate, endDate),
        );
        if (cachedDashboardJson != null) {
          try {
            final decodedList =
                json.decode(cachedDashboardJson) as List<dynamic>;
            final cachedEvaluation = decodedList
                .map(
                  (item) => Evaluation.fromJson(item as Map<String, dynamic>),
                )
                .firstWhereOrNull(
                  (e) => e.backendEvaluationResultId == evaluationResultDbId,
                );
            if (cachedEvaluation != null) {
              debugPrint(
                '[EvaluationRepository] Found cached evaluation by DB ID. Recalculating breakdown for detail.',
              );
              // If found, we can use its backendRatioCode and other data to regenerate a full Evaluation object
              // including breakdown, which might not be fully cached in the dashboard item itself.
              final ratioDef = evaluationDefinitions().firstWhere(
                (def) => def.backendCode == cachedEvaluation.backendRatioCode,
                orElse: () => throw Exception(
                  'Client-side RatioDef not found for backend code ${cachedEvaluation.backendRatioCode} when using cached DB ID.',
                ),
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

              final value = ratioDef.compute(inRange);
              final conceptualSums = _computeEvaluationConceptualSums(inRange);
              final breakdown = <ConceptualComponentValue>[];

              // Populate breakdown based on the ratioDef.id (client-side ID)
              _populateBreakdown(ratioDef.id, conceptualSums, breakdown);

              return Evaluation(
                id: ratioDef.id, // Client-side numeric ID
                title: ratioDef.title,
                yourValue: value,
                isIdeal: ratioDef.isIdeal(value),
                idealText: ratioDef.idealText,
                breakdown: breakdown.isNotEmpty ? breakdown : null,
                status: ratioDef.isIdeal(value)
                    ? EvaluationStatusModel.ideal
                    : EvaluationStatusModel.notIdeal,
                calculatedAt: DateTime.now(),
                startDate: startDate,
                endDate: endDate,
                backendRatioCode: ratioDef.backendCode,
                backendEvaluationResultId:
                    cachedEvaluation.backendEvaluationResultId,
              );
            }
          } catch (e) {
            debugPrint(
              '[EvaluationRepository] Error parsing cached dashboard for detail: $e',
            );
          }
        }
        throw EvaluationApiException(
          'Offline: Evaluation detail for DB ID $evaluationResultDbId not found in cache.',
        );
      }
    }

    // If no backend ID, or offline and no backend ID was found/handled, then use clientRatioId for local calculation
    if (clientRatioId != null) {
      debugPrint(
        '[EvaluationRepository] Calculating evaluation detail locally for ratio $clientRatioId for period $startDate - $endDate.',
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

      // If inRange is empty for detail calculation, it implies no data for this specific ratio's components.
      // The compute function in RatioDef should handle empty list (e.g., return 0).
      // The breakdown will also be based on these (likely zero) sums.

      final ratioDef = evaluationDefinitions().firstWhere(
        (def) =>
            def.id ==
            clientRatioId, // This is where the clientRatioId must match
        orElse: () => throw Exception(
          'Client-side RatioDef not found for ID $clientRatioId',
        ),
      );

      final value = ratioDef.compute(inRange);
      final conceptualSums = _computeEvaluationConceptualSums(inRange);
      final breakdown = <ConceptualComponentValue>[];

      // Use a helper function to populate the breakdown to avoid code duplication
      _populateBreakdown(clientRatioId, conceptualSums, breakdown);

      return Evaluation(
        id: ratioDef.id,
        title: ratioDef.title,
        yourValue: value,
        isIdeal: ratioDef.isIdeal(value),
        idealText: ratioDef.idealText,
        breakdown: breakdown.isNotEmpty ? breakdown : null,
        status: ratioDef.isIdeal(value)
            ? EvaluationStatusModel.ideal
            : EvaluationStatusModel.notIdeal,
        calculatedAt: DateTime.now(),
        startDate: startDate,
        endDate: endDate,
        backendRatioCode: ratioDef.backendCode, // Crucial for consistency
      );
    } else {
      throw ArgumentError(
        'Cannot get detail: Either evaluationResultDbId or clientRatioId must be provided.',
      );
    }
  }

  // Helper function to populate breakdown components based on clientRatioId
  void _populateBreakdown(
    String clientRatioId,
    _EvaluationTxSums conceptualSums,
    List<ConceptualComponentValue> breakdown,
  ) {
    if (clientRatioId == '0') {
      breakdown
        ..add(
          ConceptualComponentValue(
            name: 'Total Aset Likuid',
            value: conceptualSums.liquid,
          ),
        )
        ..add(
          ConceptualComponentValue(
            name: 'Total Pengeluaran Bulanan',
            value: conceptualSums.expense,
          ),
        );
    } else if (clientRatioId == '1') {
      breakdown
        ..add(
          ConceptualComponentValue(
            name: 'Total Aset Likuid',
            value: conceptualSums.liquid,
          ),
        )
        ..add(
          ConceptualComponentValue(
            name: 'Total Kekayaan Bersih',
            value: conceptualSums.netWorth,
          ),
        );
    } else if (clientRatioId == '2') {
      breakdown
        ..add(
          ConceptualComponentValue(
            name: 'Total Utang',
            value: conceptualSums.liabilities,
          ),
        )
        ..add(
          ConceptualComponentValue(
            name: 'Total Aset',
            value: conceptualSums.totalAssets,
          ),
        );
    } else if (clientRatioId == '3') {
      breakdown
        ..add(
          ConceptualComponentValue(
            name: 'Total Tabungan',
            value: conceptualSums.savings,
          ),
        )
        ..add(
          ConceptualComponentValue(
            name: 'Penghasilan Kotor',
            value: conceptualSums.income,
          ),
        );
    } else if (clientRatioId == '4') {
      breakdown
        ..add(
          ConceptualComponentValue(
            name: 'Total Pembayaran Utang Bulanan',
            value: conceptualSums.debtPayments,
          ),
        )
        ..add(
          ConceptualComponentValue(
            name: 'Penghasilan Bersih',
            value: conceptualSums.netIncome,
          ),
        );
    } else if (clientRatioId == '5') {
      breakdown
        ..add(
          ConceptualComponentValue(
            name: 'Total Aset Diinvestasikan',
            value: conceptualSums.invested,
          ),
        )
        ..add(
          ConceptualComponentValue(
            name: 'Total Kekayaan Bersih',
            value: conceptualSums.netWorth,
          ),
        );
    } else if (clientRatioId == '6') {
      breakdown
        ..add(
          ConceptualComponentValue(
            name: 'Total Kekayaan Bersih',
            value: conceptualSums.netWorth,
          ),
        )
        ..add(
          ConceptualComponentValue(
            name: 'Total Aset',
            value: conceptualSums.totalAssets,
          ),
        );
    }
  }

  Future<List<History>> getEvaluationHistory({
    DateTime? startDate, // Optional filter for history start date
    DateTime? endDate, // Optional filter for history end date
  }) async {
    final isOnline = await _connectivityService.isOnline;
    const historyDataCacheKey = 'all_evaluation_results_for_history_v2';

    var allHistoricalRawResults = <Evaluation>[];

    if (isOnline) {
      try {
        debugPrint(
          '[EvaluationRepository] Online: Calling service for raw evaluation history results.',
        );
        allHistoricalRawResults = await _service
            .fetchRawEvaluationResultsForHistory(
              startDate: startDate,
              endDate: endDate,
            );
        await _hiveService.putJsonString(
          evaluationResultsCacheBoxName,
          historyDataCacheKey,
          json.encode(allHistoricalRawResults.map((e) => e.toJson()).toList()),
        );
      } catch (e) {
        // ... (try cache logic - same as before) ...
        debugPrint(
          '[EvaluationRepository] Online fetch for history results failed, trying cache: $e',
        );
        final cachedJson = await _hiveService.getJsonString(
          evaluationResultsCacheBoxName,
          historyDataCacheKey,
        );
        if (cachedJson != null) {
          try {
            final decodedList = json.decode(cachedJson) as List<dynamic>;
            allHistoricalRawResults = decodedList
                .map(
                  (item) => Evaluation.fromJson(item as Map<String, dynamic>),
                )
                .toList();
          } catch (parseError) {
            debugPrint('Error parsing cached history results: $parseError');
          }
        }
        if (allHistoricalRawResults.isEmpty && e is EvaluationApiException) {
          rethrow;
        }
        if (allHistoricalRawResults.isEmpty) {
          throw EvaluationApiException(
            'Failed online, no cache for history data.',
          );
        }
      }
    } else {
      // ... (offline cache reading - same as before) ...
      debugPrint(
        '[EvaluationRepository] Offline: Reading raw evaluation history results from cache.',
      );
      final cachedJson = await _hiveService.getJsonString(
        evaluationResultsCacheBoxName,
        historyDataCacheKey,
      );
      if (cachedJson != null) {
        try {
          final decodedList = json.decode(cachedJson) as List<dynamic>;
          allHistoricalRawResults = decodedList
              .map((item) => Evaluation.fromJson(item as Map<String, dynamic>))
              .toList();
        } catch (parseError) {
          debugPrint(
            'Error parsing cached history results (offline): $parseError',
          );
        }
      }
      if (allHistoricalRawResults.isEmpty) {
        debugPrint(
          '[EvaluationRepository] Offline: No cached evaluation results for history.',
        );
        return [];
      }
    }

    if (allHistoricalRawResults.isEmpty) return [];

    // Group by unique startDate-endDate pairs from the EvaluationResults
    final groupedByDateRange = groupBy<Evaluation, String>(
      allHistoricalRawResults,
      (result) {
        if (result.startDate != null && result.endDate != null) {
          return '${result.startDate!.toIso8601String()}_${result.endDate!.toIso8601String()}';
        }
        return 'unknown_range_${result.calculatedAt.millisecondsSinceEpoch}';
      },
    );

    final historySummaries = <History>[];
    for (final dateRangeKey in groupedByDateRange.keys) {
      final resultsForRange = groupedByDateRange[dateRangeKey]!;
      if (resultsForRange.isEmpty ||
          resultsForRange.first.startDate == null ||
          resultsForRange.first.endDate == null) {
        continue;
      }

      var idealCount = 0;
      var notIdealCount = 0;
      var incompleteCount = 0;
      for (final result in resultsForRange) {
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
          start: resultsForRange.first.startDate!,
          end: resultsForRange.first.endDate!,
          ideal: idealCount,
          notIdeal: notIdealCount,
          incomplete: incompleteCount,
        ),
      );
    }
    historySummaries.sort((a, b) => b.start.compareTo(a.start));
    return historySummaries;
  }

  Future<CheckExistingEvaluationResponse> checkExistingEvaluationForDates(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final isOnline = await _connectivityService.isOnline;
    if (isOnline) {
      try {
        return await _service.checkExistingEvaluationForDates(
          startDate,
          endDate,
        );
      } catch (e) {
        // Fallback or specific error handling if needed
        debugPrint('Error checking existing evaluation online: $e');
        return CheckExistingEvaluationResponse(
          exists: false,
        ); // Assume not exists on error
      }
    } else {
      // Offline check (more complex, might be simpler to just allow proceeding offline)
      // For an offline check, you'd iterate through cached `evaluationResultsCacheBoxName`
      // and see if any entry matches the startDate and endDate.
      debugPrint(
        'Offline: Cannot check for existing evaluation dates with server.',
      );
      return CheckExistingEvaluationResponse(
        exists: false,
      ); // Default to not exists when offline
    }
  }
}
