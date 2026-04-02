class CategoryModel {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final String currency;
  final String timeUnit;
  final bool isActive;

  CategoryModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.currency,
    required this.timeUnit,
    this.isActive = true,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      imageUrl: json['image_url'] ?? json['imageUrl'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'S/',
      timeUnit: json['time_unit'] ?? json['timeUnit'] ?? 'hr',
      isActive: json['is_active'] ?? true,
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
      'is_active': isActive,
    };
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? imageUrl,
    double? price,
    String? currency,
    String? timeUnit,
    bool? isActive,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      timeUnit: timeUnit ?? this.timeUnit,
      isActive: isActive ?? this.isActive,
    );
  }
}
