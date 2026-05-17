import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/customer/presentation/customer_shell.dart';
import '../../features/catalog/presentation/catalog_screen.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/orders/presentation/customer_orders_screen.dart';
import '../../features/courier/presentation/courier_shell.dart';
import '../../features/orders/presentation/courier_orders_screen.dart';
import '../../features/shop/presentation/shop_shell.dart';
import '../../features/orders/presentation/shop_orders_screen.dart';
import '../../features/catalog/presentation/shop_catalog_screen.dart';

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen(authProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    refreshListenable: notifier,
    initialLocation: '/login',
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      if (authState.isLoading) return null;

      final role = authState.valueOrNull;
      final isLoggedIn = role != null;
      final loc = state.matchedLocation;
      final isAuthRoute = loc == '/login' || loc == '/register';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) {
        return switch (role) {
          UserRole.customer => '/customer/catalog',
          UserRole.courier => '/courier/orders',
          UserRole.shop => '/shop/orders',
        };
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      ShellRoute(
        builder: (_, __, child) => CustomerShell(child: child),
        routes: [
          GoRoute(
            path: '/customer/catalog',
            builder: (_, __) => const CatalogScreen(),
          ),
          GoRoute(
            path: '/customer/cart',
            builder: (_, __) => const CartScreen(),
          ),
          GoRoute(
            path: '/customer/orders',
            builder: (_, __) => const CustomerOrdersScreen(),
          ),
        ],
      ),
      ShellRoute(
        builder: (_, __, child) => CourierShell(child: child),
        routes: [
          GoRoute(
            path: '/courier/orders',
            builder: (_, __) => const CourierOrdersScreen(),
          ),
        ],
      ),
      ShellRoute(
        builder: (_, __, child) => ShopShell(child: child),
        routes: [
          GoRoute(
            path: '/shop/orders',
            builder: (_, __) => const ShopOrdersScreen(),
          ),
          GoRoute(
            path: '/shop/catalog',
            builder: (_, __) => const ShopCatalogScreen(),
          ),
        ],
      ),
    ],
  );
});
