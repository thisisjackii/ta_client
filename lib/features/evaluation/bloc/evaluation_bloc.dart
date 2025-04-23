import 'package:bloc/bloc.dart';
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

  Future<void> _onLoadDashboard(_, Emitter<EvaluationState> emit) async {
    if (state.start == null || state.end == null) return;
    emit(state.copyWith(loading: true));
    final items = await _repo.getDashboardItems(state.start!, state.end!);
    emit(state.copyWith(dashboardItems: items, loading: false));
  }

  Future<void> _onLoadDetail(
      LoadDetail e, Emitter<EvaluationState> emit,) async {
    emit(state.copyWith(loading: true));
    final item = await _repo.getDetailItem(e.id);
    emit(state.copyWith(detailItem: item, loading: false));
  }

  Future<void> _onLoadHistory(_, Emitter<EvaluationState> emit) async {
    emit(state.copyWith(loading: true));
    final hist = await _repo.getHistory();
    emit(state.copyWith(history: hist, loading: false));
  }
}
