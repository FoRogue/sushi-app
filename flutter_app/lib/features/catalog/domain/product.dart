class Product {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'] as String,
        name: j['name'] as String,
        description: (j['description'] as String?) ?? '',
        price: (j['price'] as num).toDouble(),
        imageUrl: (j['image_url'] as String?) ?? '',
        category: (j['category'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'price': price,
        'image_url': imageUrl,
        'category': category,
      };
}
