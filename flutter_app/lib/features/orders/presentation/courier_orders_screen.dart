import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../providers/orders_provider.dart';
import '../domain/order.dart';

class CourierOrdersScreen extends ConsumerWidget {
  const CourierOrdersScreen({super.key});

  static const _bg = Color(0xFFF9F6F0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: const Text(
          'Мои доставки',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(ordersProvider.notifier).refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(e.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.read(ordersProvider.notifier).refresh(),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
        data: (orders) {
          final active = orders
              .where((o) => o.status == 'accepted' || o.status == 'picked_up')
              .toList();
          if (active.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🛵', style: TextStyle(fontSize: 56)),
                  SizedBox(height: 12),
                  Text(
                    'Активных доставок нет',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(ordersProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: active.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _CourierOrderCard(order: active[i]),
            ),
          );
        },
      ),
    );
  }
}

class _CourierOrderCard extends ConsumerWidget {
  const _CourierOrderCard({required this.order});

  final Order order;

  static const _accent = Color(0xFFD9381E);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAccepted = order.status == 'accepted';
    final isPickedUp = order.status == 'picked_up';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Заказ #${order.id.substring(0, order.id.length.clamp(0, 8))}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPickedUp
                        ? const Color(0xFF6750A4).withOpacity(0.12)
                        : Colors.blue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isPickedUp ? 'В пути' : 'Принят',
                    style: TextStyle(
                      color: isPickedUp
                          ? const Color(0xFF6750A4)
                          : Colors.blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.address,
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF444444)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${order.items.length} позиций • ${order.totalPrice.toStringAsFixed(0)} ₽',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 14),
            if (isPickedUp)
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton(
                  onPressed: () => ref
                      .read(ordersProvider.notifier)
                      .updateStatus(order.id, 'delivered'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Подтвердить доставку',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              )
            else if (isAccepted)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: FilledButton(
                        onPressed: () => ref
                            .read(ordersProvider.notifier)
                            .updateStatus(order.id, 'picked_up'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _accent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Забрал заказ',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () => _confirmDecline(context, ref),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Отказаться',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDecline(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Отказаться от заказа?'),
        content: const Text(
            'Заказ пропадёт из вашего списка. Его сможет взять другой курьер.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(ordersProvider.notifier).declineOrder(order.id);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Отказаться'),
          ),
        ],
      ),
    );
  }
}
