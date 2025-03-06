import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class ApiClient {
  ApiClient({required String baseUrl}) {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Add interceptors for logging, authentication, and error handling.
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          _logger.i('Request: [${options.method}] ${options.uri}');
          return handler.next(options); // continue
        },
        onResponse: (response, handler) {
          _logger.i('Response: [${response.statusCode}] ${response.data}');
          return handler.next(response); // continue
        },
        onError: (DioException error, handler) {
          _logger.e('Error: ${error.message}');
          if (error.response?.statusCode == 401) {
            _logger.w(
              'Unauthorized! Consider refreshing the token or logging out.',
            );
          }
          return handler.next(error); // continue
        },
      ),
    );
  }

  late final Dio dio;
  final Logger _logger = Logger();

  // Example method showing cancellation support.
  // Future<Response> getData(String endpoint, {CancelToken? cancelToken}) async {
  //   return await dio.get(endpoint, cancelToken: cancelToken);
  // }
}
