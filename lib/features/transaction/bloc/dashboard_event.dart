import 'package:equatable/equatable.dart';
import 'package:ta_client/features/transaction/models/transaction.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object> get props => [];
}

class DashboardReloadRequested extends DashboardEvent {}

class DashboardItemDeleted extends DashboardEvent {
  const DashboardItemDeleted(this.item);

  final Transaction item;

  @override
  List<Object> get props => [item];
}
