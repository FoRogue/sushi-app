import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/cart_provider.dart';
import '../domain/cart_item.dart';
import '../../orders/providers/orders_provider.dart';
import '../../shops/providers/shops_provider.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  static const _accent = Color(0xFFD9381E);
  static const _bg = Color(0xFFF9F6F0);

  final _addressCtrl = TextEditingController();
  bool _placing = false;

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeOrder(List<CartItem> items) async {
    final selectedShop = ref.read(selectedShopProvider);
    if (selectedShop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите магазин в каталоге')),
      );
      return;
    }
    if (_addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите адрес доставки')),
      );
      return;
    }
    setState(() => _placing = true);
    try {
      await ref.read(ordersProvider.notifier).placeOrder(
            shopId: selectedShop.id,
            address: _addressCtrl.text.trim(),
            items: items
                .map((e) => {
                      'menu_item_id': int.parse(e.product.id),
                      'quantity': e.quantity,
                    })
                .toList(),
          );
      ref.read(cartProvider.notifier).clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Заказ оформлен!'),
          backgroundColor: _accent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      context.go('/customer/orders');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);
    final selectedShop = ref.watch(selectedShopProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: const Text(
          'Корзина',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
        ),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: notifier.clear,
              child: const Text('Очистить', style: TextStyle(color: _accent)),
            ),
        ],
      ),
      body: items.isEmpty
          ? const _EmptyCart()
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (selectedShop != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.store_outlined,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          selectedShop.name,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ...items.map((item) => _CartItemTile(item: item)),
                const SizedBox(height: 20),
                _AddressField(controller: _addressCtrl),
                const SizedBox(height: 20),
                _OrderSummary(items: items),
                const SizedBox(height: 16),
                SizedBox(
                  height: 54,
                  child: FilledButton(
                    onPressed: _placing ? null : () => _placeOrder(items),
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _placing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Заказать — ${notifier.total.toStringAsFixed(0)} ₽',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
              ),
            ),
    );
  }
}

class _CartItemTile extends ConsumerWidget {
  const _CartItemTile({required this.item});

  final CartItem item;

  static const _accent = Color(0xFFD9381E);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(cartProvider.notifier);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.product.price.toStringAsFixed(0)} ₽',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                _CounterBtn(
                  icon: Icons.remove,
                  onTap: () => notifier.remove(item.product.id),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    '${item.quantity}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                _CounterBtn(
                  icon: Icons.add,
                  onTap: () => notifier.add(item.product),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Text(
              '${item.subtotal.toStringAsFixed(0)} ₽',
              style: const TextStyle(
                color: _accent,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CounterBtn extends StatelessWidget {
  const _CounterBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: const Color(0xFFD9381E).withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFFD9381E)),
      ),
    );
  }
}

class _AddressField extends StatelessWidget {
  const _AddressField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Адрес доставки',
        hintText: 'ул. Пушкина, д. 1, кв. 5',
        prefixIcon: const Icon(Icons.location_on_outlined,
            color: Color(0xFFD9381E)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFD9381E), width: 1.8),
        ),
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({required this.items});

  final List<CartItem> items;

  @override
  Widget build(BuildContext context) {
    final total = items.fold(0.0, (s, e) => s + e.subtotal);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Позиций: ${items.length}'),
          Text(
            '${total.toStringAsFixed(0)} ₽',
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🛒', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          const Text('Корзина пуста',
              style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.go('/customer/catalog'),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD9381E)),
            child: const Text('Перейти в каталог'),
          ),
        ],
      ),
    );
  }
}
