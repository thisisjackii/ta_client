import 'package:equatable/equatable.dart';

abstract class BudgetingEvent extends Equatable {
  const BudgetingEvent();

  @override
  List<Object?> get props => [];
}

/// Reset only the income‐date confirmation flag
class ResetIncomeDateConfirmation extends BudgetingEvent {}

/// User confirmed an income date range
class ConfirmIncomeDateRange extends BudgetingEvent {
  const ConfirmIncomeDateRange({required this.start, required this.end});
  final DateTime start;
  final DateTime end;

  @override
  List<Object?> get props => [start, end];
}

/// Reset only the expense‐date confirmation flag
class ResetExpenseDateConfirmation extends BudgetingEvent {}

/// User confirmed an expense date range
class ConfirmExpenseDateRange extends BudgetingEvent {
  const ConfirmExpenseDateRange({required this.start, required this.end});
  final DateTime start;
  final DateTime end;

  @override
  List<Object?> get props => [start, end];
}

// … existing events below unchanged …
class SelectIncomeCategory extends BudgetingEvent {
  const SelectIncomeCategory(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

class ToggleExpenseSubItem extends BudgetingEvent {
  const ToggleExpenseSubItem({
    required this.allocationId,
    required this.subItem,
    required this.isSelected,
  });
  final String allocationId;
  final String subItem;
  final bool isSelected;
  @override
  List<Object?> get props => [allocationId, subItem, isSelected];
}

class ToggleAllocationCategory extends BudgetingEvent {
  const ToggleAllocationCategory({
    required this.category,
    required this.isSelected,
  });
  final String category;
  final bool isSelected;
  @override
  List<Object?> get props => [category, isSelected];
}

class UpdateAllocationValue extends BudgetingEvent {
  const UpdateAllocationValue({required this.id, required this.value});
  final String id;
  final double value;
  @override
  List<Object?> get props => [id, value];
}

class LoadDashboard extends BudgetingEvent {}

class IncomeStartDateChanged extends BudgetingEvent {
  const IncomeStartDateChanged(this.start);
  final DateTime start;

  @override
  List<Object?> get props => [start];
}

class IncomeEndDateChanged extends BudgetingEvent {
  const IncomeEndDateChanged(this.end);
  final DateTime end;

  @override
  List<Object?> get props => [end];
}

class ExpenseStartDateChanged extends BudgetingEvent {
  const ExpenseStartDateChanged(this.start);
  final DateTime start;

  @override
  List<Object?> get props => [start];
}

class ExpenseEndDateChanged extends BudgetingEvent {
  const ExpenseEndDateChanged(this.end);
  final DateTime end;

  @override
  List<Object?> get props => [end];
}
