import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:ta_client/features/evaluation/bloc/evaluation_event.dart';
import 'package:ta_client/features/evaluation/bloc/evaluation_state.dart';
import 'package:ta_client/features/evaluation/repositories/evaluation_repository.dart';

class EvaluationBloc extends Bloc<EvaluationEvent, EvaluationState> {
  EvaluationBloc(this._repo) : super(EvaluationState.initial()) {
    on<SelectDateRange>(_onSelectDate);
    on<LoadDashboard>(_onLoadDashboard);
    on<LoadDetail>(_onLoadDetail);
    on<LoadHistory>(_onLoadHistory);
  }
  final EvaluationRepository _repo;
  void _onSelectDate(SelectDateRange e, Emitter<EvaluationState> emit) {
    emit(state.copyWith(start: e.start, end: e.end));
  }

  Future<void> _onLoadDashboard(
    LoadDashboard event,
    Emitter<EvaluationState> emit,
  ) async {
    // 1) Log that the event fired
    debugPrint(
      '🔄 [EvaluationBloc] LoadDashboard fired: start=${state.start}, end=${state.end}',
    );

    if (state.start == null || state.end == null) {
      debugPrint('⚠️ Missing start/end dates, skipping fetch');
      return;
    }

    emit(state.copyWith(loading: true));

    try {
      final items = await _repo.getDashboardItems(state.start!, state.end!);
      // 2) Log the count of items returned
      debugPrint('✅ [EvaluationBloc] fetched ${items.length} dashboard items');
      emit(state.copyWith(dashboardItems: items, loading: false));
    } catch (e, st) {
      // 3) Log any error
      debugPrint('❌ [EvaluationBloc] error in LoadDashboard: $e\n$st');
      emit(state.copyWith(error: e.toString(), loading: false));
    }
  }

  Future<void> _onLoadDetail(
    LoadDetail e,
    Emitter<EvaluationState> emit,
  ) async {
    if (state.start != null && state.end != null) {
      emit(state.copyWith(loading: true));
      try {
        final d = await _repo.getDetail(state.start!, state.end!, e.id);
        emit(state.copyWith(detailItem: d, loading: false));
      } catch (e) {
        emit(state.copyWith(error: e.toString(), loading: false));
      }
    }
  }

  Future<void> _onLoadHistory(_, Emitter<EvaluationState> emit) async {
    emit(state.copyWith(loading: true));
    final hist = await _repo.getHistory();
    emit(state.copyWith(history: hist, loading: false));
  }
}
