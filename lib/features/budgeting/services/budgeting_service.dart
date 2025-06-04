// lib/features/budgeting/services/budgeting_service.dart
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

// --- DTOs for API Communication ---

class BackendIncomeSummaryItem extends Equatable {
  const BackendIncomeSummaryItem({
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

  final String categoryId;
  final String categoryName;
  final List<BackendSubcategoryIncome> subcategories;
  // Made non-final by removing 'final' to allow modification in repository's offline calculation
  // However, it's better to construct with final value. See repository fix.
  final double categoryTotalAmount; // Keep final, construct properly in repo

  Map<String, dynamic> toJson() => {
    'categoryId': categoryId,
    'categoryName': categoryName,
    'subcategories': subcategories.map((s) => s.toJson()).toList(),
    'categoryTotalAmount': categoryTotalAmount,
  };
  @override
  List<Object?> get props => [
    categoryId,
    categoryName,
    subcategories,
    categoryTotalAmount,
  ];
}

class BackendSubcategoryIncome extends Equatable {
  const BackendSubcategoryIncome({
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
  final String subcategoryId;
  final String subcategoryName;
  final double totalAmount;

  Map<String, dynamic> toJson() => {
    'subcategoryId': subcategoryId,
    'subcategoryName': subcategoryName,
    'totalAmount': totalAmount,
  };
  @override
  List<Object?> get props => [subcategoryId, subcategoryName, totalAmount];
}

class BackendExpenseCategorySuggestion extends Equatable {
  const BackendExpenseCategorySuggestion({
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
  final String id; // categoryId
  final String name; // categoryName
  final double? lowerBound;
  final double? upperBound;
  final List<Map<String, dynamic>> subcategories;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'lowerBound': lowerBound,
    'upperBound': upperBound,
    'subcategories': subcategories,
  };
  @override
  List<Object?> get props => [id, name, subcategories, lowerBound, upperBound];
}

class SaveExpenseAllocationsRequestDto extends Equatable {
  const SaveExpenseAllocationsRequestDto({
    required this.planStartDate,
    required this.planEndDate,
    required this.incomeCalculationStartDate,
    required this.incomeCalculationEndDate,
    required this.totalCalculatedIncome,
    required this.allocations,
    this.budgetPeriodId, // Keep for backward compatibility during DTO parsing if old data exists
  });

  // ***** ADDED fromJson factory *****
  factory SaveExpenseAllocationsRequestDto.fromJson(Map<String, dynamic> json) {
    final allocList = json['allocations'] as List<dynamic>? ?? [];
    return SaveExpenseAllocationsRequestDto(
      planStartDate: DateTime.parse(json['planStartDate'] as String).toLocal(),
      planEndDate: DateTime.parse(json['planEndDate'] as String).toLocal(),
      incomeCalculationStartDate: DateTime.parse(
        json['incomeCalculationStartDate'] as String,
      ).toLocal(),
      incomeCalculationEndDate: DateTime.parse(
        json['incomeCalculationEndDate'] as String,
      ).toLocal(),
      totalCalculatedIncome: (json['totalCalculatedIncome'] as num).toDouble(),
      allocations: allocList
          .map(
            (a) =>
                FrontendAllocationDetailDto.fromJson(a as Map<String, dynamic>),
          )
          .toList(),
      budgetPeriodId:
          json['budgetPeriodId'] as String?, // For parsing old pending data
    );
  }

  final DateTime planStartDate;
  final DateTime planEndDate;
  final DateTime incomeCalculationStartDate;
  final DateTime incomeCalculationEndDate;
  final double totalCalculatedIncome;
  final List<FrontendAllocationDetailDto> allocations;
  final String? budgetPeriodId; // For parsing old pending data, not sent to API

  Map<String, dynamic> toJson() => {
    'planStartDate': planStartDate.toUtc().toIso8601String(),
    'planEndDate': planEndDate.toUtc().toIso8601String(),
    'incomeCalculationStartDate': incomeCalculationStartDate
        .toUtc()
        .toIso8601String(),
    'incomeCalculationEndDate': incomeCalculationEndDate
        .toUtc()
        .toIso8601String(),
    'totalCalculatedIncome': totalCalculatedIncome,
    'allocations': allocations.map((a) => a.toJson()).toList(),
  };

  SaveExpenseAllocationsRequestDto copyWith({
    DateTime? planStartDate,
    DateTime? planEndDate,
    DateTime? incomeCalculationStartDate,
    DateTime? incomeCalculationEndDate,
    double? totalCalculatedIncome,
    List<FrontendAllocationDetailDto>? allocations,
    String? budgetPeriodId, // Added for internal DTO state update
  }) {
    return SaveExpenseAllocationsRequestDto(
      planStartDate: planStartDate ?? this.planStartDate,
      planEndDate: planEndDate ?? this.planEndDate,
      incomeCalculationStartDate:
          incomeCalculationStartDate ?? this.incomeCalculationStartDate,
      incomeCalculationEndDate:
          incomeCalculationEndDate ?? this.incomeCalculationEndDate,
      totalCalculatedIncome:
          totalCalculatedIncome ?? this.totalCalculatedIncome,
      allocations: allocations ?? this.allocations,
      budgetPeriodId: budgetPeriodId ?? this.budgetPeriodId,
    );
  }

  @override
  List<Object?> get props => [
    planStartDate,
    planEndDate,
    incomeCalculationStartDate,
    incomeCalculationEndDate,
    totalCalculatedIncome,
    allocations,
    budgetPeriodId,
  ];
}

class FrontendAllocationDetailDto extends Equatable {
  const FrontendAllocationDetailDto({
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
  @override
  List<Object?> get props => [categoryId, percentage, selectedSubcategoryIds];
}

class FrontendBudgetPlan extends Equatable {
  const FrontendBudgetPlan({
    required this.id,
    required this.userId,
    required this.planStartDate,
    required this.planEndDate,
    required this.incomeCalculationStartDate,
    required this.incomeCalculationEndDate,
    required this.totalCalculatedIncome,
    this.allocations = const [],
    this.isLocal = false,
  });

  factory FrontendBudgetPlan.fromJson(
    Map<String, dynamic> json, {
    bool local = false,
  }) {
    final allocList = json['allocations'] as List<dynamic>? ?? [];
    final rawTotalIncome = json['totalCalculatedIncome'];

    double parsedTotalIncome;
    if (rawTotalIncome is String) {
      parsedTotalIncome = double.tryParse(rawTotalIncome) ?? 0.0;
    } else if (rawTotalIncome is num) {
      parsedTotalIncome = rawTotalIncome.toDouble();
    } else {
      parsedTotalIncome = 0.0; // Default if null or unexpected type
    }

    return FrontendBudgetPlan(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? '',
      planStartDate: DateTime.parse(json['planStartDate'] as String).toLocal(),
      planEndDate: DateTime.parse(json['planEndDate'] as String).toLocal(),
      incomeCalculationStartDate: DateTime.parse(
        json['incomeCalculationStartDate'] as String,
      ).toLocal(),
      incomeCalculationEndDate: DateTime.parse(
        json['incomeCalculationEndDate'] as String,
      ).toLocal(),
      totalCalculatedIncome: parsedTotalIncome, // Use the robustly parsed value
      allocations: allocList
          .map(
            (a) => FrontendBudgetAllocation.fromJson(a as Map<String, dynamic>),
          )
          .toList(),
      isLocal: local || (json['isLocal'] as bool? ?? false),
    );
  }

  final String id;
  final String userId;
  final DateTime planStartDate;
  final DateTime planEndDate;
  final DateTime incomeCalculationStartDate;
  final DateTime incomeCalculationEndDate;
  final double totalCalculatedIncome;
  final List<FrontendBudgetAllocation> allocations;
  final bool isLocal;

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'planStartDate': planStartDate.toUtc().toIso8601String(),
    'planEndDate': planEndDate.toUtc().toIso8601String(),
    'incomeCalculationStartDate': incomeCalculationStartDate
        .toUtc()
        .toIso8601String(),
    'incomeCalculationEndDate': incomeCalculationEndDate
        .toUtc()
        .toIso8601String(),
    'totalCalculatedIncome': totalCalculatedIncome,
    'allocations': allocations.map((a) => a.toJson()).toList(),
    'isLocal': isLocal,
  };

  FrontendBudgetPlan copyWith({
    String? id,
    String? userId,
    DateTime? planStartDate,
    DateTime? planEndDate,
    DateTime? incomeCalculationStartDate,
    DateTime? incomeCalculationEndDate,
    double? totalCalculatedIncome,
    List<FrontendBudgetAllocation>? allocations,
    bool? isLocal,
  }) {
    return FrontendBudgetPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      planStartDate: planStartDate ?? this.planStartDate,
      planEndDate: planEndDate ?? this.planEndDate,
      incomeCalculationStartDate:
          incomeCalculationStartDate ?? this.incomeCalculationStartDate,
      incomeCalculationEndDate:
          incomeCalculationEndDate ?? this.incomeCalculationEndDate,
      totalCalculatedIncome:
          totalCalculatedIncome ?? this.totalCalculatedIncome,
      allocations: allocations ?? this.allocations,
      isLocal: isLocal ?? this.isLocal,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    planStartDate,
    planEndDate,
    incomeCalculationStartDate,
    incomeCalculationEndDate,
    totalCalculatedIncome,
    allocations,
    isLocal,
  ];
}

class FrontendBudgetAllocation extends Equatable {
  const FrontendBudgetAllocation({
    required this.id,
    required this.budgetPlanId,
    required this.categoryId,
    required this.categoryName,
    required this.subcategoryId,
    required this.subcategoryName,
    required this.percentage,
    required this.amount,
    this.isLocal = false,
  });

  factory FrontendBudgetAllocation.fromJson(
    Map<String, dynamic> json, {
    bool local = false,
  }) {
    double parseNumeric(dynamic value) {
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      } else if (value is num) {
        return value.toDouble();
      }
      return 0;
    }

    return FrontendBudgetAllocation(
      id: json['id'] as String,
      budgetPlanId: json['budgetPlanId'] as String? ?? '',
      categoryId: json['categoryId'] as String,
      categoryName:
          json['category']?['name'] as String? ??
          json['categoryName'] as String? ??
          'Unknown Category',
      subcategoryId: json['subcategoryId'] as String,
      subcategoryName:
          json['subcategory']?['name'] as String? ??
          json['subcategoryName'] as String? ??
          'Unknown Subcategory',
      percentage: parseNumeric(json['percentage']), // Use robust parsing
      amount: parseNumeric(json['amount']), // Use robust parsing
      isLocal: local || (json['isLocal'] as bool? ?? false),
    );
  }

  final String id;
  final String budgetPlanId;
  final String categoryId;
  final String categoryName;
  final String subcategoryId;
  final String subcategoryName;
  final double percentage;
  final double amount;
  final bool isLocal;

  Map<String, dynamic> toJson() => {
    'id': id,
    'budgetPlanId': budgetPlanId,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'subcategoryId': subcategoryId,
    'subcategoryName': subcategoryName,
    'percentage': percentage,
    'amount': amount,
    'isLocal': isLocal,
  };

  FrontendBudgetAllocation copyWith({
    String? id,
    String? budgetPlanId,
    String? categoryId,
    String? categoryName,
    String? subcategoryId,
    String? subcategoryName,
    double? percentage,
    double? amount,
    bool? isLocal,
  }) {
    return FrontendBudgetAllocation(
      id: id ?? this.id,
      budgetPlanId: budgetPlanId ?? this.budgetPlanId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      subcategoryName: subcategoryName ?? this.subcategoryName,
      percentage: percentage ?? this.percentage,
      amount: amount ?? this.amount,
      isLocal: isLocal ?? this.isLocal,
    );
  }

  @override
  List<Object?> get props => [
    id,
    budgetPlanId,
    categoryId,
    categoryName,
    subcategoryId,
    subcategoryName,
    percentage,
    amount,
    isLocal,
  ];
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

  Future<List<BackendIncomeSummaryItem>> fetchSummarizedIncomeForDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    const endpoint = '/budgeting/income-summary';
    final queryParams = {
      'startDate': startDate.toUtc().toIso8601String(),
      'endDate': endDate.toUtc().toIso8601String(),
    };
    debugPrint('[BudgetingService-DIO] GET $endpoint with query: $queryParams');
    try {
      final response = await _dio.get<dynamic>(
        endpoint,
        queryParameters: queryParams,
      );
      if (response.statusCode == 200 &&
          response.data is Map<String, dynamic> &&
          response.data['data'] is List) {
        final dataList = response.data['data'] as List<dynamic>;
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
      debugPrint(
        '[BudgetingService-DIO] DioException fetchSummarizedIncome: ${e.response?.data ?? e.message}',
      );
      throw BudgetingApiException(
        e.response?.data?['message']?.toString() ??
            e.message ??
            'Network error fetching income summary.',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      debugPrint(
        '[BudgetingService-DIO] Unexpected error fetchSummarizedIncome: $e',
      );
      if (e is BudgetingApiException) rethrow;
      throw BudgetingApiException(
        'Unexpected error fetching income summary: $e',
      );
    }
  }

  Future<List<BackendExpenseCategorySuggestion>>
  fetchExpenseCategorySuggestions() async {
    const endpoint = '/budgeting/expense-category-suggestions';
    debugPrint('[BudgetingService-DIO] GET $endpoint');
    try {
      final response = await _dio.get<dynamic>(endpoint);
      if (response.statusCode == 200 &&
          response.data is Map<String, dynamic> &&
          response.data['data'] is List) {
        final dataList = response.data['data'] as List<dynamic>;
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
      debugPrint(
        '[BudgetingService-DIO] DioException fetchExpenseSuggestions: ${e.response?.data ?? e.message}',
      );
      throw BudgetingApiException(
        e.response?.data?['message']?.toString() ??
            e.message ??
            'Network error fetching expense suggestions.',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      debugPrint(
        '[BudgetingService-DIO] Unexpected error fetchExpenseSuggestions: $e',
      );
      if (e is BudgetingApiException) rethrow;
      throw BudgetingApiException(
        'Unexpected error fetching expense suggestions: $e',
      );
    }
  }

  Future<FrontendBudgetPlan> saveExpenseAllocations(
    SaveExpenseAllocationsRequestDto dto,
  ) async {
    const endpoint = '/budgeting/expense-allocations';
    debugPrint(
      '[BudgetingService-DIO] POST $endpoint with body: ${dto.toJson()}',
    );
    try {
      final response = await _dio.post<dynamic>(endpoint, data: dto.toJson());
      if ((response.statusCode == 201 || response.statusCode == 200) &&
          response.data is Map<String, dynamic> &&
          response.data['data'] is Map<String, dynamic>) {
        // Ensure 'data' holds the BudgetPlan object
        return FrontendBudgetPlan.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
      } else {
        throw BudgetingApiException(
          response.data?['message']?.toString() ??
              'Failed to save expense allocations.',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      debugPrint(
        '[BudgetingService-DIO] DioException saveExpenseAllocations: ${e.response?.data ?? e.message}',
      );
      throw BudgetingApiException(
        e.response?.data?['message']?.toString() ??
            e.message ??
            'Network error saving expense allocations.',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      debugPrint(
        '[BudgetingService-DIO] Unexpected error saveExpenseAllocations: $e',
      );
      if (e is BudgetingApiException) rethrow;
      throw BudgetingApiException(
        'Unexpected error saving expense allocations: $e',
      );
    }
  }

  // Fetches allocations for a specific BudgetPlan ID
  // Backend route: GET /budgeting/plans/:budgetPlanId/allocations
  // Backend response: { success: true, data: ExpenseAllocation[] }
  Future<List<FrontendBudgetAllocation>> getBudgetAllocationsForPlan(
    String budgetPlanId,
  ) async {
    final endpoint = '/budgeting/plans/$budgetPlanId/allocations';
    debugPrint('[BudgetingService-DIO] GET $endpoint');
    try {
      final response = await _dio.get<dynamic>(endpoint);
      if (response.statusCode == 200 &&
          response.data is Map<String, dynamic> &&
          response.data['data'] is List) {
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
              'Failed to fetch budget allocations for plan.',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      debugPrint(
        '[BudgetingService-DIO] DioException getBudgetAllocationsForPlan: ${e.response?.data ?? e.message}',
      );
      throw BudgetingApiException(
        e.response?.data?['message']?.toString() ??
            e.message ??
            'Network error fetching allocations for plan.',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      debugPrint(
        '[BudgetingService-DIO] Unexpected error getBudgetAllocationsForPlan: $e',
      );
      if (e is BudgetingApiException) rethrow;
      throw BudgetingApiException(
        'Unexpected error fetching allocations for plan: $e',
      );
    }
  }

  // Method to fetch a BudgetPlan by its ID
  // Backend route: GET /budgeting/plans/:budgetPlanId
  // Backend response: { success: true, data: PopulatedBudgetPlan }
  Future<FrontendBudgetPlan> fetchBudgetPlanById(String budgetPlanId) async {
    final endpoint = '/budgeting/plans/$budgetPlanId';
    debugPrint('[BudgetingService-DIO] GET $endpoint');
    try {
      final response = await _dio.get<dynamic>(endpoint);
      if (response.statusCode == 200 &&
          response.data is Map<String, dynamic> &&
          response.data['data'] is Map<String, dynamic>) {
        return FrontendBudgetPlan.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
      } else {
        throw BudgetingApiException(
          response.data?['message']?.toString() ??
              'Failed to fetch budget plan.',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      debugPrint(
        '[BudgetingService-DIO] DioException fetchBudgetPlanById: ${e.response?.data ?? e.message}',
      );
      throw BudgetingApiException(
        e.response?.data?['message']?.toString() ??
            e.message ??
            'Network error fetching budget plan.',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      debugPrint(
        '[BudgetingService-DIO] Unexpected error fetchBudgetPlanById: $e',
      );
      if (e is BudgetingApiException) rethrow;
      throw BudgetingApiException('Unexpected error fetching budget plan: $e');
    }
  }

  Future<List<FrontendBudgetPlan>> fetchBudgetPlansForUser(
    String userId, { // userId might not be needed if API infers from token
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    const endpoint = '/budgeting/plans'; // Endpoint to get list of plans
    final queryParams = <String, String>{};
    // Backend might not use userId from query if it uses authenticated user's ID
    // queryParams['userId'] = userId;
    if (startDate != null) {
      queryParams['startDate'] = startDate.toUtc().toIso8601String();
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toUtc().toIso8601String();
    }

    debugPrint('[BudgetingService-DIO] GET $endpoint with query: $queryParams');
    try {
      final response = await _dio.get<dynamic>(
        endpoint,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      if (response.statusCode == 200 &&
          response.data is Map<String, dynamic> &&
          response.data['data'] is List) {
        final dataList = response.data['data'] as List<dynamic>;
        return dataList
            .map(
              (item) =>
                  FrontendBudgetPlan.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw BudgetingApiException(
          response.data?['message']?.toString() ??
              'Failed to fetch user budget plans.',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      debugPrint(
        '[BudgetingService-DIO] DioException fetchBudgetPlansForUser: ${e.response?.data ?? e.message}',
      );
      throw BudgetingApiException(
        e.response?.data?['message']?.toString() ??
            e.message ??
            'Network error fetching user budget plans.',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      debugPrint(
        '[BudgetingService-DIO] Unexpected error fetchBudgetPlansForUser: $e',
      );
      if (e is BudgetingApiException) rethrow;
      throw BudgetingApiException(
        'Unexpected error fetching user budget plans: $e',
      );
    }
  }
}
