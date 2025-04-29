// lib/features/budgeting/data/services/budgeting_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ta_client/core/utils/authenticated_client.dart';
import 'package:ta_client/features/budgeting/models/allocation.dart';
import 'package:ta_client/features/budgeting/models/income.dart';

/// Thrown when the server returns a 401.
class UnauthorizedException implements Exception {
  UnauthorizedException([this.message = 'Unauthorized']);
  final String message;
  @override
  String toString() => 'UnauthorizedException: $message';
}

class BudgetingService {
  BudgetingService({required String baseUrl})
    : _baseUrl = baseUrl,
      _client = AuthenticatedClient(http.Client());

  final String _baseUrl;
  final http.Client _client;

  Future<void> ensureDates(DateTime? s, DateTime? e) async {
    if (s == null || e == null) {
      throw ArgumentError('Dates not set');
    }
    final diff = e.difference(s).inDays;
    if (diff < 0) {
      throw ArgumentError('End date must be after start date');
    }
    if (diff > 31) {
      throw ArgumentError('Range cannot exceed 1 month');
    }
  }

  Future<List<Income>> fetchIncomeBuckets(DateTime start, DateTime end) async {
    await ensureDates(start, end);

    final uri = Uri.parse('$_baseUrl/transactions');
    final resp = await _client.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (resp.statusCode == 200) {
      final rawList = json.decode(resp.body) as List<dynamic>;
      // filter, sum, and map to Income
      final filtered = rawList.where((item) {
        final tx = item as Map<String, dynamic>;
        final txDate = DateTime.parse(tx['date'] as String);
        final type = (tx['category']['accountType'] as String).toLowerCase();
        return (type == 'income' || type == 'pemasukan') &&
            !txDate.isBefore(start) &&
            !txDate.isAfter(end);
      }).toList();

      // sum by categoryName
      final sums = <String, double>{};
      for (final tx in filtered) {
        final map = tx as Map<String, dynamic>;
        final name = map['category']['categoryName'] as String;
        final amt = (map['amount'] as num).toDouble();
        sums[name] = (sums[name] ?? 0) + amt;
      }

      // build Income models
      return sums.entries.map((e) {
        return Income.fromJson({
          'id': e.key,
          'title': e.key,
          'value': e.value.toInt(),
        });
      }).toList();
    }

    // non-200: parse error JSON
    String msg;
    try {
      final err = json.decode(resp.body) as Map<String, dynamic>;
      msg = err['message'] as String? ?? 'Unknown error';
    } catch (_) {
      msg = 'Server error (${resp.statusCode})';
    }

    if (resp.statusCode == 401) {
      throw UnauthorizedException(msg);
    }
    throw Exception('Error fetching incomes: $msg');
  }

  Future<List<Allocation>> fetchExpenseBuckets(
    DateTime start,
    DateTime end,
  ) async {
    await ensureDates(start, end);

    final uri = Uri.parse('$_baseUrl/transactions');
    final resp = await _client.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (resp.statusCode == 200) {
      final rawList = json.decode(resp.body) as List<dynamic>;
      // filter, sum, and map to Allocation
      final filtered = rawList.where((item) {
        final tx = item as Map<String, dynamic>;
        final txDate = DateTime.parse(tx['date'] as String);
        final type = (tx['category']['accountType'] as String).toLowerCase();
        return (type == 'expense' || type == 'pengeluaran') &&
            !txDate.isBefore(start) &&
            !txDate.isAfter(end);
      }).toList();

      // sum by categoryName
      final sums = <String, double>{};
      for (final tx in filtered) {
        final map = tx as Map<String, dynamic>;
        final name = map['category']['categoryName'] as String;
        final amt = (map['amount'] as num).toDouble();
        sums[name] = (sums[name] ?? 0) + amt;
      }

      return sums.entries.map((e) {
        return Allocation.fromJson({
          'id': e.key,
          'title': e.key,
          'target': e.value,
        });
      }).toList();
    }

    // non-200: parse error JSON
    String msg;
    try {
      final err = json.decode(resp.body) as Map<String, dynamic>;
      msg = err['message'] as String? ?? 'Unknown error';
    } catch (_) {
      msg = 'Server error (${resp.statusCode})';
    }

    if (resp.statusCode == 401) {
      throw UnauthorizedException(msg);
    }
    throw Exception('Error fetching expenses: $msg');
  }
}
