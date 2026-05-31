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
      'auth/login/customer',
      data: {'phone': phone, 'password': password},
    );
    await _persist(resp.data as Map<String, dynamic>, role: 'customer');
  }

  Future<void> loginCourier({
    required String vehicleCode,
    required String password,
  }) async {
    final resp = await _dio.post(
      'auth/login/courier',
      data: {'vehicle_code': vehicleCode, 'password': password},
    );
    await _persist(resp.data as Map<String, dynamic>, role: 'courier');
  }

  Future<void> loginShop({
    required String login,
    required String password,
  }) async {
    final resp = await _dio.post(
      'auth/login/shop',
      data: {'login': login, 'password': password},
    );
    await _persist(resp.data as Map<String, dynamic>, role: 'shop');
  }

  Future<void> _persist(Map<String, dynamic> data, {required String role}) =>
      TokenStorage.save(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
        role: role,
      );

  // ── Registration ────────────────────────────────────────────────────────────

  Future<void> registerCustomer({
    required String name,
    required String phone,
    required String password,
  }) =>
      _dio.post(
        'auth/register/customer',
        data: {'name': name, 'phone': phone, 'password': password},
      );

  Future<void> registerCourier({
    required String fullName,
    required String vehicleCode,
    required String password,
  }) =>
      _dio.post(
        'auth/register/courier',
        data: {
          'full_name': fullName,
          'vehicle_code': vehicleCode,
          'password': password,
        },
      );

  Future<void> registerShop({
    required String name,
    required String login,
    required String password,
    String? address,
  }) =>
      _dio.post(
        'auth/register/shop',
        data: {
          'name': name,
          'login': login,
          'password': password,
          if (address != null && address.isNotEmpty) 'address': address,
        },
      );
}
