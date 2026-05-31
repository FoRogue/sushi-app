import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../data/shops_repository.dart';
import '../domain/shop.dart';

final _shopsRepoProvider = Provider<ShopsRepository>(
  (_) => ShopsRepository(ApiClient.create()),
);

final shopsProvider = AsyncNotifierProvider<ShopsNotifier, List<Shop>>(
  ShopsNotifier.new,
);

class ShopsNotifier extends AsyncNotifier<List<Shop>> {
  @override
  Future<List<Shop>> build() => ref.read(_shopsRepoProvider).getShops();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(_shopsRepoProvider).getShops());
  }
}

final selectedShopProvider = StateProvider<Shop?>((ref) => null);
