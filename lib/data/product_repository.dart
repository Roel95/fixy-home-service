import 'package:fixy_home_service/models/product_model.dart';
import 'package:fixy_home_service/services/product_service.dart';

/// Repository que ahora usa ProductService de Supabase
/// Mantiene la misma interfaz para compatibilidad con código existente
class ProductRepository {
  final ProductService _productService = ProductService();

  // ============================================
  // CATEGORÍAS
  // ============================================

  Future<List<ProductCategoryModel>> getProductCategories(
      {bool forceRefresh = false}) async {
    return await _productService.getProductCategories(
        forceRefresh: forceRefresh);
  }

  // ============================================
  // PRODUCTOS
  // ============================================

  Future<List<ProductModel>> getAllProducts({bool forceRefresh = false}) async {
    return await _productService.getAllProducts(forceRefresh: forceRefresh);
  }

  Future<List<ProductModel>> getFeaturedProducts(
      {bool forceRefresh = false}) async {
    // Si forceRefresh=true, limpiar cache primero
    if (forceRefresh) {
      _productService.clearCache();
    }
    return await _productService.getFeaturedProducts();
  }

  Future<List<ProductModel>> getOnSaleProducts(
      {bool forceRefresh = false}) async {
    if (forceRefresh) {
      _productService.clearCache();
    }
    return await _productService.getOnSaleProducts();
  }

  Future<List<ProductModel>> getProductsByCategory(String categoryId) async {
    return await _productService.getProductsByCategory(categoryId);
  }

  Future<List<ProductModel>> searchProducts(String query) async {
    return await _productService.searchProducts(query);
  }

  Future<ProductModel?> getProductById(String id) async {
    return await _productService.getProductById(id);
  }

  // ============================================
  // UTILIDADES
  // ============================================

  void clearCache() {
    _productService.clearCache();
  }
}
