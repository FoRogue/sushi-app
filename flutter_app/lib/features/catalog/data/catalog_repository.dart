import 'package:dio/dio.dart';
import '../domain/product.dart';

class CatalogRepository {
  const CatalogRepository(this._dio);

  final Dio _dio;

  Future<List<Product>> getProducts() async {
    final resp = await _dio.get('catalog/items');
    final list = resp.data as List<dynamic>;
    return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Product> createProduct(Product p) async {
    final resp = await _dio.post('catalog/items', data: p.toJson());
    return Product.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<Product> updateProduct(String id, Product p) async {
    final resp = await _dio.put('catalog/items/$id', data: p.toJson());
    return Product.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> deleteProduct(String id) => _dio.delete('catalog/items/$id');
}
