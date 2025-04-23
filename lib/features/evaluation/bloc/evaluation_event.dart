// lib/features/evaluation/bloc/evaluation_event.dart
import 'package:equatable/equatable.dart';

abstract class EvaluationEvent extends Equatable {
  const EvaluationEvent();
  @override
  List<Object?> get props => [];
}

class LoadIntro extends EvaluationEvent {}

class SelectDateRange extends EvaluationEvent {
  const SelectDateRange(this.start, this.end);
  final DateTime start;
  final DateTime end;
  @override
  List<Object?> get props => [start, end];
}

class LoadDashboard extends EvaluationEvent {}

class LoadDetail extends EvaluationEvent {
  const LoadDetail(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

class LoadHistory extends EvaluationEvent {}
