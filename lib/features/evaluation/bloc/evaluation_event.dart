// lib/features/evaluation/bloc/evaluation_event.dart
import 'package:equatable/equatable.dart';

abstract class EvaluationEvent extends Equatable {
  const EvaluationEvent();
  @override
  List<Object?> get props => [];
}

class EvaluationDateRangeSelected extends EvaluationEvent {
  const EvaluationDateRangeSelected(this.start, this.end, {this.periodId});
  final DateTime start;
  final DateTime end;
  final String? periodId; // Optional: if a specific Period was created/selected
  @override
  List<Object?> get props => [start, end, periodId];
}

// Unified event for loading the dashboard; repository will decide online/offline
class EvaluationLoadDashboardRequested extends EvaluationEvent {
  // Optional: if backend uses periodId for /calculate
  const EvaluationLoadDashboardRequested({this.periodId});
  final String? periodId;
  @override
  List<Object?> get props => [periodId];
}

class EvaluationLoadDetailRequested extends EvaluationEvent {
  // For offline detail (client-side ratio ID '0', '1', etc.)

  const EvaluationLoadDetailRequested({
    this.evaluationResultDbId,
    this.clientRatioId,
  }) : assert(
         evaluationResultDbId != null || clientRatioId != null,
         'Either evaluationResultDbId or clientRatioId must be provided',
       );
  final String?
  evaluationResultDbId; // For online detail (ID of EvaluationResult record)
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
