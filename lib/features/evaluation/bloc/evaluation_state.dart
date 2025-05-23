// lib/features/evaluation/bloc/evaluation_state.dart
import 'package:equatable/equatable.dart';
import 'package:ta_client/features/evaluation/models/evaluation.dart';
import 'package:ta_client/features/evaluation/models/history.dart';

class EvaluationState extends Equatable {
  const EvaluationState({
    this.evaluationStartDate, // Renamed from startDate
    this.evaluationEndDate, // Renamed from endDate
    this.dashboardItems = const [],
    this.history = const [],
    this.detailItem,
    this.loading = false,
    this.error,
    this.dateError, // For specific date validation errors
  });

  factory EvaluationState.initial() => const EvaluationState();

  final DateTime? evaluationStartDate;
  final DateTime? evaluationEndDate;
  final List<Evaluation> dashboardItems;
  final Evaluation? detailItem;
  final List<History> history;
  final bool loading;
  final String? error;
  final String? dateError;

  EvaluationState copyWith({
    DateTime? evaluationStartDate,
    DateTime? evaluationEndDate,
    List<Evaluation>? dashboardItems,
    Evaluation? detailItem,
    bool clearDetailItem = false,
    List<History>? history,
    bool? loading,
    String? error,
    bool clearError = false,
    String? dateError,
    bool clearDateError = false,
  }) {
    return EvaluationState(
      evaluationStartDate: evaluationStartDate ?? this.evaluationStartDate,
      evaluationEndDate: evaluationEndDate ?? this.evaluationEndDate,
      dashboardItems: dashboardItems ?? this.dashboardItems,
      detailItem: clearDetailItem ? null : detailItem ?? this.detailItem,
      history: history ?? this.history,
      loading: loading ?? this.loading,
      error: clearError ? null : error ?? this.error,
      dateError: clearDateError ? null : dateError ?? this.dateError,
    );
  }

  @override
  List<Object?> get props => [
    evaluationStartDate,
    evaluationEndDate,
    dashboardItems,
    detailItem,
    history,
    loading,
    error,
    dateError,
  ];
}
