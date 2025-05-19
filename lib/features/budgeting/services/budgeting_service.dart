// lib/features/budgeting/services/budgeting_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ta_client/core/utils/authenticated_client.dart';
// Import your DTO for saving expense allocations and model for expense category suggestions
// These will map to what the backend expects/returns.

// Example DTO for what backend returns for income summary (matches IncomeByCategory in backend service)
class BackendIncomeSummaryItem {
  BackendIncomeSummaryItem({
    required this.categoryId,
    required this.categoryName,
    required this.subcategories,
    required this.categoryTotalAmount,
  });

  factory BackendIncomeSummaryItem.fromJson(Map<String, dynamic> json) {
    final subList = json['subcategories'] as List<dynamic>? ?? [];
    return BackendIncomeSummaryItem(
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      subcategories: subList
          .map(
            (s) => BackendSubcategoryIncome.fromJson(s as Map<String, dynamic>),
          )
          .toList(),
      categoryTotalAmount: (json['categoryTotalAmount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'categoryId': categoryId,
    'categoryName': categoryName,
    'subcategories': subcategories.map((s) => s.toJson()).toList(),
    'categoryTotalAmount': categoryTotalAmount,
  };

  final String categoryId;
  final String categoryName;
  final List<BackendSubcategoryIncome> subcategories;
  double categoryTotalAmount;
}

class BackendSubcategoryIncome {
  BackendSubcategoryIncome({
    required this.subcategoryId,
    required this.subcategoryName,
    required this.totalAmount,
  });

  factory BackendSubcategoryIncome.fromJson(Map<String, dynamic> json) {
    return BackendSubcategoryIncome(
      subcategoryId: json['subcategoryId'] as String,
      subcategoryName: json['subcategoryName'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'subcategoryId': subcategoryId,
    'subcategoryName': subcategoryName,
    'totalAmount': totalAmount,
  };

  final String subcategoryId;
  final String subcategoryName;
  final double totalAmount;
}

// Example DTO for what backend returns for expense category suggestions
// Matches ExpenseCategorySuggestion in backend service
class BackendExpenseCategorySuggestion {
  // e.g., [{id: "subId", name: "Sub Name"}]

  BackendExpenseCategorySuggestion({
    required this.id,
    required this.name,
    required this.subcategories, this.lowerBound,
    this.upperBound,
  });

  factory BackendExpenseCategorySuggestion.fromJson(Map<String, dynamic> json) {
    final subList = json['subcategories'] as List<dynamic>? ?? [];
    return BackendExpenseCategorySuggestion(
      id: json['id'] as String,
      name: json['name'] as String,
      lowerBound: (json['lowerBound'] as num?)?.toDouble(),
      upperBound: (json['upperBound'] as num?)?.toDouble(),
      subcategories: subList.map((s) => s as Map<String, dynamic>).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'lowerBound': lowerBound,
    'upperBound': upperBound,
    'subcategories': subcategories,
  };

  final String id; // categoryId
  final String name; // categoryName
  final double? lowerBound;
  final double? upperBound;
  final List<Map<String, dynamic>> subcategories;
}

// DTO for saving expense allocations (matches backend CreateExpenseBudgetAllocationsDto)
class SaveExpenseAllocationsRequestDto {
  SaveExpenseAllocationsRequestDto({
    required this.budgetPeriodId,
    required this.totalBudgetableIncome,
    required this.allocations,
  });

  factory SaveExpenseAllocationsRequestDto.fromJson(Map<String, dynamic> json) {
    final allocList = json['allocations'] as List<dynamic>? ?? [];
    return SaveExpenseAllocationsRequestDto(
      budgetPeriodId: json['budgetPeriodId'] as String,
      totalBudgetableIncome: (json['totalBudgetableIncome'] as num).toDouble(),
      allocations: allocList
          .map(
            (a) =>
                FrontendAllocationDetailDto.fromJson(a as Map<String, dynamic>),
          )
          .toList(),
    );
  }
  final String budgetPeriodId;
  final double totalBudgetableIncome;
  final List<FrontendAllocationDetailDto> allocations;

  Map<String, dynamic> toJson() => {
    'budgetPeriodId': budgetPeriodId,
    'totalBudgetableIncome': totalBudgetableIncome,
    'allocations': allocations.map((a) => a.toJson()).toList(),
  };
}

class FrontendAllocationDetailDto {
  FrontendAllocationDetailDto({
    required this.categoryId,
    required this.percentage,
    required this.selectedSubcategoryIds,
  });

  factory FrontendAllocationDetailDto.fromJson(Map<String, dynamic> json) {
    final subIds = json['selectedSubcategoryIds'] as List<dynamic>? ?? [];
    return FrontendAllocationDetailDto(
      categoryId: json['categoryId'] as String,
      percentage: (json['percentage'] as num).toDouble(),
      selectedSubcategoryIds: subIds.map((e) => e as String).toList(),
    );
  }
  final String categoryId;
  final double percentage;
  final List<String> selectedSubcategoryIds;

  Map<String, dynamic> toJson() => {
    'categoryId': categoryId,
    'percentage': percentage,
    'selectedSubcategoryIds': selectedSubcategoryIds,
  };
}

// Frontend model for BudgetAllocation (matches backend's BudgetAllocation)
class FrontendBudgetAllocation {
  // Parent Category's total allocated amount

  FrontendBudgetAllocation({
    required this.id,
    required this.periodId,
    required this.categoryId,
    required this.categoryName,
    required this.subcategoryId,
    required this.subcategoryName,
    required this.percentage,
    required this.amount,
  });

  factory FrontendBudgetAllocation.fromJson(Map<String, dynamic> json) {
    return FrontendBudgetAllocation(
      id: json['id'] as String,
      periodId: json['periodId'] as String,
      categoryId: json['categoryId'] as String,
      categoryName:
          json['category']?['name'] as String? ??
          json['categoryName'] as String? ??
          'Unknown',
      subcategoryId: json['subcategoryId'] as String,
      subcategoryName:
          json['subcategory']?['name'] as String? ??
          json['subcategoryName'] as String? ??
          'Unknown',
      percentage: (json['percentage'] as num).toDouble(),
      amount: (json['amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'periodId': periodId,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'subcategoryId': subcategoryId,
    'subcategoryName': subcategoryName,
    'percentage': percentage,
    'amount': amount,
  };

  final String id;
  final String periodId;
  final String categoryId;
  final String categoryName; // Denormalized for display
  final String subcategoryId;
  final String subcategoryName; // Denormalized for display
  final double percentage; // Parent Category's percentage
  final double amount;
}

class BudgetingApiException implements Exception {
  BudgetingApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => 'BudgetingApiException: $message (Status: $statusCode)';
}

class BudgetingService {
  BudgetingService({required String baseUrl})
    : _baseUrl = baseUrl,
      _client = AuthenticatedClient(http.Client());

  final String _baseUrl;
  final http.Client _client;

  // Fetches pre-summarized income data from the backend
  Future<List<BackendIncomeSummaryItem>> fetchSummarizedIncomeForPeriod(
    String periodId,
  ) async {
    final url = Uri.parse(
      '$_baseUrl/budgeting/income-summary/$periodId',
    ); // Example endpoint
    debugPrint('[BudgetingService-API] GET $url');
    final response = await _client.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List<dynamic>;
      return data
          .map(
            (item) =>
                BackendIncomeSummaryItem.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } else {
      final errorBody = json.decode(response.body);
      throw BudgetingApiException(
        (errorBody['message'] as String?) ?? 'Failed to fetch income summary',
        statusCode: response.statusCode,
      );
    }
  }

  // Fetches expense category suggestions (with bounds) from the backend
  Future<List<BackendExpenseCategorySuggestion>>
  fetchExpenseCategorySuggestions() async {
    final url = Uri.parse(
      '$_baseUrl/budgeting/expense-category-suggestions',
    ); // Example endpoint
    debugPrint('[BudgetingService-API] GET $url');
    final response = await _client.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List<dynamic>;
      return data
          .map(
            (item) => BackendExpenseCategorySuggestion.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    } else {
      final errorBody = json.decode(response.body);
      throw BudgetingApiException(
        (errorBody['message'] as String?) ??
            'Failed to fetch expense category suggestions',
        statusCode: response.statusCode,
      );
    }
  }

  // Saves the entire expense budget plan to the backend
  Future<List<FrontendBudgetAllocation>> saveExpenseAllocations(
    SaveExpenseAllocationsRequestDto dto,
  ) async {
    final url = Uri.parse(
      '$_baseUrl/budgeting/expense-allocations',
    ); // Example endpoint
    debugPrint('[BudgetingService-API] POST $url with body: ${dto.toJson()}');
    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(dto.toJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      // 201 for created, 200 for updated
      final data = json.decode(response.body) as List<dynamic>;
      return data
          .map(
            (item) =>
                FrontendBudgetAllocation.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } else {
      final errorBody = json.decode(response.body);
      throw BudgetingApiException(
        (errorBody['message'] as String?) ??
            'Failed to save expense allocations',
        statusCode: response.statusCode,
      );
    }
  }

  // Fetches existing budget allocations for a given expense period
  Future<List<FrontendBudgetAllocation>> fetchBudgetAllocationsForPeriod(
    String periodId,
  ) async {
    final url = Uri.parse(
      '$_baseUrl/budgeting/allocations?periodId=$periodId',
    ); // Example endpoint
    debugPrint('[BudgetingService-API] GET $url');
    final response = await _client.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List<dynamic>;
      return data
          .map(
            (item) =>
                FrontendBudgetAllocation.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } else {
      final errorBody = json.decode(response.body);
      throw BudgetingApiException(
        (errorBody['message'] as String?) ??
            'Failed to fetch budget allocations',
        statusCode: response.statusCode,
      );
    }
  }

  // The old ensureDates logic is primarily client-side validation before making an API call,
  // or handled by backend if client sends dates for period creation.
  // It doesn't need to be an API call itself unless backend validates period creation extensively.
}
