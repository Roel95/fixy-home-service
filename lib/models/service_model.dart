class ServiceModel {
  final String id;
  final String title;
  final String description;
  final double rating;
  final int reviews;
  final double price;
  final String currency;
  final String timeUnit;
  final String imageUrl;
  final String category;
  final String location;
  final List<String> availableDays;
  final String timeFrom;
  final String timeTo;
  final String? providerId;
  final String? providerName;
  final String? providerImageUrl;
  final String? providerPhone;
  final double? providerRating;
  final bool hasDiscount;
  final double? originalPrice;
  final DateTime? discountExpiresAt;

  ServiceModel({
    required this.id,
    required this.title,
    required this.description,
    required this.rating,
    required this.reviews,
    required this.price,
    required this.currency,
    required this.timeUnit,
    required this.imageUrl,
    required this.category,
    required this.location,
    required this.availableDays,
    required this.timeFrom,
    required this.timeTo,
    this.providerId,
    this.providerName,
    this.providerImageUrl,
    this.providerPhone,
    this.providerRating,
    this.hasDiscount = false,
    this.originalPrice,
    this.discountExpiresAt,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      reviews: json['reviews'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'S/',
      timeUnit: json['time_unit'] ?? json['timeUnit'] ?? 'hr',
      imageUrl: json['image_url'] ?? json['imageUrl'] ?? '',
      category: json['category'] ?? '',
      location: json['location'] ?? '',
      availableDays: json['available_days'] != null
          ? List<String>.from(json['available_days'])
          : (json['availableDays'] != null
              ? List<String>.from(json['availableDays'])
              : []),
      timeFrom: json['time_from'] ?? json['timeFrom'] ?? '08:00',
      timeTo: json['time_to'] ?? json['timeTo'] ?? '18:00',
      providerId: json['provider_id']?.toString(),
      providerName: json['provider_name'],
      providerImageUrl: json['provider_image_url'],
      providerPhone: json['provider_phone'],
      providerRating: json['provider_rating'] != null
          ? (json['provider_rating'] as num).toDouble()
          : null,
      hasDiscount: json['has_discount'] ?? false,
      originalPrice: json['original_price'] != null
          ? (json['original_price'] as num).toDouble()
          : null,
      discountExpiresAt: json['discount_expires_at'] != null
          ? DateTime.parse(json['discount_expires_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'title': title,
      'description': description,
      'rating': rating,
      'reviews': reviews,
      'price': price,
      'currency': currency,
      'time_unit': timeUnit,
      'image_url': imageUrl,
      'category': category,
      'location': location,
      'available_days': availableDays,
      'time_from': timeFrom,
      'time_to': timeTo,
      if (providerId != null) 'provider_id': providerId,
      if (providerName != null) 'provider_name': providerName,
      if (providerImageUrl != null) 'provider_image_url': providerImageUrl,
      if (providerPhone != null) 'provider_phone': providerPhone,
      if (providerRating != null) 'provider_rating': providerRating,
      'has_discount': hasDiscount,
      if (originalPrice != null) 'original_price': originalPrice,
      if (discountExpiresAt != null)
        'discount_expires_at': discountExpiresAt!.toIso8601String(),
    };
  }

  ServiceModel copyWith({
    String? id,
    String? title,
    String? description,
    double? rating,
    int? reviews,
    double? price,
    String? currency,
    String? timeUnit,
    String? imageUrl,
    String? category,
    String? location,
    List<String>? availableDays,
    String? timeFrom,
    String? timeTo,
    String? providerId,
    String? providerName,
    String? providerImageUrl,
    String? providerPhone,
    double? providerRating,
    bool? hasDiscount,
    double? originalPrice,
    DateTime? discountExpiresAt,
  }) =>
      ServiceModel(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        rating: rating ?? this.rating,
        reviews: reviews ?? this.reviews,
        price: price ?? this.price,
        currency: currency ?? this.currency,
        timeUnit: timeUnit ?? this.timeUnit,
        imageUrl: imageUrl ?? this.imageUrl,
        category: category ?? this.category,
        location: location ?? this.location,
        availableDays: availableDays ?? this.availableDays,
        timeFrom: timeFrom ?? this.timeFrom,
        timeTo: timeTo ?? this.timeTo,
        providerId: providerId ?? this.providerId,
        providerName: providerName ?? this.providerName,
        providerImageUrl: providerImageUrl ?? this.providerImageUrl,
        providerPhone: providerPhone ?? this.providerPhone,
        providerRating: providerRating ?? this.providerRating,
        hasDiscount: hasDiscount ?? this.hasDiscount,
        originalPrice: originalPrice ?? this.originalPrice,
        discountExpiresAt: discountExpiresAt ?? this.discountExpiresAt,
      );
}
