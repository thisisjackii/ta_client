// lib/features/transaction/repositories/transaction_hierarchy_repository.dart
import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ta_client/core/services/connectivity_service.dart';
import 'package:ta_client/core/services/service_locator.dart';
import 'package:ta_client/features/transaction/models/account_type.dart';
import 'package:ta_client/features/transaction/models/category.dart';
import 'package:ta_client/features/transaction/models/subcategory.dart';
import 'package:ta_client/features/transaction/services/transaction_hierarchy_service.dart';

class TransactionHierarchyRepository {
  TransactionHierarchyRepository({required this.service}) {
    _connectivityService = sl<ConnectivityService>();
    _initHiveBox();
  }

  final TransactionHierarchyService service;
  late ConnectivityService _connectivityService;

  static const String _hierarchyCacheBoxName =
      'transactionHierarchyCache_v1'; // Versioned cache key

  Future<void> _initHiveBox() async {
    if (!Hive.isBoxOpen(_hierarchyCacheBoxName)) {
      await Hive.openBox<String>(
        _hierarchyCacheBoxName,
      ); // Store as JSON strings
    }
  }

  Future<List<AccountType>> fetchAccountTypes({
    bool forceRefresh = false,
  }) async {
    final box = Hive.box<String>(_hierarchyCacheBoxName);
    const cacheKey = 'all_account_types';
    final isOnline = await _connectivityService.isOnline;

    if (isOnline && forceRefresh) {
      debugPrint(
        '[TxHierarchyRepo] Online & Force Refresh: Fetching AccountTypes.',
      );
      return _fetchAndCacheAccountTypes(box, cacheKey);
    } else if (isOnline) {
      final cachedJson = box.get(cacheKey);
      if (cachedJson != null) {
        debugPrint('[TxHierarchyRepo] Online: Returning cached AccountTypes.');
        try {
          final decoded =
              json.decode(cachedJson) as List<dynamic>;
          return decoded
              .map((e) => AccountType.fromJson(e as Map<String, dynamic>))
              .toList();
        } catch (e) {
          /* Corrupted cache, will fetch again */
        }
      }
      debugPrint(
        '[TxHierarchyRepo] Online: Cache miss/corrupt for AccountTypes, fetching.',
      );
      return _fetchAndCacheAccountTypes(box, cacheKey);
    } else {
      // Offline
      final cachedJson = box.get(cacheKey);
      if (cachedJson != null) {
        debugPrint('[TxHierarchyRepo] Offline: Returning cached AccountTypes.');
        try {
          final decoded = json.decode(cachedJson) as List<dynamic>;
          return decoded
              .map((e) => AccountType.fromJson(e as Map<String, dynamic>))
              .toList();
        } catch (e) {
          debugPrint(
            '[TxHierarchyRepo] Offline: Corrupted AccountType cache. Returning empty.',
          );
          return [];
        }
      }
      debugPrint(
        '[TxHierarchyRepo] Offline: No AccountTypes in cache. Returning empty.',
      );
      return [];
    }
  }

  Future<List<AccountType>> _fetchAndCacheAccountTypes(
    Box<String> box,
    String cacheKey,
  ) async {
    try {
      final list = await service.fetchAccountTypes();
      await box.put(
        cacheKey,
        json.encode(list.map((e) => e.toJson()).toList()),
      );
      return list;
    } catch (e) {
      debugPrint('[TxHierarchyRepo] Error fetching/caching AccountTypes: $e');
      if (e is HierarchyApiException && e.statusCode == 401) {
        rethrow; // Propagate auth error
      }
      return []; // Return empty on other errors
    }
  }

  Future<List<Category>> fetchCategories(
    String accountTypeId, {
    bool forceRefresh = false,
  }) async {
    final box = Hive.box<String>(_hierarchyCacheBoxName);
    final cacheKey = 'categories_for_account_$accountTypeId';
    final isOnline = await _connectivityService.isOnline;

    if (isOnline && forceRefresh) {
      return _fetchAndCacheCategories(box, cacheKey, accountTypeId);
    } else if (isOnline) {
      final cachedJson = box.get(cacheKey);
      if (cachedJson != null) {
        try {
          return _deserializeList(cachedJson, Category.fromJson);
        } catch (e) {}
      }
      return _fetchAndCacheCategories(box, cacheKey, accountTypeId);
    } else {
      final cachedJson = box.get(cacheKey);
      if (cachedJson != null) {
        try {
          return _deserializeList(cachedJson, Category.fromJson);
        } catch (e) {
          return [];
        }
      }
      return [];
    }
  }

