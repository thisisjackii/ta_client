import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ta_client/features/transaction/models/account_type.dart';
import 'package:ta_client/features/transaction/models/category.dart';
import 'package:ta_client/features/transaction/models/subcategory.dart';

class TransactionHierarchyService {
  TransactionHierarchyService(this._baseUrl) : _client = http.Client();

  final String _baseUrl;
  final http.Client _client;

  /// Fetch all account types
  Future<List<AccountType>> fetchAccountTypes() async {
    final res = await _client.get(Uri.parse('$_baseUrl/account-types'));
    if (res.statusCode != 200) {
      throw Exception('Failed to load account types');
    }
    final data = jsonDecode(res.body) as List;
    return data
        .map((e) => AccountType.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch categories for a given account type
  Future<List<Category>> fetchCategories(String accountTypeId) async {
    final res = await _client.get(
      Uri.parse('$_baseUrl/categories?accountTypeId=$accountTypeId'),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to load categories');
    }
    final data = jsonDecode(res.body) as List;
    return data
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch subcategories for a given category
  Future<List<Subcategory>> fetchSubcategories(String categoryId) async {
    final res = await _client.get(
      Uri.parse('$_baseUrl/subcategories?categoryId=$categoryId'),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to load subcategories');
    }
    final data = jsonDecode(res.body) as List;
    return data
        .map((e) => Subcategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void dispose() {
    _client.close();
  }
}
