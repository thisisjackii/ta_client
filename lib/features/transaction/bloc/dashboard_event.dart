// lib/features/transaction/bloc/dashboard_event.dart
part of 'dashboard_bloc.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object> get props => [];
}

class DashboardReloadRequested extends DashboardEvent {}

class DashboardItemAdded extends DashboardEvent {
  const DashboardItemAdded(this.item);

  final Transaction item;

  @override
  List<Object> get props => [item];
}

class DashboardItemDeleted extends DashboardEvent {
  const DashboardItemDeleted(this.item);

  final Transaction item;

  @override
  List<Object> get props => [item];
}
