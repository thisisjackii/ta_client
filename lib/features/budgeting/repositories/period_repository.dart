// lib/features/budgeting/repositories/period_repository.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
// No Hive import needed here directly
import 'package:ta_client/core/services/connectivity_service.dart';
import 'package:ta_client/core/services/hive_service.dart'; // Import HiveService
import 'package:ta_client/core/services/service_locator.dart';
import 'package:ta_client/core/state/auth_state.dart'; // To get current user ID
import 'package:ta_client/features/budgeting/models/period.dart';
import 'package:ta_client/features/budgeting/services/period_service.dart';
import 'package:uuid/uuid.dart';

class PeriodRepository {
  PeriodRepository(this._service)
    : _connectivityService = sl<ConnectivityService>(),
      _hiveService = sl<HiveService>(),
      _authState = sl<AuthState>() {
    // Get AuthState from service locator
    // No _initHiveBox needed, bootstrap.dart handles global opening
  }
  final PeriodService _service;
  final ConnectivityService _connectivityService;
  final HiveService _hiveService; // Injected
  final AuthState _authState; // Injected
  static const Uuid _uuid = Uuid();

  // Public static const for box names
  static const String periodCacheBoxName = 'budgetingPeriodsCache_v1';
  static const String pendingPeriodsBoxName = 'budgetingPendingPeriodsCache_v1';

  Future<FrontendPeriod> _cachePeriod(
    FrontendPeriod period, {
    bool isPending = false,
  }) async {
    final boxName = isPending ? pendingPeriodsBoxName : periodCacheBoxName;
    // For pending, key is local ID. For synced, key is backend ID.
    await _hiveService.putJsonString(
      boxName,
      period.id,
      json.encode(period.toJson()),
    );
    return period;
  }

  Future<FrontendPeriod?> getCachedPeriodById(String periodId) async {
    var periodJson = await _hiveService.getJsonString(
      periodCacheBoxName,
      periodId,
    );
    if (periodJson != null) {
      return FrontendPeriod.fromJson(
        json.decode(periodJson) as Map<String, dynamic>,
      );
    }
    periodJson = await _hiveService.getJsonString(
      pendingPeriodsBoxName,
      periodId,
    );
    if (periodJson != null) {
      return FrontendPeriod.fromJson(
        json.decode(periodJson) as Map<String, dynamic>,
        local: true,
      );
    }
    return null;
  }

  Future<FrontendPeriod> ensureAndGetPeriod({
    required DateTime startDate,
    required DateTime endDate,
    required String periodType,
    String? existingPeriodId,
    String? description,
    // String? userIdForLocal, // Replaced by fetching from AuthState
  }) async {
    final isOnline = await _connectivityService.isOnline;
    final currentUserId = _authState.currentUser?.id;

    if (currentUserId == null && !isOnline) {
      // Cannot create a meaningful local period without a userId if offline new
      // This case needs careful handling based on app flow. Maybe store anonymously then associate?
      // For now, let's assume if offline and no user, period creation might be deferred or error.
      debugPrint(
        '[PeriodRepository] Offline and no current user ID, cannot ensure period robustly.',
      );
      // Fallback to creating a very temporary object if absolutely necessary, but it won't sync well.
      // Or throw:
      throw PeriodApiException(
        'User not available for offline period creation.',
      );
    }

    if (existingPeriodId != null) {
      final cachedPeriod = await getCachedPeriodById(existingPeriodId);
      if (cachedPeriod != null &&
          cachedPeriod.startDate.isAtSameMomentAs(startDate) &&
          cachedPeriod.endDate.isAtSameMomentAs(endDate) &&
          cachedPeriod.periodType == periodType) {
        return cachedPeriod;
      }
      if (isOnline && cachedPeriod == null) {
        // ID provided, but not in cache, try fetching
        try {
          final backendPeriod = await _service.fetchPeriodById(
            existingPeriodId,
          );
          return await _cachePeriod(backendPeriod.copyWith(isLocal: false));
        } catch (e) {
          /* Fall through to create new */
        }
      }
    }

    if (isOnline) {
      try {
        final backendPeriod = await _service.createPeriod(
          startDate: startDate,
          endDate: endDate,
          periodType: periodType,
          description: description,
        );
        // The backend associates it with the authenticated user via token
        return await _cachePeriod(backendPeriod.copyWith(isLocal: false));
      } catch (e) {
        debugPrint(
          '[PeriodRepository] Online period creation/fetch failed: $e. Will create locally for offline.',
        );
      }
    }

    // Offline or online creation failed: create/use a local period object
    final localId = 'local_${_uuid.v4()}';
    final localPeriod = FrontendPeriod(
      id: localId,
      userId:
          currentUserId ??
          'offline_user', // Use current user's ID or a placeholder
      startDate: startDate,
      endDate: endDate,
      periodType: periodType,
      description: description,
      isLocal: true,
    );
    return _cachePeriod(localPeriod, isPending: true);
  }

