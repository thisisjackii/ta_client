// lib/features/budgeting/bloc/budgeting_event.dart
import 'package:equatable/equatable.dart';

abstract class BudgetingEvent extends Equatable {
  const BudgetingEvent();

  @override
  List<Object?> get props => [];
}

// --- Date Selection and Confirmation ---
class BudgetingIncomeDateRangeSelected extends BudgetingEvent {
  // Optional: if user is re-selecting for an existing budget period

  const BudgetingIncomeDateRangeSelected({
    required this.start,
    required this.end,
    this.existingPeriodId,
  });
  final DateTime start;
  final DateTime end;
  final String? existingPeriodId;

  @override
  List<Object?> get props => [start, end, existingPeriodId];
}

class BudgetingExpenseDateRangeSelected extends BudgetingEvent {
  const BudgetingExpenseDateRangeSelected({
    required this.start,
    required this.end,
    this.existingPeriodId,
  });
  final DateTime start;
  final DateTime end;
  final String? existingPeriodId;

  @override
  List<Object?> get props => [start, end, existingPeriodId];
}

// --- Data Loading Triggers (Repository handles online/offline) ---
class BudgetingLoadIncomeSummary extends BudgetingEvent {
  const BudgetingLoadIncomeSummary({required this.periodId});
  final String periodId;
  @override
  List<Object?> get props => [periodId];
}

class BudgetingLoadExpenseSuggestions extends BudgetingEvent {
  const BudgetingLoadExpenseSuggestions();
}

class BudgetingLoadExistingAllocations extends BudgetingEvent {
  const BudgetingLoadExistingAllocations({required this.periodId});
  final String periodId;
  @override
  List<Object?> get props => [periodId];
}

// --- User Interactions for Building the Budget ---
class BudgetingSelectIncomeSubcategory extends BudgetingEvent {
  const BudgetingSelectIncomeSubcategory({required this.subcategoryId});
  final String subcategoryId;
  @override
  List<Object?> get props => [subcategoryId];
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
  const BudgetingSaveExpensePlan();
}

// --- Utility Events ---
class BudgetingClearError extends BudgetingEvent {}

class BudgetingResetState
    extends BudgetingEvent {} // To reset the whole BLoC state

class BudgetingSyncPendingData extends BudgetingEvent {
  // For manual sync trigger
  const BudgetingSyncPendingData();
}
