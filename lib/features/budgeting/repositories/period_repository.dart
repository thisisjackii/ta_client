// lib/features/budgeting/repositories/period_repository.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ta_client/core/services/connectivity_service.dart';
import 'package:ta_client/core/services/service_locator.dart';
import 'package:ta_client/core/state/auth_state.dart';
import 'package:ta_client/features/budgeting/models/period.dart';
import 'package:ta_client/features/budgeting/services/period_service.dart';
import 'package:uuid/uuid.dart'; // For generating local IDs

class PeriodRepository {
  PeriodRepository(this._service) {
    _connectivityService = sl<ConnectivityService>();
    _initHiveBox();
  }

  final PeriodService _service;
  late ConnectivityService _connectivityService;
  static const String _periodCacheBoxName =
      'budgetingPeriodsCache'; // Specific to budgeting feature if desired
  static const String _pendingPeriodsBoxName = 'budgetingPendingPeriodsCache';

  static const Uuid _uuid = Uuid();

  Future<void> _initHiveBox() async {
    if (!Hive.isBoxOpen(_periodCacheBoxName)) {
      await Hive.openBox<String>(_periodCacheBoxName);
    }
    if (!Hive.isBoxOpen(_pendingPeriodsBoxName)) {
      await Hive.openBox<String>(_pendingPeriodsBoxName);
    }
  }

  Future<FrontendPeriod> ensureAndGetPeriod({
    required DateTime startDate,
    required DateTime endDate,
    required String periodType,
    String? existingPeriodId, // Can be a backend ID or a local temporary ID
    String? description,
    String?
    userIdForLocal, // Needed if creating a local period before user is fully auth'd or for temp objects
  }) async {
    final isOnline = await _connectivityService.isOnline;
    final cacheBox = Hive.box<String>(_periodCacheBoxName);
    final pendingBox = Hive.box<String>(_pendingPeriodsBoxName);

    // Try to find by existingPeriodId (could be backend or local)
    if (existingPeriodId != null) {
      final cachedJson =
          cacheBox.get(existingPeriodId) ?? pendingBox.get(existingPeriodId);
      if (cachedJson != null) {
        final cachedPeriod = FrontendPeriod.fromJson(
          json.decode(cachedJson) as Map<String, dynamic>,
        );
        // If details match, return cached. Useful if navigating back and forth.
        if (cachedPeriod.startDate.isAtSameMomentAs(startDate) &&
            cachedPeriod.endDate.isAtSameMomentAs(endDate) &&
            cachedPeriod.periodType == periodType) {
          debugPrint(
            '[PeriodRepository] Found matching cached period: $existingPeriodId',
          );
          return cachedPeriod;
        }
      }
    }

    // If online, try to create/fetch from backend.
    // Backend should handle finding existing period for user/type/dates or creating new.
    if (isOnline) {
      try {
        debugPrint(
          '[PeriodRepository] Online: Calling service to create/ensure period.',
        );
        final backendPeriod = await _service.createPeriod(
          startDate: startDate,
          endDate: endDate,
          periodType: periodType,
          description: description,
        );
        await cacheBox.put(
          backendPeriod.id,
          json.encode(backendPeriod.toJson()),
        );
        // If this was a pending local period, remove it from pending queue
        if (existingPeriodId != null &&
            pendingBox.containsKey(existingPeriodId)) {
          await pendingBox.delete(existingPeriodId);
        }
        return backendPeriod;
      } catch (e) {
        debugPrint(
          '[PeriodRepository] Online period creation/fetch failed: $e. Will attempt local creation if applicable.',
        );
        // Fall through to local creation if API fails but we still need a period object client-side
      }
    }

    // Offline or if online failed: create/use a local period object
    // If an existingPeriodId was provided and it was a local one, reuse it, otherwise generate new.
    final localId =
        (existingPeriodId != null &&
            (pendingBox.containsKey(existingPeriodId) ||
                cacheBox.get(existingPeriodId) != null &&
                    FrontendPeriod.fromJson(
                      json.decode(cacheBox.get(existingPeriodId)!)
                          as Map<String, dynamic>,
                    ).isLocal))
        ? existingPeriodId
        : 'local_${_uuid.v4()}';

    final localPeriod = FrontendPeriod(
      id: localId,
      userId:
          userIdForLocal ??
          '', // Requires userId context for proper local object
      startDate: startDate,
      endDate: endDate,
      periodType: periodType,
      description: description,
      isLocal: true, // Mark as local and needing sync
    );

    await pendingBox.put(localPeriod.id, json.encode(localPeriod.toJson()));
    // Also put in main cache for immediate retrieval by getCachedPeriodById
    await cacheBox.put(localPeriod.id, json.encode(localPeriod.toJson()));
    debugPrint(
      '[PeriodRepository] Using/Created local period (offline or API fail): ${localPeriod.id}',
    );
    return localPeriod;
  }

