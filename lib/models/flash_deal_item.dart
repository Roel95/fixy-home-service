import 'package:fixy_home_service/models/service_model.dart';
import 'package:fixy_home_service/models/product_model.dart';

/// Clase unificada para mostrar ofertas flash (servicios y productos)
class FlashDealItem {
  final String id;
  final String title;
  final String imageUrl;
  final double price;
  final double? originalPrice;
  final double rating;
  final int reviewCount;
  final DateTime? expiresAt;
  final FlashDealType type;
  final ServiceModel? service;
  final ProductModel? product;

  FlashDealItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.price,
    this.originalPrice,
    required this.rating,
    required this.reviewCount,
    this.expiresAt,
    required this.type,
    this.service,
    this.product,
  });

  factory FlashDealItem.fromService(ServiceModel service) {
    return FlashDealItem(
      id: service.id,
      title: service.title,
      imageUrl: service.imageUrl,
      price: service.price,
      originalPrice: service.originalPrice,
      rating: service.rating,
      reviewCount: service.reviews,
      expiresAt: service.discountExpiresAt,
      type: FlashDealType.service,
      service: service,
    );
  }

  factory FlashDealItem.fromProduct(ProductModel product) {
    return FlashDealItem(
      id: product.id,
      title: product.name,
      imageUrl: product.images.isNotEmpty ? product.images.first : '',
      price: product.price,
      originalPrice: product.originalPrice,
      rating: product.rating,
      reviewCount: product.reviewCount,
      expiresAt: null,
      type: FlashDealType.product,
      product: product,
    );
  }

  double get discountPercentage {
    if (originalPrice == null || originalPrice! <= 0) return 0;
    return ((originalPrice! - price) / originalPrice! * 100);
  }

  bool get hasDiscount => originalPrice != null && originalPrice! > price;
}

enum FlashDealType {
  service,
  product,
}
