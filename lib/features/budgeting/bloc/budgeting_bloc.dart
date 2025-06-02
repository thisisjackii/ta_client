// lib/features/budgeting/bloc/budgeting_bloc.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/core/services/service_locator.dart';
import 'package:ta_client/core/state/auth_state.dart';
// import 'package:ta_client/core/state/auth_state.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_event.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_state.dart';
import 'package:ta_client/features/budgeting/repositories/budgeting_repository.dart';
import 'package:ta_client/features/budgeting/services/budgeting_service.dart';
import 'package:ta_client/features/transaction/repositories/transaction_repository.dart';

class BudgetingBloc extends Bloc<BudgetingEvent, BudgetingState> {
  BudgetingBloc(
    this._budgetingRepo,
  ) // Removed PeriodRepo direct dependency from constructor
  : _transactionRepository =
          sl<TransactionRepository>(), // <<< Inject TransactionRepository
      super(const BudgetingState()) {
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
    on<BudgetingSyncPendingData>(_onSyncPendingData);
    on<BudgetingLoadUserPlans>(_onLoadUserPlans);
    on<BudgetingLoadPlanDetails>(_onLoadPlanDetails);
    on<BudgetingStartEdit>(_onStartEdit); // <<< ADDED HANDLER
    // Make sure ResetState also clears editing flags
    on<BudgetingResetState>(_onResetState);
    on<BudgetingDeleteCategoryAllocation>(_onDeleteCategoryAllocation);
    on<BudgetingToggleDashboardSubItem>(_onToggleDashboardSubItem);
    on<BudgetingClearStatus>(_onClearStatus); // <<< ADD THIS HANDLER
  }

