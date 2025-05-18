// lib/features/transaction/repositories/transaction_hierarchy_repository.dart

import 'package:hive/hive.dart';
import 'package:ta_client/features/transaction/models/account_type.dart';
import 'package:ta_client/features/transaction/models/category.dart';
import 'package:ta_client/features/transaction/models/subcategory.dart';
import 'package:ta_client/features/transaction/services/transaction_hierarchy_service.dart';

class TransactionHierarchyRepository {
  TransactionHierarchyRepository({required this.service});
  final TransactionHierarchyService service;

  static const _boxName = 'hierarchyBox';

  /// Fetch all account types, caching results under 'accountTypes'
  Future<List<AccountType>> fetchAccountTypes({required bool isOnline}) async {
    final box = await Hive.openBox<dynamic>(_boxName);

    if (isOnline) {
      final list = await service.fetchAccountTypes();
      await box.put('accountTypes', list.map((e) => e.toJson()).toList());
      return list;
    } else {
      final raw = box.get('accountTypes') as List<dynamic>?;
      if (raw != null) {
        return raw
            .cast<Map<String, dynamic>>()
            .map((m) => AccountType.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
      return [];
    }
  }

  /// Fetch categories for a given accountTypeId, caching under 'categories_<id>'
  Future<List<Category>> fetchCategories(
    String accountTypeId, {
    required bool isOnline,
  }) async {
    final box = await Hive.openBox<dynamic>(_boxName);
    final key = 'categories_$accountTypeId';

    if (isOnline) {
      final list = await service.fetchCategories(accountTypeId);
      await box.put(key, list.map((e) => e.toJson()).toList());
      return list;
    } else {
      final raw = box.get(key) as List<dynamic>?;
      if (raw != null) {
        return raw
            .cast<Map<String, dynamic>>()
            .map((m) => Category.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
      return [];
    }
  }

  /// Fetch subcategories for a given categoryId, caching under 'subcategories_<id>'
  Future<List<Subcategory>> fetchSubcategories(
    String categoryId, {
    required bool isOnline,
  }) async {
    final box = await Hive.openBox<dynamic>(_boxName);
    final key = 'subcategories_$categoryId';

    if (isOnline) {
      final list = await service.fetchSubcategories(categoryId);
      await box.put(key, list.map((e) => e.toJson()).toList());
      return list;
    } else {
      final raw = box.get(key) as List<dynamic>?;
      if (raw != null) {
        return raw
            .cast<Map<String, dynamic>>()
            .map((m) => Subcategory.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
      return [];
    }
  }

  /// Optional: clear all hierarchy caches
  Future<void> clearCache() async {
    final box = await Hive.openBox<dynamic>(_boxName);
    await box.delete('accountTypes');
    for (final key in box.keys.where(
      (k) =>
          k.toString().startsWith('categories_') ||
          k.toString().startsWith('subcategories_'),
    )) {
      await box.delete(key);
    }
  }
}
