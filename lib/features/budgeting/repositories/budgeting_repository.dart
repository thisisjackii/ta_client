// lib/features/budgeting/repositories/budgeting_repository.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:ta_client/core/services/connectivity_service.dart';
import 'package:ta_client/core/services/hive_service.dart';
import 'package:ta_client/core/services/service_locator.dart';
import 'package:ta_client/core/state/auth_state.dart';
import 'package:ta_client/features/budgeting/services/budgeting_service.dart';
import 'package:ta_client/features/transaction/repositories/transaction_hierarchy_repository.dart';
import 'package:ta_client/features/transaction/repositories/transaction_repository.dart';
import 'package:uuid/uuid.dart';

class BudgetingRepository {
  BudgetingRepository(this._service, this._transactionRepository)
    : _connectivityService = sl<ConnectivityService>(),
      _hiveService = sl<HiveService>(),
      _authState = sl<AuthState>();

  final BudgetingService _service;
  final TransactionRepository _transactionRepository;
  final ConnectivityService _connectivityService;
  final HiveService _hiveService;
  final AuthState _authState;
  static const Uuid _uuid = Uuid();

  static const String incomeSummaryCacheBoxName =
      'budgetingIncomeSummaryCache_v2';
  static const String expenseSuggestionsCacheBoxName =
      'budgetingExpenseSuggestionsCache_v2';
  static const String budgetPlansCacheBoxName = 'budgetingBudgetPlansCache_v2';
  static const String pendingBudgetPlansBoxName = 'budgetingPendingPlans_v2';

  Future<List<BackendIncomeSummaryItem>> getSummarizedIncomeForDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final isOnline = await _connectivityService.isOnline;
    final cacheKey =
        'incomeSummary_${startDate.toIso8601String()}_${endDate.toIso8601String()}';

