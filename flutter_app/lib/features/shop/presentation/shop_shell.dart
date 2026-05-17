import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ShopShell extends StatelessWidget {
  const ShopShell({super.key, required this.child});

  final Widget child;

  static const _tabs = ['/shop/orders', '/shop/catalog'];

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final idx = _tabs.indexWhere((t) => loc.startsWith(t)).clamp(0, 1);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => context.go(_tabs[i]),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Заказы',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Каталог',
          ),
        ],
      ),
    );
  }
}
