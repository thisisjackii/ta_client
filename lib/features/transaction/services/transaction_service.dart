// lib/features/transaction/services/transaction_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ta_client/features/transaction/models/transaction.dart';

class TransactionService {
  TransactionService({required this.baseUrl});
  final String baseUrl;

  Future<List<Transaction>> fetchTransactions() async {
    final url = Uri.parse('$baseUrl/transactions');
    debugPrint('Fetching transactions from $url');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data
          .map((json) => Transaction.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
        'Failed to fetch transactions. Status code: ${response.statusCode}. Response body: ${response.body}',
      );
    }
  }

  Future<void> createTransaction(Transaction transaction) async {
    final url = Uri.parse('$baseUrl/transactions');
    debugPrint('Posting transaction: ${transaction.toJson()} to $url');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(transaction.toJson()),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to create transaction. Status code: ${response.statusCode}. Response body: ${response.body}',
      );
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    final url = Uri.parse('$baseUrl/transactions/${transaction.id}');
    debugPrint(
      'Updating transaction at $url with data: ${transaction.toJson()}',
    );
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(transaction.toJson()),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to update transaction. Status code: ${response.statusCode}. Response body: ${response.body}',
      );
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    final url = Uri.parse('$baseUrl/transactions/$transactionId');
    debugPrint('Deleting transaction at $url');
    final response = await http.delete(url);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to delete transaction. Status code: ${response.statusCode}. Response body: ${response.body}',
      );
    }
  }

  Future<Map<String, dynamic>> classifyTransaction(String description) async {
    final url = Uri.parse('$baseUrl/transactions/classify');
    debugPrint('Classifying transaction with description: $description');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'text': description}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      debugPrint('Classification result: $data');
      return data;
    } else {
      throw Exception(
        'Failed to classify transaction. Status code: ${response.statusCode}. Response body: ${response.body}',
      );
    }
  }
}
