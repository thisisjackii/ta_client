// lib/features/budgeting/bloc/budgeting_bloc.dart
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/core/services/service_locator.dart';
import 'package:ta_client/core/state/auth_state.dart';
// import 'package:ta_client/core/state/auth_state.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_event.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_state.dart';
import 'package:ta_client/features/budgeting/repositories/budgeting_repository.dart';
import 'package:ta_client/features/budgeting/services/budgeting_service.dart';

class BudgetingBloc extends Bloc<BudgetingEvent, BudgetingState> {
  BudgetingBloc(
    this._budgetingRepo,
  ) // Removed PeriodRepo direct dependency from constructor
  : super(const BudgetingState()) {
    on<BudgetingIncomeDateRangeSelected>(_onIncomeDateRangeSelected);
    on<BudgetingPlanDateRangeSelected>(_onPlanDateRangeSelected);
    on<BudgetingLoadIncomeSummaryForSelectedDates>(_onLoadIncomeSummary);
    on<BudgetingLoadExpenseSuggestionsAndExistingPlan>(
      _onLoadExpenseSuggestionsAndExistingPlan,
    );
    on<BudgetingSelectIncomeSubcategory>(_onSelectIncomeSubcategory);
    on<BudgetingTotalIncomeConfirmed>(_onTotalIncomeConfirmed);
    on<BudgetingToggleExpenseCategory>(_onToggleExpenseCategory);
    on<BudgetingUpdateExpenseCategoryPercentage>(
      _onUpdateExpenseCategoryPercentage,
    );
    on<BudgetingToggleExpenseSubItem>(_onToggleExpenseSubItem);
    on<BudgetingSaveExpensePlan>(_onSaveExpensePlan);
    on<BudgetingClearError>(_onClearError);
    on<BudgetingClearInfoMessage>(_onClearInfoMessage);
    on<BudgetingResetState>(_onResetState);
    on<BudgetingSyncPendingData>(_onSyncPendingData);
    on<BudgetingLoadUserPlans>(_onLoadUserPlans);
  }

  final BudgetingRepository _budgetingRepo;

  Future<void> _onIncomeDateRangeSelected(
    BudgetingIncomeDateRangeSelected event,
    Emitter<BudgetingState> emit,
  ) async {
    emit(
      state.copyWith(
        loading: true,
        incomeDateConfirmed: false,
        incomeSummary: [],
        selectedIncomeSubcategoryIds: [],
        totalCalculatedIncome: 0, // Reset income
        clearDateError: true,
        clearError: true,
      ),
    );
    try {
      BudgetingRepository.validatePeriodDatesLogic(
        event.start,
        event.end,
      ); // Standard validation
      emit(
        state.copyWith(
          incomeCalculationStartDate: event.start,
          incomeCalculationEndDate: event.end,
          incomeDateConfirmed: true,
          loading: false,
        ),
      );
      add(const BudgetingLoadIncomeSummaryForSelectedDates());
    } on ArgumentError catch (e) {
      // Catch specific validation error
      emit(
        state.copyWith(
          dateError: e.message.toString(),
          incomeDateConfirmed: false,
          loading: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          error: 'Gagal mengatur periode pemasukan: $e',
          incomeDateConfirmed: false,
          loading: false,
        ),
      );
    }
  }

  Future<void> _onPlanDateRangeSelected(
    BudgetingPlanDateRangeSelected event,
    Emitter<BudgetingState> emit,
  ) async {
    emit(
      state.copyWith(
        loading: true,
        planDateConfirmed: false,
        expenseCategorySuggestions: [],
        selectedExpenseCategoryIds: [],
        expenseAllocationPercentages: {},
        selectedExpenseSubItems: {},
        clearCurrentBudgetPlan: true,
        clearDateError: true,
        clearError: true,
      ),
    );
    try {
      BudgetingRepository.validatePeriodDatesLogic(event.start, event.end);
      emit(
        state.copyWith(
          planStartDate: event.start,
          planEndDate: event.end,
          planDescription: event.planDescription,
          planDateConfirmed: true,
          loading: false,
        ),
      );
      add(const BudgetingLoadExpenseSuggestionsAndExistingPlan());
    } on ArgumentError catch (e) {
      emit(
        state.copyWith(
          dateError: e.message.toString(),
          planDateConfirmed: false,
          loading: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          error: 'Gagal mengatur periode rencana: $e',
          planDateConfirmed: false,
          loading: false,
        ),
      );
    }
  }

