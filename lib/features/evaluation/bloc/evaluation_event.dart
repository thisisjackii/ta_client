// lib/features/evaluation/bloc/evaluation_event.dart
import 'package:equatable/equatable.dart';

abstract class EvaluationEvent extends Equatable {
  const EvaluationEvent();
  @override
  List<Object?> get props => [];
}

class EvaluationDateRangeSelected extends EvaluationEvent {
  const EvaluationDateRangeSelected(
    this.start,
    this.end, {
    this.showDuplicateWarning = true,
  });
  final DateTime start;
  final DateTime end;
  final bool showDuplicateWarning;
  @override
  List<Object?> get props => [start, end, showDuplicateWarning];
}

// This event now directly uses dates from BLoC state if backend /calculate takes dates
// If backend /calculate still needs a periodId, this BLoC needs to create one first
class EvaluationCalculateAndLoadDashboard extends EvaluationEvent {
  const EvaluationCalculateAndLoadDashboard();
}

class EvaluationLoadDetailRequested extends EvaluationEvent {
  const EvaluationLoadDetailRequested({
    this.evaluationResultDbId, // Backend ID of the EvaluationResult record
    this.clientRatioId, // Client-side '0'-'6' for offline calculation
  }) : assert(
         evaluationResultDbId != null || clientRatioId != null,
         'Either evaluationResultDbId or clientRatioId must be provided',
       );
  final String? evaluationResultDbId;
  final String? clientRatioId;

  @override
  List<Object?> get props => [evaluationResultDbId, clientRatioId];
}

class EvaluationLoadHistoryRequested extends EvaluationEvent {
  const EvaluationLoadHistoryRequested({this.startDate, this.endDate});
  final DateTime? startDate;
  final DateTime? endDate;
  @override
  List<Object?> get props => [startDate, endDate];
}

class EvaluationClearError extends EvaluationEvent {}

class EvaluationClearDateError extends EvaluationEvent {}

class EvaluationProceedWithDuplicate extends EvaluationEvent {
  const EvaluationProceedWithDuplicate({
    required this.start,
    required this.end,
  });
  final DateTime start;
  final DateTime end;
  @override
  List<Object?> get props => [start, end];
}

class EvaluationNavigateToExisting extends EvaluationEvent {
  const EvaluationNavigateToExisting({required this.start, required this.end});
  final DateTime start;
  final DateTime end;
  @override
  List<Object?> get props => [start, end];
}

class EvaluationCancelDuplicateWarning extends EvaluationEvent {}
