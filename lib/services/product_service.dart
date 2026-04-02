import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fixy_home_service/models/product_model.dart';

// Callback para notificar cambios en productos
typedef ProductChangeCallback = void Function(ProductChangeEvent event);

enum ProductChangeType { insert, update, delete }

class ProductChangeEvent {
  final ProductChangeType type;
  final ProductModel? product;
  final String? productId;

  ProductChangeEvent({
    required this.type,
    this.product,
    this.productId,
  });
}

class ProductService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Suscripción realtime
  RealtimeChannel? _productsChannel;
  final List<ProductChangeCallback> _changeCallbacks = [];

  // Cache en memoria para performance
  List<ProductModel>? _cachedProducts;
  List<ProductCategoryModel>? _cachedCategories;
  DateTime? _lastFetch;

  // Singleton pattern para compartir estado
  static final ProductService _instance = ProductService._internal();
  factory ProductService() => _instance;
  ProductService._internal();

  // Cache válido por 30 segundos (para ver cambios rápido)
  static const _cacheDuration = Duration(seconds: 30);

  bool get _isCacheValid {
    if (_lastFetch == null) return false;
    return DateTime.now().difference(_lastFetch!) < _cacheDuration;
  }

  // ============================================
  // REALTIME - Sincronización en tiempo real
  // ============================================

  /// Suscribirse a cambios en productos
  void subscribeToChanges(ProductChangeCallback callback) {
    _changeCallbacks.add(callback);

    // Iniciar canal realtime si no está activo
    if (_productsChannel == null) {
      _startRealtimeSubscription();
    }
  }

  /// Cancelar suscripción a cambios
  void unsubscribeFromChanges(ProductChangeCallback callback) {
    _changeCallbacks.remove(callback);

    // Si no hay más listeners, detener la suscripción
    if (_changeCallbacks.isEmpty) {
      _stopRealtimeSubscription();
    }
  }

  void _startRealtimeSubscription() {
    print('🔴 Iniciando suscripción realtime a productos...');

    _productsChannel = _supabase
        .channel('products_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'products',
          callback: (payload) {
            print('📡 Cambio detectado en productos: ${payload.eventType}');

            // Limpiar cache para forzar recarga
            clearCache();

            // Notificar a todos los listeners
            ProductChangeType type;
            switch (payload.eventType) {
              case PostgresChangeEvent.insert:
                type = ProductChangeType.insert;
                break;
              case PostgresChangeEvent.update:
                type = ProductChangeType.update;
                break;
              case PostgresChangeEvent.delete:
                type = ProductChangeType.delete;
                break;
              default:
                type = ProductChangeType.update;
            }

            final event = ProductChangeEvent(
              type: type,
              product: ProductModel.fromJson(payload.newRecord),
              productId: payload.oldRecord['id']?.toString() ??
                  payload.newRecord['id']?.toString(),
            );

            for (final callback in _changeCallbacks) {
              callback(event);
            }
          },
        )
        .subscribe((status, error) {
      if (error != null) {
        print('❌ Error en suscripción realtime: $error');
      } else {
        print('✅ Suscripción realtime activa: $status');
      }
    });
  }

  void _stopRealtimeSubscription() {
    print('🛑 Deteniendo suscripción realtime...');
    _productsChannel?.unsubscribe();
    _productsChannel = null;
  }

  // ============================================
  // PRODUCTOS
  // ============================================

  /// Obtener todos los productos
  Future<List<ProductModel>> getAllProducts({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid && _cachedProducts != null) {
      return _cachedProducts!;
    }

    try {
      print('🛒 Obteniendo productos desde Supabase...');

      final response = await _supabase
          .from('products')
          .select()
          .order('created_at', ascending: false);

      _cachedProducts = (response as List)
          .map((json) => ProductModel.fromJson(json))
          .toList();

      _lastFetch = DateTime.now();

      print('✅ ${_cachedProducts!.length} productos cargados');
      return _cachedProducts!;
    } catch (e) {
      print('❌ Error obteniendo productos: $e');

      // Si hay error, devolver cache si existe
      if (_cachedProducts != null) {
        print('⚠️ Usando cache de productos');
        return _cachedProducts!;
      }

      rethrow;
    }
  }

  /// Obtener producto por ID
  Future<ProductModel?> getProductById(String id) async {
    try {
      // Buscar primero en cache
      if (_cachedProducts != null) {
        try {
          return _cachedProducts!.firstWhere((p) => p.id == id);
        } catch (_) {}
      }

      // Si no está en cache, buscar en DB
      final response =
          await _supabase.from('products').select().eq('id', id).single();

      return ProductModel.fromJson(response);
    } catch (e) {
      print('❌ Error obteniendo producto $id: $e');
      return null;
    }
  }

  /// Obtener productos destacados
  Future<List<ProductModel>> getFeaturedProducts() async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('is_featured', true)
          .order('created_at', ascending: false)
          .limit(10);

      return (response as List)
          .map((json) => ProductModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error obteniendo productos destacados: $e');

      // Fallback: filtrar del cache
      if (_cachedProducts != null) {
        return _cachedProducts!.where((p) => p.isFeatured).take(10).toList();
      }

      return [];
    }
  }

  /// Obtener productos en oferta
  Future<List<ProductModel>> getOnSaleProducts() async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('is_on_sale', true)
          .order('created_at', ascending: false)
          .limit(10);

      return (response as List)
          .map((json) => ProductModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error obteniendo productos en oferta: $e');

      // Fallback: filtrar del cache
      if (_cachedProducts != null) {
        return _cachedProducts!.where((p) => p.isOnSale).take(10).toList();
      }

      return [];
    }
  }

  /// Obtener productos nuevos
  Future<List<ProductModel>> getNewProducts() async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('is_new', true)
          .order('created_at', ascending: false)
          .limit(10);

      return (response as List)
          .map((json) => ProductModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error obteniendo productos nuevos: $e');
      return [];
    }
  }

  /// Obtener productos más vendidos
  Future<List<ProductModel>> getBestSellers() async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('is_best_seller', true)
          .order('review_count', ascending: false)
          .limit(10);

      return (response as List)
          .map((json) => ProductModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error obteniendo best sellers: $e');
      return [];
    }
  }

  /// Obtener productos por categoría
  Future<List<ProductModel>> getProductsByCategory(String categoryId) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('category_id', categoryId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ProductModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error obteniendo productos de categoría $categoryId: $e');

      // Fallback: filtrar del cache
      if (_cachedProducts != null) {
        return _cachedProducts!.where((p) => p.category == categoryId).toList();
      }

      return [];
    }
  }

  /// Buscar productos por nombre o descripción
  Future<List<ProductModel>> searchProducts(String query) async {
    if (query.isEmpty) return await getAllProducts();

    try {
      final lowerQuery = query.toLowerCase();

      final response = await _supabase
          .from('products')
          .select()
          .or('name.ilike.%$lowerQuery%,description.ilike.%$lowerQuery%,brand.ilike.%$lowerQuery%')
          .order('rating', ascending: false);

      return (response as List)
          .map((json) => ProductModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error buscando productos: $e');

      // Fallback: búsqueda local en cache
      if (_cachedProducts != null) {
        final lowerQuery = query.toLowerCase();
        return _cachedProducts!.where((p) {
          return p.name.toLowerCase().contains(lowerQuery) ||
              p.description.toLowerCase().contains(lowerQuery) ||
              p.brand.toLowerCase().contains(lowerQuery);
        }).toList();
      }

      return [];
    }
  }

  /// Actualizar stock de un producto
  Future<void> updateStock(String productId, int newStock) async {
    try {
      await _supabase
          .from('products')
          .update({'stock': newStock}).eq('id', productId);

      print('✅ Stock actualizado para producto $productId: $newStock');

      // Actualizar cache si existe
      if (_cachedProducts != null) {
        final index = _cachedProducts!.indexWhere((p) => p.id == productId);
        if (index >= 0) {
          // Recrear el producto con nuevo stock
          final oldProduct = _cachedProducts![index];
          _cachedProducts![index] = ProductModel(
            id: oldProduct.id,
            name: oldProduct.name,
            description: oldProduct.description,
            price: oldProduct.price,
            originalPrice: oldProduct.originalPrice,
            category: oldProduct.category,
            images: oldProduct.images,
            brand: oldProduct.brand,
            stock: newStock,
            rating: oldProduct.rating,
            reviewCount: oldProduct.reviewCount,
            specifications: oldProduct.specifications,
            isFeatured: oldProduct.isFeatured,
            isOnSale: oldProduct.isOnSale,
            unit: oldProduct.unit,
            isNew: oldProduct.isNew,
            isBestSeller: oldProduct.isBestSeller,
            createdAt: oldProduct.createdAt,
          );
        }
      }
    } catch (e) {
      print('❌ Error actualizando stock: $e');
      rethrow;
    }
  }

  /// Reducir stock después de una compra
  Future<void> reduceStock(String productId, int quantity) async {
    try {
      // Obtener stock actual
      final product = await getProductById(productId);
      if (product == null) {
        throw Exception('Producto no encontrado');
      }

      final newStock = product.stock - quantity;
      if (newStock < 0) {
        throw Exception('Stock insuficiente');
      }

      await updateStock(productId, newStock);
    } catch (e) {
      print('❌ Error reduciendo stock: $e');
      rethrow;
    }
  }

  // ============================================
  // CATEGORÍAS
  // ============================================

  /// Obtener todas las categorías
  Future<List<ProductCategoryModel>> getProductCategories(
      {bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedCategories != null) {
      return _cachedCategories!;
    }

    try {
      print('📂 Obteniendo categorías desde Supabase...');

      final response =
          await _supabase.from('product_categories').select().order('name');

      _cachedCategories = (response as List)
          .map((json) => ProductCategoryModel(
                id: json['id'],
                name: json['name'],
                icon: json['icon'] ?? '📦',
                color: json['color'] ?? '#0066FF',
                productCount: json['product_count'] ?? 0,
                imageUrl: json['image_url'],
              ))
          .toList();

      print('✅ ${_cachedCategories!.length} categorías cargadas');
      return _cachedCategories!;
    } catch (e) {
      print('❌ Error obteniendo categorías: $e');

      if (_cachedCategories != null) {
        return _cachedCategories!;
      }

      rethrow;
    }
  }

  /// Limpiar cache
  void clearCache() {
    _cachedProducts = null;
    _cachedCategories = null;
    _lastFetch = null;
    print('🗑️ Cache de productos limpiado');
  }

  Future<ProductModel> createProduct(ProductModel product) async {
    try {
      final data = product.toJson();
      data.remove('id');
      final response =
          await _supabase.from('products').insert(data).select().single();
      clearCache();
      return ProductModel.fromJson(response);
    } catch (e) {
      print('❌ Error creando producto: $e');
      rethrow;
    }
  }

  Future<ProductModel> updateProduct(ProductModel product) async {
    try {
      final response = await _supabase
          .from('products')
          .update(product.toJson())
          .eq('id', product.id)
          .select()
          .single();
      clearCache();
      return ProductModel.fromJson(response);
    } catch (e) {
      print('❌ Error actualizando producto: $e');
      rethrow;
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _supabase.from('products').delete().eq('id', productId);
      clearCache();
    } catch (e) {
      print('❌ Error eliminando producto: $e');
      rethrow;
    }
  }

  Future<ProductCategoryModel> createCategory(
      ProductCategoryModel category) async {
    try {
      final response = await _supabase
          .from('product_categories')
          .insert({
            'name': category.name,
            'icon': category.icon,
            'color': category.color,
            'image_url': category.imageUrl,
          })
          .select()
          .single();
      _cachedCategories = null;
      return ProductCategoryModel(
        id: response['id'],
        name: response['name'],
        icon: response['icon'] ?? '📦',
        color: response['color'] ?? '#0066FF',
        productCount: response['product_count'] ?? 0,
        imageUrl: response['image_url'],
      );
    } catch (e) {
      print('❌ Error creando categoría: $e');
      rethrow;
    }
  }

  Future<ProductCategoryModel> updateCategory(
      ProductCategoryModel category) async {
    try {
      final response = await _supabase
          .from('product_categories')
          .update({
            'name': category.name,
            'icon': category.icon,
            'color': category.color,
            'image_url': category.imageUrl,
          })
          .eq('id', category.id)
          .select()
          .single();
      _cachedCategories = null;
      return ProductCategoryModel(
        id: response['id'],
        name: response['name'],
        icon: response['icon'] ?? '📦',
        color: response['color'] ?? '#0066FF',
        productCount: response['product_count'] ?? 0,
        imageUrl: response['image_url'],
      );
    } catch (e) {
      print('❌ Error actualizando categoría: $e');
      rethrow;
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await _supabase.from('product_categories').delete().eq('id', categoryId);
      _cachedCategories = null;
    } catch (e) {
      print('❌ Error eliminando categoría: $e');
      rethrow;
    }
  }
}
