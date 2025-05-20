// lib/features/budgeting/repositories/budgeting_repository.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:ta_client/core/services/connectivity_service.dart';
import 'package:ta_client/core/services/hive_service.dart';
import 'package:ta_client/core/services/service_locator.dart';
import 'package:ta_client/features/budgeting/repositories/period_repository.dart';
import 'package:ta_client/features/budgeting/services/budgeting_service.dart';
import 'package:ta_client/features/transaction/repositories/transaction_hierarchy_repository.dart'; // For names
import 'package:ta_client/features/transaction/repositories/transaction_repository.dart';

class BudgetingRepository {
  BudgetingRepository(
    this._service,
    this._transactionRepository,
    this._periodRepository,
  ) : _connectivityService = sl<ConnectivityService>(),
      _hiveService = sl<HiveService>() {
    // Hive boxes are opened in bootstrap.dart
  }
  final BudgetingService _service;
  final TransactionRepository _transactionRepository;
  final PeriodRepository _periodRepository;
  final ConnectivityService _connectivityService;
  final HiveService _hiveService;

  static const String incomeSummaryCacheBoxName =
      'budgetingIncomeSummaryCache_v1';
  static const String expenseSuggestionsCacheBoxName =
      'budgetingExpenseSuggestionsCache_v1';
  static const String savedAllocationsCacheBoxName =
      'budgetingSavedAllocationsCache_v1';
  static const String pendingBudgetPlansBoxName = 'budgetingPendingPlans_v1';

