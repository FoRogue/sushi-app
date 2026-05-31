import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/storage/token_storage.dart';
import '../../shops/providers/shops_provider.dart';
import '../data/catalog_repository.dart';
import '../domain/product.dart';

final _repoProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepository(
    ApiClient.create(
      onUnauthorized: () => ref.read(authProvider.notifier).logout(),
    ),
  ),
);

// Каталог для покупателя — зависит от выбранного магазина
final catalogProvider = AsyncNotifierProvider<CatalogNotifier, List<Product>>(
  CatalogNotifier.new,
);

class CatalogNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() {
    final shop = ref.watch(selectedShopProvider);
    if (shop == null) return Future.value([]);
    return ref.read(_repoProvider).getProducts(shopId: shop.id);
  }

  Future<void> refresh() async {
    final shop = ref.read(selectedShopProvider);
    if (shop == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(_repoProvider).getProducts(shopId: shop.id),
    );
  }
}

// Каталог для магазина — только свои товары
final shopCatalogProvider =
    AsyncNotifierProvider<ShopCatalogNotifier, List<Product>>(
  ShopCatalogNotifier.new,
);

class ShopCatalogNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() async {
    final raw = await TokenStorage.getUserId();
    final shopId = raw == null || raw.isEmpty ? null : int.tryParse(raw);
    if (shopId == null) return [];
    return ref.read(_repoProvider).getProducts(shopId: shopId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final raw = await TokenStorage.getUserId();
    final shopId = raw == null || raw.isEmpty ? null : int.tryParse(raw);
    if (shopId == null) { state = const AsyncData([]); return; }
    state = await AsyncValue.guard(
      () => ref.read(_repoProvider).getProducts(shopId: shopId),
    );
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
