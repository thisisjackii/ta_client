// lib/features/budgeting/repositories/budgeting_repository.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ta_client/core/services/connectivity_service.dart';
import 'package:ta_client/core/services/service_locator.dart'; // For sl
import 'package:ta_client/features/budgeting/repositories/period_repository.dart'; // Import PeriodRepository
// Models and DTOs from budgeting_service.dart or dedicated model files
import 'package:ta_client/features/budgeting/services/budgeting_service.dart';
import 'package:ta_client/features/transaction/repositories/transaction_hierarchy_repository.dart';
import 'package:ta_client/features/transaction/repositories/transaction_repository.dart'; // For offline transactions

class BudgetingRepository {
  BudgetingRepository(
    this._service,
    this._transactionRepository,
    this._periodRepository, // Inject PeriodRepository
  ) {
    _connectivityService = sl<ConnectivityService>();
    _initHiveBoxes(); // Ensure boxes are initialized
  }

  final BudgetingService _service;
  final TransactionRepository _transactionRepository;
  final PeriodRepository _periodRepository; // Use injected PeriodRepository
  late ConnectivityService _connectivityService;

  // Hive Box Names
  static const String _incomeSummaryCacheBoxName =
      'budgetingIncomeSummaryCache_v1'; // Version cache keys
  static const String _expenseSuggestionsCacheBoxName =
      'budgetingExpenseSuggestionsCache_v1';
  static const String _savedAllocationsCacheBoxName =
      'budgetingSavedAllocationsCache_v1';
  static const String _pendingBudgetPlansBoxName = 'budgetingPendingPlans_v1';

  // Initialize Hive boxes for budgeting data
  Future<void> _initHiveBoxes() async {
    await Future.wait([
      if (!Hive.isBoxOpen(_incomeSummaryCacheBoxName))
        Hive.openBox<String>(_incomeSummaryCacheBoxName),
      if (!Hive.isBoxOpen(_expenseSuggestionsCacheBoxName))
        Hive.openBox<String>(_expenseSuggestionsCacheBoxName),
      if (!Hive.isBoxOpen(_savedAllocationsCacheBoxName))
        Hive.openBox<String>(_savedAllocationsCacheBoxName),
      if (!Hive.isBoxOpen(_pendingBudgetPlansBoxName))
        Hive.openBox<String>(_pendingBudgetPlansBoxName),
    ]);
  }

