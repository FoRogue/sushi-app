import 'package:dio/dio.dart';

class ApiClient {
  ApiClient._();

  // В Docker nginx проксирует /api/ → gateway.
  // Для локальной разработки: --dart-define=API_BASE_URL=http://localhost:8080/api
  static const _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '/api',
  );

  static Dio create() => Dio(
        BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Content-Type': 'application/json'},
        ),
      );
}
