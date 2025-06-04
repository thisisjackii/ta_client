// lib/features/budgeting/bloc/budgeting_state.dart
import 'package:equatable/equatable.dart';
import 'package:ta_client/features/budgeting/services/budgeting_service.dart'
    show // Using show to be explicit about which models are used by the state
        BackendExpenseCategorySuggestion,
        BackendIncomeSummaryItem,
        FrontendBudgetAllocation, // For displaying the current/saved plan
        FrontendBudgetPlan; // Though allocations are part of FrontendBudgetPlan

class BudgetingState extends Equatable {
  const BudgetingState({
    // Dates for the income calculation phase
    this.incomeCalculationStartDate,
    this.incomeCalculationEndDate,
    this.incomeDateConfirmed = false, // True if valid income dates are set
    // Dates for the expense plan itself
    this.planStartDate,
    this.planEndDate,
    this.planDateConfirmed = false, // True if valid plan dates are set

    this.dateError, // For UI feedback on date validation
    // Data related to income selection
    this.incomeSummary = const [],
    this.selectedIncomeSubcategoryIds = const [],
    this.totalCalculatedIncome =
        0.0, // Stored after user confirms income selection
    // Data related to expense allocation
    this.expenseCategorySuggestions = const [],
    this.selectedExpenseCategoryIds =
        const [], // IDs of categories chosen for allocation
    this.expenseAllocationPercentages = const {}, // categoryId -> percentage
    this.selectedExpenseSubItems =
        const {}, // parentCategoryId -> List<subcategoryId>
    // The current BudgetPlan being viewed or recently saved/loaded
    this.currentBudgetPlan, // This will hold the full plan including its allocations
    // Operation Status
    this.loading = false,
    this.error,
    this.saveSuccess = false,
    this.infoMessage,
    this.initialSpendingForEditedPlan = const {}, // <<< NEW PROPERTY
    this.isEditing = false, // <<< NEW PROPERTY to indicate edit mode
  });

  // Income period related
  final DateTime? incomeCalculationStartDate;
  final DateTime? incomeCalculationEndDate;
  final bool incomeDateConfirmed;

  // Expense (Budget Plan) period related
  final DateTime? planStartDate;
  final DateTime? planEndDate;
  final bool planDateConfirmed;

  final String? dateError;

  // Income data
  final List<BackendIncomeSummaryItem> incomeSummary;
  final List<String> selectedIncomeSubcategoryIds;
  final double totalCalculatedIncome;

  // Expense allocation data
  final List<BackendExpenseCategorySuggestion> expenseCategorySuggestions;
  final List<String> selectedExpenseCategoryIds;
  final Map<String, double> expenseAllocationPercentages;
  final Map<String, List<String>> selectedExpenseSubItems;

  // Current/Loaded Budget Plan
  final FrontendBudgetPlan? currentBudgetPlan; // Holds the loaded/saved plan

  final bool loading;
  final String? error;
  final bool saveSuccess;
  final String? infoMessage;

  final Map<String, double>
  initialSpendingForEditedPlan; // categoryId -> spentAmount
  final bool isEditing;

  BudgetingState copyWith({
    DateTime? incomeCalculationStartDate,
    DateTime? incomeCalculationEndDate,
    bool? incomeDateConfirmed,
    DateTime? planStartDate,
    DateTime? planEndDate,
    bool? planDateConfirmed,
    String? dateError,
    bool clearDateError = false,
    List<BackendIncomeSummaryItem>? incomeSummary,
    List<String>? selectedIncomeSubcategoryIds,
    double? totalCalculatedIncome,
    List<BackendExpenseCategorySuggestion>? expenseCategorySuggestions,
    List<String>? selectedExpenseCategoryIds,
    Map<String, double>? expenseAllocationPercentages,
    Map<String, List<String>>? selectedExpenseSubItems,
    FrontendBudgetPlan? currentBudgetPlan,
    bool clearCurrentBudgetPlan = false,
    bool? loading,
    String? error,
    bool clearError = false,
    bool? saveSuccess,
    String? infoMessage,
    bool clearInfoMessage = false,
    Map<String, double>? initialSpendingForEditedPlan,
    bool? isEditing,
    bool clearInitialSpending = false, // To clear when not editing
  }) {
    return BudgetingState(
      incomeCalculationStartDate:
          incomeCalculationStartDate ?? this.incomeCalculationStartDate,
      incomeCalculationEndDate:
          incomeCalculationEndDate ?? this.incomeCalculationEndDate,
      incomeDateConfirmed: incomeDateConfirmed ?? this.incomeDateConfirmed,
      planStartDate: planStartDate ?? this.planStartDate,
      planEndDate: planEndDate ?? this.planEndDate,
      planDateConfirmed: planDateConfirmed ?? this.planDateConfirmed,
      dateError: clearDateError ? null : dateError ?? this.dateError,
      incomeSummary: incomeSummary ?? this.incomeSummary,
      selectedIncomeSubcategoryIds:
          selectedIncomeSubcategoryIds ?? this.selectedIncomeSubcategoryIds,
      totalCalculatedIncome:
          totalCalculatedIncome ?? this.totalCalculatedIncome,
      expenseCategorySuggestions:
          expenseCategorySuggestions ?? this.expenseCategorySuggestions,
      selectedExpenseCategoryIds:
          selectedExpenseCategoryIds ?? this.selectedExpenseCategoryIds,
      expenseAllocationPercentages:
          expenseAllocationPercentages ?? this.expenseAllocationPercentages,
      selectedExpenseSubItems:
          selectedExpenseSubItems ?? this.selectedExpenseSubItems,
      currentBudgetPlan: clearCurrentBudgetPlan
          ? null
          : currentBudgetPlan ?? this.currentBudgetPlan,
      loading: loading ?? this.loading,
      error: clearError ? null : error ?? this.error,
      saveSuccess: saveSuccess ?? this.saveSuccess,
      infoMessage: clearInfoMessage ? null : infoMessage ?? this.infoMessage,
      initialSpendingForEditedPlan: clearInitialSpending
          ? const {}
          : initialSpendingForEditedPlan ?? this.initialSpendingForEditedPlan,
      isEditing: isEditing ?? this.isEditing,
    );
  }

  @override
  List<Object?> get props => [
    incomeCalculationStartDate,
    incomeCalculationEndDate,
    incomeDateConfirmed,
    planStartDate,
    planEndDate,
    planDateConfirmed,
    dateError,
    incomeSummary,
    selectedIncomeSubcategoryIds,
    totalCalculatedIncome,
    expenseCategorySuggestions,
    selectedExpenseCategoryIds,
    expenseAllocationPercentages,
    selectedExpenseSubItems,
    currentBudgetPlan,
    loading,
    error,
    saveSuccess,
    infoMessage,
    initialSpendingForEditedPlan,
    isEditing,
  ];
}
