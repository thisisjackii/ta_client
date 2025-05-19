// lib/features/budgeting/bloc/budgeting_state.dart
import 'package:equatable/equatable.dart';
// Import the DTOs/Models from the service or dedicated model files
import 'package:ta_client/features/budgeting/services/budgeting_service.dart'
    show
        BackendExpenseCategorySuggestion,
        BackendIncomeSummaryItem,
        FrontendBudgetAllocation;

class BudgetingState extends Equatable {
  // For non-error messages like "queued for sync"

  const BudgetingState({
    this.incomePeriodId,
    this.incomeStartDate,
    this.incomeEndDate,
    this.incomeDateConfirmed = false,
    this.expensePeriodId,
    this.expenseStartDate,
    this.expenseEndDate,
    this.expenseDateConfirmed = false,
    this.dateError,
    this.incomeSummary = const [],
    this.selectedIncomeSubcategoryIds = const [],
    this.expenseCategorySuggestions = const [],
    this.selectedExpenseCategoryIds = const [],
    this.expenseAllocationPercentages = const {},
    this.selectedExpenseSubItems = const {},
    this.currentAllocations = const [],
    this.loading = false,
    this.error,
    this.saveSuccess = false,
    this.infoMessage,
  });
  // Date and Period Management
  final String? incomePeriodId;
  final DateTime? incomeStartDate;
  final DateTime? incomeEndDate;
  final bool
  incomeDateConfirmed; // True if a valid period (ID, start, end) is set

  final String? expensePeriodId;
  final DateTime? expenseStartDate;
  final DateTime? expenseEndDate;
  final bool expenseDateConfirmed;

  final String?
  dateError; // For validation errors specifically from date selection

  // Data for UI
  final List<BackendIncomeSummaryItem> incomeSummary;
  final List<String> selectedIncomeSubcategoryIds;

  final List<BackendExpenseCategorySuggestion> expenseCategorySuggestions;
  final List<String> selectedExpenseCategoryIds;
  final Map<String, double>
  expenseAllocationPercentages; // categoryId -> percentage (0-100)
  final Map<String, List<String>>
  selectedExpenseSubItems; // parentCategoryId -> List<subcategoryId>

  // Represents the currently active/loaded budget allocations for the selected expense period
  final List<FrontendBudgetAllocation> currentAllocations;

  // Operation Status
  final bool loading;
  final String?
  error; // General error message for operations other than date validation
  final bool saveSuccess;
  final String? infoMessage;

  BudgetingState copyWith({
    String? incomePeriodId,
    DateTime? incomeStartDate,
    DateTime? incomeEndDate,
    bool? incomeDateConfirmed,
    String? expensePeriodId,
    DateTime? expenseStartDate,
    DateTime? expenseEndDate,
    bool? expenseDateConfirmed,
    String? dateError,
    List<BackendIncomeSummaryItem>? incomeSummary,
    List<String>? selectedIncomeSubcategoryIds,
    List<BackendExpenseCategorySuggestion>? expenseCategorySuggestions,
    List<String>? selectedExpenseCategoryIds,
    Map<String, double>? expenseAllocationPercentages,
    Map<String, List<String>>? selectedExpenseSubItems,
    List<FrontendBudgetAllocation>? currentAllocations,
    bool? loading,
    String? error,
    bool? saveSuccess,
    String? infoMessage,
  }) {
    return BudgetingState(
      incomePeriodId: incomePeriodId ?? this.incomePeriodId,
      incomeStartDate: incomeStartDate ?? this.incomeStartDate,
      incomeEndDate: incomeEndDate ?? this.incomeEndDate,
      incomeDateConfirmed: incomeDateConfirmed ?? this.incomeDateConfirmed,
      expensePeriodId: expensePeriodId ?? this.expensePeriodId,
      expenseStartDate: expenseStartDate ?? this.expenseStartDate,
      expenseEndDate: expenseEndDate ?? this.expenseEndDate,
      expenseDateConfirmed: expenseDateConfirmed ?? this.expenseDateConfirmed,
      dateError: dateError,
      incomeSummary: incomeSummary ?? this.incomeSummary,
      selectedIncomeSubcategoryIds:
          selectedIncomeSubcategoryIds ?? this.selectedIncomeSubcategoryIds,
      expenseCategorySuggestions:
          expenseCategorySuggestions ?? this.expenseCategorySuggestions,
      selectedExpenseCategoryIds:
          selectedExpenseCategoryIds ?? this.selectedExpenseCategoryIds,
      expenseAllocationPercentages:
          expenseAllocationPercentages ?? this.expenseAllocationPercentages,
      selectedExpenseSubItems:
          selectedExpenseSubItems ?? this.selectedExpenseSubItems,
      currentAllocations: currentAllocations ?? this.currentAllocations,
      loading: loading ?? this.loading,
      error: error,
      saveSuccess: saveSuccess ?? this.saveSuccess,
      infoMessage: infoMessage,
    );
  }

  @override
  List<Object?> get props => [
    incomePeriodId,
    incomeStartDate,
    incomeEndDate,
    incomeDateConfirmed,
    expensePeriodId,
    expenseStartDate,
    expenseEndDate,
    expenseDateConfirmed,
    dateError,
    incomeSummary,
    selectedIncomeSubcategoryIds,
    expenseCategorySuggestions,
    selectedExpenseCategoryIds,
    expenseAllocationPercentages,
    selectedExpenseSubItems,
    currentAllocations,
    loading,
    error,
    saveSuccess,
    infoMessage,
  ];
}
