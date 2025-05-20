// lib/features/transaction/repositories/transaction_hierarchy_repository.dart
import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import 'package:ta_client/core/services/connectivity_service.dart';
import 'package:ta_client/core/services/hive_service.dart';
import 'package:ta_client/core/services/service_locator.dart';
import 'package:ta_client/features/transaction/models/account_type.dart';
import 'package:ta_client/features/transaction/models/category.dart';
import 'package:ta_client/features/transaction/models/subcategory.dart';
import 'package:ta_client/features/transaction/services/transaction_hierarchy_service.dart';

class TransactionHierarchyRepository {
  TransactionHierarchyRepository({required this.service})
    : _connectivityService = sl<ConnectivityService>(),
      _hiveService = sl<HiveService>() {
    // No _initHiveBox needed, bootstrap.dart handles global opening
  }

  final TransactionHierarchyService service;
  final ConnectivityService _connectivityService;
  final HiveService _hiveService; // Injected

  static const String hierarchyCacheBoxName =
      'transactionHierarchyCache_v1'; // Versioned cache key

  Future<List<AccountType>> fetchAccountTypes({
    bool forceRefresh = false,
  }) async {
    const cacheKey = 'all_account_types';
    final isOnline = await _connectivityService.isOnline;

    if (isOnline && forceRefresh) {
      return _fetchAndCacheAccountTypes(cacheKey);
    } else if (isOnline) {
      final cachedJson = await _hiveService.getJsonString(
        hierarchyCacheBoxName,
        cacheKey,
      );
      if (cachedJson != null) {
        try {
          return _deserializeList(cachedJson, AccountType.fromJson);
        } catch (e) {
          /* Corrupted, will fetch again */
          debugPrint('[TxHierarchyRepo] Cached AccountTypes corrupted: $e');
        }
      }
      return _fetchAndCacheAccountTypes(cacheKey);
    } else {
      // Offline
      final cachedJson = await _hiveService.getJsonString(
        hierarchyCacheBoxName,
        cacheKey,
      );
      if (cachedJson != null) {
        try {
          return _deserializeList(cachedJson, AccountType.fromJson);
        } catch (e) {
          return [];
        }
      }
      return [];
    }
  }

  Future<List<AccountType>> _fetchAndCacheAccountTypes(String cacheKey) async {
    try {
      final list = await service.fetchAccountTypes();
      await _hiveService.putJsonString(
        hierarchyCacheBoxName,
        cacheKey,
        json.encode(list.map((e) => e.toJson()).toList()),
      );
      return list;
    } catch (e) {
      debugPrint('[TxHierarchyRepo] Error fetching/caching AccountTypes: $e');
      if (e is HierarchyApiException && e.statusCode == 401) rethrow;
      return [];
    }
  }

  Future<List<Category>> fetchCategories(
    String accountTypeId, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'categories_for_account_$accountTypeId';
    final isOnline = await _connectivityService.isOnline;

    if (isOnline && forceRefresh) {
      return _fetchAndCacheCategories(cacheKey, accountTypeId);
    } else if (isOnline) {
      final cachedJson = await _hiveService.getJsonString(
        hierarchyCacheBoxName,
        cacheKey,
      );
      if (cachedJson != null) {
        try {
          return _deserializeList(cachedJson, Category.fromJson);
        } catch (e) {
          /* Corrupted, will fetch again */
          debugPrint('[TxHierarchyRepo] Cached Categories corrupted: $e');
        }
      }
      return _fetchAndCacheCategories(cacheKey, accountTypeId);
    } else {
      // Offline
      final cachedJson = await _hiveService.getJsonString(
        hierarchyCacheBoxName,
        cacheKey,
      );
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
    String cacheKey,
    String accountTypeId,
  ) async {
    try {
      final list = await service.fetchCategories(accountTypeId);
      await _hiveService.putJsonString(
        hierarchyCacheBoxName,
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
    final cacheKey = 'subcategories_for_category_$categoryId';
    final isOnline = await _connectivityService.isOnline;

    if (isOnline && forceRefresh) {
      return _fetchAndCacheSubcategories(cacheKey, categoryId);
    } else if (isOnline) {
      final cachedJson = await _hiveService.getJsonString(
        hierarchyCacheBoxName,
        cacheKey,
      );
      if (cachedJson != null) {
        try {
          return _deserializeList(cachedJson, Subcategory.fromJson);
        } catch (e) {
          /* Corrupted, will fetch again */
          debugPrint('[TxHierarchyRepo] Cached Subcategories corrupted: $e');
        }
      }
      return _fetchAndCacheSubcategories(cacheKey, categoryId);
    } else {
      // Offline
      final cachedJson = await _hiveService.getJsonString(
        hierarchyCacheBoxName,
        cacheKey,
      );
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
    String cacheKey,
    String categoryId,
  ) async {
    try {
      final list = await service.fetchSubcategories(categoryId);
      await _hiveService.putJsonString(
        hierarchyCacheBoxName,
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

  // More efficient single item getters using individual caches (if implemented)
  Future<Category?> getCachedCategoryById(String categoryId) async {
    // This would ideally look up a box where categories are keyed by ID
    // For now, it re-fetches lists to find it, which is inefficient but demonstrates need for better caching.
    // To make this efficient, _fetchAndCacheCategories should also put each category into a 'category_detail_{id}' key.
    debugPrint(
      '[TxHierarchyRepo] getCachedCategoryById is inefficient; consider individual caching by ID.',
    );
    final allAccountTypes =
        await fetchAccountTypes(); // This uses its own cache logic
    for (final accType in allAccountTypes) {
      final categories = await fetchCategories(
        accType.id,
      ); // This uses its own cache logic
      final found = categories.firstWhere(
        (c) => c.id == categoryId,
        orElse: () => const Category(id: '_', name: '_', accountTypeId: '_'),
      );
      if (found.id != '_') return found;
    }
    return null;
  }

  Future<Subcategory?> getCachedSubcategoryById(String subcategoryId) async {
    debugPrint(
      '[TxHierarchyRepo] getCachedSubcategoryById is inefficient; consider individual caching by ID.',
    );
    final allAccountTypes = await fetchAccountTypes();
    for (final accType in allAccountTypes) {
      final categories = await fetchCategories(accType.id);
      for (final cat in categories) {
        final subcategories = await fetchSubcategories(cat.id);
        final found = subcategories.firstWhere(
          (s) => s.id == subcategoryId,
          orElse: () => const Subcategory(id: '_', name: '_', categoryId: '_'),
        );
        if (found.id != '_') return found;
      }
    }
    return null;
  }

  Future<void> clearHierarchyCache() async {
    await _hiveService.clearBox(hierarchyCacheBoxName);
    debugPrint(
      '[TxHierarchyRepo] Cleared hierarchy cache box: $hierarchyCacheBoxName',
    );
  }
}
