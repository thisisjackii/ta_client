// lib/features/budgeting/data/services/budgeting_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ta_client/features/budgeting/models/allocation.dart';
import 'package:ta_client/features/budgeting/models/income.dart';

class BudgetingService {
  BudgetingService({required this.baseUrl});
  final String baseUrl;

  Future<void> _ensureDates(DateTime? s, DateTime? e) async {
    if (s == null || e == null) throw ArgumentError('Dates not set');
    final diff = e.difference(s).inDays;
    if (diff < 0) throw ArgumentError('End date must be after start date');
    if (diff > 31) throw ArgumentError('Range cannot exceed 1 month');
  }

  Future<List<Income>> fetchIncomeBuckets(DateTime start, DateTime end) async {
    await _ensureDates(start, end);

    final uri = Uri.parse('$baseUrl/transactions');
    print('[BudgetingService] ▶ FETCHING incomes from $start to $end');
    print('[BudgetingService] ▶ GET $uri');

    final resp = await http.get(uri);
    print(
      '[BudgetingService] ▶ HTTP ${resp.statusCode}: ${resp.body.length} bytes',
    );

    // Decode raw JSON
    final raw = json.decode(resp.body) as List<dynamic>;
    print('[BudgetingService] ▶ DECODED ${raw.length} total transactions');

    // Apply date + type filter
    final filtered = raw.where((item) {
      final tx = item as Map<String, dynamic>;
      final txDate = DateTime.parse(tx['date'] as String);

      // **CHANGE THIS** if your backend uses a different key or casing!
      final catMap = tx['category'] as Map<String, dynamic>;
      final type = (catMap['accountType'] as String).toLowerCase();

      return (type.toLowerCase() == 'income' ||
              type.toLowerCase() == 'pemasukan') &&
          !txDate.isBefore(start) &&
          !txDate.isAfter(end);
    }).toList();

    print(
      '[BudgetingService] ▶ FILTERED ${filtered.length} “income” txns between $start → $end',
    );
    for (final tx in filtered.take(5)) {
      final date = tx['date'];
      final catMap = tx['category'] as Map<String, dynamic>;
      final rawType = catMap['accountType'];
      final amt = tx['amount'];
      print('    • $date │ type=$rawType │ amount=$amt');
    }

    // Sum per categoryName
    final sums = <String, double>{};
    for (final tx in filtered) {
      final catJson = tx['category'] as Map<String, dynamic>;
      final catName = catJson['categoryName'] as String;
      final amt = (tx['amount'] as num).toDouble();
      sums[catName] = (sums[catName] ?? 0) + amt;
    }

    // Map to Income models
    final incomes = sums.entries.map((e) {
      final jsonMap = {
        'id': e.key,
        'title': e.key,
        'value': e.value.toInt(),
      };
      return Income.fromJson(jsonMap);
    }).toList();

    print('[BudgetingService] ▶ RETURNING ${incomes.length} income buckets');
    return incomes;
  }

  Future<List<Allocation>> fetchExpenseBuckets(
    DateTime start,
    DateTime end,
  ) async {
    await _ensureDates(start, end);

    final uri = Uri.parse('$baseUrl/transactions');
    print('[BudgetingService] ▶ FETCHING expenses from $start to $end');
    print('[BudgetingService] ▶ GET $uri');

    final resp = await http.get(uri);
    print(
      '[BudgetingService] ▶ HTTP ${resp.statusCode}: ${resp.body.length} bytes',
    );

    final raw = json.decode(resp.body) as List<dynamic>;
    print('[BudgetingService] ▶ DECODED ${raw.length} total transactions');

    final filtered = raw.where((item) {
      final tx = item as Map<String, dynamic>;
      final txDate = DateTime.parse(tx['date'] as String);

      final catMap = tx['category'] as Map<String, dynamic>;
      final type = (catMap['accountType'] as String).toLowerCase();

      return (type == 'expense' || type == 'pengeluaran') &&
          !txDate.isBefore(start) &&
          !txDate.isAfter(end);
    }).toList();

    print(
      '[BudgetingService] ▶ FILTERED ${filtered.length} “expense” txns between $start → $end',
    );
    for (final tx in filtered.take(5)) {
      final date = tx['date'];
      final catMap = tx['category'] as Map<String, dynamic>;
      final rawType = catMap['accountType'];
      final amt = tx['amount'];
      print('    • $date │ type=$rawType │ amount=$amt');
    }

    final sums = <String, double>{};
    for (final tx in filtered) {
      final catJson = tx['category'] as Map<String, dynamic>;
      final catName = catJson['categoryName'] as String;
      final amt = (tx['amount'] as num).toDouble();
      sums[catName] = (sums[catName] ?? 0) + amt;
    }

    final allocations = sums.entries.map((e) {
      final jsonMap = {
        'id': e.key,
        'title': e.key,
        'target': e.value,
      };
      return Allocation.fromJson(jsonMap);
    }).toList();

    print(
      '[BudgetingService] ▶ RETURNING ${allocations.length} allocation buckets',
    );
    return allocations;
  }
}
