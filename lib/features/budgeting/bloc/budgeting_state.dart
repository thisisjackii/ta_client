// lib/features/budgeting/bloc/budgeting_state.dart
import 'package:equatable/equatable.dart';
import 'package:ta_client/features/budgeting/models/allocation.dart';
import 'package:ta_client/features/budgeting/models/income.dart';

class BudgetingState extends Equatable {
  const BudgetingState({
    this.startDate,
    this.endDate,
    this.dateConfirmed = false,
    this.dateError,
    this.incomes = const [],
    this.totalIncome = 0,
    this.selectedIncomeIds = const [],
    this.allocations = const [],
    this.allocationValues = const {},
    this.selectedCategories = const {},
    this.selectedSubExpenses = const {},
    this.loading = false,
    this.error,
  });
  final DateTime? startDate;
  final DateTime? endDate;
  final bool dateConfirmed;
  final String? dateError;
  final List<Income> incomes;
  final int totalIncome;
  final List<String> selectedIncomeIds;
  final List<Allocation> allocations;
  final Map<String, double> allocationValues;
  final Set<String> selectedCategories;
  final Map<String, List<String>> selectedSubExpenses;
  final bool loading;
  final String? error;

  BudgetingState copyWith({
    DateTime? startDate,
    DateTime? endDate,
    bool? dateConfirmed,
    String? dateError,
    List<Income>? incomes,
    int? totalIncome,
    List<String>? selectedIncomeIds,
    List<Allocation>? allocations,
    Map<String, double>? allocationValues,
    Set<String>? selectedCategories,
    Map<String, List<String>>? selectedSubExpenses,
    bool? loading,
    String? error,
  }) {
    return BudgetingState(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      dateConfirmed: dateConfirmed ?? this.dateConfirmed,
      dateError: dateError,
      incomes: incomes ?? this.incomes,
      totalIncome: totalIncome ?? this.totalIncome,
      selectedIncomeIds: selectedIncomeIds ?? this.selectedIncomeIds,
      allocations: allocations ?? this.allocations,
      allocationValues: allocationValues ?? this.allocationValues,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      selectedSubExpenses: selectedSubExpenses ?? this.selectedSubExpenses,
      loading: loading ?? this.loading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        startDate,
        endDate,
        dateConfirmed,
        dateError,
        incomes,
        totalIncome,
        selectedIncomeIds,
        allocations,
        allocationValues,
        selectedCategories,
        selectedSubExpenses,
        loading,
        error,
      ];
}
