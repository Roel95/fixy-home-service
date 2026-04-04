class BannerModel {
  final String id;
  final String title;
  final String? subtitle;
  final String imageUrl;
  final String? discount;
  final String backgroundColor;
  final String textColor;
  final String? route;
  final Map<String, dynamic>? routeParams;
  final bool isActive;
  final String type; // 'app' o 'shop'
  final String? actionType; // 'product', 'category', 'service', 'url', 'none'
  final String? actionId; // ID del producto, categoría, servicio, o URL
  final int order; // Orden de visualización
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BannerModel({
    required this.id,
    required this.title,
    this.subtitle,
    required this.imageUrl,
    this.discount,
    this.backgroundColor = '#E8F3FF',
    this.textColor = '#0066FF',
    this.route,
    this.routeParams,
    this.isActive = true,
    this.type = 'app',
    this.actionType,
    this.actionId,
    this.order = 0,
    this.startDate,
    this.endDate,
    this.createdAt,
    this.updatedAt,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      subtitle: json['subtitle'],
      imageUrl: json['image_url'] ?? '',
      discount: json['discount'],
      backgroundColor: json['background_color'] ?? '#E8F3FF',
      textColor: json['text_color'] ?? '#0066FF',
      route: json['route'],
      routeParams: json['route_params'] != null
          ? Map<String, dynamic>.from(json['route_params'])
          : null,
      isActive: json['is_active'] ?? true,
      type: json['type'] ?? 'app',
      actionType: json['action_type'],
      actionId: json['action_id'],
      order: json['order'] ?? 0,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : null,
      endDate:
          json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'image_url': imageUrl,
      'discount': discount,
      'background_color': backgroundColor,
      'text_color': textColor,
      'route': route,
      'route_params': routeParams,
      'is_active': isActive,
      'type': type,
      'action_type': actionType,
      'action_id': actionId,
      'order': order,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'image_url': imageUrl,
      'discount': discount,
      'background_color': backgroundColor,
      'text_color': textColor,
      'route': route,
      'route_params': routeParams,
      'is_active': isActive,
      'type': type,
      'action_type': actionType,
      'action_id': actionId,
      'order': order,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'image_url': imageUrl,
      'discount': discount,
      'background_color': backgroundColor,
      'text_color': textColor,
      'route': route,
      'route_params': routeParams,
      'is_active': isActive,
      'type': type,
      'action_type': actionType,
      'action_id': actionId,
      'order': order,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
    };
  }

  BannerModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? imageUrl,
    String? discount,
    String? backgroundColor,
    String? textColor,
    String? route,
    Map<String, dynamic>? routeParams,
    bool? isActive,
    String? type,
    String? actionType,
    String? actionId,
    int? order,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BannerModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      discount: discount ?? this.discount,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      route: route ?? this.route,
      routeParams: routeParams ?? this.routeParams,
      isActive: isActive ?? this.isActive,
      type: type ?? this.type,
      actionType: actionType ?? this.actionType,
      actionId: actionId ?? this.actionId,
      order: order ?? this.order,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isVisible {
    if (!isActive) return false;
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }

  String get typeLabel => type == 'app' ? 'App' : 'Tienda';

  String get actionTypeLabel {
    switch (actionType) {
      case 'product':
        return 'Producto';
      case 'category':
        return 'Categoría';
      case 'service':
        return 'Servicio';
      case 'url':
        return 'URL';
      default:
        return 'Sin acción';
    }
  }

  @override
  String toString() {
    return 'BannerModel(id: $id, title: $title, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BannerModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
