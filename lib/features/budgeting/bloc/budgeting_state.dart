import 'package:equatable/equatable.dart';
import 'package:ta_client/features/budgeting/models/allocation.dart';
import 'package:ta_client/features/budgeting/models/income.dart';

class BudgetingState extends Equatable {
  const BudgetingState({
    this.incomeStartDate,
    this.incomeEndDate,
    this.incomeDateConfirmed = false,
    this.dateError,
    this.expenseStartDate,
    this.expenseEndDate,
    this.expenseDateConfirmed = false,
    this.incomes = const [],
    this.selectedIncomeIds = const [],
    this.allocations = const [],
    this.selectedCategories = const [],
    this.selectedSubExpenses = const {},
    this.allocationValues = const {},
    this.loading = false,
    this.error,
  });
  final DateTime? incomeStartDate;
  final DateTime? incomeEndDate;
  final bool incomeDateConfirmed;
  final String? dateError;

  final DateTime? expenseStartDate;
  final DateTime? expenseEndDate;
  final bool expenseDateConfirmed;

  final List<Income> incomes;
  final List<String> selectedIncomeIds;

  final List<Allocation> allocations;
  final List<String> selectedCategories;
  final Map<String, List<String>> selectedSubExpenses;
  final Map<String, double> allocationValues;

  final bool loading;
  final String? error;

  BudgetingState copyWith({
    DateTime? incomeStartDate,
    DateTime? incomeEndDate,
    bool? incomeDateConfirmed,
    String? dateError,
    DateTime? expenseStartDate,
    DateTime? expenseEndDate,
    bool? expenseDateConfirmed,
    List<Income>? incomes,
    List<String>? selectedIncomeIds,
    List<Allocation>? allocations,
    List<String>? selectedCategories,
    Map<String, List<String>>? selectedSubExpenses,
    Map<String, double>? allocationValues,
    bool? loading,
    String? error,
  }) {
    return BudgetingState(
      incomeStartDate: incomeStartDate ?? this.incomeStartDate,
      incomeEndDate: incomeEndDate ?? this.incomeEndDate,
      incomeDateConfirmed: incomeDateConfirmed ?? this.incomeDateConfirmed,
      dateError: dateError,
      expenseStartDate: expenseStartDate ?? this.expenseStartDate,
      expenseEndDate: expenseEndDate ?? this.expenseEndDate,
      expenseDateConfirmed: expenseDateConfirmed ?? this.expenseDateConfirmed,
      incomes: incomes ?? this.incomes,
      selectedIncomeIds: selectedIncomeIds ?? this.selectedIncomeIds,
      allocations: allocations ?? this.allocations,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      selectedSubExpenses: selectedSubExpenses ?? this.selectedSubExpenses,
      allocationValues: allocationValues ?? this.allocationValues,
      loading: loading ?? this.loading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    incomeStartDate,
    incomeEndDate,
    incomeDateConfirmed,
    dateError,
    expenseStartDate,
    expenseEndDate,
    expenseDateConfirmed,
    incomes,
    selectedIncomeIds,
    allocations,
    selectedCategories,
    selectedSubExpenses,
    allocationValues,
    loading,
    error,
  ];
}
