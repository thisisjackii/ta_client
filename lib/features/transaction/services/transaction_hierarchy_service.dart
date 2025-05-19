// lib/features/transaction/services/transaction_hierarchy_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import 'package:http/http.dart' as http;
import 'package:ta_client/core/utils/authenticated_client.dart'; // Use authenticated client
import 'package:ta_client/features/transaction/models/account_type.dart';
import 'package:ta_client/features/transaction/models/category.dart';
import 'package:ta_client/features/transaction/models/subcategory.dart';

class HierarchyApiException implements Exception {
  HierarchyApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() =>
      'HierarchyApiException: $message (Status Code: $statusCode)';
}

class TransactionHierarchyService {
  TransactionHierarchyService({required String baseUrl})
    : _baseUrl = baseUrl,
      _client = AuthenticatedClient(http.Client()); // Use AuthenticatedClient

  final String _baseUrl;
  final http.Client _client;

  Future<List<AccountType>> fetchAccountTypes() async {
    // Backend endpoint should be protected if this isn't public data
    final url = Uri.parse('$_baseUrl/account-types'); // Example endpoint
    debugPrint('[TransactionHierarchyService-API] GET $url');
    final response = await _client.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List<dynamic>;
      return data
          .map((e) => AccountType.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      try {
        final errorBody = json.decode(response.body) as Map<String, dynamic>;
        throw HierarchyApiException(
          errorBody['message'] as String? ?? 'Failed to load account types',
          statusCode: response.statusCode,
        );
      } catch (e) {
        throw HierarchyApiException(
          'Failed to load account types. Server response: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    }
  }

  Future<List<Category>> fetchCategories(String accountTypeId) async {
    final url = Uri.parse(
      '$_baseUrl/categories?accountTypeId=$accountTypeId',
    ); // Example endpoint
    debugPrint('[TransactionHierarchyService-API] GET $url');
    final response = await _client.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List<dynamic>;
      return data
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      try {
        final errorBody = json.decode(response.body) as Map<String, dynamic>;
        throw HierarchyApiException(
          errorBody['message'] as String? ?? 'Failed to load categories',
          statusCode: response.statusCode,
        );
      } catch (e) {
        throw HierarchyApiException(
          'Failed to load categories. Server response: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    }
  }

  Future<List<Subcategory>> fetchSubcategories(String categoryId) async {
    final url = Uri.parse(
      '$_baseUrl/subcategories?categoryId=$categoryId',
    ); // Example endpoint
    debugPrint('[TransactionHierarchyService-API] GET $url');
    final response = await _client.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List<dynamic>;
      return data
          .map((e) => Subcategory.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      try {
        final errorBody = json.decode(response.body) as Map<String, dynamic>;
        throw HierarchyApiException(
          errorBody['message'] as String? ?? 'Failed to load subcategories',
          statusCode: response.statusCode,
        );
      } catch (e) {
        throw HierarchyApiException(
          'Failed to load subcategories. Server response: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    }
  }

  // No dispose needed for AuthenticatedClient if inner client is managed elsewhere or is default http.Client
}