    if (isOnline) {
      try {
        final summary = await _service.fetchSummarizedIncomeForDateRange(
          startDate: startDate,
          endDate: endDate,
        );
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
          try {
            return (json.decode(cachedJson) as List<dynamic>)
                .map(
                  (item) => BackendIncomeSummaryItem.fromJson(
                    item as Map<String, dynamic>,
                  ),
                )
                .toList();
          } catch (parseErr) {
            debugPrint('Error parsing cached income summary: $parseErr');
          }
        }
        if (e is BudgetingApiException) rethrow;
        throw BudgetingApiException(
          'Failed online, no cache for income summary: $e',
        );
      }
    } else {
      final cachedJson = await _hiveService.getJsonString(
        incomeSummaryCacheBoxName,
        cacheKey,
      );
      if (cachedJson != null) {
        try {
          return (json.decode(cachedJson) as List<dynamic>)
              .map(
                (item) => BackendIncomeSummaryItem.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList();
        } catch (parseErr) {
          debugPrint(
            'Error parsing cached income summary (offline): $parseErr',
          );
        }
      }
      debugPrint(
        '[BudgetingRepository] Offline: No cache for income summary. Calculating from local transactions for range $startDate - $endDate.',
      );
      final cachedTransactions = await _transactionRepository
          .getCachedTransactionList();
      final inRangeIncomeTransactions = cachedTransactions
          .where(
            (t) =>
                t.subcategoryId.isNotEmpty &&
                !t.date.isBefore(startDate) &&
                !t.date.isAfter(
                  endDate
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
      final hierarchyRepo = sl<TransactionHierarchyRepository>();

      for (final tx in inRangeIncomeTransactions) {
        final subId = tx.subcategoryId;
        var subName = tx.subcategoryName ?? 'N/A';
        var catId = tx.categoryId ?? 'N/A_CAT';
        var catName = tx.categoryName ?? 'N/A Category';

        if (tx.subcategoryName == null || tx.categoryName == null) {
          final subObj = await hierarchyRepo.getCachedSubcategoryById(subId);
          if (subObj != null) {
            subName = subObj.name;
            catId = subObj.categoryId;
            final catObj = await hierarchyRepo.getCachedCategoryById(catId);
            if (catObj != null) catName = catObj.name;
          }
        }
        subcategoryTotals[subId] = (subcategoryTotals[subId] ?? 0) + tx.amount;
        subcategoryIdToNameMap.putIfAbsent(subId, () => subName);
        subcategoryIdToParentCategoryIdMap.putIfAbsent(subId, () => catId);
        categoryIdToNameMap.putIfAbsent(catId, () => catName);
      }

      // Removed unused 'categoryTotals' map
      final summaryItems = <BackendIncomeSummaryItem>[];

      for (final entry in categoryIdToNameMap.entries) {
        final catId = entry.key;
        final catName = entry.value;
        double currentCategoryTotal = 0;
        final subSummaries = <BackendSubcategoryIncome>[];

        subcategoryIdToParentCategoryIdMap.forEach((subId, parentCatId) {
          if (parentCatId == catId) {
            final subTotal = subcategoryTotals[subId]!;
            currentCategoryTotal += subTotal;
            subSummaries.add(
              BackendSubcategoryIncome(
                subcategoryId: subId,
                subcategoryName: subcategoryIdToNameMap[subId]!,
                totalAmount: subTotal,
              ),
            );
          }
        });
        if (subSummaries.isNotEmpty) {
          summaryItems.add(
            BackendIncomeSummaryItem(
              categoryId: catId,
              categoryName: catName,
              subcategories: subSummaries,
              categoryTotalAmount: currentCategoryTotal,
            ),
          ); // Construct with final total
        }
      }
      await _hiveService.putJsonString(
        incomeSummaryCacheBoxName,
        cacheKey,
        json.encode(summaryItems.map((s) => s.toJson()).toList()),
      );
      return summaryItems;
    }
  }

  Future<List<BackendExpenseCategorySuggestion>>
  getExpenseCategorySuggestions() async {
    final isOnline = await _connectivityService.isOnline;
    const cacheKey = 'expenseCategorySuggestions_v2';
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
          try {
            return (json.decode(cachedJson) as List<dynamic>)
                .map(
                  (item) => BackendExpenseCategorySuggestion.fromJson(
                    item as Map<String, dynamic>,
                  ),
                )
                .toList();
          } catch (parseErr) {
            debugPrint('Error parsing cached suggestions: $parseErr');
          }
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
        try {
          return (json.decode(cachedJson) as List<dynamic>)
              .map(
                (item) => BackendExpenseCategorySuggestion.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList();
        } catch (parseErr) {
          debugPrint('Error parsing cached suggestions (offline): $parseErr');
          return [];
        }
      }
      return [];
    }
  }

  Future<FrontendBudgetPlan> saveBudgetPlanWithAllocations(
    SaveExpenseAllocationsRequestDto dto,
  ) async {
    final isOnline = await _connectivityService.isOnline;
    final currentUserId = _authState.currentUser?.id;

    if (currentUserId == null) {
      throw BudgetingApiException(
        'User not authenticated. Cannot save budget plan.',
      );
    }
    final localPlanKeyForQueueing =
        'pending_plan_${dto.planStartDate.toIso8601String()}_${dto.planEndDate.toIso8601String()}'; // Use a more descriptive key for pending DTOs

    final optimisticPlan = await _optimisticPlanFromDto(
      dto,
      localPlanKeyForQueueing,
      currentUserId,
    );

    await _hiveService.putJsonString(
      pendingBudgetPlansBoxName,
      localPlanKeyForQueueing,
      json.encode(dto.toJson()),
    );
    await _hiveService.putJsonString(
      budgetPlansCacheBoxName,
      localPlanKeyForQueueing, // Cache optimistic plan under its local key for immediate retrieval
      json.encode(optimisticPlan.toJson()),
    );

    if (isOnline) {
      try {
        final savedPlanFromApi = await _service.saveExpenseAllocations(dto);
        await _hiveService.putJsonString(
          budgetPlansCacheBoxName,
          savedPlanFromApi.id,
          json.encode(savedPlanFromApi.copyWith(isLocal: false).toJson()),
        );
        if (localPlanKeyForQueueing != savedPlanFromApi.id) {
          // If backend ID is different from generated key
          await _hiveService.delete(
            budgetPlansCacheBoxName,
            localPlanKeyForQueueing,
          );
        }
        await _hiveService.delete(
          pendingBudgetPlansBoxName,
          localPlanKeyForQueueing,
        );
        return savedPlanFromApi;
      } catch (e) {
        debugPrint(
          '[BudgetingRepository] Online saveBudgetPlanWithAllocations failed, DTO already queued with key $localPlanKeyForQueueing: $e',
        );
        // If API call fails, it's already queued. Return optimistic.
        // No need to re-queue here if the service itself indicated queuing via exception message.
        if (e is BudgetingApiException &&
            e.message.contains('queued for sync')) {
          return optimisticPlan;
        }
        if (e is BudgetingApiException) rethrow;
        return optimisticPlan; // For other errors, rely on queue
      }
    } else {
      debugPrint(
        '[BudgetingRepository] Offline: Budget plan DTO queued with key $localPlanKeyForQueueing.',
      );
      return optimisticPlan;
    }
  }

  Future<FrontendBudgetPlan> _optimisticPlanFromDto(
    SaveExpenseAllocationsRequestDto dto,
    String planId,
    String userId,
  ) async {
    final hierarchyRepo = sl<TransactionHierarchyRepository>();
    final optimisticAllocations = <FrontendBudgetAllocation>[];
    for (final allocDetail in dto.allocations) {
      final cat = await hierarchyRepo.getCachedCategoryById(
        allocDetail.categoryId,
      );
      for (final subId in allocDetail.selectedSubcategoryIds) {
        final subcat = await hierarchyRepo.getCachedSubcategoryById(subId);
        optimisticAllocations.add(
          FrontendBudgetAllocation(
            id: 'local_alloc_${_uuid.v4()}', // Unique local ID for each allocation
            budgetPlanId: planId,
            categoryId: allocDetail.categoryId,
            categoryName: cat?.name ?? '...',
            subcategoryId: subId,
            subcategoryName: subcat?.name ?? '...',
            percentage: allocDetail.percentage,
            amount: (allocDetail.percentage / 100) * dto.totalCalculatedIncome,
            isLocal: true,
          ),
        );
      }
    }
    return FrontendBudgetPlan(
      id: planId, // This ID is the key for the pending DTO or the backend ID
      userId: userId,
      description: dto.planDescription,
      planStartDate: dto.planStartDate,
      planEndDate: dto.planEndDate,
      incomeCalculationStartDate: dto.incomeCalculationStartDate,
      incomeCalculationEndDate: dto.incomeCalculationEndDate,
      totalCalculatedIncome: dto.totalCalculatedIncome,
      allocations: optimisticAllocations,
      isLocal: true, // The plan itself is marked local if optimistic
    );
  }

  Future<FrontendBudgetPlan?> getBudgetPlanById(String budgetPlanId) async {
    final planJson = await _hiveService.getJsonString(
      budgetPlansCacheBoxName,
      budgetPlanId,
    );
    if (planJson != null) {
      try {
        return FrontendBudgetPlan.fromJson(
          json.decode(planJson) as Map<String, dynamic>,
        );
      } catch (e) {
        debugPrint('Error parsing cached budget plan $budgetPlanId: $e');
      }
    }

    // If not in main cache, it might be a pending plan identified by its local key
    final pendingDtoJson = await _hiveService.getJsonString(
      pendingBudgetPlansBoxName,
      budgetPlanId,
    );
    if (pendingDtoJson != null) {
      try {
        final dto = SaveExpenseAllocationsRequestDto.fromJson(
          json.decode(pendingDtoJson) as Map<String, dynamic>,
        );
        final currentUserId = _authState.currentUser?.id;
        if (currentUserId == null) {
          debugPrint(
            'Cannot construct optimistic pending plan: no current user.',
          );
          return null;
        }
        return _optimisticPlanFromDto(dto, budgetPlanId, currentUserId);
      } catch (e) {
        debugPrint(
          'Error creating optimistic plan from pending DTO $budgetPlanId: $e',
        );
      }
    }

    final isOnline = await _connectivityService.isOnline;
    if (isOnline) {
      try {
        final planFromApi = await _service.fetchBudgetPlanById(budgetPlanId);
        await _hiveService.putJsonString(
          budgetPlansCacheBoxName,
          planFromApi.id,
          json.encode(planFromApi.copyWith(isLocal: false).toJson()),
        );
        return planFromApi;
      } catch (e) {
        debugPrint(
          'Error fetching budget plan by ID $budgetPlanId from API: $e',
        );
      }
    }
    return null;
  }

  Future<List<FrontendBudgetAllocation>> getAllocationsForPlan(
    String budgetPlanId,
  ) async {
    final budgetPlan = await getBudgetPlanById(budgetPlanId);
    return budgetPlan?.allocations ?? [];
  }

  Future<void> syncPendingBudgetPlans() async {
    final pendingMap = _hiveService.getBoxEntries<String>(
      pendingBudgetPlansBoxName,
    );
    if (pendingMap.isEmpty) {
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
      '[BudgetingRepository] Syncing ${pendingMap.length} pending budget plans.',
    );
    final successfullySyncedLocalPlanKeys =
        <String>[]; // ***** RENAMED VARIABLE *****

    for (final entry in pendingMap.entries) {
      final localPlanKey = entry.key as String;
      final planDtoJson = entry.value;
      try {
        final dto = SaveExpenseAllocationsRequestDto.fromJson(
          json.decode(planDtoJson) as Map<String, dynamic>,
        );
        debugPrint(
          '[BudgetingRepository] Attempting to sync budget plan DTO for local key: $localPlanKey',
        );

        // The DTO's internal `budgetPeriodId` is used by the service, if it was a local ID, it needs resolution.
        // However, the saveExpenseAllocations in service now expects planStartDate, planEndDate etc.
        // The `dto` here IS the SaveExpenseAllocationsRequestDto.
        final syncedPlanFromApi = await _service.saveExpenseAllocations(dto);

        await _hiveService.putJsonString(
          budgetPlansCacheBoxName,
          syncedPlanFromApi.id,
          json.encode(syncedPlanFromApi.copyWith(isLocal: false).toJson()),
        );
        // Remove the optimistic local version if it was cached under a different local key
        if (localPlanKey != syncedPlanFromApi.id) {
          await _hiveService.delete(budgetPlansCacheBoxName, localPlanKey);
        }

        successfullySyncedLocalPlanKeys.add(
          localPlanKey,
        ); // ***** USE RENAMED VARIABLE *****
        debugPrint(
          '[BudgetingRepository] Synced budget plan (local key $localPlanKey) to backend plan ID ${syncedPlanFromApi.id}',
        );
      } catch (e) {
        debugPrint(
          '[BudgetingRepository] Failed to sync budget plan for local key $localPlanKey: $e. It will remain in queue.',
        );
        if (e is BudgetingApiException && e.statusCode == 401) {
          debugPrint('Auth error during budget sync, stopping.');
          break;
        }
      }
    }

    if (successfullySyncedLocalPlanKeys.isNotEmpty) {
      // ***** USE RENAMED VARIABLE *****
      final box = await _hiveService.getOpenBox<String>(
        pendingBudgetPlansBoxName,
      );
      await box.deleteAll(
        successfullySyncedLocalPlanKeys,
      ); // ***** USE RENAMED VARIABLE *****
      debugPrint(
        '[BudgetingRepository] Cleaned ${successfullySyncedLocalPlanKeys.length} synced budget plans from queue.',
      );
    }
  }

  // Add or ensure this method exists and is suitable for checking ANY plan
  Future<List<FrontendBudgetPlan>> getBudgetPlansForUser(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final isOnline = await _connectivityService.isOnline;
    final cacheKey =
        'all_budget_plans_user_$userId'; // A general key for all plans for the user

    if (isOnline) {
      try {
        final plans = await _service.fetchBudgetPlansForUser(
          userId,
          startDate: startDate,
          endDate: endDate,
        ); // Assuming service method exists
        await _hiveService.putJsonString(
          budgetPlansCacheBoxName,
          cacheKey,
          json.encode(plans.map((p) => p.toJson()).toList()),
        );
        return plans;
      } catch (e) {
        debugPrint(
          '[BudgetingRepo] Error fetching all plans: $e. Trying cache.',
        );
        // Fall through to cache
      }
    }
    // Try cache (online failure or offline)
    final cachedJson = await _hiveService.getJsonString(
      budgetPlansCacheBoxName,
      cacheKey,
    );
    if (cachedJson != null) {
      try {
        return (json.decode(cachedJson) as List<dynamic>)
            .map(
              (item) =>
                  FrontendBudgetPlan.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      } catch (parseErr) {
        debugPrint('Error parsing cached all budget plans: $parseErr');
        return [];
      }
    }
    return []; // Return empty if no cache and offline or error
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
      if (diff > 35) {
        throw ArgumentError(
          'Rentang periode anggaran tidak boleh lebih dari sekitar satu bulan.',
        );
      }
    }
  }
}
