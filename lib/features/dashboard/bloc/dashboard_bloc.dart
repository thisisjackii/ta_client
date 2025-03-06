import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/features/dashboard/bloc/dashboard_event.dart';
import 'package:ta_client/features/dashboard/bloc/dashboard_state.dart';
import 'package:ta_client/features/dashboard/models/dashboard_item.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc() : super(DashboardLoading()) {
    on<DashboardReloadRequested>(_onReload);
    on<DashboardItemDeleted>(_onItemDeleted);

    // Load initial data
    add(DashboardReloadRequested());
  }

  /// Handles [DashboardReloadRequested] event.
  //
  /// Emits [DashboardLoading] initially, then attempts to load the dashboard
  /// data. If successful, emits [DashboardLoaded] with the loaded data.
  /// Otherwise, emits [DashboardError] with the error message.
  Future<void> _onReload(
    DashboardReloadRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      // Simulate fetching dashboard data
      await Future.delayed(const Duration(seconds: 2));
      emit(
        DashboardLoaded([
          DashboardItem('Item 1', 'Description 1'),
          DashboardItem('Item 2', 'Description 2'),
          DashboardItem('Item 3', 'Description 3'),
        ]),
      );
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  /// Handles [DashboardItemDeleted] event.
  ///
  /// When an item is deleted, this updates the state by removing the item from
  /// the list of items. This does nothing if the state is not
  /// [DashboardLoaded].
  void _onItemDeleted(
    DashboardItemDeleted event,
    Emitter<DashboardState> emit,
  ) {
    final currentState = state;
    if (currentState is DashboardLoaded) {
      final updatedItems = List.of(currentState.items)..remove(event.item);
      emit(DashboardLoaded(updatedItems));
    }
  }
}
