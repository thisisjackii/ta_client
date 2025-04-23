// lib/features/budgeting/data/repository/budgeting_repository.dart
import 'package:ta_client/features/budgeting/models/allocation.dart';
import 'package:ta_client/features/budgeting/models/income.dart';
import 'package:ta_client/features/budgeting/services/budgeting_service.dart';

class BudgetingRepository {
  BudgetingRepository(this._service);
  final BudgetingService _service;
  Future<List<Income>> getIncomes() => _service.fetchIncomeData();
  Future<List<Allocation>> getAllocations() => _service.fetchAllocationData();
}
