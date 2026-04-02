import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fixy_home_service/models/product_model.dart';

class OrderService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================
  // CREAR ORDEN
  // ============================================

  /// Crear una nueva orden desde el carrito
  Future<String> createOrder({
    required List<CartItemModel> items,
    required Map<String, dynamic> shippingAddress,
    String? notes,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Calcular montos
      final subtotal = items.fold<double>(
        0.0,
        (sum, item) => sum + (item.product.price * item.quantity),
      );
      final shipping = subtotal >= 100 ? 0.0 : 10.0;
      final total = subtotal + shipping;

      print('🛒 Creando orden...');
      print('   Subtotal: S/$subtotal');
      print('   Envío: S/$shipping');
      print('   Total: S/$total');

      // Crear la orden
      final orderData = {
        'user_id': user.id,
        'status': 'pending',
        'subtotal': subtotal,
        'shipping': shipping,
        'discount': 0.0,
        'total': total,
        'shipping_address': shippingAddress,
        'payment_method': 'pending',
        'payment_status': 'pending',
        if (notes != null) 'notes': notes,
      };

      final orderResponse =
          await _supabase.from('orders').insert(orderData).select().single();

      final orderId = orderResponse['id'] as String;
      final orderNumber = orderResponse['order_number'] as String;

      print('✅ Orden creada: $orderNumber');

      // Crear los items de la orden
      final orderItems = items.map((item) {
        return {
          'order_id': orderId,
          'product_id': item.product.id,
          'product_name': item.product.name,
          'product_brand': item.product.brand,
          'product_image': item.product.images.first,
          'quantity': item.quantity,
          'unit_price': item.product.price,
          'total_price': item.product.price * item.quantity,
        };
      }).toList();

      await _supabase.from('order_items').insert(orderItems);

      print('✅ ${orderItems.length} items agregados a la orden');

      // TODO: Reducir stock de productos
      // Por ahora lo dejamos comentado para no afectar la demo
      // for (var item in items) {
      //   await _reduceProductStock(item.product.id, item.quantity);
      // }

      return orderId;
    } catch (e) {
      print('❌ Error creando orden: $e');
      rethrow;
    }
  }

  // Reducir stock de un producto
  Future<void> _reduceProductStock(String productId, int quantity) async {
    try {
      // Obtener stock actual
      final product = await _supabase
          .from('products')
          .select('stock')
          .eq('id', productId)
          .single();

      final currentStock = product['stock'] as int;
      final newStock = currentStock - quantity;

      if (newStock < 0) {
        throw Exception('Stock insuficiente para producto $productId');
      }

      // Actualizar stock
      await _supabase
          .from('products')
          .update({'stock': newStock}).eq('id', productId);

      print('✅ Stock actualizado: $productId → $newStock');
    } catch (e) {
      print('❌ Error reduciendo stock: $e');
      rethrow;
    }
  }

  // ============================================
  // OBTENER ÓRDENES
  // ============================================

  /// Obtener órdenes del usuario actual
  Future<List<OrderModel>> getUserOrders() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      print('📦 Obteniendo órdenes del usuario...');

      final response = await _supabase
          .from('orders')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final orders =
          (response as List).map((json) => OrderModel.fromJson(json)).toList();

      // Cargar items de cada orden
      for (var order in orders) {
        order.items = await getOrderItems(order.id);
      }

      print('✅ ${orders.length} órdenes cargadas');
      return orders;
    } catch (e) {
      print('❌ Error obteniendo órdenes: $e');
      return [];
    }
  }

  /// Obtener orden por ID
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final response =
          await _supabase.from('orders').select().eq('id', orderId).single();

      final order = OrderModel.fromJson(response);
      order.items = await getOrderItems(orderId);

      return order;
    } catch (e) {
      print('❌ Error obteniendo orden $orderId: $e');
      return null;
    }
  }

  /// Obtener items de una orden
  Future<List<OrderItemModel>> getOrderItems(String orderId) async {
    try {
      final response =
          await _supabase.from('order_items').select().eq('order_id', orderId);

      return (response as List)
          .map((json) => OrderItemModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error obteniendo items de orden $orderId: $e');
      return [];
    }
  }

  // ============================================
  // ACTUALIZAR ORDEN
  // ============================================

  /// Actualizar estado de la orden
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _supabase
          .from('orders')
          .update({'status': newStatus}).eq('id', orderId);

      print('✅ Estado de orden $orderId actualizado a: $newStatus');
    } catch (e) {
      print('❌ Error actualizando estado de orden: $e');
      rethrow;
    }
  }

  /// Actualizar estado de pago
  Future<void> updatePaymentStatus(String orderId, String paymentStatus) async {
    try {
      await _supabase
          .from('orders')
          .update({'payment_status': paymentStatus}).eq('id', orderId);

      print('✅ Estado de pago actualizado: $paymentStatus');
    } catch (e) {
      print('❌ Error actualizando estado de pago: $e');
      rethrow;
    }
  }

  /// Cancelar orden
  Future<void> cancelOrder(String orderId) async {
    try {
      await updateOrderStatus(orderId, 'cancelled');

      // TODO: Restaurar stock de productos

      print('✅ Orden cancelada: $orderId');
    } catch (e) {
      print('❌ Error cancelando orden: $e');
      rethrow;
    }
  }

  /// Obtener estadísticas de pedidos por rango de fechas
  Future<Map<String, dynamic>> getOrderStats({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _supabase
          .from('orders')
          .select()
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      final orders = (response as List);
      double totalSales = 0;
      for (final order in orders) {
        totalSales += (order['total'] as num?)?.toDouble() ?? 0;
      }

      return {
        'total_orders': orders.length,
        'total_sales': totalSales,
      };
    } catch (e) {
      print('❌ Error obteniendo estadísticas: $e');
      return {'total_orders': 0, 'total_sales': 0.0};
    }
  }

  /// Obtener pedidos recientes
  Future<List<OrderModel>> getRecentOrders({int limit = 5}) async {
    try {
      final response = await _supabase
          .from('orders')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => OrderModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error obteniendo pedidos recientes: $e');
      return [];
    }
  }
}

