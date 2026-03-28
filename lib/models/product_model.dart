class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? originalPrice;
  final String category;
  final List<String> images;
  final String brand;
  final int stock;
  final double rating;
  final int reviewCount;
  final List<String> specifications;
  final bool isFeatured;
  final bool isOnSale;
  final String unit;
  final bool isNew;
  final bool isBestSeller;
  final DateTime? createdAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.category,
    required this.images,
    required this.brand,
    required this.stock,
    required this.rating,
    required this.reviewCount,
    required this.specifications,
    this.isFeatured = false,
    this.isOnSale = false,
    this.unit = 'unidad',
    this.isNew = false,
    this.isBestSeller = false,
    this.createdAt,
  });

  bool get isInStock => stock > 0;
  bool get isLowStock => stock > 0 && stock <= 5;

  double get discountPercentage {
    if (originalPrice == null || originalPrice! <= price) return 0;
    return ((originalPrice! - price) / originalPrice!) * 100;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'original_price': originalPrice,
        'category_id': category,
        'images': images,
        'brand': brand,
        'stock': stock,
        'rating': rating,
        'review_count': reviewCount,
        'specifications': specifications,
        'is_featured': isFeatured,
        'is_on_sale': isOnSale,
        'unit': unit,
        'is_new': isNew,
        'is_best_seller': isBestSeller,
        'created_at': createdAt?.toIso8601String(),
      };

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
        id: json['id'].toString(),
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        originalPrice: json['original_price'] != null
            ? (json['original_price'] as num).toDouble()
            : null,
        category: json['category_id'] ?? json['category'] ?? '',
        images: json['images'] != null ? List<String>.from(json['images']) : [],
        brand: json['brand'] ?? '',
        stock: json['stock'] ?? 0,
        rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
        reviewCount: json['review_count'] ?? 0,
        specifications: json['specifications'] != null
            ? List<String>.from(json['specifications'])
            : [],
        isFeatured: json['is_featured'] ?? false,
        isOnSale: json['is_on_sale'] ?? false,
        unit: json['unit'] ?? 'unidad',
        isNew: json['is_new'] ?? false,
        isBestSeller: json['is_best_seller'] ?? false,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : null,
      );
}

class ProductCategoryModel {
  final String id;
  final String name;
  final String icon;
  final String color;
  final int productCount;
  final String? imageUrl;

  ProductCategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.productCount,
    this.imageUrl,
  });
}

class CartItemModel {
  final ProductModel product;
  int quantity;

  CartItemModel({
    required this.product,
    this.quantity = 1,
  });

  double get totalPrice => product.price * quantity;

  Map<String, dynamic> toJson() => {
        'product': product.toJson(),
        'quantity': quantity,
      };

  factory CartItemModel.fromJson(Map<String, dynamic> json) => CartItemModel(
        product: ProductModel.fromJson(json['product']),
        quantity: json['quantity'],
      );
}

class CartModel {
  final List<CartItemModel> items;

  CartModel({this.items = const []});

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get shipping => subtotal > 100 ? 0 : 10;

  double get total => subtotal + shipping;

  bool get isEmpty => items.isEmpty;
}
