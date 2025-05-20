// lib/features/budgeting/services/budgeting_service.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
    required this.subcategories,
    this.lowerBound,
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

  SaveExpenseAllocationsRequestDto copyWith({
    String? budgetPeriodId,
    double? totalBudgetableIncome,
    List<FrontendAllocationDetailDto>? allocations,
  }) {
    return SaveExpenseAllocationsRequestDto(
      budgetPeriodId: budgetPeriodId ?? this.budgetPeriodId,
      totalBudgetableIncome:
          totalBudgetableIncome ?? this.totalBudgetableIncome,
      allocations: allocations ?? this.allocations,
    );
  }
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
  BudgetingService({required Dio dio}) : _dio = dio;
  final Dio _dio;

  Future<List<BackendIncomeSummaryItem>> fetchSummarizedIncomeForPeriod(
    String periodId,
  ) async {
    final endpoint = '/budgeting/income-summary/$periodId';
    debugPrint('[BudgetingService-DIO] GET $endpoint');
    try {
      final response = await _dio.get<dynamic>(endpoint);
      if (response.statusCode == 200 && response.data?['data'] is List) {
        // Assuming backend wraps in {data: [...]}
        final dataList = response.data['data'] as List<dynamic>;
        return dataList
            .map(
              (item) => BackendIncomeSummaryItem.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();
      } else if (response.statusCode == 200 && response.data is List) {
        // If backend returns list directly
        final dataList = response.data as List<dynamic>;
        return dataList
            .map(
              (item) => BackendIncomeSummaryItem.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();
      } else {
        throw BudgetingApiException(
          response.data?['message']?.toString() ??
              'Failed to fetch income summary.',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw BudgetingApiException(
        e.response?.data?['message']?.toString() ??
            e.message ??
            'Network error fetching income summary.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<List<BackendExpenseCategorySuggestion>>
  fetchExpenseCategorySuggestions() async {
    const endpoint = '/budgeting/expense-category-suggestions';
    debugPrint('[BudgetingService-DIO] GET $endpoint');
    try {
      final response = await _dio.get<dynamic>(endpoint);
      if (response.statusCode == 200 && response.data?['data'] is List) {
        final dataList = response.data['data'] as List<dynamic>;
        return dataList
            .map(
              (item) => BackendExpenseCategorySuggestion.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();
      } else if (response.statusCode == 200 && response.data is List) {
        final dataList = response.data as List<dynamic>;
        return dataList
            .map(
              (item) => BackendExpenseCategorySuggestion.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();
      } else {
        throw BudgetingApiException(
          response.data?['message']?.toString() ??
              'Failed to fetch expense suggestions.',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw BudgetingApiException(
        e.response?.data?['message']?.toString() ??
            e.message ??
            'Network error fetching expense suggestions.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<List<FrontendBudgetAllocation>> saveExpenseAllocations(
    SaveExpenseAllocationsRequestDto dto,
  ) async {
    const endpoint = '/budgeting/expense-allocations';
    debugPrint(
      '[BudgetingService-DIO] POST $endpoint',
    ); // Body logged by interceptor
    try {
      final response = await _dio.post<dynamic>(endpoint, data: dto.toJson());
      if ((response.statusCode == 201 || response.statusCode == 200) &&
          response.data?['data'] is List) {
        final dataList = response.data['data'] as List<dynamic>;
        return dataList
            .map(
              (item) => FrontendBudgetAllocation.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();
      } else {
        throw BudgetingApiException(
          response.data?['message']?.toString() ??
              'Failed to save expense allocations.',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw BudgetingApiException(
        e.response?.data?['message']?.toString() ??
            e.message ??
            'Network error saving expense allocations.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<List<FrontendBudgetAllocation>> fetchBudgetAllocationsForPeriod(
    String periodId,
  ) async {
    const endpoint = '/budgeting/allocations';
    final queryParams = {'periodId': periodId};
    debugPrint('[BudgetingService-DIO] GET $endpoint with params $queryParams');
    try {
      final response = await _dio.get<dynamic>(
        endpoint,
        queryParameters: queryParams,
      );
      if (response.statusCode == 200 && response.data?['data'] is List) {
        final dataList = response.data['data'] as List<dynamic>;
        return dataList
            .map(
              (item) => FrontendBudgetAllocation.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();
      } else if (response.statusCode == 200 && response.data is List) {
        final dataList = response.data as List<dynamic>;
        return dataList
            .map(
              (item) => FrontendBudgetAllocation.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();
      } else {
        throw BudgetingApiException(
          response.data?['message']?.toString() ??
              'Failed to fetch budget allocations.',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw BudgetingApiException(
        e.response?.data?['message']?.toString() ??
            e.message ??
            'Network error fetching budget allocations.',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
