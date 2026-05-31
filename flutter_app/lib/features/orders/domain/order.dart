class OrderItem {
  const OrderItem({
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  final int menuItemId;
  final String name;
  final int quantity;
  final double unitPrice;

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        menuItemId: j['menu_item_id'] as int,
        name: j['name'] as String,
        quantity: j['quantity'] as int,
        unitPrice: (j['unit_price'] as num).toDouble(),
      );
}

class Order {
  const Order({
    required this.id,
    required this.shopId,
    required this.items,
    required this.totalPrice,
    required this.status,
    required this.address,
    required this.createdAt,
  });

  final String id;
  final int shopId;
  final List<OrderItem> items;
  final double totalPrice;
  final String status;
  final String address;
  final DateTime createdAt;

  String get statusLabel => switch (status) {
        'pending' => 'Ожидает',
        'accepted' => 'Принят',
        'picked_up' => 'В пути',
        'delivered' => 'Доставлен',
        'cancelled' => 'Отменён',
        _ => status,
      };

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        id: j['id'].toString(),
        shopId: j['shop_id'] as int,
        items: (j['items'] as List<dynamic>? ?? [])
            .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalPrice: (j['total_price'] as num).toDouble(),
        status: j['status'] as String,
        address: (j['address'] as String?) ?? '',
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}
