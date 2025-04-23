import 'package:equatable/equatable.dart';
import 'package:ta_client/features/evaluation/models/evaluation.dart';
import 'package:ta_client/features/evaluation/models/history.dart';

class EvaluationState extends Equatable {
  const EvaluationState({
    required this.dashboardItems,
    required this.history,
    this.start,
    this.end,
    this.detailItem,
    this.loading = false,
    this.error,
  });
  factory EvaluationState.initial() =>
      const EvaluationState(dashboardItems: [], history: []);
  final DateTime? start;
  final DateTime? end;
  final List<Evaluation> dashboardItems;
  final Evaluation? detailItem;
  final List<History> history;
  final bool loading;
  final String? error;
  EvaluationState copyWith(
      {DateTime? start,
      DateTime? end,
      List<Evaluation>? dashboardItems,
      Evaluation? detailItem,
      List<History>? history,
      bool? loading,
      String? error,}) {
    return EvaluationState(
      start: start ?? this.start,
      end: end ?? this.end,
      dashboardItems: dashboardItems ?? this.dashboardItems,
      detailItem: detailItem ?? this.detailItem,
      history: history ?? this.history,
      loading: loading ?? this.loading,
      error: error,
    );
  }

  @override
  List<Object?> get props =>
      [start, end, dashboardItems, detailItem, history, loading, error];
}
