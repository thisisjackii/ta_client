// lib/features/evaluation/bloc/evaluation_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:ta_client/features/budgeting/repositories/period_repository.dart';
// No longer need ConnectivityService here, Repository handles it.
import 'package:ta_client/features/evaluation/bloc/evaluation_event.dart';
import 'package:ta_client/features/evaluation/bloc/evaluation_state.dart';
import 'package:ta_client/features/evaluation/repositories/evaluation_repository.dart';
import 'package:ta_client/features/evaluation/services/evaluation_service.dart'; // For EvaluationApiException

class EvaluationBloc extends Bloc<EvaluationEvent, EvaluationState> {
  EvaluationBloc(this._repo, this._periodRepo /*this._connectivityService*/)
    : super(EvaluationState.initial()) {
    on<EvaluationDateRangeSelected>(_onDateRangeSelected);
    on<EvaluationLoadDashboardRequested>(_onLoadDashboard); // Unified event
    on<EvaluationLoadDetailRequested>(_onLoadDetail);
    on<EvaluationLoadHistoryRequested>(_onLoadHistory);
  }
  final EvaluationRepository _repo;
  final PeriodRepository _periodRepo; // Injected
  // final ConnectivityService _connectivityService; // Injected

  // Helper to get current userId - assumes ProfileBloc is loaded and available via GetIt
  // This is a simplification; robust userId access might come from an AuthBloc.
  // String? _getCurrentUserId() {
  //   /* ... as before ... */
  //   return null; // Placeholder
  // }

  Future<void> _onDateRangeSelected(
    EvaluationDateRangeSelected event,
    Emitter<EvaluationState> emit,
  ) async {
    emit(
      state.copyWith(
        loading: true,
        startDate: event.start,
        endDate: event.end,
        dashboardItems: [], // Clear previous dashboard items
      ),
    );
    try {
      // Backend's PeriodService.validatePeriodDatesLogic is also called by ensureAndGetPeriod
      // but client-side validation can be good for quick feedback if needed.
      // Your isAtLeastOneMonthAccordingToRequest logic is in the UI page, which is fine.

      // final currentUserId = _getCurrentUserId();
      // ensureAndGetPeriod handles online/offline for period creation/fetching
      final period = await _periodRepo.ensureAndGetPeriod(
        startDate: event.start,
        endDate: event.end,
        periodType:
            'general_evaluation', // Or a more specific type for evaluations
        description:
            'Periode Evaluasi (${DateFormat('dd/MM/yy').format(event.start)}-${DateFormat('dd/MM/yy').format(event.end)})',
        // userIdForLocal: currentUserId, // For offline period creation
      );

      emit(
        state.copyWith(
          // Store the actual period dates from the confirmed/created period object
          startDate: period.startDate,
          endDate: period.endDate,
          // No need to store periodId directly in EvaluationState if LoadDashboard uses start/end
          // But it's good to have if other operations need it.
          // For now, let's assume LoadDashboard will trigger calculateAndFetch with dates,
          // and the repository can re-ensure/fetch period if needed.
          // OR, pass the period.id to LoadDashboardRequested.
          loading: false, // Done with period ensuring
        ),
      );

      // Now trigger dashboard load WITH the confirmed periodId from the 'period' object
      add(EvaluationLoadDashboardRequested(periodId: period.id));
    } catch (e) {
      debugPrint('[EvaluationBloc] Error ensuring period for evaluation: $e');
      emit(
        state.copyWith(
          error: 'Gagal mengatur periode evaluasi: $e',
          loading: false,
        ),
      );
    }
  }

  Future<void> _onLoadDashboard(
    EvaluationLoadDashboardRequested event, // This event now expects periodId
    Emitter<EvaluationState> emit,
  ) async {
    if (event.periodId.isEmpty) {
      // This condition should ideally not be met if _onDateRangeSelected works correctly
      emit(
        state.copyWith(
          error: 'ID Periode dibutuhkan untuk memuat dasbor evaluasi.',
          loading: false,
        ),
      );
      return;
    }
    // startDate and endDate are already in state from _onDateRangeSelected
    if (state.startDate == null || state.endDate == null) {
      emit(
        state.copyWith(
          error: 'Rentang tanggal evaluasi belum diatur.',
          loading: false,
        ),
      );
      return;
    }

    debugPrint(
      '[EvaluationBloc] LoadDashboard triggered with periodId: ${event.periodId}',
    );
    emit(state.copyWith(loading: true, dashboardItems: []));
    try {
      final items = await _repo.getDashboardItems(
        periodId: event.periodId, // Pass periodId to the repository
        startDate:
            state.startDate!, // Still pass for offline calculation in repo
        endDate: state.endDate!, // Still pass for offline calculation in repo
      );
      emit(state.copyWith(dashboardItems: items, loading: false));
    } on EvaluationApiException catch (e) {
      emit(state.copyWith(error: e.message, loading: false));
    } catch (e) {
      emit(
        state.copyWith(
          error: 'Gagal memuat dasbor evaluasi: $e',
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
