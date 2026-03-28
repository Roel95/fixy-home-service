class CategoryModel {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final String currency;
  final String timeUnit;

  CategoryModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.currency,
    required this.timeUnit,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      imageUrl: json['image_url'] ?? json['imageUrl'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'S/',
      timeUnit: json['time_unit'] ?? json['timeUnit'] ?? 'hr',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'price': price,
      'currency': currency,
      'time_unit': timeUnit,
    };
  }
}
