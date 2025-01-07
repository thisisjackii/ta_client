import 'package:equatable/equatable.dart';
import 'package:ta_client/features/dashboard/models/dashboard_item.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object> get props => [];
}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  const DashboardLoaded(this.items);

  final List<DashboardItem> items;

  @override
  List<Object> get props => [items];
}

class DashboardError extends DashboardState {
  const DashboardError(this.errorMessage);

  final String errorMessage;

  @override
  List<Object> get props => [errorMessage];
}
