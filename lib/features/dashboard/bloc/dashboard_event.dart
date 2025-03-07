// lib/features/dashboard/bloc/dashboard_event.dart
import 'package:equatable/equatable.dart';
import 'package:ta_client/features/dashboard/models/dashboard_item.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object> get props => [];
}

class DashboardReloadRequested extends DashboardEvent {}

class DashboardItemDeleted extends DashboardEvent {
  const DashboardItemDeleted(this.item);

  final DashboardItem item;

  @override
  List<Object> get props => [item];
}
