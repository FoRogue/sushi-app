import 'package:dio/dio.dart';
import '../domain/order.dart';

class OrderRepository {
  const OrderRepository(this._dio);

  final Dio _dio;

  Future<List<Order>> getOrders() async {
    final resp = await _dio.get('orders');
    final list = resp.data as List<dynamic>;
    return list.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Order> createOrder({
    required String address,
    required List<Map<String, dynamic>> items,
  }) async {
    final resp = await _dio.post('orders', data: {
      'address': address,
      'items': items,
    });
    return Order.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<Order> updateStatus(String id, String status) async {
    final resp = await _dio.patch('orders/$id/status', data: {'status': status});
    return Order.fromJson(resp.data as Map<String, dynamic>);
  }
}
