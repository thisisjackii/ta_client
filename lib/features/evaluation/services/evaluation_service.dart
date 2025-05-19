// lib/features/evaluation/services/evaluation_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ta_client/core/utils/authenticated_client.dart';
import 'package:ta_client/features/evaluation/models/evaluation.dart';
import 'package:ta_client/features/evaluation/models/history.dart'; // Assuming this is what backend /history returns

// Exception for API communication issues
class EvaluationApiException implements Exception {
  EvaluationApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => 'EvaluationApiException: $message (Status: $statusCode)';
}

class EvaluationService {
  EvaluationService({required String baseUrl})
    : _baseUrl = baseUrl,
      _client = AuthenticatedClient(http.Client());

  final String _baseUrl;
  final http.Client _client;

  // Calls backend to calculate (or retrieve already calculated) evaluations for a period
  Future<List<Evaluation>> calculateAndFetchEvaluationsForPeriod({
    String? periodId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (periodId == null && (startDate == null || endDate == null)) {
      throw ArgumentError(
        'Either periodId or both startDate and endDate must be provided.',
      );
    }
    final url = Uri.parse('$_baseUrl/evaluations/calculate'); // POST endpoint
    final body = <String, String>{};
    if (periodId != null) {
      body['periodId'] = periodId;
    } else {
      body['startDate'] = startDate!.toIso8601String();
      body['endDate'] = endDate!.toIso8601String();
    }

    debugPrint(
      '[EvaluationService-API] POST /evaluations/calculate with body: $body',
    );
    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final decodedResponse =
          json.decode(response.body) as Map<String, dynamic>;
      final resultsData = decodedResponse['results'] as List<dynamic>? ?? [];
      return resultsData.map((data) {
        final item = data as Map<String, dynamic>;
        return Evaluation(
          // Maps backend's SingleRatioCalculationResult
          id: item['ratioId'] as String,
          backendRatioCode: item['ratioCode'] as String?,
          title: item['ratioTitle'] as String,
          yourValue: (item['value'] as num).toDouble(),
          isIdeal: (item['status'] as String?)?.toUpperCase() == 'IDEAL',
          // idealText should come from the Ratio definition, backend /calculate might need to include it
          // or client fetches Ratio definitions separately and merges.
          idealText:
              item['idealRangeText']
                  as String?, // Assuming backend now adds this
        );
      }).toList();
    } else {
      final errorBody = json.decode(response.body);
      throw EvaluationApiException(
        (errorBody['message'] is String
                ? errorBody['message']
                : 'Failed to calculate/fetch evaluations')
            as String,
        statusCode: response.statusCode,
      );
    }
  }

  Future<Evaluation> fetchEvaluationDetail(String evaluationResultDbId) async {
    final url = Uri.parse('$_baseUrl/evaluations/$evaluationResultDbId/detail');
    debugPrint(
      '[EvaluationService-API] GET /evaluations/$evaluationResultDbId/detail',
    );
    final response = await _client.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final ratioData = data['ratio'] as Map<String, dynamic>?;
      final breakdownData = data['breakdownComponents'] as List<dynamic>?;
      return Evaluation(
        id: data['ratioId'] as String,
        backendEvaluationResultId: data['id'] as String?,
        backendRatioCode: ratioData?['code'] as String?,
        title: ratioData?['title'] as String? ?? 'Unknown Ratio',
        yourValue: (data['value'] as num).toDouble(),
        isIdeal: (data['status'] as String?)?.toUpperCase() == 'IDEAL',
        idealText: ratioData?['idealRangeDisplay'] as String?,
        breakdown: breakdownData?.map((comp) {
          final component = comp as Map<String, dynamic>;
          return ConceptualComponentValue(
            name: component['name'] as String,
            value: (component['value'] as num).toDouble(),
          );
        }).toList(),
      );
    } else {
      final errorBody = json.decode(response.body);
      throw EvaluationApiException(
        (errorBody['message'] is String
                ? errorBody['message']
                : 'Failed to fetch evaluation detail')
            as String,
        statusCode: response.statusCode,
      );
    }
  }

  // Assuming backend /history returns the summarized History model structure directly
  Future<List<History>> fetchEvaluationHistory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, String>{};
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

    final url = Uri.parse(
      '$_baseUrl/evaluations/history',
    ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
    debugPrint(
      '[EvaluationService-API] GET /evaluations/history with params: $queryParams',
    );
    final response = await _client.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List<dynamic>;
      return data
          .map((item) => History.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      final errorBody = json.decode(response.body);
      throw EvaluationApiException(
        (errorBody['message'] is String
                ? errorBody['message']
                : 'Failed to fetch evaluation history')
            as String,
        statusCode: response.statusCode,
      );
    }
  }
}
