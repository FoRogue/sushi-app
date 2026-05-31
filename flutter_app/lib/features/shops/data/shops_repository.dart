import 'package:dio/dio.dart';
import '../domain/shop.dart';

class ShopsRepository {
  const ShopsRepository(this._dio);

  final Dio _dio;

  Future<List<Shop>> getShops() async {
    final resp = await _dio.get('users/shops');
    final list = resp.data as List<dynamic>;
    return list.map((e) => Shop.fromJson(e as Map<String, dynamic>)).toList();
  }
}
