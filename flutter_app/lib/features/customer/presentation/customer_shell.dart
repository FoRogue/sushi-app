import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';

class CustomerShell extends ConsumerWidget {
  const CustomerShell({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    '/customer/catalog',
    '/customer/cart',
    '/customer/orders',
  ];

  static const _destinations = [
    (icon: Icons.restaurant_menu_outlined, activeIcon: Icons.restaurant_menu, label: 'Каталог'),
    (icon: Icons.shopping_cart_outlined, activeIcon: Icons.shopping_cart, label: 'Корзина'),
    (icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: 'Заказы'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = GoRouterState.of(context).matchedLocation;
    final idx = _tabs.indexWhere((t) => loc.startsWith(t)).clamp(0, 2);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 720) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: idx,
                  onDestinationSelected: (i) => context.go(_tabs[i]),
                  labelType: NavigationRailLabelType.all,
                  destinations: _destinations
                      .map((d) => NavigationRailDestination(
                            icon: Icon(d.icon),
                            selectedIcon: Icon(d.activeIcon),
                            label: Text(d.label),
                          ))
                      .toList(),
                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: IconButton(
                          icon: const Icon(Icons.logout),
                          tooltip: 'Выйти',
                          onPressed: () async {
                            await ref.read(authProvider.notifier).logout();
                            if (context.mounted) context.go('/login');
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: child),
              ],
            ),
          );
        }

        return Scaffold(
          body: child,
          bottomNavigationBar: NavigationBar(
            selectedIndex: idx,
            onDestinationSelected: (i) => context.go(_tabs[i]),
            destinations: _destinations
                .map((d) => NavigationDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.activeIcon),
                      label: d.label,
                    ))
                .toList(),
          ),
        );
      },
    );
  }
}