  Future<void> _onLoadIncomeSummary(
    BudgetingLoadIncomeSummaryForSelectedDates event,
    Emitter<BudgetingState> emit,
  ) async {
    if (!state.incomeDateConfirmed ||
        state.incomeCalculationStartDate == null ||
        state.incomeCalculationEndDate == null) {
      emit(
        state.copyWith(
          error: 'Periode kalkulasi pemasukan belum dikonfirmasi.',
          loading: false,
        ),
      );
      return;
    }
    emit(state.copyWith(loading: true, saveSuccess: false, clearError: true));
    try {
      final summary = await _budgetingRepo.getSummarizedIncomeForDateRange(
        startDate: state.incomeCalculationStartDate!,
        endDate: state.incomeCalculationEndDate!,
      );
      emit(state.copyWith(incomeSummary: summary, loading: false));
    } on BudgetingApiException catch (e) {
      emit(state.copyWith(error: e.message, loading: false));
    } catch (e) {
      emit(
        state.copyWith(
          error: 'Gagal memuat ringkasan pemasukan: $e',
          loading: false,
        ),
      );
    }
  }

  void _onTotalIncomeConfirmed(
    BudgetingTotalIncomeConfirmed event,
    Emitter<BudgetingState> emit,
  ) {
    emit(state.copyWith(totalCalculatedIncome: event.totalIncome));
  }

  Future<void> _onLoadExpenseSuggestionsAndExistingPlan(
    BudgetingLoadExpenseSuggestionsAndExistingPlan event,
    Emitter<BudgetingState> emit,
  ) async {
    if (!state.planDateConfirmed ||
        state.planStartDate == null ||
        state.planEndDate == null) {
      emit(
        state.copyWith(
          error: 'Periode rencana pengeluaran belum dikonfirmasi.',
          loading: false,
        ),
      );
      return;
    }
    emit(state.copyWith(loading: true, saveSuccess: false, clearError: true));
    try {
      final suggestions = await _budgetingRepo.getExpenseCategorySuggestions();
      // Attempt to load existing plan for these exact dates.
      // This might involve a new repository method or adapting getBudgetPlanById if ID is known (e.g. user selected existing plan)
      // For now, we assume if plan dates are set, we try to find if a plan exists for these exact dates.
      // This needs a robust way to identify an "existing plan" without an ID first.
      // Let's simplify: if user is creating a new plan, existing plan is null. If editing, it would be pre-loaded.
      // So, LoadExistingAllocations would be a separate event if user selects an existing plan to edit.
      // For a new plan, currentBudgetPlan would be null.

      // If there's a previously known plan ID for these dates (e.g. from a list of user's plans),
      // we could load it here. For now, this mainly loads suggestions.
      // If we decide user can pick from existing plans by date, then we'd fetch it here.
      // For a new plan flow, we only load suggestions.
      // If an existing plan ID *was* passed or stored in state for editing:
      // final existingPlan = state.currentBudgetPlan?.id != null ? await _budgetingRepo.getBudgetPlanById(state.currentBudgetPlan!.id) : null;

      emit(
        state.copyWith(
          expenseCategorySuggestions: suggestions,
          // currentBudgetPlan: existingPlan, // If loading an existing plan
          // Populate allocation states from existingPlan if found
          loading: false,
        ),
      );
    } on BudgetingApiException catch (e) {
      emit(state.copyWith(error: e.message, loading: false));
    } catch (e) {
      emit(
        state.copyWith(error: 'Gagal memuat data alokasi: $e', loading: false),
      );
    }
  }

  void _onSelectIncomeSubcategory(
    BudgetingSelectIncomeSubcategory event,
    Emitter<BudgetingState> emit,
  ) {
    final ids = List<String>.from(state.selectedIncomeSubcategoryIds);
    ids.contains(event.subcategoryId)
        ? ids.remove(event.subcategoryId)
        : ids.add(event.subcategoryId);

    // Recalculate total selected income
    double newTotalCalculatedIncome = 0;
    for (final catSummary in state.incomeSummary) {
      for (final subSummary in catSummary.subcategories) {
        if (ids.contains(subSummary.subcategoryId)) {
          newTotalCalculatedIncome += subSummary.totalAmount;
        }
      }
    }
    emit(
      state.copyWith(
        selectedIncomeSubcategoryIds: ids,
        totalCalculatedIncome: newTotalCalculatedIncome, // Update total income
        saveSuccess: false,
      ),
    );
  }

