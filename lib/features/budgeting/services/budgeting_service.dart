// lib/features/budgeting/data/services/budgeting_service.dart
import 'package:ta_client/features/budgeting/models/allocation.dart';
import 'package:ta_client/features/budgeting/models/income.dart';

class BudgetingService {
  BudgetingService({required this.baseUrl});
  final String baseUrl;
  Future<List<Income>> fetchIncomeData() async {
    // Simulate API delay
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return [
      Income(id: '0', title: 'Gaji', value: 1500000),
      Income(id: '1', title: 'Upah', value: 500000),
      Income(id: '2', title: 'Bonus', value: 700000),
    ];
  }

  Future<List<Allocation>> fetchAllocationData() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return [
      Allocation(id: '0', title: 'Rumah', target: 3500000),
      Allocation(id: '1', title: 'Sosial', target: 750000),
      Allocation(id: '2', title: 'Tabungan', target: 150000),
    ];
  }
}
