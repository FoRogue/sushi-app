import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../providers/catalog_provider.dart';
import '../domain/product.dart';
import '../../cart/providers/cart_provider.dart';
import '../../shops/providers/shops_provider.dart';
import '../../shops/domain/shop.dart';

class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  static const _bg = Color(0xFFF9F6F0);
  static const _accent = Color(0xFFD9381E);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedShop = ref.watch(selectedShopProvider);

    if (selectedShop == null) {
      return _ShopsListView(onSelect: (shop) {
        ref.read(selectedShopProvider.notifier).state = shop;
      });
    }

    final state = ref.watch(catalogProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Каталог',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
            ),
            GestureDetector(
              onTap: () =>
                  ref.read(selectedShopProvider.notifier).state = null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    selectedShop.name,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _accent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.swap_horiz, size: 14, color: _accent),
                ],
              ),
            ),
          ],
        ),
        toolbarHeight: 64,
        actions: [
          Consumer(builder: (_, ref, __) {
            final count = ref.watch(
              cartProvider.select((c) => c.fold(0, (s, e) => s + e.quantity)),
            );
            return IconButton(
              onPressed: () => context.go('/customer/cart'),
              icon: Badge(
                isLabelVisible: count > 0,
                label: Text('$count'),
                child: const Icon(Icons.shopping_cart_outlined),
              ),
            );
          }),
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
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(catalogProvider.notifier).refresh(),
        ),
        data: (products) => products.isEmpty
            ? const _EmptyView(message: 'Меню пусто')
            : RefreshIndicator(
                onRefresh: () => ref.read(catalogProvider.notifier).refresh(),
                child: LayoutBuilder(
                  builder: (_, constraints) {
                    final w = constraints.maxWidth;
                    final cols = w > 1100
                        ? 5
                        : w > 800
                            ? 4
                            : w > 550
                                ? 3
                                : 2;
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: products.length,
                      itemBuilder: (_, i) =>
                          _ProductCard(product: products[i]),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class _ShopsListView extends ConsumerWidget {
  const _ShopsListView({required this.onSelect});

  final void Function(Shop) onSelect;

  static const _bg = Color(0xFFF9F6F0);
  static const _accent = Color(0xFFD9381E);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shopsProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: const Text(
          'Выберите магазин',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(shopsProvider.notifier).refresh(),
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
                onPressed: () => ref.read(shopsProvider.notifier).refresh(),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
        data: (shops) => shops.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🏪', style: TextStyle(fontSize: 56)),
                    SizedBox(height: 12),
                    Text(
                      'Нет зарегистрированных магазинов',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: shops.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final shop = shops[i];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => onSelect(shop),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: _accent.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text('🏪',
                                    style: TextStyle(fontSize: 24)),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    shop.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (shop.address != null &&
                                      shop.address!.isNotEmpty)
                                    Text(
                                      shop.address!,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _ProductCard extends ConsumerWidget {
  const _ProductCard({required this.product});

  final Product product;

  static const _accent = Color(0xFFD9381E);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inCart = ref.watch(
      cartProvider.select(
        (c) => c
            .where((e) => e.product.id == product.id)
            .fold(0, (s, e) => s + e.quantity),
      ),
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              color: const Color(0xFFEEE8E0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🍱', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 4),
                  Text(
                    product.typeLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${product.price.toStringAsFixed(0)} ₽',
                  style: const TextStyle(
                    color: _accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 34,
                  child: inCart == 0
                      ? FilledButton(
                          onPressed: () =>
                              ref.read(cartProvider.notifier).add(product),
                          style: FilledButton.styleFrom(
                            backgroundColor: _accent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text(
                            'В корзину',
                            style: TextStyle(fontSize: 12),
                          ),
                        )
                      : Row(
                          children: [
                            _CounterBtn(
                              icon: Icons.remove,
                              onTap: () => ref
                                  .read(cartProvider.notifier)
                                  .remove(product.id),
                            ),
                            Expanded(
                              child: Text(
                                '$inCart',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            _CounterBtn(
                              icon: Icons.add,
                              onTap: () =>
                                  ref.read(cartProvider.notifier).add(product),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
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

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🍣', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Повторить')),
        ],
      ),
    );
  }
}
