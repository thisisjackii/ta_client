// lib/features/evaluation/services/evaluation_service.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ta_client/features/evaluation/models/evaluation.dart';
// History model is for the repository to construct, service fetches raw Evaluation data
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

  // This method now takes startDate and endDate directly
  Future<List<Evaluation>> calculateAndFetchEvaluationsForDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    const endpoint = '/evaluations/calculate'; // Corrected backend path
    final requestBody = {
      'startDate': startDate.toUtc().toIso8601String(),
      'endDate': endDate.toUtc().toIso8601String(),
    };

    debugPrint(
      '[EvaluationService-DIO] REQUEST: POST $endpoint with body: $requestBody',
    );
    try {
      final response = await _dio.post<dynamic>(endpoint, data: requestBody);
      // Backend: { success: true, message: "...", data: SingleRatioCalculationResultDto[] }
      if (response.statusCode == 200 &&
          response.data is Map<String, dynamic> &&
          response.data['data'] is List &&
          response.data['success'] == true) {
        final resultsData = response.data['data'] as List<dynamic>;
        return resultsData.map((data) {
          final item = data as Map<String, dynamic>;
          final statusString =
              (item['status'] as String?)?.toUpperCase() ?? 'INCOMPLETE';
          final evalStatus = EvaluationStatusModel.values.firstWhere(
            (e) => e.name.toUpperCase() == statusString,
            orElse: () => EvaluationStatusModel.incomplete,
          );

          return Evaluation(
            id: item['ratioId'] as String,
            title: item['ratioTitle'] as String,
            yourValue: (item['value'] as num).toDouble(),
            isIdeal:
                evalStatus ==
                EvaluationStatusModel.ideal, // *** CORRECTED DERIVATION ***
            status: evalStatus,
            idealText: item['idealRangeDisplay'] as String?,
            calculatedAt:
                DateTime.now(), // This specific DTO doesn't send calculatedAt
            backendRatioCode: item['ratioCode'] as String,
            // For this response, startDate & endDate of the evaluation are known from the request
            startDate: startDate,
            endDate: endDate,
          );
        }).toList();
      } else {
        throw EvaluationApiException(
          response.data?['message']?.toString() ??
              'Failed to calculate evaluations.',
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
        'An unexpected error occurred during evaluation: $e',
      );
    }
  }

  Future<Evaluation> fetchEvaluationDetail(String evaluationResultDbId) async {
    final endpoint = '/evaluations/$evaluationResultDbId/detail';
    debugPrint('[EvaluationService-DIO] GET $endpoint');
    try {
      final response = await _dio.get<dynamic>(endpoint);
      if (response.statusCode == 200 &&
          response.data is Map<String, dynamic> &&
          response.data['data'] is Map<String, dynamic> &&
          response.data['success'] == true) {
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
        'An unexpected error occurred fetching detail: $e',
      );
    }
  }

  Future<List<Evaluation>> fetchRawEvaluationResultsForHistory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    const endpoint = '/evaluations/history';
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
          response.data['data'] is List &&
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
        'An unexpected error occurred fetching raw history: $e',
      );
    }
  }
}