  Future<FrontendPeriod?> getCachedPeriodById(String periodId) async {
    final box = Hive.box<String>(_periodCacheBoxName);
    final periodJson = box.get(periodId);
    if (periodJson != null) {
      return FrontendPeriod.fromJson(
        json.decode(periodJson) as Map<String, dynamic>,
        local: periodJson.contains('"isLocal":true'),
      );
    }
    final pendingBox = Hive.box<String>(_pendingPeriodsBoxName);
    final pendingJson = pendingBox.get(periodId);
    if (pendingJson != null) {
      return FrontendPeriod.fromJson(
        json.decode(pendingJson) as Map<String, dynamic>,
        local: true,
      );
    }
    return null;
  }

  Future<List<FrontendPeriod>> getAllCachedPeriods(
    String userId, {
    String? periodType,
  }) async {
    final box = Hive.box<String>(_periodCacheBoxName);
    final periods = <FrontendPeriod>[];
    for (final key in box.keys) {
      final periodJson = box.get(key);
      if (periodJson != null) {
        final period = FrontendPeriod.fromJson(
          json.decode(periodJson) as Map<String, dynamic>,
        );
        if (period.userId == userId &&
            (periodType == null || period.periodType == periodType)) {
          periods.add(period);
        }
      }
    }
    // Also check pending periods
    final pendingBox = Hive.box<String>(_pendingPeriodsBoxName);
    for (final key in pendingBox.keys) {
      final periodJson = pendingBox.get(key);
      if (periodJson != null) {
        final period = FrontendPeriod.fromJson(
          json.decode(periodJson) as Map<String, dynamic>,
          local: true,
        );
        if (period.userId == userId &&
            (periodType == null || period.periodType == periodType) &&
            !periods.any((p) => p.id == period.id)) {
          periods.add(period);
        }
      }
    }
    periods.sort((a, b) => b.startDate.compareTo(a.startDate));
    return periods;
  }

  Future<void> syncPendingPeriods() async {
    // Removed userId param here
    final pendingBox = Hive.box<String>(_pendingPeriodsBoxName);
    // ... (initial checks for pendingBox.isEmpty, isOnline) ...

    final authState = sl<AuthState>(); // Get AuthState from GetIt
    if (!authState.isAuthenticated || authState.currentUser == null) {
      debugPrint(
        '[PeriodRepository] Cannot sync pending periods: User not authenticated or user ID unavailable.',
      );
      return;
    }
    final currentUserId = authState.currentUser!.id;

    debugPrint(
      '[PeriodRepository] Syncing ${pendingBox.length} pending periods for user $currentUserId.',
    );
    final syncedKeys = <String>[];

    for (final localId in pendingBox.keys.toList()) {
      final periodJson = pendingBox.get(localId);
      if (periodJson != null) {
        final localPeriodData = FrontendPeriod.fromJson(
          json.decode(periodJson) as Map<String, dynamic>,
          local: true,
        );
        try {
          final backendPeriod = await _service.createPeriod(
            // Backend needs to associate with user via token
            startDate: localPeriodData.startDate,
            endDate: localPeriodData.endDate,
            periodType: localPeriodData.periodType,
            description: localPeriodData.description,
            // existingPeriodId: localPeriodData.id, // Send local ID if backend can use it for idempotency check
          );
          // Update cache with backend data
          final cacheBox = Hive.box<String>(_periodCacheBoxName);
          await cacheBox.put(
            backendPeriod.id,
            json.encode(backendPeriod.copyWith(userId: currentUserId).toJson()),
          ); // Ensure userId is in cached object
          if (localId != backendPeriod.id) await cacheBox.delete(localId);

          syncedKeys.add(localId as String);
          debugPrint(
            '[PeriodRepository] Synced local period $localId to backend period ${backendPeriod.id} for user $currentUserId',
          );

          // TODO: Update dependent records (BudgetAllocations, etc.) that used the localPeriod.id
          // This is a complex step. After syncing a period and getting its backend ID,
          // you need to find any BudgetAllocations, etc., that were created offline
          // using the local_period_id and update their periodId to the new backend_period_id
          // before attempting to sync those allocations.
          // This might involve another queue or marking them for "periodId update".
        } catch (e) {
          debugPrint(
            '[PeriodRepository] Failed to sync pending period $localId for user $currentUserId: $e',
          );
        }
      }
    }
    for (final key in syncedKeys) {
      await pendingBox.delete(key);
    }
  }
}
