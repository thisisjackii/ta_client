// lib/features/evaluation/data/repository/evaluation_repository.dart
import 'package:ta_client/features/evaluation/models/evaluation.dart';
import 'package:ta_client/features/evaluation/models/history.dart';
import 'package:ta_client/features/evaluation/services/evaluation_service.dart';

class EvaluationRepository {
  EvaluationRepository(this._service);
  final EvaluationService _service;
  Future<List<Evaluation>> getDashboardItems(DateTime start, DateTime end) =>
      _service.fetchDashboards(start, end);
  Future<Evaluation> getDetailItem(String id) => _service.fetchDetail(id);
  Future<List<History>> getHistory() => _service.fetchHistory();
}