  final BudgetingRepository _budgetingRepo;
  final TransactionRepository _transactionRepository; // <<< NEW

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
    emit(
      state.copyWith(
        loading: true,
        saveSuccess: false,
        clearError: true,
        incomeSummary: [],
      ),
    ); // Clear previous summary while loading new
    try {
      final summary = await _budgetingRepo.getSummarizedIncomeForDateRange(
        startDate: state.incomeCalculationStartDate!,
        endDate: state.incomeCalculationEndDate!,
      );

      List<String> newSelectedIncomeSubcategoryIds = [];

      if (state.currentBudgetPlan != null) {
        // For a loaded plan, assume all income items fetched for its income calculation period
        // were the ones contributing to its totalCalculatedIncome for display purposes.
        // The card will show the plan's total, and this list will provide the breakdown items.
        if (summary.isNotEmpty) {
          newSelectedIncomeSubcategoryIds = summary
              .expand(
                (cat) => cat.subcategories.map((sub) => sub.subcategoryId),
              )
              .toList();
          debugPrint(
            "[BudgetingBloc] For loaded plan, setting selectedIncomeSubcategoryIds to all ${newSelectedIncomeSubcategoryIds.length} fetched income items for display breakdown.",
          );
        }
      } else {
        // If no current plan (i.e., in creation flow), retain existing selections.
        // This part is usually handled by _onSelectIncomeSubcategory.
        // However, if this event is triggered during creation after date change, we might want to reset or re-evaluate.
        // For now, if no plan, we don't automatically select all from summary; selections are manual.
        newSelectedIncomeSubcategoryIds = List.from(
          state.selectedIncomeSubcategoryIds,
        );
      }

      emit(
        state.copyWith(
          incomeSummary: summary,
          loading: false,
          selectedIncomeSubcategoryIds: newSelectedIncomeSubcategoryIds,
        ),
      );
    } catch (e) {
      // If fetching income summary fails, keep the current plan's total income but show no breakdown.
      emit(
        state.copyWith(
          error: 'Gagal memuat ringkasan pemasukan: $e',
          loading: false,
          incomeSummary: [], // Clear summary on error
          selectedIncomeSubcategoryIds: [], // Clear selections on error
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
      final existingPlan = state.currentBudgetPlan?.id != null
          ? await _budgetingRepo.getBudgetPlanById(state.currentBudgetPlan!.id)
          : null;

      emit(
        state.copyWith(
          expenseCategorySuggestions: suggestions,
          currentBudgetPlan: existingPlan, // If loading an existing plan
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
    emit(
      const BudgetingState().copyWith(
        isEditing: false,
        clearInitialSpending: true,
      ),
    ); // Ensure editing flags are reset
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
        add(
          BudgetingLoadPlanDetails(planId: currentPlanIdToRefresh),
        ); // Example event
      } else if (state.planDateConfirmed) {
        // If user was in process of creating new for these dates
        add(const BudgetingLoadExpenseSuggestionsAndExistingPlan());
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
        isEditing: false,
        clearInitialSpending: true,
      ),
    );
    try {
      final authState = sl<AuthState>();
      if (!authState.isAuthenticated || authState.currentUser == null) {
        emit(state.copyWith(loading: false, error: 'User not authenticated.'));
        return;
      }
      final plans = await _budgetingRepo.getBudgetPlansForUser(
        authState.currentUser!.id,
      );
      if (plans.isNotEmpty) {
        final latestPlan = plans.first; // Assuming sorted by date descending
        emit(
          state.copyWith(
            loading: false, // Stop initial loading
            currentBudgetPlan: latestPlan,
            planStartDate: latestPlan.planStartDate,
            planEndDate: latestPlan.planEndDate,
            planDescription: latestPlan.description,
            planDateConfirmed: true,
            incomeCalculationStartDate: latestPlan.incomeCalculationStartDate,
            incomeCalculationEndDate: latestPlan.incomeCalculationEndDate,
            totalCalculatedIncome: latestPlan.totalCalculatedIncome,
            incomeDateConfirmed: true,
          ),
        );
        // After loading plan, trigger income summary load for its income period
        add(const BudgetingLoadIncomeSummaryForSelectedDates());
      } else {
        emit(
          state.copyWith(
            loading: false,
            infoMessage: 'Tidak ada rencana anggaran tersimpan.',
          ),
        );
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

  Future<void> _onLoadPlanDetails(
    BudgetingLoadPlanDetails event,
    Emitter<BudgetingState> emit,
  ) async {
    emit(
      state.copyWith(
        loading: true,
        clearError: true,
        clearInfoMessage: true,
        clearCurrentBudgetPlan: true,
      ),
    ); // Keep isEditing as is or reset if needed
    try {
      final plan = await _budgetingRepo.getBudgetPlanById(event.planId);
      if (plan != null) {
        emit(
          state.copyWith(
            loading: false, // Stop initial loading
            currentBudgetPlan: plan,
            planStartDate: plan.planStartDate,
            planEndDate: plan.planEndDate,
            planDescription: plan.description,
            planDateConfirmed: true,
            incomeCalculationStartDate: plan.incomeCalculationStartDate,
            incomeCalculationEndDate: plan.incomeCalculationEndDate,
            totalCalculatedIncome: plan.totalCalculatedIncome,
            incomeDateConfirmed: true,
            // selectedIncomeSubcategoryIds: [], // Don't reset here yet, let income summary load
            // initialSpendingForEditedPlan: state.isEditing ? state.initialSpendingForEditedPlan : {}, // Preserve if editing
          ),
        );
        // After loading plan, trigger income summary load for its income period
        add(const BudgetingLoadIncomeSummaryForSelectedDates());
        // If editing, also re-calculate/load initial spending
        if (state.isEditing) {
          // This logic might be better inside _onStartEdit or a dedicated event
          // For now, assuming _onStartEdit already populated initialSpending
        }
      } else {
        emit(
          state.copyWith(
            loading: false,
            error:
                'Rencana anggaran dengan ID ${event.planId} tidak ditemukan.',
            clearCurrentBudgetPlan: true,
            isEditing: false,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          loading: false,
          error: 'Gagal memuat detail rencana anggaran: $e',
          clearCurrentBudgetPlan: true,
          isEditing: false,
        ),
      );
    }
  }

  Future<void> _onStartEdit(
    BudgetingStartEdit event,
    Emitter<BudgetingState> emit,
  ) async {
    emit(
      state.copyWith(
        loading: true,
        clearError: true,
        clearInfoMessage: true,
        clearCurrentBudgetPlan: true,
        isEditing: true,
        clearInitialSpending: true,
      ),
    );
    try {
      final planToEdit = await _budgetingRepo.getBudgetPlanById(event.planId);
      if (planToEdit == null) {
        emit(
          state.copyWith(
            loading: false,
            error: 'Rencana anggaran untuk diedit tidak ditemukan.',
            isEditing: false,
          ),
        );
        return;
      }

      // Calculate initial spending for this plan
      final categorySpending = <String, double>{};
      final subcategorySpending =
          <String, double>{}; // subcategoryId -> spentAmount

      final transactionsForPlanPeriod = await _transactionRepository.fetchTransactions(
        // This needs to fetch transactions for the *user* within the *plan's date range*
        // Assuming fetchTransactions can take date filters or similar.
        // For simplicity, let's assume it gets all user's transactions and we filter client-side.
        // This is NOT ideal for performance but simplifies the BLoC change.
        // A better approach is a repository method: getTransactionsForUserInDateRange(userId, startDate, endDate)
      );

      final relevantTransactions = transactionsForPlanPeriod
          .where(
            (tx) =>
                !tx.date.isBefore(planToEdit.planStartDate) &&
                !tx.date.isAfter(
                  planToEdit.planEndDate
                      .add(const Duration(days: 1))
                      .subtract(const Duration(microseconds: 1)),
                ) &&
                tx.accountTypeName?.toLowerCase() ==
                    'pengeluaran', // Only expenses count against budget
          )
          .toList();

      for (final alloc in planToEdit.allocations) {
        final spentInCat = relevantTransactions
            .where(
              (tx) => tx.categoryId == alloc.categoryId,
            ) // Assuming Transaction has categoryId
            .fold(0.toDouble(), (sum, tx) => sum + tx.amount);
        categorySpending[alloc.categoryId] = spentInCat;

        final spentInSubcat = relevantTransactions
            .where((tx) => tx.subcategoryId == alloc.subcategoryId)
            .fold(0.toDouble(), (sum, tx) => sum + tx.amount);
        subcategorySpending[alloc.subcategoryId] = spentInSubcat;
      }

      final newExpenseAllocationPercentages = <String, double>{};
      final newSelectedExpenseSubItems = <String, List<String>>{};
      final newSelectedExpenseCategoryIds = <String>[];

      for (final alloc in planToEdit.allocations) {
        if (!newSelectedExpenseCategoryIds.contains(alloc.categoryId)) {
          newSelectedExpenseCategoryIds.add(alloc.categoryId);
        }
        newExpenseAllocationPercentages.putIfAbsent(
          alloc.categoryId,
          () => alloc.percentage,
        );
        newSelectedExpenseSubItems
            .putIfAbsent(alloc.categoryId, () => [])
            .add(alloc.subcategoryId);
      }

      emit(
        state.copyWith(
          loading: false,
          currentBudgetPlan: planToEdit,
          planStartDate: planToEdit.planStartDate,
          planEndDate: planToEdit.planEndDate,
          planDescription: planToEdit.description,
          planDateConfirmed: true,
          incomeCalculationStartDate: planToEdit.incomeCalculationStartDate,
          incomeCalculationEndDate: planToEdit.incomeCalculationEndDate,
          totalCalculatedIncome: planToEdit.totalCalculatedIncome,
          incomeDateConfirmed: true,
          selectedExpenseCategoryIds: newSelectedExpenseCategoryIds,
          expenseAllocationPercentages: newExpenseAllocationPercentages,
          selectedExpenseSubItems: newSelectedExpenseSubItems,
          initialSpendingForEditedPlan:
              categorySpending, // Store the calculated spending
          // isEditing: true, // Already set at the start of this handler
        ),
      );
      add(const BudgetingLoadExpenseSuggestionsAndExistingPlan());
    } on BudgetingApiException catch (e) {
      emit(state.copyWith(loading: false, error: e.message, isEditing: false));
    } catch (e) {
      emit(
        state.copyWith(
          loading: false,
          error: 'Gagal memulai edit rencana: $e',
          isEditing: false,
        ),
      );
    }
  }

  Future<void> _onDeleteCategoryAllocation(
    BudgetingDeleteCategoryAllocation event,
    Emitter<BudgetingState> emit,
  ) async {
    if (state.currentBudgetPlan == null) {
      emit(
        state.copyWith(error: 'Tidak ada rencana aktif untuk dimodifikasi.'),
      );
      return;
    }
    // Check spending (TC-63) - This relies on initialSpendingForEditedPlan being populated
    // when the plan was loaded into currentBudgetPlan. We might need to refresh it or ensure it's accurate.
    // For simplicity, let's assume it's available if currentBudgetPlan is set.
    // A more robust way: recalculate spending for this category JUST before delete.
    final spendingInThisCategory =
        state.initialSpendingForEditedPlan[event.categoryId] ?? 0.0;
    if (spendingInThisCategory > 0) {
      emit(
        state.copyWith(
          error:
              'Tidak dapat menghapus kategori yang sudah memiliki progres pengeluaran.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(loading: true, clearError: true, clearInfoMessage: true),
    );

    final updatedPlan = state.currentBudgetPlan!.copyWith(
      allocations: List<FrontendBudgetAllocation>.from(
        state.currentBudgetPlan!.allocations,
      )..removeWhere((alloc) => alloc.categoryId == event.categoryId),
    );

    // Update BLoC state immediately for UI responsiveness
    final newSelectedCategoryIds = List<String>.from(
      state.selectedExpenseCategoryIds,
    )..remove(event.categoryId);
    final newExpenseAllocationPercentages = Map<String, double>.from(
      state.expenseAllocationPercentages,
    )..remove(event.categoryId);
    final newSelectedExpenseSubItems = Map<String, List<String>>.from(
      state.selectedExpenseSubItems,
    )..remove(event.categoryId);

    // Recalculate DTO for saving
    final dto = _createSaveDtoFromState(
      state.copyWith(
        // Use a state copy with updated allocation lists
        currentBudgetPlan: updatedPlan,
        selectedExpenseCategoryIds: newSelectedCategoryIds,
        expenseAllocationPercentages: newExpenseAllocationPercentages,
        selectedExpenseSubItems: newSelectedExpenseSubItems,
      ),
    );

    try {
      final savedPlan = await _budgetingRepo.saveBudgetPlanWithAllocations(dto);
      emit(
        state.copyWith(
          loading: false,
          saveSuccess: true,
          currentBudgetPlan: savedPlan, // Update with the plan from backend
          infoMessage: 'Kategori alokasi dihapus dan rencana disimpan.',
          // Manually update the lists in the state based on the DTO that was saved
          selectedExpenseCategoryIds: newSelectedCategoryIds,
          expenseAllocationPercentages: newExpenseAllocationPercentages,
          selectedExpenseSubItems: newSelectedExpenseSubItems,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          loading: false,
          error: 'Gagal menghapus alokasi kategori: $e',
        ),
      );
      // Revert optimistic UI update if save fails? More complex, for now, rely on user refresh or re-edit.
    }
  }

  Future<void> _onToggleDashboardSubItem(
    BudgetingToggleDashboardSubItem event,
    Emitter<BudgetingState> emit,
  ) async {
    if (state.currentBudgetPlan == null) {
      emit(
        state.copyWith(error: 'Tidak ada rencana aktif untuk dimodifikasi.'),
      );
      return;
    }

    // Check spending for the parent category (TC-67)
    final spendingInParentCategory =
        state.initialSpendingForEditedPlan[event.parentCategoryId] ?? 0.0;
    if (spendingInParentCategory > 0) {
      emit(
        state.copyWith(
          error:
              'Tidak dapat mengubah subkategori karena kategori induk sudah memiliki progres pengeluaran.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(loading: true, clearError: true, clearInfoMessage: true),
    );

    final newSelectedExpenseSubItems = Map<String, List<String>>.from(
      state.selectedExpenseSubItems,
    );
    final subItemsForParent = List<String>.from(
      newSelectedExpenseSubItems[event.parentCategoryId] ?? [],
    );

    if (event.isSelected) {
      if (!subItemsForParent.contains(event.subcategoryId)) {
        subItemsForParent.add(event.subcategoryId);
      }
    } else {
      subItemsForParent.remove(event.subcategoryId);
    }
    // If a category ends up with no subcategories selected but still has a percentage,
    // the save DTO logic should ideally handle this (e.g., by not including it or erroring).
    // For now, we assume the percentage remains and user might need to adjust it via full edit.
    if (subItemsForParent.isEmpty &&
        (state.expenseAllocationPercentages[event.parentCategoryId] ?? 0.0) >
            0) {
      emit(
        state.copyWith(
          loading: false,
          error:
              "Kategori '${state.currentBudgetPlan?.allocations.firstWhere((a) => a.categoryId == event.parentCategoryId).categoryName}' harus memiliki minimal satu subkategori terpilih jika dialokasikan persentase.",
        ),
      );
      return;
    }
    newSelectedExpenseSubItems[event.parentCategoryId] = subItemsForParent;

    // Create the DTO to save the entire plan with this one subitem change
    final dto = _createSaveDtoFromState(
      state.copyWith(selectedExpenseSubItems: newSelectedExpenseSubItems),
    );

    try {
      final savedPlan = await _budgetingRepo.saveBudgetPlanWithAllocations(dto);
      emit(
        state.copyWith(
          loading: false,
          saveSuccess: true,
          currentBudgetPlan: savedPlan,
          selectedExpenseSubItems:
              newSelectedExpenseSubItems, // Reflect change in BLoC state
          infoMessage: 'Subkategori diperbarui dan rencana disimpan.',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          loading: false,
          error: 'Gagal memperbarui subkategori: $e',
        ),
      );
    }
  }

  void _onClearStatus(
    BudgetingClearStatus event,
    Emitter<BudgetingState> emit,
  ) {
    // <<< ADD THIS METHOD
    emit(
      state.copyWith(
        saveSuccess: false,
        clearError: true,
        clearInfoMessage: true,
        // Decide if other flags like 'loading' should also be reset here
        // or if this event is purely for success/error/info message clearing.
      ),
    );
  }

  // Helper to create SaveExpenseAllocationsRequestDto from current BLoC state
  SaveExpenseAllocationsRequestDto _createSaveDtoFromState(
    BudgetingState currentState,
  ) {
    if (currentState.currentBudgetPlan == null) {
      // This should ideally not happen if currentBudgetPlan is always set when modifications are possible
      throw StateError(
        'Cannot create DTO without a current budget plan in state.',
      );
    }
    final plan = currentState.currentBudgetPlan!;
    final allocationDetails = <FrontendAllocationDetailDto>[];

    for (final catId in currentState.selectedExpenseCategoryIds) {
      final percentage =
          currentState.expenseAllocationPercentages[catId] ?? 0.0;
      final selectedSubIds = currentState.selectedExpenseSubItems[catId] ?? [];

      // Only include categories that have a percentage and selected subcategories
      if (percentage > 0 && selectedSubIds.isNotEmpty) {
        allocationDetails.add(
          FrontendAllocationDetailDto(
            categoryId: catId,
            percentage: percentage,
            selectedSubcategoryIds: selectedSubIds,
          ),
        );
      } else if (percentage > 0 && selectedSubIds.isEmpty) {
        // This case should be prevented by UI or earlier validation, but as a safeguard:
        debugPrint(
          'Warning: Category $catId has percentage but no subcategories selected. It will not be included in save DTO.',
        );
      }
    }
    // Validate total percentage again before creating DTO
    final totalPercentageClient = allocationDetails.fold<double>(
      0,
      (sum, alloc) => sum + alloc.percentage,
    );
    if (allocationDetails.isNotEmpty &&
        (totalPercentageClient < 99.99 || totalPercentageClient > 100.01) &&
        currentState.totalCalculatedIncome > 0) {
      // This should ideally be caught by UI first.
      throw ArgumentError(
        'Total persentase alokasi harus 100% atau 0%. Saat ini: ${totalPercentageClient.toStringAsFixed(1)}%',
      );
    }

    return SaveExpenseAllocationsRequestDto(
      planDescription: plan.description,
      planStartDate: plan.planStartDate,
      planEndDate: plan.planEndDate,
      incomeCalculationStartDate: plan.incomeCalculationStartDate,
      incomeCalculationEndDate: plan.incomeCalculationEndDate,
      totalCalculatedIncome: plan.totalCalculatedIncome,
      allocations: allocationDetails,
    );
  }
}