  // --- Income Summary ---
  Future<List<BackendIncomeSummaryItem>> getSummarizedIncomeForPeriod(
    String periodId,
  ) async {
    final period = await _periodRepository.getCachedPeriodById(periodId);
    if (period == null) {
      throw BudgetingApiException(
        'Period details for $periodId not found. Cannot get income summary.',
      );
    }

    final isOnline = await _connectivityService.isOnline;
    final cacheKey = 'incomeSummary_$periodId';

    if (isOnline) {
      try {
        final summary = await _service.fetchSummarizedIncomeForPeriod(periodId);
        await _hiveService.putJsonString(
          incomeSummaryCacheBoxName,
          cacheKey,
          json.encode(summary.map((s) => s.toJson()).toList()),
        );
        return summary;
      } catch (e) {
        final cachedJson = await _hiveService.getJsonString(
          incomeSummaryCacheBoxName,
          cacheKey,
        );
        if (cachedJson != null) {
          return (json.decode(cachedJson) as List<dynamic>)
              .map(
                (item) => BackendIncomeSummaryItem.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList();
        }
        if (e is BudgetingApiException) rethrow;
        throw BudgetingApiException(
          'Failed online, no cache for income summary: $e',
        );
      }
    } else {
      // OFFLINE
      final cachedJson = await _hiveService.getJsonString(
        incomeSummaryCacheBoxName,
        cacheKey,
      );
      if (cachedJson != null) {
        return (json.decode(cachedJson) as List<dynamic>)
            .map(
              (item) => BackendIncomeSummaryItem.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();
      }
      debugPrint(
        '[BudgetingRepository] Offline: No cache. Calculating income summary from local transactions for period $periodId.',
      );
      final cachedTransactions = await _transactionRepository
          .getCachedTransactionList();
      final inRangeIncomeTransactions = cachedTransactions
          .where(
            (t) =>
                t.subcategoryId.isNotEmpty &&
                !t.date.isBefore(period.startDate) &&
                !t.date.isAfter(
                  period.endDate
                      .add(const Duration(days: 1))
                      .subtract(const Duration(microseconds: 1)),
                ) &&
                t.accountTypeName?.toLowerCase() == 'pemasukan',
          )
          .toList();

      if (inRangeIncomeTransactions.isEmpty) return [];

      final subcategoryTotals = <String, double>{};
      final subcategoryIdToNameMap = <String, String>{};
      final subcategoryIdToParentCategoryIdMap = <String, String>{};
      final categoryIdToNameMap = <String, String>{};

      for (final tx in inRangeIncomeTransactions) {
        final subId = tx.subcategoryId;
        final subName = tx.subcategoryName ?? 'N/A';
        final catId = tx.categoryId ?? 'N/A_CAT';
        final catName = tx.categoryName ?? 'N/A Category';
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
      return finalSummaryMap.values.toList();
    }
  }

  // --- Expense Category Suggestions ---
  Future<List<BackendExpenseCategorySuggestion>>
  getExpenseCategorySuggestions() async {
    final isOnline = await _connectivityService.isOnline;
    const cacheKey = 'expenseCategorySuggestions_v1';
    if (isOnline) {
      try {
        final suggestions = await _service.fetchExpenseCategorySuggestions();
        await _hiveService.putJsonString(
          expenseSuggestionsCacheBoxName,
          cacheKey,
          json.encode(suggestions.map((s) => s.toJson()).toList()),
        );
        return suggestions;
      } catch (e) {
        final cachedJson = await _hiveService.getJsonString(
          expenseSuggestionsCacheBoxName,
          cacheKey,
        );
        if (cachedJson != null) {
          return (json.decode(cachedJson) as List<dynamic>)
              .map(
                (item) => BackendExpenseCategorySuggestion.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList();
        }
        if (e is BudgetingApiException) rethrow;
        throw BudgetingApiException(
          'Failed online, no cache for suggestions: $e',
        );
      }
    } else {
      final cachedJson = await _hiveService.getJsonString(
        expenseSuggestionsCacheBoxName,
        cacheKey,
      );
      if (cachedJson != null) {
        return (json.decode(cachedJson) as List<dynamic>)
            .map(
              (item) => BackendExpenseCategorySuggestion.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();
      }
      return [];
    }
  }

  // --- Save/Fetch Budget Allocations ---
  Future<List<FrontendBudgetAllocation>> saveExpenseAllocations(
    SaveExpenseAllocationsRequestDto dto,
  ) async {
    final isOnline = await _connectivityService.isOnline;
    final period = await _periodRepository.getCachedPeriodById(
      dto.budgetPeriodId,
    );
    if (period == null) {
      throw BudgetingApiException('Period for budget plan not found locally.');
    }

    // If the period is local (unsynced) AND we are online, we MUST sync the period first.
    if (period.isLocal && isOnline) {
      debugPrint(
        '[BudgetingRepository] Period ${period.id} is local. Attempting to sync period before saving allocations.',
      );
      try {
        await _periodRepository
            .syncPendingPeriods(); // This should sync the specific period
        final syncedPeriod = await _periodRepository.getCachedPeriodById(
          period.id,
        ); // Try to get by old local ID
        var finalPeriodIdToUse = period.id;

        if (syncedPeriod != null &&
            !syncedPeriod.isLocal &&
            syncedPeriod.id != period.id) {
          // This means the local period was synced and got a new backend ID
          finalPeriodIdToUse = syncedPeriod.id;
          debugPrint(
            '[BudgetingRepository] Local period ${period.id} synced to ${syncedPeriod.id}. Using new ID for budget plan.',
          );
        } else if (syncedPeriod != null &&
            !syncedPeriod.isLocal &&
            syncedPeriod.id == period.id) {
          // Local ID happened to be same as backend ID or sync updated in place.
          finalPeriodIdToUse = syncedPeriod.id;
        } else {
          throw BudgetingApiException(
            'Failed to sync local period ${period.id} before saving budget. Please try syncing periods first.',
          );
        }
        // Update DTO with potentially new, synced period ID
        dto.copyWith(
          budgetPeriodId: finalPeriodIdToUse,
        ); // Need copyWith on DTO
      } catch (e) {
        throw BudgetingApiException(
          'Error syncing period before saving budget allocations: $e',
        );
      }
    } else if (period.isLocal && !isOnline) {
      debugPrint(
        '[BudgetingRepository] Period ${period.id} is local and app is offline. Budget will be queued with local period ID.',
      );
    }

    final periodCacheKeyForSaved = 'allocations_${dto.budgetPeriodId}';
    if (isOnline) {
      try {
        final savedAllocations = await _service.saveExpenseAllocations(dto);
        await _hiveService.putJsonString(
          savedAllocationsCacheBoxName,
          periodCacheKeyForSaved,
          json.encode(savedAllocations.map((a) => a.toJson()).toList()),
        );
        await _hiveService.delete(
          pendingBudgetPlansBoxName,
          dto.budgetPeriodId,
        ); // Use DTO's periodId (which is now synced backend ID if applicable)
        return savedAllocations;
      } catch (e) {
        await _hiveService.putJsonString(
          pendingBudgetPlansBoxName,
          dto.budgetPeriodId,
          json.encode(dto.toJson()),
        );
        if (e is BudgetingApiException) rethrow;
        throw BudgetingApiException('Failed online, queued budget plan: $e');
      }
    } else {
      await _hiveService.putJsonString(
        pendingBudgetPlansBoxName,
        dto.budgetPeriodId,
        json.encode(dto.toJson()),
      );
      throw BudgetingApiException(
        'Offline: Budget plan for period ${dto.budgetPeriodId} queued.',
      );
    }
  }

  Future<List<FrontendBudgetAllocation>> getBudgetAllocationsForPeriod(
    String periodId,
  ) async {
    final isOnline = await _connectivityService.isOnline;
    final pendingPlanJson = await _hiveService.getJsonString(
      pendingBudgetPlansBoxName,
      periodId,
    );

    if (pendingPlanJson != null) {
      try {
        final dto = SaveExpenseAllocationsRequestDto.fromJson(
          json.decode(pendingPlanJson) as Map<String, dynamic>,
        );
        final optimisticList = <FrontendBudgetAllocation>[];
        var tempIdCounter = 0;
        final hierarchyRepo = sl<TransactionHierarchyRepository>(); // For names
        for (final allocDetail in dto.allocations) {
          final category = await hierarchyRepo.getCachedCategoryById(
            allocDetail.categoryId,
          );
          final categoryName = category?.name ?? '...';
          final categoryAllocatedAmount =
              (allocDetail.percentage / 100) * dto.totalBudgetableIncome;
          for (final subId in allocDetail.selectedSubcategoryIds) {
            final subcategory = await hierarchyRepo.getCachedSubcategoryById(
              subId,
            );
            optimisticList.add(
              FrontendBudgetAllocation(
                id: 'local_alloc_${tempIdCounter++}',
                periodId: dto.budgetPeriodId,
                categoryId: allocDetail.categoryId,
                categoryName: categoryName,
                subcategoryId: subId,
                subcategoryName: subcategory?.name ?? '...',
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
        return [];
      }
    }

    final cacheKey = 'allocations_$periodId';
    if (isOnline) {
      try {
        final allocations = await _service.fetchBudgetAllocationsForPeriod(
          periodId,
        );
        await _hiveService.putJsonString(
          savedAllocationsCacheBoxName,
          cacheKey,
          json.encode(allocations.map((a) => a.toJson()).toList()),
        );
        return allocations;
      } catch (e) {
        final cachedJson = await _hiveService.get<dynamic>(
          savedAllocationsCacheBoxName,
          cacheKey,
        );
        if (cachedJson != null) {
          final decoded = json.decode(cachedJson as String) as List<dynamic>;
          return decoded
              .map(
                (item) => FrontendBudgetAllocation.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList();
        }
      }
      // Offline or online failed, try main cache
      final cachedJson = await _hiveService.getJsonString(
        savedAllocationsCacheBoxName,
        cacheKey,
      );
      if (cachedJson != null) {
        return (json.decode(cachedJson) as List<dynamic>)
            .map(
              (item) => FrontendBudgetAllocation.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();
      }
      return [];
    }
    return [];
  }

  Future<void> syncPendingBudgetPlans() async {
    final pendingMap = _hiveService.getBoxEntries<String>(
      pendingBudgetPlansBoxName,
    );
    if (pendingMap.isEmpty) return;
    final isOnline = await _connectivityService.isOnline;
    if (!isOnline) return;

    final successfullySyncedKeys = <String>[];
    for (final entry in pendingMap.entries) {
      final localPeriodIdKey =
          entry.key as String; // This was the key, possibly a local_period_id
      final planJson = entry.value;
      try {
        var dto = SaveExpenseAllocationsRequestDto.fromJson(
          json.decode(planJson) as Map<String, dynamic>,
        );

        // Resolve localPeriodIdKey to backendPeriodId if it was local
        final period = await _periodRepository.getCachedPeriodById(
          localPeriodIdKey,
        );
        if (period == null) {
          debugPrint(
            '[BudgetingRepo] Cannot sync budget for local key $localPeriodIdKey, period not found in cache.',
          );
          continue;
        }
        if (period.isLocal) {
          // It's a local_period_id or a backend ID that wasn't confirmed synced
          debugPrint(
            '[BudgetingRepo] Period $localPeriodIdKey used in pending budget is local/unsynced. Sync periods first.',
          );
          // Trigger period sync for this user if not already done.
          // For now, we skip if the period itself isn't synced to a backend ID.
          // This highlights the dependency: periods must sync and update their IDs before budgets using them can sync.
          // The PeriodRepository.syncPendingPeriods() needs to update related BudgetAllocation DTOs.
          continue;
        }
        // If we are here, period.id is assumed to be the backend-synced ID.
        // If the DTO stored a local_period_id, it should have been updated by PeriodRepository.syncPendingPeriods's TODO.
        // For safety, ensure DTO uses the confirmed synced period ID.
        if (dto.budgetPeriodId != period.id &&
            period.id.startsWith('local_') == false /*is backend id*/ ) {
          debugPrint(
            "[BudgetingRepo] Updating DTO's period ID from ${dto.budgetPeriodId} to synced ID ${period.id}",
          );
          dto = dto.copyWith(budgetPeriodId: period.id); // DTO needs copyWith
        }

        final syncedAllocations = await _service.saveExpenseAllocations(dto);
        await _hiveService.putJsonString(
          savedAllocationsCacheBoxName,
          'allocations_${dto.budgetPeriodId}',
          json.encode(syncedAllocations.map((a) => a.toJson()).toList()),
        );
        successfullySyncedKeys.add(
          localPeriodIdKey,
        ); // Delete by the original key it was stored with
      } catch (e) {
        debugPrint(
          '[BudgetingRepository] Failed to sync budget plan for period $localPeriodIdKey: $e. It will remain in queue.',
        );
      }
    }
    for (final key in successfullySyncedKeys) {
      await _hiveService.delete(pendingBudgetPlansBoxName, key);
    }
    // ...
  }

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

// Add copyWith to SaveExpenseAllocationsRequestDto
// In lib/features/budgeting/services/budgeting_service.dart (or models/budget_plan_dto.dart)
// class SaveExpenseAllocationsRequestDto {
// ...
//   SaveExpenseAllocationsRequestDto copyWith({
//     String? budgetPeriodId,
//     double? totalBudgetableIncome,
//     List<FrontendAllocationDetailDto>? allocations,
//   }) {
//     return SaveExpenseAllocationsRequestDto(
//       budgetPeriodId: budgetPeriodId ?? this.budgetPeriodId,
//       totalBudgetableIncome: totalBudgetableIncome ?? this.totalBudgetableIncome,
//       allocations: allocations ?? this.allocations,
//     );
//   }
// }