  Future<List<Category>> _fetchAndCacheCategories(
    Box<String> box,
    String cacheKey,
    String accountTypeId,
  ) async {
    try {
      final list = await service.fetchCategories(accountTypeId);
      await box.put(
        cacheKey,
        json.encode(list.map((e) => e.toJson()).toList()),
      );
      return list;
    } catch (e) {
      debugPrint(
        '[TxHierarchyRepo] Error fetching/caching Categories for $accountTypeId: $e',
      );
      if (e is HierarchyApiException && e.statusCode == 401) rethrow;
      return [];
    }
  }

  Future<List<Subcategory>> fetchSubcategories(
    String categoryId, {
    bool forceRefresh = false,
  }) async {
    final box = Hive.box<String>(_hierarchyCacheBoxName);
    final cacheKey = 'subcategories_for_category_$categoryId';
    final isOnline = await _connectivityService.isOnline;

    if (isOnline && forceRefresh) {
      return _fetchAndCacheSubcategories(box, cacheKey, categoryId);
    } else if (isOnline) {
      final cachedJson = box.get(cacheKey);
      if (cachedJson != null) {
        try {
          return _deserializeList(cachedJson, Subcategory.fromJson);
        } catch (e) {}
      }
      return _fetchAndCacheSubcategories(box, cacheKey, categoryId);
    } else {
      final cachedJson = box.get(cacheKey);
      if (cachedJson != null) {
        try {
          return _deserializeList(cachedJson, Subcategory.fromJson);
        } catch (e) {
          return [];
        }
      }
      return [];
    }
  }

  Future<List<Subcategory>> _fetchAndCacheSubcategories(
    Box<String> box,
    String cacheKey,
    String categoryId,
  ) async {
    try {
      final list = await service.fetchSubcategories(categoryId);
      await box.put(
        cacheKey,
        json.encode(list.map((e) => e.toJson()).toList()),
      );
      return list;
    } catch (e) {
      debugPrint(
        '[TxHierarchyRepo] Error fetching/caching Subcategories for $categoryId: $e',
      );
      if (e is HierarchyApiException && e.statusCode == 401) rethrow;
      return [];
    }
  }

  // Helper for deserialization
  List<T> _deserializeList<T>(
    String jsonString,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final decodedList = json.decode(jsonString) as List<dynamic>;
    return decodedList.map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }

  // Helper to get a single cached category/subcategory by ID (useful for displaying names from IDs)
  // These would iterate through cached lists or use more direct keying if performance is critical.
  // For now, simple iteration through the full cached lists.
  Future<Category?> getCachedCategoryById(String categoryId) async {
    // This is inefficient if called often. Better to cache categories individually by ID.
    // For now, assumes fetchAccountTypes -> fetchCategories populates cache.
    final allAccountTypes = await fetchAccountTypes();
    for (final accType in allAccountTypes) {
      final categories = await fetchCategories(accType.id);
      final found = categories.where((c) => c.id == categoryId);
      if (found.isNotEmpty) return found.first;
    }
    return null;
  }

  Future<Subcategory?> getCachedSubcategoryById(String subcategoryId) async {
    // Similar inefficiency.
    final allAccountTypes = await fetchAccountTypes();
    for (final accType in allAccountTypes) {
      final categories = await fetchCategories(accType.id);
      for (final cat in categories) {
        final subcategories = await fetchSubcategories(cat.id);
        final found = subcategories.where((s) => s.id == subcategoryId);
        if (found.isNotEmpty) return found.first;
      }
    }
    return null;
  }

  Future<void> clearHierarchyCache() async {
    final box = Hive.box<String>(_hierarchyCacheBoxName);
    await box.clear(); // Clears all entries in this specific box
    debugPrint('[TxHierarchyRepo] Cleared hierarchy cache.');
  }
}
