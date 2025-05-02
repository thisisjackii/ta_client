import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_event.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_state.dart';
import 'package:ta_client/features/budgeting/repositories/budgeting_repository.dart';

class BudgetingBloc extends Bloc<BudgetingEvent, BudgetingState> {
  BudgetingBloc(this._repo) : super(const BudgetingState()) {
    on<ResetIncomeDateConfirmation>(_onResetIncomeDate);
    on<ConfirmIncomeDateRange>(_onConfirmIncomeDate);
    on<ResetExpenseDateConfirmation>(_onResetExpenseDate);
    on<ConfirmExpenseDateRange>(_onConfirmExpenseDate);

    on<SelectIncomeCategory>(_onSelectIncome);
    on<ToggleExpenseSubItem>(_onToggleSubExpense);
    on<ToggleAllocationCategory>(_onToggleAllocationCategory);
    on<UpdateAllocationValue>(_onUpdateAllocationValue);
    on<LoadDashboard>(_onLoadDashboard);
    on<IncomeStartDateChanged>(_onIncomeStartDateChanged);
    on<IncomeEndDateChanged>(_onIncomeEndDateChanged);
    on<ExpenseStartDateChanged>(_onExpenseStartDateChanged);
    on<ExpenseEndDateChanged>(_onExpenseEndDateChanged);
  }
  final BudgetingRepository _repo;

  Future<void> _onResetIncomeDate(
    ResetIncomeDateConfirmation e,
    Emitter<BudgetingState> emit,
  ) {
    emit(state.copyWith(incomeDateConfirmed: false));
    return Future.value();
  }

  Future<void> _onConfirmIncomeDate(
    ConfirmIncomeDateRange e,
    Emitter<BudgetingState> emit,
  ) async {
    try {
      await _repo.ensureDates(e.start, e.end);
      emit(
        state.copyWith(
          incomeStartDate: e.start,
          incomeEndDate: e.end,
          incomeDateConfirmed: true,
          loading: true,
        ),
      );
      final incomes = await _repo.getIncomeBuckets(e.start, e.end);
      emit(state.copyWith(incomes: incomes, loading: false));
    } catch (err) {
      emit(state.copyWith(dateError: err.toString(), loading: false));
    }
  }

  Future<void> _onResetExpenseDate(
    ResetExpenseDateConfirmation e,
    Emitter<BudgetingState> emit,
  ) {
    emit(state.copyWith(expenseDateConfirmed: false));
    return Future.value();
  }

  Future<void> _onConfirmExpenseDate(
    ConfirmExpenseDateRange e,
    Emitter<BudgetingState> emit,
  ) async {
    try {
      await _repo.ensureDates(e.start, e.end);
      emit(
        state.copyWith(
          expenseStartDate: e.start,
          expenseEndDate: e.end,
          expenseDateConfirmed: true,
          loading: true,
        ),
      );
      final allocations = await _repo.getExpenseBuckets(e.start, e.end);
      emit(state.copyWith(allocations: allocations, loading: false));
    } catch (err) {
      emit(state.copyWith(dateError: err.toString(), loading: false));
    }
  }

  // … keep your existing handlers for SelectIncomeCategory, ToggleExpenseSubItem, etc. …
  void _onSelectIncome(SelectIncomeCategory e, Emitter<BudgetingState> emit) {
    final ids = List<String>.from(state.selectedIncomeIds);
    ids.contains(e.id) ? ids.remove(e.id) : ids.add(e.id);
    emit(state.copyWith(selectedIncomeIds: ids));
  }

  void _onToggleSubExpense(
    ToggleExpenseSubItem e,
    Emitter<BudgetingState> emit,
  ) {
    final map = Map<String, List<String>>.from(state.selectedSubExpenses);
    final list = List<String>.from(map[e.allocationId] ?? []);
    e.isSelected ? list.add(e.subItem) : list.remove(e.subItem);
    map[e.allocationId] = list;
    emit(state.copyWith(selectedSubExpenses: map));
  }

  void _onToggleAllocationCategory(
    ToggleAllocationCategory e,
    Emitter<BudgetingState> emit,
  ) {
    // 1. Copy current lists/maps so we don’t mutate the original state
    final cats = List<String>.from(state.selectedCategories);
    final allocs = Map<String, double>.from(state.allocationValues);

    // 2. Add or remove the category
    if (e.isSelected) {
      cats.add(e.category);
    } else {
      cats.remove(e.category);
      // 3. Reset its allocation to 0 when unchecked
      allocs[e.category] = 0.0;
    }

    // 4. Emit a new state with both updated selections and values
    emit(state.copyWith(selectedCategories: cats, allocationValues: allocs));
  }

  void _onUpdateAllocationValue(
    UpdateAllocationValue e,
    Emitter<BudgetingState> emit,
  ) {
    final values = Map<String, double>.from(state.allocationValues);
    values[e.id] = e.value;
    emit(state.copyWith(allocationValues: values));
  }

  Future<void> _onLoadDashboard(
    LoadDashboard e,
    Emitter<BudgetingState> emit,
  ) async {
    final st = state;
    // Require both ranges
    if (!st.incomeDateConfirmed || !st.expenseDateConfirmed) {
      // Nothing to do yet
      return;
    }

    emit(st.copyWith(loading: true));
    try {
      // fetch incomes
      final incomes = await _repo.getIncomeBuckets(
        st.incomeStartDate!,
        st.incomeEndDate!,
      );
      // fetch allocations
      final allocations = await _repo.getExpenseBuckets(
        st.expenseStartDate!,
        st.expenseEndDate!,
      );
      emit(
        st.copyWith(incomes: incomes, allocations: allocations, loading: false),
      );
    } catch (err) {
      emit(st.copyWith(error: err.toString(), loading: false));
    }
  }

  Future<void> _onIncomeStartDateChanged(
    IncomeStartDateChanged e,
    Emitter<BudgetingState> emit,
  ) {
    emit(state.copyWith(incomeStartDate: e.start));
    return Future.value();
  }

  Future<void> _onIncomeEndDateChanged(
    IncomeEndDateChanged e,
    Emitter<BudgetingState> emit,
  ) {
    emit(state.copyWith(incomeEndDate: e.end));
    return Future.value();
  }

  Future<void> _onExpenseStartDateChanged(
    ExpenseStartDateChanged e,
    Emitter<BudgetingState> emit,
  ) {
    emit(state.copyWith(expenseStartDate: e.start));
    return Future.value();
  }

  Future<void> _onExpenseEndDateChanged(
    ExpenseEndDateChanged e,
    Emitter<BudgetingState> emit,
  ) {
    emit(state.copyWith(expenseEndDate: e.end));
    return Future.value();
  }
}
