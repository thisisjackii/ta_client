// lib/features/transaction/services/transaction_service.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ta_client/features/transaction/models/transaction.dart';

class TransactionApiException implements Exception {
  TransactionApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() =>
      'TransactionApiException: $message (Status Code: $statusCode)';
}

class TransactionService {
  TransactionService({required Dio dio}) : _dio = dio;
  final Dio _dio;

  Future<Map<String, dynamic>> classifyTransaction(String description) async {
    const endpoint = '/transactions/classify';
    final requestBodyMap = {'text': description};
    try {
      final response = await _dio.post<dynamic>(endpoint, data: requestBodyMap);
      // Backend response is { success: bool, data?: {...}, message?: "..." }
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return response.data
            as Map<String, dynamic>; // Return the whole response map
      } else {
        throw TransactionApiException(
          response.data?['message']?.toString() ??
              'Classification failed with status ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      debugPrint(
        '[TransactionService-DIO] DioException classifying: ${e.response?.data ?? e.message}',
      );
      throw TransactionApiException(
        e.response?.data?['message']?.toString() ??
            e.message ??
            'Network error during classification',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      debugPrint('[TransactionService-DIO] Unexpected error classifying: $e');
      if (e is TransactionApiException) rethrow;
      throw TransactionApiException(
        'An unexpected error occurred during classification: $e',
      );
    }
  }

  Future<Transaction> createTransaction(Transaction transaction) async {
    const endpoint = '/transactions';
    final requestJson = transaction.toJson();
    try {
      final response = await _dio.post<dynamic>(endpoint, data: requestJson);
      if (response.statusCode == 201 &&
          response.data is Map<String, dynamic> &&
          response.data['data'] is Map<String, dynamic>) {
        return Transaction.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
      } else {
        throw TransactionApiException(
          response.data?['message']?.toString() ??
              'Failed to create transaction',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      debugPrint(
        '[TransactionService-DIO] DioException creating transaction: ${e.response?.data ?? e.message}',
      );
      throw TransactionApiException(
        e.response?.data?['message']?.toString() ??
            e.message ??
            'Network error creating transaction',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      debugPrint(
        '[TransactionService-DIO] Unexpected error creating transaction: $e',
      );
      if (e is TransactionApiException) rethrow;
      throw TransactionApiException(
        'An unexpected error occurred while creating transaction: $e',
      );
    }
  }

  Future<Transaction> updateTransaction(Transaction transaction) async {
    if (transaction.id.isEmpty || transaction.id.startsWith('local_')) {
      throw ArgumentError(
        'Cannot update transaction without a valid backend ID.',
      );
    }
    final endpoint = '/transactions/${transaction.id}';
    final requestJson = transaction.toJson();
    try {
      final response = await _dio.put<dynamic>(endpoint, data: requestJson);
      if (response.statusCode == 200 &&
          response.data is Map<String, dynamic> &&
          response.data['data'] is Map<String, dynamic>) {
        return Transaction.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
      } else {
        throw TransactionApiException(
          response.data?['message']?.toString() ??
              'Failed to update transaction',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      debugPrint(
        '[TransactionService-DIO] DioException updating transaction: ${e.response?.data ?? e.message}',
      );
      throw TransactionApiException(
        e.response?.data?['message']?.toString() ??
            e.message ??
            'Network error updating transaction',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      debugPrint(
        '[TransactionService-DIO] Unexpected error updating transaction: $e',
      );
      if (e is TransactionApiException) rethrow;
      throw TransactionApiException(
        'An unexpected error occurred while updating transaction: $e',
      );
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    if (transactionId.isEmpty || transactionId.startsWith('local_')) {
      throw ArgumentError(
        'Cannot delete transaction without a valid backend ID for API call.',
      );
    }
    final endpoint = '/transactions/$transactionId';
    try {
      final response = await _dio.delete<dynamic>(endpoint);
      if (response.statusCode == 204) {
        return;
      } else {
        throw TransactionApiException(
          response.data?['message']?.toString() ??
              'Failed to delete transaction',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      debugPrint(
        '[TransactionService-DIO] DioException deleting transaction: ${e.response?.data ?? e.message}',
      );
      throw TransactionApiException(
        e.response?.data?['message']?.toString() ??
            e.message ??
            'Network error deleting transaction',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      debugPrint(
        '[TransactionService-DIO] Unexpected error deleting transaction: $e',
      );
      if (e is TransactionApiException) rethrow;
      throw TransactionApiException(
        'An unexpected error occurred while deleting transaction: $e',
      );
    }
  }

  Future<List<Transaction>> fetchTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? subcategoryId,
    bool? isBookmarked,
    int? page,
    int? limit,
  }) async {
    const endpoint = '/transactions';
    final queryParams = <String, String>{};
    if (startDate != null) {
      queryParams['startDate'] = startDate.toUtc().toIso8601String();
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toUtc().toIso8601String();
    }
    if (categoryId != null) queryParams['categoryId'] = categoryId;
    if (subcategoryId != null) queryParams['subcategoryId'] = subcategoryId;
    if (isBookmarked != null) {
      queryParams['isBookmarked'] = isBookmarked.toString();
    }
    if (page != null) queryParams['page'] = page.toString();
    if (limit != null) queryParams['limit'] = limit.toString();

    try {
      final response = await _dio.get<dynamic>(
        endpoint,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      if (response.statusCode == 200 &&
          response.data is Map<String, dynamic> &&
          response.data['data'] is List) {
        final dataList = response.data['data'] as List<dynamic>;
        return dataList
            .map(
              (jsonItem) =>
                  Transaction.fromJson(jsonItem as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw TransactionApiException(
          response.data?['message']?.toString() ??
              'Failed to fetch transactions',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      debugPrint(
        '[TransactionService-DIO] DioException fetching transactions: ${e.response?.data ?? e.message}',
      );
      throw TransactionApiException(
        e.response?.data?['message']?.toString() ??
            e.message ??
            'Network error fetching transactions',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      debugPrint(
        '[TransactionService-DIO] Unexpected error fetching transactions: $e',
      );
      if (e is TransactionApiException) rethrow;
      throw TransactionApiException(
        'An unexpected error occurred while fetching transactions: $e',
      );
    }
  }

  Future<Transaction> toggleBookmark(String transactionId) async {
    if (transactionId.isEmpty || transactionId.startsWith('local_')) {
      throw ArgumentError(
        'Cannot toggle bookmark for a transaction without a valid backend ID.',
      );
    }
    final endpoint = '/transactions/$transactionId/bookmark';
    try {
      final response = await _dio.post<dynamic>(endpoint);
      if (response.statusCode == 200 &&
          response.data is Map<String, dynamic> &&
          response.data['data'] is Map<String, dynamic>) {
        return Transaction.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
      } else {
        throw TransactionApiException(
          response.data?['message']?.toString() ?? 'Failed to toggle bookmark',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      debugPrint(
        '[TransactionService-DIO] DioException toggling bookmark: ${e.response?.data ?? e.message}',
      );
      throw TransactionApiException(
        e.response?.data?['message']?.toString() ??
            e.message ??
            'Network error toggling bookmark',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      debugPrint(
        '[TransactionService-DIO] Unexpected error toggling bookmark: $e',
      );
      if (e is TransactionApiException) rethrow;
      throw TransactionApiException(
        'An unexpected error occurred while toggling bookmark: $e',
      );
    }
  }
}