  Future<List<FrontendPeriod>> getPeriodsForUser(
    String userId, {
    String? periodType,
  }) async {
    final isOnline = await _connectivityService.isOnline;
    final allUserPeriods = <FrontendPeriod>[];

    // 1. Add pending (local) periods for this user
    _hiveService.getBoxEntries<String>(pendingPeriodsBoxName).forEach((
      key,
      periodJson,
    ) {
      final period = FrontendPeriod.fromJson(
        json.decode(periodJson) as Map<String, dynamic>,
        local: true,
      );
      if (period.userId == userId &&
          (periodType == null || period.periodType == periodType)) {
        allUserPeriods.add(period);
      }
    });

    // 2. If online, fetch from server, cache, and merge/deduplicate
    if (isOnline) {
      try {
        final backendPeriods = await _service.fetchPeriods(
          periodType: periodType,
        ); // Service returns for authenticated user
        for (final bp in backendPeriods) {
          await _cachePeriod(bp.copyWith(isLocal: false)); // Cache as synced
          // Remove any local/pending version that this backend period replaces
          final localVersionIndex = allUserPeriods.indexWhere(
            (lp) =>
                lp.isLocal &&
                lp.startDate.isAtSameMomentAs(bp.startDate) &&
                lp.endDate.isAtSameMomentAs(bp.endDate) &&
                lp.periodType == bp.periodType &&
                lp.userId == bp.userId,
          );
          if (localVersionIndex != -1) {
            await _hiveService.delete(
              pendingPeriodsBoxName,
              allUserPeriods[localVersionIndex].id,
            );
            allUserPeriods.removeAt(localVersionIndex);
          }
          // Add backend version if not already present by ID (or replace if different)
          allUserPeriods
            ..removeWhere((p) => p.id == bp.id)
            ..add(bp);
        }
      } catch (e) {
        debugPrint(
          '[PeriodRepository] Error fetching periods online, will rely on cache: $e',
        );
        // Fallback to only cached synced periods if online fetch fails
        _hiveService.getBoxEntries<String>(periodCacheBoxName).forEach((
          key,
          periodJson,
        ) {
          final period = FrontendPeriod.fromJson(
            json.decode(periodJson) as Map<String, dynamic>,
          );
          if (period.userId == userId &&
              (periodType == null || period.periodType == periodType) &&
              !allUserPeriods.any((p) => p.id == period.id)) {
            // Avoid duplicates if already added from pending
            allUserPeriods.add(period);
          }
        });
      }
    } else {
      // Offline: Add already synced periods from cache
      _hiveService.getBoxEntries<String>(periodCacheBoxName).forEach((
        key,
        periodJson,
      ) {
        final period = FrontendPeriod.fromJson(
          json.decode(periodJson) as Map<String, dynamic>,
        );
        if (period.userId == userId &&
            (periodType == null || period.periodType == periodType) &&
            !allUserPeriods.any((p) => p.id == period.id)) {
          allUserPeriods.add(period);
        }
      });
    }

    allUserPeriods.sort((a, b) => b.startDate.compareTo(a.startDate));
    return allUserPeriods;
  }

  Future<void> syncPendingPeriods() async {
    // Removed userId param, get from AuthState
    final isOnline = await _connectivityService.isOnline;
    if (!isOnline) return;

    final pendingBox = await _hiveService.getOpenBox<String>(
      pendingPeriodsBoxName,
    );
    final pendingMap = _hiveService.getBoxEntries<String>(
      pendingPeriodsBoxName,
    );
    if (pendingMap.isEmpty) return;

    final authState = sl<AuthState>();
    if (!authState.isAuthenticated || authState.currentUser == null) {
      debugPrint(
        '[PeriodRepository] Cannot sync pending periods: User not authenticated.',
      );
      return;
    }
    final currentUserId = authState.currentUser!.id;

    debugPrint(
      '[PeriodRepository] Syncing ${pendingMap.length} pending periods for user $currentUserId.',
    );
    final syncedLocalIds = <String>[];

    for (final localId in pendingMap.keys.toList().cast<String>()) {
      final periodJson = pendingMap[localId];
      if (periodJson != null) {
        final localPeriod = FrontendPeriod.fromJson(
          json.decode(periodJson) as Map<String, dynamic>,
          local: true,
        );

        // Only sync if it belongs to the current user or was an "offline_user" period now being claimed
        if (localPeriod.userId == currentUserId ||
            localPeriod.userId == 'offline_user') {
          try {
            final backendPeriod = await _service.createPeriod(
              startDate: localPeriod.startDate,
              endDate: localPeriod.endDate,
              periodType: localPeriod.periodType,
              description: localPeriod.description,
            );

            // Update main cache with synced version (backend ID)
            await _cachePeriod(
              backendPeriod.copyWith(isLocal: false, userId: currentUserId),
            );
            // If localId was different, remove old localId from main cache if it was put there
            if (localId != backendPeriod.id) {
              await (await _hiveService.getOpenBox<String>(
                periodCacheBoxName,
              )).delete(localId);
            }
            syncedLocalIds.add(localId);
            debugPrint(
              '[PeriodRepository] Synced local period $localId to backend period ${backendPeriod.id}',
            );
            // TODO: CRITICAL - Update periodId in related offline BudgetAllocations/Evaluations
            // from localId to backendPeriod.id before those are synced.
          } catch (e) {
            debugPrint(
              '[PeriodRepository] Failed to sync pending period $localId: $e',
            );
          }
        }
      }
    }
    for (final key in syncedLocalIds) {
      await pendingBox.delete(key);
    }
  }
}
