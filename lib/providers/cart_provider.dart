import 'package:flutter/foundation.dart';
import 'package:fixy_home_service/models/product_model.dart';
import 'package:fixy_home_service/services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  final CartService _cartService = CartService();

  List<CartItemModel> _items = [];
  bool _isLoading = false;
  bool _isInitialized = false;

  List<CartItemModel> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  CartModel get cart => CartModel(items: _items);

  Future<void> loadCart({bool forceRefresh = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      final items = await _cartService.getCartItems(forceRefresh: forceRefresh);
      _items = items;
      _isInitialized = true;
    } catch (e) {
      print('❌ [CartProvider] Error cargando carrito: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addToCart(ProductModel product, {int quantity = 1}) async {
    try {
      final existingIndex =
          _items.indexWhere((item) => item.product.id == product.id);
      if (existingIndex >= 0) {
        _items[existingIndex].quantity += quantity;
      } else {
        _items.add(CartItemModel(product: product, quantity: quantity));
      }
      notifyListeners();
      await _cartService.addToCart(product, quantity: quantity);
    } catch (e) {
      await loadCart(forceRefresh: true);
      rethrow;
    }
  }

  Future<void> removeFromCart(String productId) async {
    try {
      _items.removeWhere((item) => item.product.id == productId);
      notifyListeners();
      await _cartService.removeFromCart(productId);
    } catch (e) {
      await loadCart(forceRefresh: true);
      rethrow;
    }
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    if (quantity <= 0) return removeFromCart(productId);
    try {
      final index = _items.indexWhere((item) => item.product.id == productId);
      if (index >= 0) {
        _items[index].quantity = quantity;
        notifyListeners();
      }
      await _cartService.updateQuantity(productId, quantity);
    } catch (e) {
      await loadCart(forceRefresh: true);
      rethrow;
    }
  }

  Future<void> clearCart() async {
    try {
      _items.clear();
      notifyListeners();
      await _cartService.clearCart();
    } catch (e) {
      await loadCart(forceRefresh: true);
      rethrow;
    }
  }

  bool isInCart(String productId) =>
      _items.any((item) => item.product.id == productId);

  int getQuantity(String productId) {
    try {
      return _items.firstWhere((item) => item.product.id == productId).quantity;
    } catch (_) {
      return 0;
    }
  }

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  Future<void> syncLocalCart(List<CartItemModel> localItems) async {
    if (localItems.isEmpty) return;
    try {
      await _cartService.syncLocalCart(localItems);
      await loadCart(forceRefresh: true);
    } catch (e) {
      print('❌ [CartProvider] Error sincronizando carrito: $e');
    }
  }

  void clearCache() {
    _items.clear();
    _isInitialized = false;
    _cartService.clearCache();
    notifyListeners();
  }

  Future<void> refresh() async => await loadCart(forceRefresh: true);
}
