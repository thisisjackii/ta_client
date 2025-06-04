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
    this.dateConflictExists = false,
    this.tempSelectedStartDate,
    this.tempSelectedEndDate,
    this.conflictingEvaluationData,
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
  final bool dateConflictExists; // True if user needs to make a choice
  final DateTime? tempSelectedStartDate; // To hold dates while dialog is shown
  final DateTime? tempSelectedEndDate;
  final List<Evaluation>?
  conflictingEvaluationData; // To pre-fill dashboard if user navigates

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
    bool? dateConflictExists,
    DateTime? tempSelectedStartDate,
    bool clearTempSelectedStartDate = false,
    DateTime? tempSelectedEndDate,
    bool clearTempSelectedEndDate = false,
    List<Evaluation>? conflictingEvaluationData,
    bool clearConflictingEvaluationData = false,
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
      dateConflictExists: dateConflictExists ?? this.dateConflictExists,
      tempSelectedStartDate: clearTempSelectedStartDate
          ? null
          : tempSelectedStartDate ?? this.tempSelectedStartDate,
      tempSelectedEndDate: clearTempSelectedEndDate
          ? null
          : tempSelectedEndDate ?? this.tempSelectedEndDate,
      conflictingEvaluationData: clearConflictingEvaluationData
          ? null
          : conflictingEvaluationData ?? this.conflictingEvaluationData,
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
    dateConflictExists,
    tempSelectedStartDate,
    tempSelectedEndDate,
    conflictingEvaluationData,
  ];
}
