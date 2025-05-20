// lib/features/transaction/services/transaction_hierarchy_service.dart
// No dart:convert
import 'package:dio/dio.dart'; // Import Dio
import 'package:flutter/foundation.dart' hide Category;
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
  TransactionHierarchyService({required Dio dio}) : _dio = dio; // Inject Dio
  final Dio _dio;

  Future<List<AccountType>> fetchAccountTypes() async {
    const endpoint =
        '/category-hierarchy/account-types'; // Corrected endpoint from previous analysis
    debugPrint('[TxHierarchyService-DIO] GET $endpoint');
    try {
      final response = await _dio.get<dynamic>(endpoint);
      // Backend returns { success: true, data: AccountType[] }
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final responseMap = response.data as Map<String, dynamic>;
        if (responseMap['success'] == true && responseMap['data'] is List) {
          return (responseMap['data'] as List)
              .map((e) => AccountType.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      throw HierarchyApiException(
        response.data?['message']?.toString() ??
            'Failed to load account types from server.',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      debugPrint(
        '[TxHierarchyService-DIO] DioException fetching AccountTypes: ${e.response?.data ?? e.message}',
      );
      throw HierarchyApiException(
        e.response?.data?['message']?.toString() ??
            e.message ??
            'Network error fetching account types.',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      debugPrint(
        '[TxHierarchyService-DIO] Unexpected error fetching AccountTypes: $e',
      );
      if (e is HierarchyApiException) rethrow;
      throw HierarchyApiException(
        'An unexpected error occurred while fetching account types: ${e}',
      );
    }
  }

  Future<List<Category>> fetchCategories(String accountTypeId) async {
    const endpoint = '/category-hierarchy/categories'; // Corrected endpoint
    final queryParams = {'accountTypeId': accountTypeId};
    debugPrint(
      '[TxHierarchyService-DIO] GET $endpoint with params: $queryParams',
    );
    try {
      final response = await _dio.get<dynamic>(
        endpoint,
        queryParameters: queryParams,
      );
      // Backend returns { success: true, data: Category[] }
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final responseMap = response.data as Map<String, dynamic>;
        if (responseMap['success'] == true && responseMap['data'] is List) {
          return (responseMap['data'] as List)
              .map((e) => Category.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      throw HierarchyApiException(
        response.data?['message']?.toString() ??
            'Failed to load categories from server.',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      debugPrint(
        '[TxHierarchyService-DIO] DioException fetching Categories: ${e.response?.data ?? e.message}',
      );
      throw HierarchyApiException(
        e.response?.data?['message']?.toString() ??
            e.message ??
            'Network error fetching categories.',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      debugPrint(
        '[TxHierarchyService-DIO] Unexpected error fetching Categories: $e',
      );
      if (e is HierarchyApiException) rethrow;
      throw HierarchyApiException(
        'An unexpected error occurred while fetching categories: ${e}',
      );
    }
  }

  Future<List<Subcategory>> fetchSubcategories(String categoryId) async {
    const endpoint = '/category-hierarchy/subcategories'; // Corrected endpoint
    final queryParams = {'categoryId': categoryId};
    debugPrint(
      '[TxHierarchyService-DIO] GET $endpoint with params: $queryParams',
    );
    try {
      final response = await _dio.get<dynamic>(
        endpoint,
        queryParameters: queryParams,
      ); // Ensure type for response.data
      // Backend returns { success: true, data: Subcategory[] }
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final responseMap = response.data as Map<String, dynamic>;
        if (responseMap['success'] == true && responseMap['data'] is List) {
          return (responseMap['data'] as List)
              .map((e) => Subcategory.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      throw HierarchyApiException(
        response.data?['message']?.toString() ??
            'Failed to load subcategories from server.',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      debugPrint(
        '[TxHierarchyService-DIO] DioException fetching Subcategories: ${e.response?.data ?? e.message}',
      );
      throw HierarchyApiException(
        e.response?.data?['message']?.toString() ??
            e.message ??
            'Network error fetching subcategories.',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      debugPrint(
        '[TxHierarchyService-DIO] Unexpected error fetching Subcategories: $e',
      );
      if (e is HierarchyApiException) rethrow;
      throw HierarchyApiException(
        'An unexpected error occurred while fetching subcategories: ${e}',
      );
    }
  }
}
