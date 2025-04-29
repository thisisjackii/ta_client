// lib/features/budgeting/data/repository/budgeting_repository.dart
import 'package:ta_client/features/budgeting/models/allocation.dart';
import 'package:ta_client/features/budgeting/models/income.dart';
import 'package:ta_client/features/budgeting/services/budgeting_service.dart';

class BudgetingRepository {
  BudgetingRepository(this._service);
  final BudgetingService _service;
  Future<List<Income>> getIncomeBuckets(DateTime s, DateTime e) =>
      _service.fetchIncomeBuckets(s, e);
  Future<List<Allocation>> getExpenseBuckets(DateTime s, DateTime e) =>
      _service.fetchExpenseBuckets(s, e);
  // call ensuredates from service
  Future<void> ensureDates(DateTime? s, DateTime? e) =>
      _service.ensureDates(s, e);
}
