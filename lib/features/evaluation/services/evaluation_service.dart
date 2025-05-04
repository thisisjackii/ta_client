// lib/features/evaluation/services/evaluation_service.dart
import 'package:ta_client/features/evaluation/models/evaluation.dart';
import 'package:ta_client/features/evaluation/models/history.dart';
import 'package:ta_client/features/evaluation/utils/evaluation_calculator.dart';
import 'package:ta_client/features/transaction/services/transaction_service.dart';

class EvaluationService {
  EvaluationService({required this.transactionService});
  final TransactionService transactionService;

  /// Fetch all txns, filter by [start]..[end], then compute each RatioDef.
  Future<List<Evaluation>> fetchDashboard(DateTime start, DateTime end) async {
    final all = await transactionService.fetchTransactions();
    final inRange = all
        .where((t) => !t.date.isBefore(start) && !t.date.isAfter(end))
        .toList();

    return evaluationDefinitions().map((def) {
      final v = def.compute(inRange);
      return Evaluation(
        id: def.id,
        title: def.title,
        yourValue: v,
        idealText: def.idealText,
        isIdeal: def.isIdeal(v),
      );
    }).toList();
  }

  Future<Evaluation> fetchDetail(DateTime start, DateTime end, String id) {
    return fetchDashboard(
      start,
      end,
    ).then((list) => list.firstWhere((e) => e.id == id));
  }

  Future<List<History>> fetchHistory() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return [
      History(
        start: DateTime(2024),
        end: DateTime(2024, 3, 31),
        ideal: 3,
        notIdeal: 2,
        incomplete: 1,
      ),
      History(
        start: DateTime(2024, 4),
        end: DateTime(2024, 6, 30),
        ideal: 5,
        notIdeal: 0,
        incomplete: 1,
      ),
      History(
        start: DateTime(2024, 7),
        end: DateTime(2024, 9, 30),
        ideal: 2,
        notIdeal: 4,
        incomplete: 0,
      ),
    ];
  }
}
