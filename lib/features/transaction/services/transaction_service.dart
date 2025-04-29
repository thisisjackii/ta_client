// lib/features/transaction/services/transaction_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ta_client/core/utils/authenticated_client.dart';
import 'package:ta_client/features/transaction/models/transaction.dart';

/// Thrown whenever the server returns a 401
class UnauthorizedException implements Exception {
  UnauthorizedException([this.message = 'Unauthorized']);
  final String message;
  @override
  String toString() => 'UnauthorizedException: $message';
}

class TransactionService {
  TransactionService({required String baseUrl})
    : _baseUrl = baseUrl,
      _client = AuthenticatedClient(http.Client());

  final String _baseUrl;
  final http.Client _client;

  Future<Map<String, dynamic>> classifyTransaction(String description) async {
    final url = Uri.parse('$_baseUrl/transactions/classify');
    debugPrint('Classifying transaction with description: $description');

    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'text': description}),
    );

    switch (response.statusCode) {
      case 200:
        return json.decode(response.body) as Map<String, dynamic>;
      case 401:
        throw UnauthorizedException();
      default:
        throw Exception(
          'Failed to classify transaction. '
          'Status code: ${response.statusCode}. '
          'Response body: ${response.body}',
        );
    }
  }

  Future<void> createTransaction(Transaction transaction) async {
    final url = Uri.parse('$_baseUrl/transactions');
    debugPrint('Creating transaction: ${transaction.toJson()}');

    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(transaction.toJson()),
    );

    if (response.statusCode == 401) {
      throw UnauthorizedException();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to create transaction. '
        'Status code: ${response.statusCode}. '
        'Response body: ${response.body}',
      );
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    final url = Uri.parse('$_baseUrl/transactions/${transaction.id}');
    debugPrint(
      'Updating transaction #${transaction.id}: ${transaction.toJson()}',
    );

    final response = await _client.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(transaction.toJson()),
    );

    if (response.statusCode == 401) {
      throw UnauthorizedException();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to update transaction. '
        'Status code: ${response.statusCode}. '
        'Response body: ${response.body}',
      );
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    final url = Uri.parse('$_baseUrl/transactions/$transactionId');
    debugPrint('Deleting transaction #$transactionId');

    final response = await _client.delete(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 401) {
      throw UnauthorizedException();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to delete transaction. '
        'Status code: ${response.statusCode}. '
        'Response body: ${response.body}',
      );
    }
  }

  Future<List<Transaction>> fetchTransactions() async {
    final url = Uri.parse('$_baseUrl/transactions');
    debugPrint('Fetching transactions from $url');

    final response = await _client.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 401) {
      throw UnauthorizedException();
    }
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch transactions. '
        'Status code: ${response.statusCode}. '
        'Response body: ${response.body}',
      );
    }

    final data = json.decode(response.body) as List<dynamic>;
    return data
        .map((json) => Transaction.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Transaction> toggleBookmark(String transactionId) async {
    final url = Uri.parse('$_baseUrl/transactions/$transactionId/bookmark');
    debugPrint('Toggling bookmark for transaction #$transactionId');

    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 401) {
      throw UnauthorizedException();
    }
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to toggle bookmark. '
        'Status code: ${response.statusCode}. '
        'Response body: ${response.body}',
      );
    }

    return Transaction.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }
}
