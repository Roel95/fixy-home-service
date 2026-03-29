import 'package:fixy_home_service/models/product_model.dart';
import 'package:fixy_home_service/services/product_service.dart';

/// Repository que ahora usa ProductService de Supabase
/// Mantiene la misma interfaz para compatibilidad con código existente
class ProductRepository {
  final ProductService _productService = ProductService();

  // ============================================
  // CATEGORÍAS - MÉTODOS ADMIN
  // ============================================

  Future<List<ProductCategoryModel>> getProductCategories(
      {bool forceRefresh = false}) async {
    return await _productService.getProductCategories(
        forceRefresh: forceRefresh);
  }

  /// Obtener todas las categorías (alias para admin)
  Future<List<ProductCategoryModel>> getCategories() async {
    return await _productService.getProductCategories();
  }

  /// Crear nueva categoría
  Future<ProductCategoryModel> createCategory(
      ProductCategoryModel category) async {
    return await _productService.createCategory(category);
  }

  /// Actualizar categoría
  Future<ProductCategoryModel> updateCategory(
      ProductCategoryModel category) async {
    return await _productService.updateCategory(category);
  }

  /// Eliminar categoría
  Future<void> deleteCategory(String categoryId) async {
    return await _productService.deleteCategory(categoryId);
  }

  // ============================================
  // PRODUCTOS - MÉTODOS ADMIN
  // ============================================

  Future<List<ProductModel>> getAllProducts({bool forceRefresh = false}) async {
    return await _productService.getAllProducts(forceRefresh: forceRefresh);
  }

  /// Obtener todos los productos (alias para admin)
  Future<List<ProductModel>> getProducts() async {
    return await _productService.getAllProducts();
  }

  /// Crear nuevo producto
  Future<ProductModel> createProduct(ProductModel product) async {
    return await _productService.createProduct(product);
  }

  /// Actualizar producto
  Future<ProductModel> updateProduct(ProductModel product) async {
    return await _productService.updateProduct(product);
  }

  /// Eliminar producto
  Future<void> deleteProduct(String productId) async {
    return await _productService.deleteProduct(productId);
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
