import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/providers/auth_provider.dart';
import '../data/catalog_repository.dart';
import '../domain/product.dart';

final _repoProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepository(
    ApiClient.create(
      onUnauthorized: () => ref.read(authProvider.notifier).logout(),
    ),
  ),
);

final catalogProvider = AsyncNotifierProvider<CatalogNotifier, List<Product>>(
  CatalogNotifier.new,
);

class CatalogNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() => ref.read(_repoProvider).getProducts();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(_repoProvider).getProducts());
  }

  Future<void> create(Product p) async {
    final created = await ref.read(_repoProvider).createProduct(p);
    state = AsyncData([...state.valueOrNull ?? [], created]);
  }

  Future<void> editProduct(String id, Product p) async {
    final updated = await ref.read(_repoProvider).updateProduct(id, p);
    state = AsyncData(
      (state.valueOrNull ?? []).map((e) => e.id == id ? updated : e).toList(),
    );
  }

  Future<void> delete(String id) async {
    await ref.read(_repoProvider).deleteProduct(id);
    state = AsyncData(
      (state.valueOrNull ?? []).where((e) => e.id != id).toList(),
    );
  }
}