  void _onToggleExpenseCategory(
    BudgetingToggleExpenseCategory event,
    Emitter<BudgetingState> emit,
  ) {
    final cats = List<String>.from(state.selectedExpenseCategoryIds);
    final percentages = Map<String, double>.from(
      state.expenseAllocationPercentages,
    );
    final subItems = Map<String, List<String>>.from(
      state.selectedExpenseSubItems,
    );
    if (event.isSelected) {
      if (!cats.contains(event.categoryId)) cats.add(event.categoryId);
      percentages[event.categoryId] = percentages[event.categoryId] ?? 0.0;
    } else {
      cats.remove(event.categoryId);
      percentages.remove(event.categoryId);
      subItems.remove(event.categoryId);
    }
    emit(
      state.copyWith(
        selectedExpenseCategoryIds: cats,
        expenseAllocationPercentages: percentages,
        selectedExpenseSubItems: subItems,
        saveSuccess: false,
      ),
    );
  }

  void _onUpdateExpenseCategoryPercentage(
    BudgetingUpdateExpenseCategoryPercentage event,
    Emitter<BudgetingState> emit,
  ) {
    final percentages = Map<String, double>.from(
      state.expenseAllocationPercentages,
    );
    final selectedCats = List<String>.from(state.selectedExpenseCategoryIds);
    if (!selectedCats.contains(event.categoryId) && event.percentage > 0) {
      selectedCats.add(event.categoryId);
    }
    percentages[event.categoryId] = event.percentage.clamp(0.0, 100.0);
    emit(
      state.copyWith(
        expenseAllocationPercentages: percentages,
        selectedExpenseCategoryIds: selectedCats,
        saveSuccess: false,
      ),
    );
  }

  void _onToggleExpenseSubItem(
    BudgetingToggleExpenseSubItem event,
    Emitter<BudgetingState> emit,
  ) {
    final map = Map<String, List<String>>.from(state.selectedExpenseSubItems);
    final list = List<String>.from(map[event.parentCategoryId] ?? []);
    if (event.isSelected) {
      if (!list.contains(event.subcategoryId)) list.add(event.subcategoryId);
    } else {
      list.remove(event.subcategoryId);
    }
    map[event.parentCategoryId] = list;
    emit(state.copyWith(selectedExpenseSubItems: map, saveSuccess: false));
  }

