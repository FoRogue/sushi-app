import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/providers/auth_provider.dart';
import '../data/order_repository.dart';
import '../domain/order.dart';

final _repoProvider = Provider.autoDispose<OrderRepository>(
  (ref) => OrderRepository(
    ApiClient.create(
      onUnauthorized: () => ref.read(authProvider.notifier).logout(),
    ),
  ),
);

final ordersProvider =
    AsyncNotifierProvider.autoDispose<OrdersNotifier, List<Order>>(
  OrdersNotifier.new,
);

class OrdersNotifier extends AutoDisposeAsyncNotifier<List<Order>> {
  @override
  Future<List<Order>> build() => ref.read(_repoProvider).getOrders();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(_repoProvider).getOrders());
  }

  Future<void> placeOrder({
    required String address,
    required List<Map<String, dynamic>> items,
  }) async {
    final order = await ref.read(_repoProvider).createOrder(
          address: address,
          items: items,
        );
    state = AsyncData([order, ...state.valueOrNull ?? []]);
  }

  Future<void> updateStatus(String id, String status) async {
    final updated = await ref.read(_repoProvider).updateStatus(id, status);
    state = AsyncData(
      (state.valueOrNull ?? [])
          .map((e) => e.id == id ? updated : e)
          .toList(),
    );
  }
}
