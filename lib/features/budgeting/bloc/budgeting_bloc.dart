// lib/features/budgeting/bloc/budgeting_bloc.dart
import 'dart:async';
// For Math.abs
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/core/services/service_locator.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_event.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_state.dart';
import 'package:ta_client/features/budgeting/repositories/budgeting_repository.dart';
import 'package:ta_client/features/budgeting/repositories/period_repository.dart'; // Import PeriodRepository
import 'package:ta_client/features/budgeting/services/budgeting_service.dart'
    show
        BackendIncomeSummaryItem,
        BudgetingApiException,
        FrontendAllocationDetailDto,
        SaveExpenseAllocationsRequestDto;

class BudgetingBloc extends Bloc<BudgetingEvent, BudgetingState> {
  BudgetingBloc(this._budgetingRepo, this._periodRepo)
    : super(const BudgetingState()) {
    on<BudgetingIncomeDateRangeSelected>(_onIncomeDateRangeSelected);
    on<BudgetingExpenseDateRangeSelected>(_onExpenseDateRangeSelected);
    on<BudgetingLoadIncomeSummary>(_onLoadIncomeSummary);
    on<BudgetingLoadExpenseSuggestions>(_onLoadExpenseSuggestions);
    on<BudgetingLoadExistingAllocations>(_onLoadExistingAllocations);
    on<BudgetingSelectIncomeSubcategory>(_onSelectIncomeSubcategory);
    on<BudgetingToggleExpenseCategory>(_onToggleExpenseCategory);
    on<BudgetingUpdateExpenseCategoryPercentage>(
      _onUpdateExpenseCategoryPercentage,
    );
    on<BudgetingToggleExpenseSubItem>(_onToggleExpenseSubItem);
    on<BudgetingSaveExpensePlan>(_onSaveExpensePlan);
    on<BudgetingClearError>(_onClearError);
    on<BudgetingResetState>(_onResetState);
    on<BudgetingSyncPendingData>(_onSyncPendingData);
  }

