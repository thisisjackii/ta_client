// lib/features/budgeting/bloc/budgeting_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_event.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_state.dart';
import 'package:ta_client/features/budgeting/repositories/budgeting_repository.dart';

class BudgetingBloc extends Bloc<BudgetingEvent, BudgetingState> {
  BudgetingBloc({required this.repository}) : super(const BudgetingState()) {
    on<LoadBudgetingData>(_onLoad);
    on<ConfirmDateRange>(_onConfirmDateRange);
    on<SelectIncomeCategory>(_onSelectIncome);
    on<StartDateChanged>(_onStartDateChanged);
    on<EndDateChanged>(_onEndDateChanged);
    on<ToggleAllocationCategory>(_onToggleCategory);
    on<UpdateAllocationValue>(_onUpdateValue);
    on<ToggleExpenseSubItem>(_onToggleSub);
    on<ResetDateConfirmation>(_onResetDateConfirmation);
  }

  final BudgetingRepository repository;

  Future<void> _onLoad(
    LoadBudgetingData event,
    Emitter<BudgetingState> emit,
  ) async {
    emit(state.copyWith(loading: true));
    try {
      final incomes = await repository.getIncomeBuckets(
        state.startDate ?? DateTime.now(),
        state.endDate ?? DateTime.now(),
      );
      final allocations = await repository.getExpenseBuckets(
        state.startDate ?? DateTime.now(),
        state.endDate ?? DateTime.now(),
      );
      final totalIncome = incomes.fold<int>(0, (sum, inc) => sum + inc.value);
      final initValues = {for (final a in allocations) a.id: 0.0};
      emit(
        state.copyWith(
          incomes: incomes,
          allocations: allocations,
          totalIncome: totalIncome,
          allocationValues: initValues,
          dateConfirmed: true,
          loading: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(error: e.toString(), loading: false));
    }
  }

  Future<void> _onConfirmDateRange(
    ConfirmDateRange ev,
    Emitter<BudgetingState> emit,
  ) async {
    // validate + fetch
    try {
      emit(
        state.copyWith(
          startDate: ev.start,
          endDate: ev.end,
          dateConfirmed: false,
          loading: true,
        ),
      );

      final incomes = await repository.getIncomeBuckets(ev.start, ev.end);
      final allocations = await repository.getExpenseBuckets(ev.start, ev.end);
      final totalIncome = incomes.fold<int>(0, (sum, inc) => sum + inc.value);
      final initValues = {for (final a in allocations) a.title: 0.0};

      emit(
        state.copyWith(
          dateConfirmed: true,
          incomes: incomes,
          totalIncome: totalIncome,
          allocations: allocations,
          allocationValues: initValues,
          loading: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(dateError: e.toString(), loading: false));
    }
  }

  void _onSelectIncome(SelectIncomeCategory ev, Emitter<BudgetingState> emit) {
    final sel = List<String>.from(state.selectedIncomeIds);
    sel.contains(ev.id) ? sel.remove(ev.id) : sel.add(ev.id);
    emit(state.copyWith(selectedIncomeIds: sel));
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

  void _onToggleCategory(
    ToggleAllocationCategory ev,
    Emitter<BudgetingState> emit,
  ) {
    final cats = Set<String>.from(state.selectedCategories);
    if (ev.isSelected) {
      cats.add(ev.category);
    } else {
      cats.remove(ev.category);
    }
    emit(state.copyWith(selectedCategories: cats));
  }

  void _onUpdateValue(UpdateAllocationValue ev, Emitter<BudgetingState> emit) {
    final vals = Map<String, double>.from(state.allocationValues);
    vals[ev.id] = ev.value;
    emit(state.copyWith(allocationValues: vals));
  }

  void _onToggleSub(ToggleExpenseSubItem event, Emitter<BudgetingState> emit) {
    // 1. Convert any existing Iterable to List and build a fresh map
    final updatedSubs = <String, List<String>>{
      for (final e in state.selectedSubExpenses.entries)
        e.key: e.value.toList(),
    };

    // 2. Copy or initialize the list for this category:
    final currentList = List<String>.from(
      updatedSubs[event.allocationId] ?? <String>[],
    );

    // 3. Add or remove the subItem:
    if (event.isSelected) {
      currentList.add(event.subItem);
    } else {
      currentList.remove(event.subItem);
    }

    // 4. Put the new list back into the map:
    updatedSubs[event.allocationId] = currentList;

    // 5. Emit a new state with the updated map:
    emit(state.copyWith(selectedSubExpenses: updatedSubs));
  }

  void _onResetDateConfirmation(
    ResetDateConfirmation event,
    Emitter<BudgetingState> emit,
  ) {
    emit(state.copyWith(dateConfirmed: false));
  }
}
