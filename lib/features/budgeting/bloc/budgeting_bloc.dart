// lib/features/budgeting/bloc/budgeting_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_event.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_state.dart';
import 'package:ta_client/features/budgeting/repositories/budgeting_repository.dart';

class BudgetingBloc extends Bloc<BudgetingEvent, BudgetingState> {
  BudgetingBloc({required this.repository}) : super(BudgetingState.initial()) {
    on<LoadBudgetingData>(_onLoad);
    on<SelectIncomeCategory>(_onSelectIncome);
    on<UpdateAllocationValue>(_onUpdateAlloc);
    on<StartDateChanged>(_onStartDateChanged);
    on<EndDateChanged>(_onEndDateChanged);
    on<ToggleExpenseSubItem>(_onToggleSubItem);
    on<ToggleAllocationCategory>(_onToggleCategory);
  }
  final BudgetingRepository repository;

  Future<void> _onLoad(
    LoadBudgetingData event,
    Emitter<BudgetingState> emit,
  ) async {
    emit(state.copyWith(loading: true));
    try {
      final incomes = await repository.getIncomes();
      final allocations = await repository.getAllocations();
      final initValues = {for (final a in allocations) a.id: 0.0};
      emit(
        state.copyWith(
          incomes: incomes,
          allocations: allocations,
          allocationValues: initValues,
          loading: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(error: e.toString(), loading: false));
    }
  }

  void _onSelectIncome(
    SelectIncomeCategory event,
    Emitter<BudgetingState> emit,
  ) {
    final selected = List<String>.from(state.selectedIncomeIds);
    if (selected.contains(event.id)) {
      selected.remove(event.id);
    } else {
      selected.add(event.id);
    }
    emit(state.copyWith(selectedIncomeIds: selected));
  }

  void _onUpdateAlloc(
    UpdateAllocationValue event,
    Emitter<BudgetingState> emit,
  ) {
    final values = Map<String, double>.from(state.allocationValues);
    values[event.id] = event.value;
    emit(state.copyWith(allocationValues: values));
  }

  void _onStartDateChanged(
    StartDateChanged event,
    Emitter<BudgetingState> emit,
  ) {
    emit(state.copyWith(startDate: event.date));
  }

  void _onEndDateChanged(
    EndDateChanged event,
    Emitter<BudgetingState> emit,
  ) {
    emit(state.copyWith(endDate: event.date));
  }

  void _onToggleSubItem(
    ToggleExpenseSubItem event,
    Emitter<BudgetingState> emit,
  ) {
    final mapCopy = Map<String, Set<String>>.from(state.selectedSubExpenses);
    final currentSet =
        Set<String>.from(mapCopy[event.allocationId] ?? <String>{});

    if (event.isSelected) {
      currentSet.add(event.subItem);
    } else {
      currentSet.remove(event.subItem);
    }

    mapCopy[event.allocationId] = currentSet;
    emit(state.copyWith(selectedSubExpenses: mapCopy));
  }

  void _onToggleCategory(
    ToggleAllocationCategory e,
    Emitter<BudgetingState> emit,
  ) {
    final newSet = Set<String>.from(state.selectedCategories);
    if (e.isSelected) {
      newSet.add(e.category);
    } else {
      newSet.remove(e.category);
    }
    // also zero out percentage & clear sub-items if unselected
    final newValues = Map<String, double>.from(state.allocationValues);
    final newSubs = Map<String, Set<String>>.from(state.selectedSubExpenses);
    if (!e.isSelected) {
      newValues[e.category] = 0.0;
      newSubs.remove(e.category);
    }
    emit(
      state.copyWith(
        selectedCategories: newSet,
        allocationValues: newValues,
        selectedSubExpenses: newSubs,
      ),
    );
  }
}
