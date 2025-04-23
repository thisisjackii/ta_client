// lib/features/budgeting/bloc/budgeting_event.dart
import 'package:equatable/equatable.dart';

abstract class BudgetingEvent extends Equatable {
  const BudgetingEvent();
  @override
  List<Object?> get props => [];
}

class LoadBudgetingData extends BudgetingEvent {}

class SelectIncomeCategory extends BudgetingEvent {
  const SelectIncomeCategory(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

class UpdateAllocationValue extends BudgetingEvent {
  const UpdateAllocationValue({required this.id, required this.value});
  final String id;
  final double value;
  @override
  List<Object?> get props => [id, value];
}

class StartDateChanged extends BudgetingEvent {
  const StartDateChanged(this.date);
  final DateTime date;
  @override
  List<Object?> get props => [date];
}

class EndDateChanged extends BudgetingEvent {
  const EndDateChanged(this.date);
  final DateTime date;
  @override
  List<Object?> get props => [date];
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
