/// Modelo para representar items dentro de un pedido
class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final String? imageUrl;
  final String? sku;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    this.imageUrl,
    this.sku,
  });

  double get total => price * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product_id'] ?? '',
      productName: json['product_name'] ?? '',
      quantity: json['quantity'] ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['image_url'],
      sku: json['sku'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'price': price,
      'image_url': imageUrl,
      'sku': sku,
    };
  }
}

/// Estados posibles de un pedido
enum OrderStatus {
  pending('pending', 'Pendiente', 0xFFFF9500),
  processing('processing', 'Procesando', 0xFF007AFF),
  shipped('shipped', 'Enviado', 0xFF5856D6),
  delivered('delivered', 'Entregado', 0xFF34C759),
  cancelled('cancelled', 'Cancelado', 0xFFFF3B30),
  refunded('refunded', 'Reembolsado', 0xFF8E8E93);

  final String value;
  final String label;
  final int color;

  const OrderStatus(this.value, this.label, this.color);

  static OrderStatus fromString(String? value) {
    return OrderStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => OrderStatus.pending,
    );
  }
}

/// Modelo para dirección de envío
class ShippingAddress {
  final String fullName;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String? state;
  final String? postalCode;
  final String? country;

  ShippingAddress({
    required this.fullName,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    this.state,
    this.postalCode,
    this.country,
  });

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      fullName: json['full_name'] ?? '',
      phone: json['phone'] ?? '',
      addressLine1: json['address_line_1'] ?? '',
      addressLine2: json['address_line_2'],
      city: json['city'] ?? '',
      state: json['state'],
      postalCode: json['postal_code'],
      country: json['country'] ?? 'Perú',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'phone': phone,
      'address_line_1': addressLine1,
      'address_line_2': addressLine2,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
    };
  }

  String get formattedAddress {
    final parts = [
      addressLine1,
      if (addressLine2 != null && addressLine2!.isNotEmpty) addressLine2,
      city,
      if (state != null && state!.isNotEmpty) state,
      if (postalCode != null && postalCode!.isNotEmpty) postalCode,
      country,
    ].where((e) => e != null && e.isNotEmpty).join(', ');
    return parts;
  }
}

/// Modelo principal para pedidos/órdenes
class Order {
  final String id;
  final String? orderNumber;
  final String? userId;
  final String? userEmail;
  final String? userName;
  final List<OrderItem> items;
  final ShippingAddress shippingAddress;
  final OrderStatus status;
  final double subtotal;
  final double shippingCost;
  final double discount;
  final double total;
  final String? notes;
  final String? trackingNumber;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? couponCode;

  Order({
    required this.id,
    this.orderNumber,
    this.userId,
    this.userEmail,
    this.userName,
    required this.items,
    required this.shippingAddress,
    this.status = OrderStatus.pending,
    required this.subtotal,
    this.shippingCost = 0.0,
    this.discount = 0.0,
    required this.total,
    this.notes,
    this.trackingNumber,
    required this.createdAt,
    this.updatedAt,
    this.shippedAt,
    this.deliveredAt,
    this.paymentMethod,
    this.paymentStatus,
    this.couponCode,
  });

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  /// Getter para texto del estado
  String get statusText {
    switch (status) {
      case OrderStatus.pending:
        return 'Pendiente';
      case OrderStatus.processing:
        return 'Procesando';
      case OrderStatus.shipped:
        return 'Enviado';
      case OrderStatus.delivered:
        return 'Entregado';
      case OrderStatus.cancelled:
        return 'Cancelado';
      default:
        return 'Desconocido';
    }
  }

  /// Getter para texto del estado de pago
  String get paymentStatusText {
    switch (paymentStatus?.toLowerCase()) {
      case 'paid':
        return 'Pagado';
      case 'pending':
        return 'Pendiente';
      case 'failed':
        return 'Fallido';
      case 'refunded':
        return 'Reembolsado';
      default:
        return paymentStatus ?? 'Desconocido';
    }
  }

  /// Alias para shippingCost
  double get shipping => shippingCost;

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      orderNumber: json['order_number'],
      userId: json['user_id'],
      userEmail: json['user_email'],
      userName: json['user_name'],
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      shippingAddress: ShippingAddress.fromJson(json['shipping_address'] ?? {}),
      status: OrderStatus.fromString(json['status']),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      shippingCost: (json['shipping_cost'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'],
      trackingNumber: json['tracking_number'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? ''),
      shippedAt: DateTime.tryParse(json['shipped_at'] ?? ''),
      deliveredAt: DateTime.tryParse(json['delivered_at'] ?? ''),
      paymentMethod: json['payment_method'],
      paymentStatus: json['payment_status'],
      couponCode: json['coupon_code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'user_id': userId,
      'user_email': userEmail,
      'user_name': userName,
      'items': items.map((e) => e.toJson()).toList(),
      'shipping_address': shippingAddress.toJson(),
      'status': status.value,
      'subtotal': subtotal,
      'shipping_cost': shippingCost,
      'discount': discount,
      'total': total,
      'notes': notes,
      'tracking_number': trackingNumber,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'shipped_at': shippedAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'coupon_code': couponCode,
    };
  }

  Order copyWith({
    String? id,
    String? orderNumber,
    String? userId,
    String? userEmail,
    String? userName,
    List<OrderItem>? items,
    ShippingAddress? shippingAddress,
    OrderStatus? status,
    double? subtotal,
    double? shippingCost,
    double? discount,
    double? total,
    String? notes,
    String? trackingNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? shippedAt,
    DateTime? deliveredAt,
    String? paymentMethod,
    String? paymentStatus,
    String? couponCode,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      items: items ?? this.items,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      shippingCost: shippingCost ?? this.shippingCost,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      notes: notes ?? this.notes,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      shippedAt: shippedAt ?? this.shippedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      couponCode: couponCode ?? this.couponCode,
    );
  }
}
