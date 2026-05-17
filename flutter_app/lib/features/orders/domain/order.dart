class OrderItem {
  const OrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
  });

  final String productId;
  final String name;
  final int quantity;
  final double price;

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        productId: j['product_id'] as String,
        name: j['name'] as String,
        quantity: j['quantity'] as int,
        price: (j['price'] as num).toDouble(),
      );
}

class Order {
  const Order({
    required this.id,
    required this.items,
    required this.total,
    required this.status,
    required this.address,
    required this.createdAt,
  });

  final String id;
  final List<OrderItem> items;
  final double total;
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
        id: j['id'] as String,
        items: (j['items'] as List<dynamic>)
            .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: (j['total'] as num).toDouble(),
        status: j['status'] as String,
        address: (j['address'] as String?) ?? '',
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}
