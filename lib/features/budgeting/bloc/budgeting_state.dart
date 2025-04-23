// lib/features/budgeting/bloc/budgeting_state.dart
import 'package:equatable/equatable.dart';
import 'package:ta_client/features/budgeting/models/allocation.dart';
import 'package:ta_client/features/budgeting/models/income.dart';

class BudgetingState extends Equatable {
  const BudgetingState({
    required this.incomes,
    required this.selectedIncomeIds,
    required this.allocations,
    required this.allocationValues,
    required this.selectedSubExpenses,
    required this.selectedCategories,
    this.startDate,
    this.endDate,
    this.loading = false,
    this.error,
  });
  factory BudgetingState.initial() => const BudgetingState(
        incomes: [],
        selectedIncomeIds: [],
        allocations: [],
        allocationValues: {},
        selectedSubExpenses: {},
        selectedCategories: {},
        loading: true,
      );
  final List<Income> incomes;
  final List<String> selectedIncomeIds;
  final List<Allocation> allocations;
  final Map<String, double> allocationValues;
  final Map<String, Set<String>> selectedSubExpenses;
  final Set<String> selectedCategories;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool loading;
  final String? error;

  BudgetingState copyWith({
    List<Income>? incomes,
    List<String>? selectedIncomeIds,
    List<Allocation>? allocations,
    Map<String, double>? allocationValues,
    Map<String, Set<String>>? selectedSubExpenses,
    Set<String>? selectedCategories,
    DateTime? startDate,
    DateTime? endDate,
    bool? loading,
    String? error,
  }) {
    return BudgetingState(
      incomes: incomes ?? this.incomes,
      selectedIncomeIds: selectedIncomeIds ?? this.selectedIncomeIds,
      allocations: allocations ?? this.allocations,
      allocationValues: allocationValues ?? this.allocationValues,
      selectedSubExpenses: selectedSubExpenses ?? this.selectedSubExpenses,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      loading: loading ?? this.loading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        incomes,
        selectedIncomeIds,
        allocations,
        allocationValues,
        selectedSubExpenses,
        selectedCategories,
        startDate,
        endDate,
        loading,
        error,
      ];
}
