// lib/features/budgeting/services/period_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ta_client/core/utils/authenticated_client.dart';
import 'package:ta_client/features/budgeting/models/period.dart'; // Your FrontendPeriod model

class PeriodApiException implements Exception {
  PeriodApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => 'PeriodApiException: $message (Status: $statusCode)';
}

class PeriodService {
  PeriodService({required String baseUrl})
    : _baseUrl = baseUrl,
      _client = AuthenticatedClient(http.Client());

  final String _baseUrl;
  final http.Client _client;

  Future<FrontendPeriod> createPeriod({
    required DateTime startDate,
    required DateTime endDate,
    required String periodType,
    String? description,
  }) async {
    final url = Uri.parse('$_baseUrl/periods'); // Assuming POST /api/v1/periods
    final body = {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'periodType': periodType,
      if (description != null) 'description': description,
    };
    debugPrint('[PeriodService-API] POST $url with body: $body');
    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 201) {
      return FrontendPeriod.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    } else {
      final errorBody = json.decode(response.body);
      throw PeriodApiException(
        (errorBody['message'] as String?) ?? 'Failed to create period',
        statusCode: response.statusCode,
      );
    }
  }

  Future<List<FrontendPeriod>> fetchPeriods({String? periodType}) async {
    final queryParams = <String, String>{};
    if (periodType != null) queryParams['periodType'] = periodType;

    final url = Uri.parse(
      '$_baseUrl/periods',
    ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
    debugPrint('[PeriodService-API] GET $url');
    final response = await _client.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List<dynamic>;
      return data
          .map((item) => FrontendPeriod.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      final errorBody = json.decode(response.body);
      throw PeriodApiException(
        (errorBody['message'] as String?) ?? 'Failed to fetch periods',
        statusCode: response.statusCode,
      );
    }
  }

  Future<FrontendPeriod> fetchPeriodById(String periodId) async {
    final url = Uri.parse('$_baseUrl/periods/$periodId');
    debugPrint('[PeriodService-API] GET $url');
    final response = await _client.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return FrontendPeriod.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    } else {
      final errorBody = json.decode(response.body);
      throw PeriodApiException(
        (errorBody['message'] as String?) ?? 'Failed to fetch period $periodId',
        statusCode: response.statusCode,
      );
    }
  }

  // Add updatePeriod and deletePeriod if needed
}