  final BudgetingRepository _budgetingRepo;
  final PeriodRepository _periodRepo;

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
      ),
    );
    try {
      BudgetingRepository.validatePeriodDatesLogic(event.start, event.end);

      final incomePeriod = await _periodRepo.ensureAndGetPeriod(
        existingPeriodId: event.existingPeriodId,
        startDate: event.start,
        endDate: event.end,
        periodType: 'income',
        description: 'Periode Pemasukan Anggaran',
        // userIdForLocal might be needed if PeriodRepository requires it for offline creation
        // For now, assuming AuthenticatedClient provides user context to backend or repo handles it
      );

      emit(
        state.copyWith(
          incomePeriodId: incomePeriod.id,
          incomeStartDate: incomePeriod.startDate,
          incomeEndDate: incomePeriod.endDate,
          incomeDateConfirmed: true,
          loading: false,
        ),
      );
      add(BudgetingLoadIncomeSummary(periodId: incomePeriod.id));
    } on Exception catch (e) {
      emit(
        state.copyWith(
          dateError: e.toString(),
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

  Future<void> _onExpenseDateRangeSelected(
    BudgetingExpenseDateRangeSelected event,
    Emitter<BudgetingState> emit,
  ) async {
    emit(
      state.copyWith(
        loading: true,
        expenseDateConfirmed: false,
        expenseCategorySuggestions: [],
        selectedExpenseCategoryIds: [],
        expenseAllocationPercentages: {},
        selectedExpenseSubItems: {},
        currentAllocations: [],
      ),
    );
    try {
      BudgetingRepository.validatePeriodDatesLogic(event.start, event.end);

      final expensePeriod = await _periodRepo.ensureAndGetPeriod(
        existingPeriodId: event.existingPeriodId,
        startDate: event.start,
        endDate: event.end,
        periodType: 'expense',
        description: 'Periode Alokasi Pengeluaran',
      );

      emit(
        state.copyWith(
          expensePeriodId: expensePeriod.id,
          expenseStartDate: expensePeriod.startDate,
          expenseEndDate: expensePeriod.endDate,
          expenseDateConfirmed: true,
          loading: false,
        ),
      );
      add(const BudgetingLoadExpenseSuggestions());
      add(BudgetingLoadExistingAllocations(periodId: expensePeriod.id));
    } on Exception catch (e) {
      emit(
        state.copyWith(
          dateError: e.toString(),
          expenseDateConfirmed: false,
          loading: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          error: 'Gagal mengatur periode pengeluaran: $e',
          expenseDateConfirmed: false,
          loading: false,
        ),
      );
    }
  }

  Future<void> _onLoadIncomeSummary(
    BudgetingLoadIncomeSummary event,
    Emitter<BudgetingState> emit,
  ) async {
    if (!state.incomeDateConfirmed || event.periodId.isEmpty) {
      emit(
        state.copyWith(
          error: 'Periode pemasukan belum dikonfirmasi atau ID hilang.',
        ),
      );
      return;
    }
    emit(state.copyWith(loading: true, saveSuccess: false));
    try {
      final summary = await _budgetingRepo.getSummarizedIncomeForPeriod(
        event.periodId,
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

  Future<void> _onLoadExpenseSuggestions(
    BudgetingLoadExpenseSuggestions event,
    Emitter<BudgetingState> emit,
  ) async {
    emit(state.copyWith(loading: true, saveSuccess: false));
    try {
      final suggestions = await _budgetingRepo.getExpenseCategorySuggestions();
      emit(
        state.copyWith(expenseCategorySuggestions: suggestions, loading: false),
      );
    } on BudgetingApiException catch (e) {
      emit(state.copyWith(error: e.message, loading: false));
    } catch (e) {
      emit(
        state.copyWith(
          error: 'Gagal memuat saran kategori pengeluaran: $e',
          loading: false,
        ),
      );
    }
  }

  Future<void> _onLoadExistingAllocations(
    BudgetingLoadExistingAllocations event,
    Emitter<BudgetingState> emit,
  ) async {
    if (event.periodId.isEmpty) {
      emit(
        state.copyWith(
          error: 'Tidak dapat memuat alokasi: ID periode pengeluaran hilang.',
        ),
      );
      return;
    }
    emit(state.copyWith(loading: true, saveSuccess: false));
    try {
      final allocations = await _budgetingRepo.getBudgetAllocationsForPeriod(
        event.periodId,
      );

      final newPercentages = <String, double>{};
      final newSelectedCategories = <String>[];
      final newSelectedSubItems = <String, List<String>>{};

      for (final allocRecord in allocations) {
        if (!newSelectedCategories.contains(allocRecord.categoryId)) {
          newSelectedCategories.add(allocRecord.categoryId);
        }
        newPercentages[allocRecord.categoryId] = allocRecord.percentage;
        newSelectedSubItems
            .putIfAbsent(allocRecord.categoryId, () => [])
            .add(allocRecord.subcategoryId);
      }

      emit(
        state.copyWith(
          currentAllocations: allocations,
          selectedExpenseCategoryIds: newSelectedCategories,
          expenseAllocationPercentages: newPercentages,
          selectedExpenseSubItems: newSelectedSubItems,
          loading: false,
        ),
      );
    } on BudgetingApiException catch (e) {
      emit(state.copyWith(error: e.message, loading: false));
    } catch (e) {
      emit(
        state.copyWith(
          error: 'Gagal memuat alokasi yang ada: $e',
          loading: false,
        ),
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
    emit(state.copyWith(selectedIncomeSubcategoryIds: ids, saveSuccess: false));
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
    if (state.expensePeriodId == null || state.expensePeriodId!.isEmpty) {
      emit(
        state.copyWith(
          error: 'Periode pengeluaran belum diatur.',
          saveSuccess: false,
        ),
      );
      return;
    }
    emit(state.copyWith(loading: true, saveSuccess: false));

    double totalBudgetableIncome = 0;
    for (final catSummary in state.incomeSummary) {
      for (final subSummary in catSummary.subcategories) {
        if (state.selectedIncomeSubcategoryIds.contains(
          subSummary.subcategoryId,
        )) {
          totalBudgetableIncome += subSummary.totalAmount;
        }
      }
    }
    if (totalBudgetableIncome == 0 &&
        state.selectedExpenseCategoryIds.isNotEmpty &&
        state.expenseAllocationPercentages.values.any((p) => p > 0)) {
      emit(
        state.copyWith(
          loading: false,
          error:
              'Tidak bisa mengalokasikan pengeluaran dengan total pemasukan Rp 0.',
          saveSuccess: false,
        ),
      );
      return;
    }

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
        totalBudgetableIncome > 0) {
      // Allow small float inaccuracies
      emit(
        state.copyWith(
          loading: false,
          error:
              'Total persentase alokasi untuk kategori aktif harus 100%. Saat ini: ${totalPercentageClient.toStringAsFixed(1)}%',
          saveSuccess: false,
        ),
      );
      return;
    }
    if (allocationDetails.isEmpty &&
        totalBudgetableIncome > 0 &&
        state.selectedExpenseCategoryIds.any(
          (catId) => (state.expenseAllocationPercentages[catId] ?? 0) > 0,
        )) {
      emit(
        state.copyWith(
          loading: false,
          error:
              'Pilih subkategori untuk kategori pengeluaran yang Anda alokasikan.',
          saveSuccess: false,
        ),
      );
      return;
    }

    final dto = SaveExpenseAllocationsRequestDto(
      budgetPeriodId: state.expensePeriodId!,
      totalBudgetableIncome: totalBudgetableIncome,
      allocations: allocationDetails,
    );

    try {
      final savedAllocations = await _budgetingRepo.saveExpenseAllocations(dto);
      emit(
        state.copyWith(
          loading: false,
          saveSuccess: true,
          currentAllocations: savedAllocations,
          infoMessage: 'Rencana anggaran berhasil disimpan!',
        ),
      );
    } on BudgetingApiException catch (e) {
      if (e.message.contains('queued for sync')) {
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
    emit(state.copyWith());
  }

  void _onResetState(BudgetingResetState event, Emitter<BudgetingState> emit) {
    emit(const BudgetingState());
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
      await _budgetingRepo.syncPendingBudgetPlans(); // Sync budget plans
      await sl<PeriodRepository>().syncPendingPeriods(); // Sync periods

      emit(
        state.copyWith(
          loading: false,
          infoMessage: 'Sinkronisasi selesai. Muat ulang data jika perlu.',
        ),
      );
      if (state.expensePeriodId != null && state.expensePeriodId!.isNotEmpty) {
        add(BudgetingLoadExistingAllocations(periodId: state.expensePeriodId!));
      }
      if (state.incomePeriodId != null && state.incomePeriodId!.isNotEmpty) {
        add(BudgetingLoadIncomeSummary(periodId: state.incomePeriodId!));
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
}
