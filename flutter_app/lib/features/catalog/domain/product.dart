class Product {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.type,
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final String type;

  String get typeLabel => switch (type) {
        'sushi' => 'Суши',
        'roll' => 'Ролл',
        'drink' => 'Напиток',
        _ => type,
      };

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'].toString(),
        name: j['name'] as String,
        description: (j['description'] as String?) ?? '',
        price: (j['price'] as num).toDouble(),
        type: (j['type'] as String?) ?? 'sushi',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'price': price,
        'type': type,
      };
}
