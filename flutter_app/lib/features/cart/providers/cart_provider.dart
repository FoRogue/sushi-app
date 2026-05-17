import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/cart_item.dart';
import '../../catalog/domain/product.dart';

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];

  void add(Product product) {
    final idx = state.indexWhere((e) => e.product.id == product.id);
    if (idx >= 0) {
      state = [
        for (var i = 0; i < state.length; i++)
          if (i == idx) state[i].copyWith(quantity: state[i].quantity + 1)
          else state[i],
      ];
    } else {
      state = [...state, CartItem(product: product, quantity: 1)];
    }
  }

  void remove(String productId) {
    final idx = state.indexWhere((e) => e.product.id == productId);
    if (idx < 0) return;
    final item = state[idx];
    if (item.quantity > 1) {
      state = [
        for (var i = 0; i < state.length; i++)
          if (i == idx) item.copyWith(quantity: item.quantity - 1)
          else state[i],
      ];
    } else {
      state = state.where((e) => e.product.id != productId).toList();
    }
  }

  void clear() => state = [];

  double get total => state.fold(0, (sum, e) => sum + e.subtotal);
  int get itemCount => state.fold(0, (sum, e) => sum + e.quantity);
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(
  CartNotifier.new,
);
