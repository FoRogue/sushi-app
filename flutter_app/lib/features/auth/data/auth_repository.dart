import 'package:dio/dio.dart';
import '../../../core/storage/token_storage.dart';

class AuthRepository {
  const AuthRepository(this._dio);

  final Dio _dio;

  Future<void> loginCustomer({
    required String phone,
    required String password,
  }) async {
    final resp = await _dio.post(
      '/auth/login/customer',
      data: {'phone': phone, 'password': password},
    );
    await _persist(resp.data as Map<String, dynamic>);
  }

  Future<void> loginCourier({
    required String vehicleCode,
    required String password,
  }) async {
    final resp = await _dio.post(
      '/auth/login/courier',
      data: {'vehicle_code': vehicleCode, 'password': password},
    );
    await _persist(resp.data as Map<String, dynamic>);
  }

  Future<void> loginShop({
    required String address,
    required String password,
  }) async {
    final resp = await _dio.post(
      '/auth/login/shop',
      data: {'address': address, 'password': password},
    );
    await _persist(resp.data as Map<String, dynamic>);
  }

  Future<void> _persist(Map<String, dynamic> data) => TokenStorage.save(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
      );

  // ── Registration ────────────────────────────────────────────────────────────

  Future<void> registerCustomer({
    required String name,
    required String phone,
    required String password,
  }) =>
      _dio.post(
        '/auth/register/customer',
        data: {'name': name, 'phone': phone, 'password': password},
      );

  Future<void> registerCourier({
    required String vehicleCode,
    required String password,
  }) =>
      _dio.post(
        '/auth/register/courier',
        data: {'vehicle_code': vehicleCode, 'password': password},
      );

  Future<void> registerShop({
    required String name,
    required String address,
    required String password,
  }) =>
      _dio.post(
        '/auth/register/shop',
        data: {'name': name, 'address': address, 'password': password},
      );
}
