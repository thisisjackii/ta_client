// lib/features/transaction/services/transaction_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ta_client/core/utils/authenticated_client.dart';
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
  TransactionService({required String baseUrl})
    : _baseUrl = baseUrl,
      _client = AuthenticatedClient(http.Client());

  final String _baseUrl;
  final http.Client _client;

  Future<Map<String, dynamic>> classifyTransaction(String description) async {
    // This endpoint might be better placed in a general `ClassifierService` if used elsewhere
    final url = Uri.parse(
      '$_baseUrl/transactions/classify',
    ); // Backend provides this
    debugPrint(
      '[TransactionService-API] POST $url for classification: $description',
    );
    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'text': description}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      try {
        final errorBody = json.decode(response.body) as Map<String, dynamic>;
        throw TransactionApiException(
          errorBody['message'] as String? ?? 'Failed to classify transaction',
          statusCode: response.statusCode,
        );
      } catch (e) {
        throw TransactionApiException(
          'Failed to classify. Server response: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    }
  }

  Future<Transaction> createTransaction(Transaction transaction) async {
    final url = Uri.parse('$_baseUrl/transactions');
    debugPrint(
      '[TransactionService-API] POST $url with: ${transaction.toJson()}',
    );
    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(
        transaction.toJson(),
      ), // toJson() now sends subcategoryId
    );

    if (response.statusCode == 201) {
      return Transaction.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    } else {
      try {
        final errorBody = json.decode(response.body) as Map<String, dynamic>;
        throw TransactionApiException(
          errorBody['message'] as String? ?? 'Failed to create transaction',
          statusCode: response.statusCode,
        );
      } catch (e) {
        throw TransactionApiException(
          'Failed to create transaction. Server response: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    }
  }

  Future<Transaction> updateTransaction(Transaction transaction) async {
    if (transaction.id.isEmpty || transaction.id.startsWith('local_')) {
      throw ArgumentError(
        'Cannot update transaction without a valid backend ID.',
      );
    }
    final url = Uri.parse('$_baseUrl/transactions/${transaction.id}');
    debugPrint(
      '[TransactionService-API] PUT $url with: ${transaction.toJson()}',
    );
    final response = await _client.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(transaction.toJson()),
    );

    if (response.statusCode == 200) {
      return Transaction.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    } else {
      try {
        final errorBody = json.decode(response.body) as Map<String, dynamic>;
        throw TransactionApiException(
          errorBody['message'] as String? ?? 'Failed to update transaction',
          statusCode: response.statusCode,
        );
      } catch (e) {
        throw TransactionApiException(
          'Failed to update transaction. Server response: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    if (transactionId.isEmpty || transactionId.startsWith('local_')) {
      throw ArgumentError(
        'Cannot delete transaction without a valid backend ID for API call.',
      );
    }
    final url = Uri.parse('$_baseUrl/transactions/$transactionId');
    debugPrint('[TransactionService-API] DELETE $url');
    final response = await _client.delete(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 204) {
      // No content on successful delete
      return;
    } else {
      try {
        final errorBody = json.decode(response.body) as Map<String, dynamic>;
        throw TransactionApiException(
          errorBody['message'] as String? ?? 'Failed to delete transaction',
          statusCode: response.statusCode,
        );
      } catch (e) {
        throw TransactionApiException(
          'Failed to delete transaction. Server response: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    }
  }

  Future<List<Transaction>> fetchTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? subcategoryId,
    String? categoryId,
  }) async {
    final queryParams = <String, String>{};
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
    if (subcategoryId != null) queryParams['subcategoryId'] = subcategoryId;
    if (categoryId != null) queryParams['categoryId'] = categoryId;
    // Add other filter params as supported by backend (e.g., bookmarked, amount range)

    final url = Uri.parse(
      '$_baseUrl/transactions',
    ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
    debugPrint('[TransactionService-API] GET $url');
    final response = await _client.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List<dynamic>;
      return data
          .map(
            (jsonItem) =>
                Transaction.fromJson(jsonItem as Map<String, dynamic>),
          )
          .toList();
    } else {
      try {
        final errorBody = json.decode(response.body) as Map<String, dynamic>;
        throw TransactionApiException(
          errorBody['message'] as String? ?? 'Failed to fetch transactions',
          statusCode: response.statusCode,
        );
      } catch (e) {
        throw TransactionApiException(
          'Failed to fetch transactions. Server response: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    }
  }

  Future<Transaction> toggleBookmark(String transactionId) async {
    if (transactionId.isEmpty || transactionId.startsWith('local_')) {
      throw ArgumentError(
        'Cannot toggle bookmark for a transaction without a valid backend ID.',
      );
    }
    final url = Uri.parse('$_baseUrl/transactions/$transactionId/bookmark');
    debugPrint('[TransactionService-API] POST $url (bookmark)');
    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return Transaction.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    } else {
      try {
        final errorBody = json.decode(response.body) as Map<String, dynamic>;
        throw TransactionApiException(
          errorBody['message'] as String? ?? 'Failed to toggle bookmark',
          statusCode: response.statusCode,
        );
      } catch (e) {
        throw TransactionApiException(
          'Failed to toggle bookmark. Server response: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    }
  }
}