// ============================================
// MODELOS
// ============================================

class OrderModel {
  final String id;
  final String orderNumber;
  final String userId;
  final String? userName;
  final String? userEmail;
  final String status;
  final double subtotal;
  final double shipping;
  final double discount;
  final double total;
  final Map<String, dynamic> shippingAddress;
  final String paymentMethod;
  final String paymentStatus;
  final String? trackingNumber;
  final DateTime? estimatedDelivery;
  final DateTime? deliveredAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  List<OrderItemModel> items = [];

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.userId,
    this.userName,
    this.userEmail,
    required this.status,
    required this.subtotal,
    required this.shipping,
    required this.discount,
    required this.total,
    required this.shippingAddress,
    required this.paymentMethod,
    required this.paymentStatus,
    this.trackingNumber,
    this.estimatedDelivery,
    this.deliveredAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      orderNumber: json['order_number'],
      userId: json['user_id'],
      userName: json['user_name'],
      userEmail: json['user_email'],
      status: json['status'],
      subtotal: (json['subtotal'] as num).toDouble(),
      shipping: (json['shipping'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      shippingAddress: json['shipping_address'] as Map<String, dynamic>,
      paymentMethod: json['payment_method'],
      paymentStatus: json['payment_status'],
      trackingNumber: json['tracking_number'],
      estimatedDelivery: json['estimated_delivery'] != null
          ? DateTime.parse(json['estimated_delivery'])
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'])
          : null,
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  String get statusText {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'processing':
        return 'Procesando';
      case 'confirmed':
        return 'Confirmado';
      case 'shipped':
        return 'Enviado';
      case 'delivered':
        return 'Entregado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }

  String get paymentStatusText {
    switch (paymentStatus) {
      case 'pending':
        return 'Pendiente';
      case 'processing':
        return 'Procesando';
      case 'completed':
        return 'Completado';
      case 'failed':
        return 'Fallido';
      case 'refunded':
        return 'Reembolsado';
      default:
        return paymentStatus;
    }
  }

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
}

class OrderItemModel {
  final String id;
  final String orderId;
  final String? productId;
  final String productName;
  final String productBrand;
  final String productImage;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final DateTime createdAt;

  OrderItemModel({
    required this.id,
    required this.orderId,
    this.productId,
    required this.productName,
    required this.productBrand,
    required this.productImage,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.createdAt,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'],
      orderId: json['order_id'],
      productId: json['product_id'],
      productName: json['product_name'],
      productBrand: json['product_brand'],
      productImage: json['product_image'],
      quantity: json['quantity'],
      unitPrice: (json['unit_price'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
