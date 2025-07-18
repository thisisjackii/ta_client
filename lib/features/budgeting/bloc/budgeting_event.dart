// lib/features/budgeting/bloc/budgeting_event.dart
import 'package:equatable/equatable.dart';
// For DTO

abstract class BudgetingEvent extends Equatable {
  const BudgetingEvent();
  @override
  List<Object?> get props => [];
}

// --- Date Selection and Confirmation ---
class BudgetingIncomeDateRangeSelected extends BudgetingEvent {
  const BudgetingIncomeDateRangeSelected({
    required this.start,
    required this.end,
  });
  final DateTime start;
  final DateTime end;
  @override
  List<Object?> get props => [start, end];
}

class BudgetingPlanDateRangeSelected extends BudgetingEvent {
  // Renamed from ExpenseDateRangeSelected
  const BudgetingPlanDateRangeSelected({
    required this.start,
    required this.end,
  });
  final DateTime start;
  final DateTime end;
  @override
  List<Object?> get props => [start, end];
}

// --- Data Loading Triggers ---
// Triggered after income dates are confirmed
class BudgetingLoadIncomeSummaryForSelectedDates extends BudgetingEvent {
  const BudgetingLoadIncomeSummaryForSelectedDates();
}

// Triggered after plan dates are confirmed
class BudgetingLoadExpenseSuggestionsAndExistingPlan extends BudgetingEvent {
  const BudgetingLoadExpenseSuggestionsAndExistingPlan();
}

// New Event: To load details of a specific plan
class BudgetingLoadPlanDetails extends BudgetingEvent {
  // <<< NEW EVENT
  const BudgetingLoadPlanDetails({required this.planId});
  final String planId;
  @override
  List<Object?> get props => [planId];
}

// --- User Interactions for Building the Budget ---
class BudgetingSelectIncomeSubcategory extends BudgetingEvent {
  const BudgetingSelectIncomeSubcategory({required this.subcategoryId});
  final String subcategoryId;
  @override
  List<Object?> get props => [subcategoryId];
}

// Event to explicitly set the total calculated income after user confirms selections
class BudgetingTotalIncomeConfirmed extends BudgetingEvent {
  const BudgetingTotalIncomeConfirmed(this.totalIncome);
  final double totalIncome;
  @override
  List<Object?> get props => [totalIncome];
}

class BudgetingToggleExpenseCategory extends BudgetingEvent {
  const BudgetingToggleExpenseCategory({
    required this.categoryId,
    required this.isSelected,
  });
  final String categoryId;
  final bool isSelected;
  @override
  List<Object?> get props => [categoryId, isSelected];
}

class BudgetingUpdateExpenseCategoryPercentage extends BudgetingEvent {
  const BudgetingUpdateExpenseCategoryPercentage({
    required this.categoryId,
    required this.percentage,
  });
  final String categoryId;
  final double percentage;
  @override
  List<Object?> get props => [categoryId, percentage];
}

class BudgetingToggleExpenseSubItem extends BudgetingEvent {
  const BudgetingToggleExpenseSubItem({
    required this.parentCategoryId,
    required this.subcategoryId,
    required this.isSelected,
  });
  final String parentCategoryId;
  final String subcategoryId;
  final bool isSelected;
  @override
  List<Object?> get props => [parentCategoryId, subcategoryId, isSelected];
}

// --- Saving the Budget ---
class BudgetingSaveExpensePlan extends BudgetingEvent {
  const BudgetingSaveExpensePlan(); // DTO will be constructed from BLoC state
}

// --- Utility Events ---
class BudgetingClearError extends BudgetingEvent {}

class BudgetingClearInfoMessage extends BudgetingEvent {}

class BudgetingResetState extends BudgetingEvent {}

class BudgetingSyncPendingData extends BudgetingEvent {}

class BudgetingLoadUserPlans
    extends BudgetingEvent {} // Or more specific like BudgetingLoadLatestPlan

class BudgetingStartEdit extends BudgetingEvent {
  // <<< NEW EVENT
  const BudgetingStartEdit({required this.planId});
  final String planId;
  @override
  List<Object?> get props => [planId];
}

class BudgetingDeleteCategoryAllocation extends BudgetingEvent {
  // For swipe-delete
  const BudgetingDeleteCategoryAllocation({required this.categoryId});
  final String categoryId;
  @override
  List<Object?> get props => [categoryId];
}

class BudgetingToggleDashboardSubItem extends BudgetingEvent {
  // For direct subcategory toggle
  const BudgetingToggleDashboardSubItem({
    required this.parentCategoryId,
    required this.subcategoryId,
    required this.isSelected,
  });
  final String parentCategoryId;
  final String subcategoryId;
  final bool isSelected;
  @override
  List<Object?> get props => [parentCategoryId, subcategoryId, isSelected];
}

class BudgetingClearStatus extends BudgetingEvent {
  // <<< ADD THIS EVENT
  const BudgetingClearStatus();
}
