// lib/features/evaluation/bloc/evaluation_state.dart
import 'package:equatable/equatable.dart';
import 'package:ta_client/features/evaluation/models/evaluation.dart';
import 'package:ta_client/features/evaluation/models/history.dart';

class EvaluationState extends Equatable {
  const EvaluationState({
    required this.dashboardItems,
    required this.history,
    this.startDate,
    this.endDate,
    this.detailItem,
    this.loading = false,
    this.error,
  });
  factory EvaluationState.initial() =>
      const EvaluationState(dashboardItems: [], history: []);
  final DateTime? startDate;
  final DateTime? endDate;
  final List<Evaluation> dashboardItems;
  final Evaluation? detailItem;
  final List<History> history;
  final bool loading;
  final String? error;
  EvaluationState copyWith({
    DateTime? startDate,
    DateTime? endDate,
    List<Evaluation>? dashboardItems,
    Evaluation? detailItem,
    List<History>? history,
    bool? loading,
    String? error,
  }) {
    return EvaluationState(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      dashboardItems: dashboardItems ?? this.dashboardItems,
      detailItem: detailItem ?? this.detailItem,
      history: history ?? this.history,
      loading: loading ?? this.loading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    startDate,
    endDate,
    dashboardItems,
    detailItem,
    history,
    loading,
    error,
  ];
}
