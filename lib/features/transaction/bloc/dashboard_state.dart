// lib/features/transaction/bloc/dashboard_state.dart
part of 'dashboard_bloc.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object> get props => [];
}

class DashboardLoading extends DashboardState {
  const DashboardLoading({this.items = const [], this.isSyncing = false});
  final List<Transaction> items; // Keep existing items while loading new
  final bool isSyncing;
  @override
  List<Object> get props => [items, isSyncing];
}

class DashboardLoaded extends DashboardState {
  const DashboardLoaded(this.items);
  final List<Transaction> items;
  @override
  List<Object> get props => [items];
}

class DashboardError extends DashboardState {
  const DashboardError(this.errorMessage);
  final String errorMessage;
  @override
  List<Object> get props => [errorMessage];
}

class DashboardUnauthenticated extends DashboardState {}
