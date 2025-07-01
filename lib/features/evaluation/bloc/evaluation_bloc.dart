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
    on<EvaluationProceedWithDuplicate>(_onProceedWithDuplicate);
    on<EvaluationNavigateToExisting>(_onNavigateToExisting);
    on<EvaluationCancelDuplicateWarning>(_onCancelDuplicateWarning);
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

    // If basic validations pass, then check for duplicates:
    if (event.showDuplicateWarning) {
      emit(
        state.copyWith(loading: true, clearError: true, clearDateError: true),
      );
      CheckExistingEvaluationResponse existingCheck;
      try {
        existingCheck = await _repo.checkExistingEvaluationForDates(
          event.start,
          event.end,
        );
        debugPrint(
          '[EvaluationBloc] Check existing result: exists=${existingCheck.exists}, dataCount=${existingCheck.data.length}',
        );
      } catch (e) {
        debugPrint(
          '[EvaluationBloc] Error checking for duplicate evaluation dates: $e',
        );
        existingCheck = CheckExistingEvaluationResponse(exists: false);
        // Emit a failure state or proceed as if no duplicate?
        // For now, let's emit an error and let UI decide to re-open date picker.
        emit(
          state.copyWith(
            loading: false,
            error: 'Gagal memeriksa duplikasi data. Coba lagi.',
          ),
        );
        return;
      }

      if (existingCheck.exists) {
        debugPrint(
          '[EvaluationBloc] Conflict detected! Emitting dateConflictExists: true',
        );
        emit(
          state.copyWith(
            loading: false,
            dateConflictExists: true, // <<<< THIS IS THE TRIGGER
            tempSelectedStartDate: event.start,
            tempSelectedEndDate: event.end,
            conflictingEvaluationData: existingCheck.data, // <<<< POPULATE THIS
            clearConflictingEvaluationData:
                true, // Ensure dashboard is cleared if we are showing conflict
          ),
        );
        return;
      }
    }

    // If no duplicate or warning was bypassed/not requested, proceed to load/calculate
    debugPrint(
      '[EvaluationBloc] No conflict or warning bypassed. Proceeding to set dates and load dashboard.',
    );
    emit(
      state.copyWith(
        loading: true,
        evaluationStartDate: event.start,
        evaluationEndDate: event.end,
        dashboardItems: [],
        dateConflictExists: false, // Ensure conflict flag is false here
        clearTempSelectedStartDate:
            true, // Clear temps as main dates are now set
        clearTempSelectedEndDate: true,
        clearConflictingEvaluationData: true,
        clearError: true,
        clearDateError: true,
      ),
    );
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

  Future<void> _onProceedWithDuplicate(
    EvaluationProceedWithDuplicate event,
    Emitter<EvaluationState> emit,
  ) async {
    emit(
      state.copyWith(
        loading: true,
        evaluationStartDate: event.start,
        evaluationEndDate: event.end,
        dashboardItems: [],
        dateConflictExists: false, // Reset flag
        clearTempSelectedStartDate: true,
        clearTempSelectedEndDate: true,
        clearConflictingEvaluationData: true,
        clearError: true,
        clearDateError: true,
      ),
    );
    add(
      const EvaluationCalculateAndLoadDashboard(),
    ); // This will now re-evaluate/upsert
  }

  Future<void> _onNavigateToExisting(
    EvaluationNavigateToExisting event,
    Emitter<EvaluationState> emit,
  ) async {
    // We need to load the dashboard for these specific existing dates.
    // The checkExistingEvaluationForDates might have returned the data,
    // or we refetch it ensuring it's not a "re-calculation" but a load.
    // The `EvaluationCalculateAndLoadDashboard` event, due to backend `upsert`,
    // will effectively load existing if no transactions changed, or re-calculate
    // and update if transactions did change for that period.
    emit(
      state.copyWith(
        loading: true,
        evaluationStartDate: event.start,
        evaluationEndDate: event.end,
        dashboardItems:
            state.conflictingEvaluationData ??
            [], // Use prefetched data if available
        dateConflictExists: false,
        clearTempSelectedStartDate: true,
        clearTempSelectedEndDate: true,
        clearConflictingEvaluationData: true, // Clear it after use
        clearError: true,
        clearDateError: true,
      ),
    );
    // If conflictingEvaluationData was populated, the UI can directly use it.
    // Otherwise, trigger a load (which might be a re-calculation/upsert).
    if (state.conflictingEvaluationData == null ||
        state.conflictingEvaluationData!.isEmpty) {
      add(const EvaluationCalculateAndLoadDashboard());
    } else {
      // Data is already in state.dashboardItems, set loading to false.
      // UI will navigate to dashboard.
      emit(state.copyWith(loading: false));
    }
  }

  void _onCancelDuplicateWarning(
    EvaluationCancelDuplicateWarning event,
    Emitter<EvaluationState> emit,
  ) {
    emit(
      state.copyWith(
        dateConflictExists: false, // Reset flag
        // Keep tempSelectedDates so dialog can repopulate with them if re-opened
        // clearTempSelectedStartDate: true, // Or keep them if dialog should repopulate
        // clearTempSelectedEndDate: true,
        clearConflictingEvaluationData: true,
        loading: false, // Ensure loading is false
      ),
    );
    // UI remains on EvaluationDatePage, dialog is closed.
  }
}
