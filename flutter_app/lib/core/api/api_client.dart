import 'package:dio/dio.dart';
import '../storage/token_storage.dart';

class ApiClient {
  ApiClient._();

  static const _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080/api/',
  );

  static Dio create({Future<void> Function()? onUnauthorized}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    dio.interceptors.add(_AuthInterceptor(onUnauthorized));
    return dio;
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._onUnauthorized);

  final Future<void> Function()? _onUnauthorized;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await TokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      await _onUnauthorized?.call();
    }
    handler.next(err);
  }
}