  // --- Income Summary ---
  Future<List<BackendIncomeSummaryItem>> getSummarizedIncomeForPeriod(
    String periodId,
  ) async {
    final period = await _periodRepository.getCachedPeriodById(periodId);

    if (period == null) {
      debugPrint(
        '[BudgetingRepository] Period details not found for periodId $periodId to get income summary.',
      );
      throw BudgetingApiException(
        'Period details not found locally for income summary. Ensure period is selected/created.',
      );
    }

    final isOnline = await _connectivityService.isOnline;
    final cacheKey = 'incomeSummary_$periodId';
    final box = Hive.box<String>(_incomeSummaryCacheBoxName);

    if (isOnline) {
      try {
        debugPrint(
          '[BudgetingRepository] Online: Fetching income summary from service for period $periodId.',
        );
        final summary = await _service.fetchSummarizedIncomeForPeriod(periodId);
        await box.put(
          cacheKey,
          json.encode(summary.map((s) => s.toJson()).toList()),
        );
        return summary;
      } catch (e) {
        debugPrint(
          '[BudgetingRepository] Online fetch failed for income summary, trying cache: $e',
        );
        final cachedJson = box.get(cacheKey);
        if (cachedJson != null) {
          final decoded = json.decode(cachedJson) as List<dynamic>;
          return decoded
              .map(
                (item) => BackendIncomeSummaryItem.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList();
        }
        if (e is BudgetingApiException) rethrow;
        throw BudgetingApiException(
          'Failed online, no cache for income summary.',
        );
      }
    } else {
      // OFFLINE
      debugPrint(
        '[BudgetingRepository] Offline: Attempting to calculate/read income summary for period $periodId.',
      );
      final cachedJson = box.get(cacheKey);
      if (cachedJson != null) {
        debugPrint(
          '[BudgetingRepository] Offline: Found cached income summary.',
        );
        final decoded = json.decode(cachedJson) as List<dynamic>;
        return decoded
            .map(
              (item) => BackendIncomeSummaryItem.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();
      }

      debugPrint(
        '[BudgetingRepository] Offline: No cache. Calculating income summary from local transactions.',
      );
      final cachedTransactions =
          _transactionRepository.getCachedTransactionList() ?? [];

      final inRangeIncomeTransactions = cachedTransactions
          .where(
            (t) =>
                !t.date.isBefore(period.startDate) &&
                !t.date.isAfter(
                  period.endDate
                      .add(const Duration(days: 1))
                      .subtract(const Duration(microseconds: 1)),
                ) &&
                t.accountTypeName?.toLowerCase() ==
                    'pemasukan', // Ensure Transaction model has accountTypeName
          )
          .toList();

      if (inRangeIncomeTransactions.isEmpty) {
        debugPrint(
          '[BudgetingRepository] Offline: No relevant cached income transactions in range for period $periodId.',
        );
        return [];
      }

      final subcategoryTotals = <String, double>{};
      final subcategoryIdToNameMap = <String, String>{};
      final subcategoryIdToParentCategoryIdMap = <String, String>{};
      final categoryIdToNameMap = <String, String>{};

      for (final tx in inRangeIncomeTransactions) {
        // These fields must exist on your hydrated Transaction model from cache
        final subId = tx.subcategoryId;
        final subName = tx.subcategoryName!;
        final catId = tx.categoryId!;
        final catName = tx.categoryName!;

        subcategoryTotals[subId] = (subcategoryTotals[subId] ?? 0) + tx.amount;
        subcategoryIdToNameMap.putIfAbsent(subId, () => subName);
        subcategoryIdToParentCategoryIdMap.putIfAbsent(subId, () => catId);
        categoryIdToNameMap.putIfAbsent(catId, () => catName);
      }

      final finalSummaryMap = <String, BackendIncomeSummaryItem>{};
      subcategoryTotals.forEach((subId, totalAmount) {
        final parentCatId = subcategoryIdToParentCategoryIdMap[subId]!;
        final parentCatName = categoryIdToNameMap[parentCatId]!;
        final subName = subcategoryIdToNameMap[subId]!;

        finalSummaryMap.putIfAbsent(
          parentCatId,
          () => BackendIncomeSummaryItem(
            categoryId: parentCatId,
            categoryName: parentCatName,
            subcategories: [],
            categoryTotalAmount: 0,
          ),
        );

        finalSummaryMap[parentCatId]!.subcategories.add(
          BackendSubcategoryIncome(
            subcategoryId: subId,
            subcategoryName: subName,
            totalAmount: totalAmount,
          ),
        );
        finalSummaryMap[parentCatId]!.categoryTotalAmount += totalAmount;
      });

      debugPrint(
        '[BudgetingRepository] Offline: Calculated income summary with ${finalSummaryMap.length} categories.',
      );
      return finalSummaryMap.values.toList();
    }
  }

  // --- Expense Category Suggestions ---
  Future<List<BackendExpenseCategorySuggestion>>
  getExpenseCategorySuggestions() async {
    final isOnline = await _connectivityService.isOnline;
    const cacheKey = 'expenseCategorySuggestions_v1';
    final box = Hive.box<String>(_expenseSuggestionsCacheBoxName);

    if (isOnline) {
      try {
        debugPrint(
          '[BudgetingRepository] Online: Fetching expense category suggestions from service.',
        );
        final suggestions = await _service.fetchExpenseCategorySuggestions();
        await box.put(
          cacheKey,
          json.encode(suggestions.map((s) => s.toJson()).toList()),
        );
        return suggestions;
      } catch (e) {
        debugPrint(
          '[BudgetingRepository] Online fetch failed for expense suggestions, trying cache: $e',
        );
        final cachedJson = box.get(cacheKey);
        if (cachedJson != null) {
          final decoded = json.decode(cachedJson) as List<dynamic>;
          return decoded
              .map(
                (item) => BackendExpenseCategorySuggestion.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList();
        }
        if (e is BudgetingApiException) rethrow;
        throw BudgetingApiException(
          'Failed to fetch expense suggestions online and no cache.',
        );
      }
    } else {
      debugPrint(
        '[BudgetingRepository] Offline: Reading expense category suggestions from cache.',
      );
      final cachedJson = box.get(cacheKey);
      if (cachedJson != null) {
        final decoded = json.decode(cachedJson) as List<dynamic>;
        return decoded
            .map(
              (item) => BackendExpenseCategorySuggestion.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();
      }
      debugPrint(
        '[BudgetingRepository] Offline: No cached expense suggestions. Returning empty. Consider seeding defaults.',
      );
      return [];
    }
  }

  // --- Save/Fetch Budget Allocations ---
  Future<List<FrontendBudgetAllocation>> saveExpenseAllocations(
    SaveExpenseAllocationsRequestDto dto,
  ) async {
    final isOnline = await _connectivityService.isOnline;
    final periodCacheKeyForSaved = 'allocations_${dto.budgetPeriodId}';
    final savedAllocationsBox = Hive.box<String>(_savedAllocationsCacheBoxName);
    final pendingBox = Hive.box<String>(_pendingBudgetPlansBoxName);

    if (isOnline) {
      try {
        debugPrint(
          '[BudgetingRepository] Online: Saving expense allocations via service for period ${dto.budgetPeriodId}.',
        );
        final savedAllocations = await _service.saveExpenseAllocations(dto);
        await savedAllocationsBox.put(
          periodCacheKeyForSaved,
          json.encode(savedAllocations.map((a) => a.toJson()).toList()),
        );
        await pendingBox.delete(dto.budgetPeriodId);
        return savedAllocations;
      } catch (e) {
        debugPrint(
          '[BudgetingRepository] Online save failed, queuing budget plan for period ${dto.budgetPeriodId}: $e',
        );
        await pendingBox.put(dto.budgetPeriodId, json.encode(dto.toJson()));
        if (e is BudgetingApiException) rethrow; // Re-throw to BLoC
        throw BudgetingApiException(
          'Failed to save budget online, queued for later sync.',
        );
      }
    } else {
      debugPrint(
        '[BudgetingRepository] Offline: Queuing budget plan for period ${dto.budgetPeriodId}.',
      );
      await pendingBox.put(dto.budgetPeriodId, json.encode(dto.toJson()));

      // Optimistically construct what the UI might show for the offline plan
      // This requires knowing category/subcategory names, which might not be in the DTO.
      // For a truly reflective UI, you'd need to fetch those names from cached hierarchy data.
      // For now, we'll throw an exception indicating it's queued, and UI can reflect that.
      throw BudgetingApiException(
        'Offline: Budget plan for period ${dto.budgetPeriodId} queued. Displaying this plan may require local data.',
      );
    }
  }

  Future<List<FrontendBudgetAllocation>> getBudgetAllocationsForPeriod(
    String periodId,
  ) async {
    final isOnline = await _connectivityService.isOnline;
    final periodCacheKey = 'allocations_$periodId';
    final savedAllocationsBox = Hive.box<String>(_savedAllocationsCacheBoxName);
    final pendingBox = Hive.box<String>(_pendingBudgetPlansBoxName);

    final pendingPlanJson = pendingBox.get(periodId);
    if (pendingPlanJson != null) {
      debugPrint(
        '[BudgetingRepository] Found pending (offline) budget plan for period $periodId. Attempting to display.',
      );
      try {
        final dto = SaveExpenseAllocationsRequestDto.fromJson(
          json.decode(pendingPlanJson) as Map<String, dynamic>,
        );
        // This is an optimistic display. Actual IDs and potentially enriched names will come after sync.
        final optimisticList = <FrontendBudgetAllocation>[];
        // Fetch category/subcategory names from a local cache/source if possible
        // For now, using placeholders or assuming DTO might have names (which it doesn't)
        var tempIdCounter = 0;
        for (final allocDetail in dto.allocations) {
          final category = await sl<TransactionHierarchyRepository>()
              .getCachedCategoryById(allocDetail.categoryId);
          final categoryName = category?.name ?? 'Category...';
          final categoryAllocatedAmount =
              (allocDetail.percentage / 100) * dto.totalBudgetableIncome;
          for (final subId in allocDetail.selectedSubcategoryIds) {
            final subcategory = await sl<TransactionHierarchyRepository>()
                .getCachedSubcategoryById(subId);
            final subcategoryName = subcategory?.name ?? 'Subcategory...';
            optimisticList.add(
              FrontendBudgetAllocation(
                id: 'local_alloc_${tempIdCounter++}', // Temporary local ID
                periodId: dto.budgetPeriodId,
                categoryId: allocDetail.categoryId,
                categoryName: categoryName,
                subcategoryId: subId,
                subcategoryName: subcategoryName,
                percentage: allocDetail.percentage,
                amount: categoryAllocatedAmount,
              ),
            );
          }
        }
        return optimisticList;
      } catch (e) {
        debugPrint(
          '[BudgetingRepository] Error deserializing/displaying pending plan for $periodId, falling back: $e',
        );
        // Fall through to try saved allocations cache or online fetch
      }
    }

    if (isOnline) {
      try {
        final allocations = await _service.fetchBudgetAllocationsForPeriod(
          periodId,
        );
        await savedAllocationsBox.put(
          periodCacheKey,
          json.encode(allocations.map((a) => a.toJson()).toList()),
        );
        return allocations;
      } catch (e) {
        final cachedJson = savedAllocationsBox.get(periodCacheKey);
        if (cachedJson != null) {
          final decoded = json.decode(cachedJson) as List<dynamic>;
          return decoded
              .map(
                (item) => FrontendBudgetAllocation.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList();
        }
        if (e is BudgetingApiException) rethrow;
        throw BudgetingApiException('Failed online, no cache for allocations.');
      }
    } else {
      final cachedJson = savedAllocationsBox.get(periodCacheKey);
      if (cachedJson != null) {
        final decoded = json.decode(cachedJson) as List<dynamic>;
        return decoded
            .map(
              (item) => FrontendBudgetAllocation.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();
      }
      debugPrint(
        '[BudgetingRepository] Offline: No cached saved allocations for period $periodId.',
      );
      return [];
    }
  }

  Future<void> syncPendingBudgetPlans() async {
    final pendingBox = Hive.box<String>(_pendingBudgetPlansBoxName);
    if (pendingBox.isEmpty) {
      debugPrint('[BudgetingRepository] No pending budget plans to sync.');
      return;
    }
    final isOnline = await _connectivityService.isOnline;
    if (!isOnline) {
      debugPrint(
        '[BudgetingRepository] Offline, cannot sync pending budget plans.',
      );
      return;
    }

    debugPrint(
      '[BudgetingRepository] Syncing ${pendingBox.length} pending budget plans.',
    );
    final successfullySyncedKeys = <String>[];
    final savedAllocationsBox = Hive.box<String>(_savedAllocationsCacheBoxName);

    for (final entry in pendingBox.toMap().entries) {
      final periodIdKey = entry.key as String; // This is the budgetPeriodId
      final planJson = entry.value;
      try {
        final dto = SaveExpenseAllocationsRequestDto.fromJson(
          json.decode(planJson) as Map<String, dynamic>,
        );
        final syncedAllocations = await _service.saveExpenseAllocations(dto);

        // Cache the newly synced allocations using the correct periodId from the DTO
        final periodCacheKey = 'allocations_${dto.budgetPeriodId}';
        await savedAllocationsBox.put(
          periodCacheKey,
          json.encode(syncedAllocations.map((a) => a.toJson()).toList()),
        );

        successfullySyncedKeys.add(periodIdKey);
        debugPrint(
          '[BudgetingRepository] Successfully synced budget plan for period $periodIdKey.',
        );
      } catch (e) {
        debugPrint(
          '[BudgetingRepository] Failed to sync budget plan for period $periodIdKey: $e. It will remain in queue.',
        );
      }
    }
    for (final key in successfullySyncedKeys) {
      await pendingBox.delete(key);
    }
    if (successfullySyncedKeys.isNotEmpty) {
      debugPrint(
        '[BudgetingRepository] Cleaned ${successfullySyncedKeys.length} synced budget plans from queue.',
      );
    }
  }

  // Client-side validation helper (can be static or moved to a utility)
  static void validatePeriodDatesLogic(
    DateTime? s,
    DateTime? e, {
    bool forBudgeting = true,
  }) {
    if (s == null || e == null) {
      throw ArgumentError('Tanggal mulai dan akhir harus diisi.');
    }
    if (e.isBefore(s)) {
      throw ArgumentError('Tanggal akhir tidak boleh sebelum tanggal mulai.');
    }
    if (forBudgeting) {
      final diff = e.difference(s).inDays;
      // Allow up to roughly a month. PSPEC used "> 31" as error.
      // For 1 month exactly, diff can be 27 to 30 depending on month.
      // Let's use a slightly more flexible check, e.g., up to 35 days to accommodate "one month" idea.
      if (diff > 35) {
        // Or use a more precise month diff calculation if needed.
        throw ArgumentError(
          'Rentang periode anggaran tidak boleh lebih dari sekitar satu bulan.',
        );
      }
    }
  }
}
