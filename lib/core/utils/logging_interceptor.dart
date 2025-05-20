// lib/core/utils/logging_interceptor.dart
import 'dart:convert'; // For jsonEncode

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('DIO REQUEST[${options.method}] => PATH: ${options.uri}');
    debugPrint('DIO REQUEST headers: ${options.headers}');
    if (options.data != null) {
      try {
        final requestBody = options.data is Map || options.data is List
            ? jsonEncode(options.data) // Pretty print JSON if possible
            : options.data.toString();
        debugPrint(
          'DIO REQUEST body: ${requestBody.substring(0, requestBody.length > 500 ? 500 : requestBody.length)} (may be truncated)',
        );
      } catch (e) {
        debugPrint(
          'DIO REQUEST body: (Could not decode/encode for logging: ${options.data.runtimeType})',
        );
      }
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    debugPrint(
      'DIO RESPONSE[${response.statusCode}] (${response.statusMessage}) => PATH: ${response.requestOptions.uri}',
    );
    debugPrint('DIO RESPONSE headers: ${response.headers}'); // Can be verbose
    try {
      final responseBody =
          response.data is Map ||
              response.data is List ||
              response.data is String
          ? jsonEncode(
              response.data,
            ) // Pretty print if JSON structure or already string
          : response.data.toString();
      debugPrint(
        'DIO RESPONSE data: ${responseBody.substring(0, responseBody.length > 1000 ? 1000 : responseBody.length)} (may be truncated)',
      );
    } catch (e) {
      debugPrint(
        'DIO RESPONSE data: (Could not decode/encode for logging: ${response.data.runtimeType})',
      );
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint(
      'DIO ERROR[${err.response?.statusCode ?? 'N/A'}] => PATH: ${err.requestOptions.uri}',
    );
    if (err.response != null) {
      debugPrint('DIO ERROR response data: ${err.response?.data}');
    } else {
      // This is likely a connection error, timeout, etc.
      debugPrint('DIO ERROR message: ${err.message}');
      debugPrint('DIO ERROR type: ${err.type}');
    }
    super.onError(err, handler);
  }
}
