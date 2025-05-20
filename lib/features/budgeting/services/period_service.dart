// lib/features/budgeting/services/period_service.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ta_client/features/budgeting/models/period.dart'; // Your FrontendPeriod model

class PeriodApiException implements Exception {
  PeriodApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => 'PeriodApiException: $message (Status: $statusCode)';
}

class PeriodService {
  PeriodService({required Dio dio}) : _dio = dio;
  final Dio _dio;

  Future<FrontendPeriod> createPeriod({
    required DateTime startDate,
    required DateTime endDate,
    required String periodType,
    String? description,
  }) async {
    const endpoint = '/periods';
    final requestBody = {
      'startDate': startDate.toUtc().toIso8601String(),
      'endDate': endDate.toUtc().toIso8601String(),
      'periodType': periodType,
      if (description != null) 'description': description,
    };
    debugPrint('[PeriodService-DIO] POST $endpoint with body: $requestBody');
    try {
      final response = await _dio.post<dynamic>(endpoint, data: requestBody);

      // Backend returns { success: true, data: <period_object> }
      if (response.statusCode == 201 &&
          response.data is Map<String, dynamic> &&
          response.data['data'] is Map<String, dynamic>) {
        // ***** CORRECTED PARSING: Access nested 'data' key *****
        return FrontendPeriod.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
      } else {
        String errorMessage = 'Failed to create period on server.';
        if (response.data is Map<String, dynamic> &&
            response.data['message'] != null) {
          errorMessage = response.data['message'].toString();
        } else if (response.data != null && response.statusCode != 201) {
          errorMessage =
              'Server error: ${response.statusCode} - ${response.data.toString()}';
        }
        throw PeriodApiException(errorMessage, statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      debugPrint(
        '[PeriodService-DIO] DioException creating period: ${e.response?.data ?? e.message}',
      );
      throw PeriodApiException(
        e.response?.data?['message']?.toString() ??
            e.message ??
            'Network error creating period.',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      debugPrint('[PeriodService-DIO] Unexpected error creating period: $e');
      if (e is PeriodApiException) rethrow;
      throw PeriodApiException(
        'An unexpected error occurred while creating period: ${e.toString()}',
      );
    }
  }

  Future<List<FrontendPeriod>> fetchPeriods({String? periodType}) async {
    const endpoint = '/periods';
    final queryParams = <String, String>{};
    if (periodType != null)
      queryParams['type'] =
          periodType; // Backend route uses 'type' for query param

    debugPrint('[PeriodService-DIO] GET $endpoint with params: $queryParams');
    try {
      final response = await _dio.get<dynamic>(
        endpoint,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      // Backend returns { success: true, data: periods[] }
      if (response.statusCode == 200 &&
          response.data is Map<String, dynamic> &&
          response.data['data'] is List) {
        // ***** CORRECTED CHECK *****
        final dataList = response.data['data'] as List<dynamic>;
        return dataList
            .map(
              (item) => FrontendPeriod.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      } else {
        // This case handles if backend returns something unexpected even with 200 OK
        // or if success flag is false but still 200 OK (less common for GET lists).
        throw PeriodApiException(
          response.data?['message']?.toString() ??
              'Failed to fetch periods from server (unexpected format).',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      debugPrint(
        '[PeriodService-DIO] DioException fetching periods: ${e.response?.data ?? e.message}',
      );
      throw PeriodApiException(
        e.response?.data?['message']?.toString() ??
            e.message ??
            'Network error fetching periods.',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      debugPrint('[PeriodService-DIO] Unexpected error fetching periods: $e');
      if (e is PeriodApiException) rethrow;
      throw PeriodApiException(
        'An unexpected error occurred while fetching periods: ${e.toString()}',
      );
    }
  }

  Future<FrontendPeriod> fetchPeriodById(String periodId) async {
    final endpoint = '/periods/$periodId';
    debugPrint('[PeriodService-DIO] GET $endpoint');
    try {
      final response = await _dio.get<dynamic>(endpoint);
      // Backend returns { success: true, data: period }
      if (response.statusCode == 200 &&
          response.data is Map<String, dynamic> &&
          response.data['data'] is Map<String, dynamic>) {
        // ***** CORRECTED CHECK *****
        return FrontendPeriod.fromJson(
          response.data['data'] as Map<String, dynamic>,
        ); // ***** CORRECTED PARSING *****
      } else {
        throw PeriodApiException(
          response.data?['message']?.toString() ??
              'Failed to fetch period $periodId from server.',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      debugPrint(
        '[PeriodService-DIO] DioException fetching period $periodId: ${e.response?.data ?? e.message}',
      );
      throw PeriodApiException(
        e.response?.data?['message']?.toString() ??
            e.message ??
            'Network error fetching period $periodId.',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      debugPrint(
        '[PeriodService-DIO] Unexpected error fetching period $periodId: $e',
      );
      if (e is PeriodApiException) rethrow;
      throw PeriodApiException(
        'An unexpected error occurred while fetching period $periodId: ${e.toString()}',
      );
    }
  }

  // You would also need updatePeriod and deletePeriod methods here if your app supports those actions.
  // Example for updatePeriod:
  Future<FrontendPeriod> updatePeriod(
    String periodId,
    FrontendPeriod periodDataToUpdate,
  ) async {
    final endpoint = '/periods/$periodId';
    // Use toUpdateApiJson if it only sends fields that can be updated
    final requestBody = periodDataToUpdate.toUpdateApiJson();
    debugPrint('[PeriodService-DIO] PUT $endpoint with body: $requestBody');
    try {
      final response = await _dio.put<dynamic>(endpoint, data: requestBody);
      // Backend: { success: true, data: updatedPeriod }
      if (response.statusCode == 200 &&
          response.data is Map<String, dynamic> &&
          response.data['data'] is Map<String, dynamic>) {
        return FrontendPeriod.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
      } else {
        throw PeriodApiException(
          response.data?['message']?.toString() ??
              'Failed to update period on server.',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      debugPrint(
        '[PeriodService-DIO] DioException updating period: ${e.response?.data ?? e.message}',
      );
      throw PeriodApiException(
        e.response?.data?['message']?.toString() ??
            e.message ??
            'Network error updating period.',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      debugPrint('[PeriodService-DIO] Unexpected error updating period: $e');
      if (e is PeriodApiException) rethrow;
      throw PeriodApiException(
        'An unexpected error occurred while updating period: ${e.toString()}',
      );
    }
  }

  Future<void> deletePeriod(String periodId) async {
    final endpoint = '/periods/$periodId';
    debugPrint('[PeriodService-DIO] DELETE $endpoint');
    try {
      final response = await _dio.delete<dynamic>(endpoint);
      if (response.statusCode == 204) {
        // HTTP 204 No Content for successful delete
        return;
      } else {
        // This path might not be hit if Dio throws for non-204.
        throw PeriodApiException(
          response.data?['message']?.toString() ??
              'Failed to delete period on server.',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      debugPrint(
        '[PeriodService-DIO] DioException deleting period: ${e.response?.data ?? e.message}',
      );
      throw PeriodApiException(
        e.response?.data?['message']?.toString() ??
            e.message ??
            'Network error deleting period.',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      debugPrint('[PeriodService-DIO] Unexpected error deleting period: $e');
      if (e is PeriodApiException) rethrow;
      throw PeriodApiException(
        'An unexpected error occurred while deleting period: ${e.toString()}',
      );
    }
  }
}
