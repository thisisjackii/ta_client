// lib/features/transaction/bloc/dashboard_event.dart
part of 'dashboard_bloc.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();
  @override
  List<Object> get props => [];
}

class DashboardItemAdded extends DashboardEvent {
  const DashboardItemAdded(this.item);

  final Transaction item;

  @override
  List<Object> get props => [item];
}

class DashboardLoadRequested extends DashboardEvent {}

class DashboardForceRefreshRequested
    extends DashboardEvent {} // For pull-to-refresh or sync completion

// Events to update dashboard list based on TransactionBloc actions
// These are dispatched by UI or by listening to another BLoC (advanced)
class DashboardTransactionCreated extends DashboardEvent {
  const DashboardTransactionCreated(this.transaction);
  final Transaction transaction;
  @override
  List<Object> get props => [transaction];
}

class DashboardTransactionUpdated extends DashboardEvent {
  const DashboardTransactionUpdated(this.transaction);
  final Transaction transaction;
  @override
  List<Object> get props => [transaction];
}

class DashboardTransactionDeleted extends DashboardEvent {
  const DashboardTransactionDeleted(this.transactionId);
  final String transactionId;
  @override
  List<Object> get props => [transactionId];
}

class DashboardSyncPendingRequested extends DashboardEvent {}
