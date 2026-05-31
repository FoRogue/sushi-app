class Shop {
  const Shop({required this.id, required this.name, this.login, this.address});

  final int id;
  final String name;
  final String? login;
  final String? address;

  factory Shop.fromJson(Map<String, dynamic> j) => Shop(
        id: j['id'] as int,
        name: (j['name'] as String?) ?? '',
        login: j['login'] as String?,
        address: j['address'] as String?,
      );
}
