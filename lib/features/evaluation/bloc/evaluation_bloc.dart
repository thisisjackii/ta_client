// lib/features/evaluation/bloc/evaluation_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
// No longer need ConnectivityService here, Repository handles it.
import 'package:ta_client/features/evaluation/bloc/evaluation_event.dart';
import 'package:ta_client/features/evaluation/bloc/evaluation_state.dart';
import 'package:ta_client/features/evaluation/repositories/evaluation_repository.dart';
import 'package:ta_client/features/evaluation/services/evaluation_service.dart'; // For EvaluationApiException

class EvaluationBloc extends Bloc<EvaluationEvent, EvaluationState> {
  EvaluationBloc(this._repo) : super(EvaluationState.initial()) {
    on<EvaluationDateRangeSelected>(_onDateRangeSelected);
    on<EvaluationLoadDashboardRequested>(_onLoadDashboard); // Unified event
    on<EvaluationLoadDetailRequested>(_onLoadDetail);
    on<EvaluationLoadHistoryRequested>(_onLoadHistory);
  }
  final EvaluationRepository _repo;

  void _onDateRangeSelected(
    EvaluationDateRangeSelected event,
    Emitter<EvaluationState> emit,
  ) {
    emit(
      state.copyWith(
        startDate: event.start,
        endDate: event.end,
        dashboardItems: [], // Clear previous dashboard items
      ),
    );
    // Automatically trigger dashboard load after dates are selected
    add(
      EvaluationLoadDashboardRequested(periodId: event.periodId),
    ); // Pass periodId if available from date selection step
  }

  Future<void> _onLoadDashboard(
    EvaluationLoadDashboardRequested event,
    Emitter<EvaluationState> emit,
  ) async {
    if (state.startDate == null || state.endDate == null) {
      emit(state.copyWith(error: 'Date range not selected.', loading: false));
      return;
    }
    debugPrint(
      '[EvaluationBloc] LoadDashboard triggered: periodId=${event.periodId}, start=${state.startDate}, end=${state.endDate}',
    );
    emit(state.copyWith(loading: true, dashboardItems: []));
    try {
      // Repository now handles online/offline logic
      final items = await _repo.getDashboardItems(
        periodId: event.periodId, // Pass if backend uses periodId
        startDate: state.startDate!,
        endDate: state.endDate!,
      );
      debugPrint(
        '[EvaluationBloc] Fetched/Calculated ${items.length} dashboard items',
      );
      emit(state.copyWith(dashboardItems: items, loading: false));
    } on EvaluationApiException catch (e) {
      debugPrint('[EvaluationBloc] API Error: ${e.message}');
      emit(state.copyWith(error: e.message, loading: false));
    } catch (e, st) {
      debugPrint('[EvaluationBloc] General error in _onLoadDashboard: $e\n$st');
      emit(
        state.copyWith(
          error: 'Failed to load evaluation dashboard: $e',
          loading: false,
        ),
      );
    }
  }

  Future<void> _onLoadDetail(
    EvaluationLoadDetailRequested event,
    Emitter<EvaluationState> emit,
  ) async {
    emit(state.copyWith(loading: true));
    try {
      // Repository handles online/offline logic
      final detail = await _repo.getDetail(
        evaluationResultDbId: event.evaluationResultDbId,
        clientRatioId: event.clientRatioId,
        // The repository will need startDate and endDate for offline calculation context
        // These should be available in the BLoC state if dashboard was loaded.
        startDate: state.startDate!,
        endDate: state.endDate!,
      );
      emit(state.copyWith(detailItem: detail, loading: false));
    } on EvaluationApiException catch (e) {
      debugPrint('[EvaluationBloc] API Error loading detail: ${e.message}');
      emit(state.copyWith(error: e.message, loading: false));
    } catch (e, st) {
      debugPrint('[EvaluationBloc] General error in _onLoadDetail: $e\n$st');
      emit(
        state.copyWith(
          error: 'Failed to load evaluation detail: $e',
          loading: false,
        ),
      );
    }
  }

  Future<void> _onLoadHistory(
    EvaluationLoadHistoryRequested event,
    Emitter<EvaluationState> emit,
  ) async {
    emit(state.copyWith(loading: true, history: []));
    try {
      // Repository handles online/offline (history is likely online-only via repo)
      final hist = await _repo.getEvaluationHistory(
        startDate: event.startDate,
        endDate: event.endDate,
      );
      emit(state.copyWith(history: hist, loading: false));
    } on EvaluationApiException catch (e) {
      debugPrint('[EvaluationBloc] API Error loading history: ${e.message}');
      emit(state.copyWith(error: e.message, loading: false));
    } catch (e, st) {
      debugPrint('[EvaluationBloc] General error in _onLoadHistory: $e\n$st');
      emit(state.copyWith(error: e.toString(), loading: false));
    }
  }
}
