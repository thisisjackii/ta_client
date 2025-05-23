// lib/features/evaluation/bloc/evaluation_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
// Removed PeriodRepository import
import 'package:ta_client/features/evaluation/bloc/evaluation_event.dart';
import 'package:ta_client/features/evaluation/bloc/evaluation_state.dart';
import 'package:ta_client/features/evaluation/repositories/evaluation_repository.dart';
import 'package:ta_client/features/evaluation/services/evaluation_service.dart';

class EvaluationBloc extends Bloc<EvaluationEvent, EvaluationState> {
  EvaluationBloc(this._repo) // Removed PeriodRepo
    : super(EvaluationState.initial()) {
    on<EvaluationDateRangeSelected>(_onDateRangeSelected);
    on<EvaluationCalculateAndLoadDashboard>(_onCalculateAndLoadDashboard);
    on<EvaluationLoadDetailRequested>(_onLoadDetail);
    on<EvaluationLoadHistoryRequested>(_onLoadHistory);
    on<EvaluationClearError>(
      (_, emit) => emit(state.copyWith(clearError: true)),
    );
    on<EvaluationClearDateError>(
      (_, emit) => emit(state.copyWith(clearDateError: true)),
    );
  }
  final EvaluationRepository _repo;

  Future<void> _onDateRangeSelected(
    EvaluationDateRangeSelected event,
    Emitter<EvaluationState> emit,
  ) async {
    // Simple date validation (more complex in UI or repo if needed)
    if (event.end.isBefore(event.start)) {
      emit(
        state.copyWith(
          dateError: 'Tanggal akhir tidak boleh sebelum tanggal mulai.',
        ),
      );
      return;
    }
    // PSPEC 4.1 validation for min 1 month (approx 29 days)
    final diffDays = event.end.difference(event.start).inDays;
    if (diffDays < 29) {
      emit(
        state.copyWith(
          dateError: 'Rentang periode evaluasi minimal adalah 1 bulan.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        loading: true, // Indicate loading for the date setting part
        evaluationStartDate: event.start,
        evaluationEndDate: event.end,
        dashboardItems: [],
        clearError: true,
        clearDateError: true,
      ),
    );
    // Dates are set, now trigger calculation and dashboard load
    add(const EvaluationCalculateAndLoadDashboard());
    // emit(state.copyWith(loading: false)); // Loading for calculation will be handled by the next event
  }

  Future<void> _onCalculateAndLoadDashboard(
    EvaluationCalculateAndLoadDashboard event,
    Emitter<EvaluationState> emit,
  ) async {
    if (state.evaluationStartDate == null || state.evaluationEndDate == null) {
      emit(
        state.copyWith(
          error: 'Rentang tanggal evaluasi belum diatur.',
          loading: false,
        ),
      );
      return;
    }

    emit(
      state.copyWith(loading: true, dashboardItems: [], clearError: true),
    ); // Show loading for this specific operation
    try {
      // The repository's getDashboardItems will call the service's
      // calculateAndFetchEvaluationsForPeriod, which now takes startDate and endDate
      // if the backend was updated accordingly.
      // If backend still needs periodId, this BLoC or Repo would need to create one.
      // Assuming backend /calculate endpoint now takes startDate & endDate.
      final items = await _repo.getDashboardItems(
        startDate: state.evaluationStartDate!,
        endDate: state.evaluationEndDate!,
        // periodId is no longer passed if backend calculate is ad-hoc by dates
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
    if (state.evaluationStartDate == null || state.evaluationEndDate == null) {
      emit(
        state.copyWith(
          error: 'Periode evaluasi tidak valid untuk melihat detail.',
          loading: false,
        ),
      );
      return;
    }
    emit(
      state.copyWith(loading: true, clearDetailItem: true, clearError: true),
    );
    try {
      final detail = await _repo.getDetail(
        evaluationResultDbId: event.evaluationResultDbId,
        clientRatioId: event.clientRatioId,
        startDate: state.evaluationStartDate!, // Pass context dates
        endDate: state.evaluationEndDate!, // Pass context dates
      );
      emit(state.copyWith(detailItem: detail, loading: false));
    } on EvaluationApiException catch (e) {
      debugPrint('[EvaluationBloc] API Error loading detail: ${e.message}');
      emit(state.copyWith(error: e.message, loading: false));
    } catch (e, st) {
      debugPrint('[EvaluationBloc] General error in _onLoadDetail: $e\n$st');
      emit(
        state.copyWith(
          error: 'Gagal memuat detail evaluasi: $e',
          loading: false,
        ),
      );
    }
  }

  Future<void> _onLoadHistory(
    EvaluationLoadHistoryRequested event,
    Emitter<EvaluationState> emit,
  ) async {
    emit(state.copyWith(loading: true, history: [], clearError: true));
    try {
      final hist = await _repo.getEvaluationHistory(
        startDate: event.startDate, // Optional filter dates
        endDate: event.endDate,
      );
      emit(state.copyWith(history: hist, loading: false));
    } on EvaluationApiException catch (e) {
      debugPrint('[EvaluationBloc] API Error loading history: ${e.message}');
      emit(state.copyWith(error: e.message, loading: false));
    } catch (e, st) {
      debugPrint('[EvaluationBloc] General error in _onLoadHistory: $e\n$st');
      emit(
        state.copyWith(
          error: 'Gagal memuat riwayat evaluasi: $e',
          loading: false,
        ),
      );
    }
  }
}
