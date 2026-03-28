import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fixy_home_service/models/product_model.dart';

class CartService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Cache del carrito actual
  String? _cartId;
  List<CartItemModel>? _cachedItems;

  // ============================================
  // OBTENER O CREAR CARRITO
  // ============================================

  /// Obtener el carrito del usuario actual (o crearlo si no existe)
  Future<String> _getOrCreateCart() async {
    if (_cartId != null) return _cartId!;

    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado');
    }

    try {
      // Buscar carrito existente
      final response = await _supabase
          .from('carts')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null) {
        _cartId = response['id'] as String;
        print('🛒 Carrito encontrado: $_cartId');
        return _cartId!;
      }

      // Crear nuevo carrito
      final newCart = await _supabase
          .from('carts')
          .insert({'user_id': user.id})
          .select('id')
          .single();

      _cartId = newCart['id'] as String;
      print('🛒 Nuevo carrito creado: $_cartId');
      return _cartId!;
    } catch (e) {
      print('❌ Error obteniendo/creando carrito: $e');
      rethrow;
    }
  }

  // ============================================
  // OBTENER ITEMS DEL CARRITO
  // ============================================

  /// Obtener todos los items del carrito con información de productos
  Future<List<CartItemModel>> getCartItems({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedItems != null) {
      return _cachedItems!;
    }

    try {
      final cartId = await _getOrCreateCart();

      print('🛒 Cargando items del carrito...');

      // Obtener items del carrito con JOIN a productos
      final response = await _supabase.from('cart_items').select('''
            id,
            quantity,
            created_at,
            products:product_id (
              id,
              name,
              description,
              price,
              original_price,
              category_id,
              images,
              brand,
              stock,
              rating,
              review_count,
              specifications,
              is_featured,
              is_on_sale,
              unit,
              is_new,
              is_best_seller,
              created_at
            )
          ''').eq('cart_id', cartId).order('created_at', ascending: false);

      final items = (response as List)
          .map((item) {
            final productData = item['products'];
            if (productData == null) {
              // Producto eliminado, saltar este item
              return null;
            }

            final product = ProductModel.fromJson(productData);
            return CartItemModel(
              product: product,
              quantity: item['quantity'] as int,
            );
          })
          .whereType<CartItemModel>()
          .toList();

      _cachedItems = items;
      print('✅ ${items.length} items cargados del carrito');

      return items;
    } catch (e) {
      print('❌ Error obteniendo items del carrito: $e');

      // Si hay error, devolver cache si existe
      if (_cachedItems != null) {
        print('⚠️ Usando cache del carrito');
        return _cachedItems!;
      }

      return [];
    }
  }

  // ============================================
  // AGREGAR AL CARRITO
  // ============================================

  /// Agregar producto al carrito (o incrementar cantidad si ya existe)
  Future<void> addToCart(ProductModel product, {int quantity = 1}) async {
    try {
      final cartId = await _getOrCreateCart();

      print('🛒 Agregando ${product.name} al carrito (cantidad: $quantity)...');

      // Verificar si el producto ya está en el carrito
      final existing = await _supabase
          .from('cart_items')
          .select('id, quantity')
          .eq('cart_id', cartId)
          .eq('product_id', product.id)
          .maybeSingle();

      if (existing != null) {
        // Actualizar cantidad existente
        final newQuantity = (existing['quantity'] as int) + quantity;

        await _supabase
            .from('cart_items')
            .update({'quantity': newQuantity}).eq('id', existing['id']);

        print('✅ Cantidad actualizada a: $newQuantity');
      } else {
        // Insertar nuevo item
        await _supabase.from('cart_items').insert({
          'cart_id': cartId,
          'product_id': product.id,
          'quantity': quantity,
        });

        print('✅ Producto agregado al carrito');
      }

      // Invalidar cache
      _cachedItems = null;
    } catch (e) {
      print('❌ Error agregando al carrito: $e');
      rethrow;
    }
  }

  // ============================================
  // ACTUALIZAR CANTIDAD
  // ============================================

  /// Actualizar la cantidad de un producto en el carrito
  Future<void> updateQuantity(String productId, int quantity) async {
    if (quantity <= 0) {
      return removeFromCart(productId);
    }

    try {
      final cartId = await _getOrCreateCart();

      print('🛒 Actualizando cantidad de $productId a $quantity...');

      await _supabase
          .from('cart_items')
          .update({'quantity': quantity})
          .eq('cart_id', cartId)
          .eq('product_id', productId);

      print('✅ Cantidad actualizada');

      // Invalidar cache
      _cachedItems = null;
    } catch (e) {
      print('❌ Error actualizando cantidad: $e');
      rethrow;
    }
  }

  // ============================================
  // ELIMINAR DEL CARRITO
  // ============================================

  /// Eliminar un producto del carrito
  Future<void> removeFromCart(String productId) async {
    try {
      final cartId = await _getOrCreateCart();

      print('🛒 Eliminando producto $productId del carrito...');

      await _supabase
          .from('cart_items')
          .delete()
          .eq('cart_id', cartId)
          .eq('product_id', productId);

      print('✅ Producto eliminado del carrito');

      // Invalidar cache
      _cachedItems = null;
    } catch (e) {
      print('❌ Error eliminando del carrito: $e');
      rethrow;
    }
  }

  // ============================================
  // VACIAR CARRITO
  // ============================================

  /// Vaciar todos los items del carrito
  Future<void> clearCart() async {
    try {
      final cartId = await _getOrCreateCart();

      print('🛒 Vaciando carrito...');

      await _supabase.from('cart_items').delete().eq('cart_id', cartId);

      print('✅ Carrito vaciado');

      // Invalidar cache
      _cachedItems = null;
    } catch (e) {
      print('❌ Error vaciando carrito: $e');
      rethrow;
    }
  }

  // ============================================
  // VERIFICAR SI ESTÁ EN CARRITO
  // ============================================

  /// Verificar si un producto está en el carrito
  Future<bool> isInCart(String productId) async {
    try {
      final cartId = await _getOrCreateCart();

      final response = await _supabase
          .from('cart_items')
          .select('id')
          .eq('cart_id', cartId)
          .eq('product_id', productId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('❌ Error verificando si está en carrito: $e');
      return false;
    }
  }

  /// Obtener la cantidad de un producto en el carrito
  Future<int> getQuantity(String productId) async {
    try {
      final cartId = await _getOrCreateCart();

      final response = await _supabase
          .from('cart_items')
          .select('quantity')
          .eq('cart_id', cartId)
          .eq('product_id', productId)
          .maybeSingle();

      if (response == null) return 0;

      return response['quantity'] as int;
    } catch (e) {
      print('❌ Error obteniendo cantidad: $e');
      return 0;
    }
  }

  // ============================================
  // SINCRONIZAR CARRITO LOCAL CON SUPABASE
  // ============================================

  /// Sincronizar items locales con Supabase (útil al iniciar sesión)
  Future<void> syncLocalCart(List<CartItemModel> localItems) async {
    if (localItems.isEmpty) return;

    try {
      print(
          '🔄 Sincronizando ${localItems.length} items locales con Supabase...');

      for (var item in localItems) {
        await addToCart(item.product, quantity: item.quantity);
      }

      print('✅ Sincronización completada');
    } catch (e) {
      print('❌ Error sincronizando carrito local: $e');
    }
  }

  /// Limpiar cache (útil al cerrar sesión)
  void clearCache() {
    _cartId = null;
    _cachedItems = null;
    print('🗑️ Cache del carrito limpiado');
  }
}
