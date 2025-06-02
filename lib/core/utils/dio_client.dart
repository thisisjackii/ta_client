// lib/core/network/dio_client.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ta_client/core/services/hive_service.dart'; // Import HiveService
import 'package:ta_client/core/services/service_locator.dart';
import 'package:ta_client/core/state/auth_state.dart';
import 'package:ta_client/core/utils/logging_interceptor.dart';

Dio createDioInstance() {
  final baseUrl = dotenv.env['BASE_URL'] ?? 'http:/localhost:4000/api/v1/';
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(milliseconds: 15000), // 15 seconds
      receiveTimeout: const Duration(milliseconds: 15000), // 15 seconds
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Logging Interceptor (for debugging)
  if (kDebugMode) {
    // Only add logging in debug mode
    dio.interceptors.add(LoggingInterceptor());
  }

  // Authentication Interceptor
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Make onRequest async
        final hiveService = sl<HiveService>(); // Get HiveService
        final token = await hiveService
            .getAuthToken(); // Use HiveService, await it
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
          if (kDebugMode) {
            debugPrint(
              '[Dio Auth Interceptor] Token added to request for ${options.path}',
            );
          }
        } else {
          if (kDebugMode) {
            debugPrint(
              '[Dio Auth Interceptor] No token found for ${options.path}',
            );
          }
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          debugPrint(
            '[Dio Auth Interceptor] Received 401 Unauthorized for ${e.requestOptions.path}. Logging out.',
          );
          try {
            // AuthState logout will also call hiveService.deleteAuthToken()
            if (sl.isRegistered<AuthState>()) {
              await sl<AuthState>().logout();
            } else if (sl.isRegistered<HiveService>()) {
              // Fallback if AuthState isn't used/registered for some reason
              await sl<HiveService>().deleteAuthToken();
            }
          } catch (logoutError) {
            debugPrint(
              '[Dio Auth Interceptor] Error during token clear after 401: $logoutError',
            );
          }
        }
        return handler.next(e);
      },
    ),
  );
  return dio;
}
