// lib/features/evaluation/services/evaluation_service.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ta_client/features/evaluation/models/evaluation.dart';
// History model is for the repository to construct
// import 'package:ta_client/features/evaluation/models/history.dart'; // Not used directly by service response

class EvaluationApiException implements Exception {
  EvaluationApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => 'EvaluationApiException: $message (Status: $statusCode)';
}

class EvaluationService {
  EvaluationService({required Dio dio}) : _dio = dio;
  final Dio _dio;

  Future<List<Evaluation>> calculateAndFetchEvaluationsForPeriod({
    required String periodId,
  }) async {
    if (periodId.isEmpty) {
      throw ArgumentError(
        'Period ID is strictly required for calculateAndFetchEvaluationsForPeriod.',
      );
    }
    const endpoint = '/transaction-evaluations/calculate';
    final requestBody = {'periodId': periodId};

    debugPrint(
      '[EvaluationService-DIO] REQUEST: POST $endpoint with body: $requestBody',
    );
    try {
      final response = await _dio.post<dynamic>(endpoint, data: requestBody);
      if (response.statusCode == 200 &&
          response.data is Map<String, dynamic> &&
          response.data['data'] is List && // Expecting 'data' key for the list
          response.data['success'] == true) {
        final resultsData = response.data['data'] as List<dynamic>;
        return resultsData.map((data) {
          final item = data as Map<String, dynamic>;
          // This mapping should align with SingleRatioCalculationResultDto from backend
          return Evaluation(
            id:
                item['ratioId']
                    as String, // Using ratioId as the primary ID for frontend Evaluation model
            title: item['ratioTitle'] as String,
            yourValue: (item['value'] as num).toDouble(),
            status: EvaluationStatusModel.values.firstWhere(
              (e) =>
                  e.name.toLowerCase() ==
                  (item['status'] as String).toLowerCase(),
              orElse: () => EvaluationStatusModel.incomplete,
            ),
            idealText: item['idealRangeDisplay'] as String?,
            calculatedAt:
                DateTime.now(), // Backend currently doesn't send calculatedAt in this specific DTO
            backendRatioCode: item['ratioCode'] as String,
            // backendEvaluationResultId and periodId will be set if this Evaluation obj is from full EvaluationResult
          );
        }).toList();
      } else {
        throw EvaluationApiException(
          response.data?['message']?.toString() ??
              'Failed to calculate/fetch evaluations.',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      debugPrint(
        '[EvaluationService-DIO] DioException calculating evaluations: ${e.response?.data ?? e.message}',
      );
      throw EvaluationApiException(
        e.response?.data?['message']?.toString() ??
            e.message ??
            'Network error processing evaluations.',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      debugPrint(
        '[EvaluationService-DIO] Unexpected error calculating evaluations: $e',
      );
      if (e is EvaluationApiException) rethrow;
      throw EvaluationApiException(
        'An unexpected error occurred: ${e}',
      );
    }
  }

  Future<Evaluation> fetchEvaluationDetail(String evaluationResultDbId) async {
    final endpoint = '/transaction-evaluations/$evaluationResultDbId/detail';
    debugPrint('[EvaluationService-DIO] GET $endpoint');
    try {
      final response = await _dio.get<dynamic>(endpoint);
      if (response.statusCode == 200 &&
          response.data is Map<String, dynamic> &&
          response.data['data']
              is Map<String, dynamic> && // Check for nested 'data'
          response.data['success'] == true) {
        // Evaluation.fromJson needs to correctly parse the backend's EvaluationResultDetailDto
        return Evaluation.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
      } else {
        throw EvaluationApiException(
          response.data?['message']?.toString() ??
              'Failed to fetch evaluation detail.',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      debugPrint(
        '[EvaluationService-DIO] DioException fetching detail: ${e.response?.data ?? e.message}',
      );
      throw EvaluationApiException(
        e.response?.data?['message']?.toString() ??
            e.message ??
            'Network error fetching detail.',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      debugPrint(
        '[EvaluationService-DIO] Unexpected error fetching detail: $e',
      );
      if (e is EvaluationApiException) rethrow;
      throw EvaluationApiException(
        'An unexpected error occurred: ${e}',
      );
    }
  }

  // Returns raw Evaluation objects (mapped from PopulatedEvaluationResult on backend)
  Future<List<Evaluation>> fetchRawEvaluationResultsForHistory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    const endpoint = '/transaction-evaluations/history';
    final queryParams = <String, String>{};
    if (startDate != null) {
      queryParams['startDate'] = startDate.toUtc().toIso8601String();
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toUtc().toIso8601String();
    }

    debugPrint(
      '[EvaluationService-DIO] GET $endpoint for raw history with params: $queryParams',
    );
    try {
      final response = await _dio.get<dynamic>(
        endpoint,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      if (response.statusCode == 200 &&
          response.data is Map<String, dynamic> &&
          response.data['data'] is List && // Check for nested 'data'
          response.data['success'] == true) {
        final dataList = response.data['data'] as List<dynamic>;
        return dataList
            .map((item) => Evaluation.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw EvaluationApiException(
          response.data?['message']?.toString() ??
              'Failed to fetch raw evaluation results.',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      debugPrint(
        '[EvaluationService-DIO] DioException fetching raw history: ${e.response?.data ?? e.message}',
      );
      throw EvaluationApiException(
        e.response?.data?['message']?.toString() ??
            e.message ??
            'Network error fetching raw history.',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      debugPrint(
        '[EvaluationService-DIO] Unexpected error fetching raw history: $e',
      );
      if (e is EvaluationApiException) rethrow;
      throw EvaluationApiException(
        'An unexpected error occurred: ${e}',
      );
    }
  }
}