  Future<void> _onSaveExpensePlan(
    BudgetingSaveExpensePlan event,
    Emitter<BudgetingState> emit,
  ) async {
    if (state.planStartDate == null || state.planEndDate == null) {
      emit(
        state.copyWith(
          error: 'Periode rencana pengeluaran belum diatur.',
          saveSuccess: false,
        ),
      );
      return;
    }
    if (state.incomeCalculationStartDate == null ||
        state.incomeCalculationEndDate == null) {
      emit(
        state.copyWith(
          error: 'Periode kalkulasi pemasukan belum diatur.',
          saveSuccess: false,
        ),
      );
      return;
    }
    if (state.totalCalculatedIncome == 0.0 &&
        state.expenseAllocationPercentages.values.any((p) => p > 0)) {
      emit(
        state.copyWith(
          error: 'Tidak dapat membuat rencana dengan total pemasukan Rp 0.',
          loading: false,
          saveSuccess: false,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        loading: true,
        saveSuccess: false,
        clearError: true,
        clearInfoMessage: true,
      ),
    );

    final allocationDetails = <FrontendAllocationDetailDto>[];
    for (final catId in state.selectedExpenseCategoryIds) {
      final percentage = state.expenseAllocationPercentages[catId] ?? 0.0;
      final selectedSubIds = state.selectedExpenseSubItems[catId] ?? [];
      if (percentage > 0 && selectedSubIds.isNotEmpty) {
        allocationDetails.add(
          FrontendAllocationDetailDto(
            categoryId: catId,
            percentage: percentage,
            selectedSubcategoryIds: selectedSubIds,
          ),
        );
      }
    }

    final totalPercentageClient = allocationDetails.fold<double>(
      0,
      (sum, alloc) => sum + alloc.percentage,
    );
    if (allocationDetails.isNotEmpty &&
        (totalPercentageClient < 99.99 || totalPercentageClient > 100.01) &&
        state.totalCalculatedIncome > 0) {
      emit(
        state.copyWith(
          loading: false,
          error:
              'Total persentase alokasi harus 100%. Saat ini: ${totalPercentageClient.toStringAsFixed(1)}%',
          saveSuccess: false,
        ),
      );
      return;
    }

    final dto = SaveExpenseAllocationsRequestDto(
      planDescription: state.planDescription,
      planStartDate: state.planStartDate!,
      planEndDate: state.planEndDate!,
      incomeCalculationStartDate: state.incomeCalculationStartDate!,
      incomeCalculationEndDate: state.incomeCalculationEndDate!,
      totalCalculatedIncome: state.totalCalculatedIncome,
      allocations: allocationDetails,
    );

    try {
      final savedBudgetPlan = await _budgetingRepo
          .saveBudgetPlanWithAllocations(dto);
      emit(
        state.copyWith(
          loading: false,
          saveSuccess: true,
          currentBudgetPlan: savedBudgetPlan, // Store the saved/updated plan
          infoMessage: 'Rencana anggaran berhasil disimpan!',
        ),
      );
    } on BudgetingApiException catch (e) {
      if (e.message.contains('queued')) {
        emit(
          state.copyWith(
            loading: false,
            saveSuccess: false,
            infoMessage: e.message,
          ),
        );
      } else {
        emit(
          state.copyWith(loading: false, saveSuccess: false, error: e.message),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          loading: false,
          saveSuccess: false,
          error: 'Gagal menyimpan rencana anggaran: $e',
        ),
      );
    }
  }

  void _onClearError(BudgetingClearError event, Emitter<BudgetingState> emit) {
    emit(state.copyWith(clearError: true));
  }

  void _onClearInfoMessage(
    BudgetingClearInfoMessage event,
    Emitter<BudgetingState> emit,
  ) {
    emit(state.copyWith(clearInfoMessage: true));
  }

  void _onResetState(BudgetingResetState event, Emitter<BudgetingState> emit) {
    emit(const BudgetingState()); // Reset to initial state
  }

  Future<void> _onSyncPendingData(
    BudgetingSyncPendingData event,
    Emitter<BudgetingState> emit,
  ) async {
    emit(
      state.copyWith(
        loading: true,
        infoMessage: 'Sinkronisasi data anggaran...',
      ),
    );
    try {
      await _budgetingRepo.syncPendingBudgetPlans();
      // After sync, you might want to reload the current plan if one was active
      String? currentPlanIdToRefresh;
      if (state.currentBudgetPlan != null &&
          !state.currentBudgetPlan!.isLocal) {
        // if it was a synced plan
        currentPlanIdToRefresh = state.currentBudgetPlan!.id;
      } else if (state.currentBudgetPlan != null &&
          state.currentBudgetPlan!.isLocal) {
        // If it was a local plan, it might have a new ID after sync.
        // This is complex; for now, we just signal completion. UI might need a general refresh.
      }

      emit(
        state.copyWith(
          loading: false,
          infoMessage: 'Sinkronisasi selesai. Muat ulang data jika perlu.',
        ),
      );

      // Optionally, try to reload data for the current context if possible
      if (currentPlanIdToRefresh != null) {
        // add(BudgetingLoadPlanDetails(planId: currentPlanIdToRefresh)); // Example event
      } else if (state.planDateConfirmed) {
        // If user was in process of creating new for these dates
        // add(BudgetingLoadExpenseSuggestionsAndExistingPlan());
      }
    } on BudgetingApiException catch (e) {
      emit(state.copyWith(loading: false, error: e.message));
    } catch (e) {
      emit(
        state.copyWith(
          loading: false,
          error: 'Gagal sinkronisasi data anggaran: $e',
        ),
      );
    }
  }

  Future<void> _onLoadUserPlans(
    BudgetingLoadUserPlans event,
    Emitter<BudgetingState> emit,
  ) async {
    emit(
      state.copyWith(
        loading: true,
        clearError: true,
        clearCurrentBudgetPlan: true,
      ),
    );
    try {
      final authState = sl<AuthState>(); // Assuming GetIt access
      if (!authState.isAuthenticated || authState.currentUser == null) {
        emit(state.copyWith(loading: false, error: 'User not authenticated.'));
        return;
      }
      final plans = await _budgetingRepo.getBudgetPlansForUser(
        authState.currentUser!.id,
      );
      if (plans.isNotEmpty) {
        // Load the latest plan, for example. Or provide a way to select.
        final latestPlan = plans.first; // Assuming sorted by date descending
        emit(
          state.copyWith(
            loading: false,
            currentBudgetPlan: latestPlan,
            planDateConfirmed: true,
            incomeDateConfirmed: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            loading: false,
            infoMessage: 'Tidak ada rencana anggaran tersimpan.',
          ),
        );
        // Optionally, navigate to intro or prompt creation if direct dashboard access finds no plans
        // Navigator.of(context).pushNamed(Routes.budgetingIntro);
      }
    } catch (e) {
      emit(
        state.copyWith(
          loading: false,
          error: 'Gagal memuat rencana anggaran: $e',
        ),
      );
    }
  }
}
