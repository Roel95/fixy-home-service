import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixy_home_service/data/product_repository.dart';
import 'package:fixy_home_service/models/product_model.dart';
import 'package:fixy_home_service/providers/cart_provider.dart';
import 'package:fixy_home_service/screens/shop/product_detail_screen.dart';
import 'package:fixy_home_service/screens/shop/cart_screen.dart';
import 'package:fixy_home_service/theme/app_theme.dart';
import 'package:fixy_home_service/utils/page_transitions.dart';
import 'package:fixy_home_service/widgets/cart_badge.dart';
import 'package:fixy_home_service/widgets/advanced_filters_sheet.dart';
import 'package:fixy_home_service/services/product_service.dart';

class AllProductsScreen extends StatefulWidget {
  const AllProductsScreen({super.key});

  @override
  State<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends State<AllProductsScreen> {
  late ProductRepository _repository;
  late ProductService _productService;
  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  String _sortBy = 'featured';
  ProductFilters _filters = ProductFilters();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _repository = ProductRepository();
    _productService = ProductService();
    _loadProducts(forceRefresh: true);

    // Suscribirse a cambios en tiempo real
    _productService.subscribeToChanges(_onProductChanged);
  }

  Future<void> _loadProducts({bool forceRefresh = false}) async {
    try {
      final products =
          await _repository.getAllProducts(forceRefresh: forceRefresh);
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
          _applyFiltersAndSorting();
        });
      }
    } catch (e) {
      print('❌ Error cargando productos: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshProducts() async {
    await Future.delayed(const Duration(milliseconds: 800));
    _loadProducts(forceRefresh: true);
  }

  void _onProductChanged(ProductChangeEvent event) {
    print('🔄 Producto cambiado en AllProductsScreen: ${event.type}');
    if (mounted) {
      _loadProducts(forceRefresh: true);
    }
  }

  @override
  void dispose() {
    _productService.unsubscribeFromChanges(_onProductChanged);
    super.dispose();
  }

  void _applyFiltersAndSorting() {
    setState(() {
      // Apply filters
      _filteredProducts = _products.where((p) {
        if (p.price < _filters.minPrice || p.price > _filters.maxPrice) {
          return false;
        }
        if (_filters.selectedBrands.isNotEmpty &&
            !_filters.selectedBrands.contains(p.brand)) {
          return false;
        }
        if (p.rating < _filters.minRating) return false;
        if (_filters.onlyInStock && !p.isInStock) return false;
        if (_filters.onlyOnSale && !p.isOnSale) return false;
        return true;
      }).toList();

      // Apply sorting
      switch (_sortBy) {
        case 'price_low':
          _filteredProducts.sort((a, b) => a.price.compareTo(b.price));
          break;
        case 'price_high':
          _filteredProducts.sort((a, b) => b.price.compareTo(a.price));
          break;
        case 'rating':
          _filteredProducts.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'newest':
          // Assuming products have implicit order (newest first)
          break;
        case 'featured':
        default:
          _filteredProducts.sort(
              (a, b) => (b.isFeatured ? 1 : 0).compareTo(a.isFeatured ? 1 : 0));
      }
    });
  }

  int _getActiveFiltersCount() {
    int count = 0;
    if (_filters.minPrice > 0 || _filters.maxPrice < 500) count++;
    if (_filters.selectedBrands.isNotEmpty) count++;
    if (_filters.minRating > 0) count++;
    if (_filters.onlyInStock) count++;
    if (_filters.onlyOnSale) count++;
    return count;
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ordenar por',
                style: AppTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _SortOption(
                title: 'Destacados',
                value: 'featured',
                currentValue: _sortBy,
                onTap: () {
                  setState(() => _sortBy = 'featured');
                  _applyFiltersAndSorting();
                  Navigator.pop(context);
                },
              ),
              _SortOption(
                title: 'Más Recientes',
                value: 'newest',
                currentValue: _sortBy,
                onTap: () {
                  setState(() => _sortBy = 'newest');
                  _applyFiltersAndSorting();
                  Navigator.pop(context);
                },
              ),
              _SortOption(
                title: 'Precio: Menor a Mayor',
                value: 'price_low',
                currentValue: _sortBy,
                onTap: () {
                  setState(() => _sortBy = 'price_low');
                  _applyFiltersAndSorting();
                  Navigator.pop(context);
                },
              ),
              _SortOption(
                title: 'Precio: Mayor a Menor',
                value: 'price_high',
                currentValue: _sortBy,
                onTap: () {
                  setState(() => _sortBy = 'price_high');
                  _applyFiltersAndSorting();
                  Navigator.pop(context);
                },
              ),
              _SortOption(
                title: 'Mejor Valorados',
                value: 'rating',
                currentValue: _sortBy,
                onTap: () {
                  setState(() => _sortBy = 'rating');
                  _applyFiltersAndSorting();
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8ECF3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8ECF3),
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE8ECF3),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              const BoxShadow(
                color: Color(0xFFFFFFFF),
                offset: Offset(-2, -2),
                blurRadius: 4,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: const Color(0xFF2D3748).withValues(alpha: 0.15),
                offset: const Offset(2, 2),
                blurRadius: 4,
                spreadRadius: 0,
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back,
                color: Color(0xFF2D3748), size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Todos los Productos',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_filteredProducts.length} de ${_products.length} productos',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CartBadge(
              onTap: () {
                Navigator.push(
                  context,
                  SlideUpRoute(page: const CartScreen()),
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      AdvancedFiltersSheet.show(context, _filters, (filters) {
                        setState(() {
                          _filters = filters;
                          _applyFiltersAndSorting();
                        });
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.filter_list,
                              size: 20, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            _filters.hasActiveFilters
                                ? 'Filtros (${_getActiveFiltersCount()})'
                                : 'Filtros',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _showSortOptions,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sort,
                              size: 20, color: AppTheme.primaryColor),
                          SizedBox(width: 8),
                          Text(
                            'Ordenar',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Products grid
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : RefreshIndicator(
                    onRefresh: _refreshProducts,
                    color: const Color(0xFF667EEA),
                    backgroundColor: const Color(0xFFE8ECF3),
                    child: _filteredProducts.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height - 250,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.inventory_2_outlined,
                                          size: 80, color: Colors.grey[300]),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'No hay productos disponibles',
                                        style: TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            _filters = ProductFilters();
                                            _applyFiltersAndSorting();
                                          });
                                        },
                                        child: const Text('Limpiar filtros'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : GridView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(20),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.7,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: _filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = _filteredProducts[index];
                              return _ProductGridItem(
                                product: product,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    SlideRightRoute(
                                      page:
                                          ProductDetailScreen(product: product),
                                    ),
                                  );
                                },
                                onAddToCart: () {
                                  context
                                      .read<CartProvider>()
                                      .addToCart(product);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.check_circle,
                                              color: Colors.white),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                                '${product.name} agregado al carrito'),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 2),
                                      action: SnackBarAction(
                                        label: 'VER',
                                        textColor: Colors.white,
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            SlideUpRoute(
                                                page: const CartScreen()),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProductGridItem extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  const _ProductGridItem({
    required this.product,
    required this.onTap,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    product.images.first,
                    width: double.infinity,
                    height: 140,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 140,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported,
                          size: 50, color: Colors.grey),
                    ),
                  ),
                ),
                if (product.isOnSale)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3B30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '-${product.discountPercentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (product.isFeatured)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.amber[700],
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: Colors.amber[700]),
                        const SizedBox(width: 4),
                        Text(
                          '${product.rating}',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${product.reviewCount})',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (product.isOnSale &&
                                  product.originalPrice != null)
                                Text(
                                  'S/ ${product.originalPrice!.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              Text(
                                'S/ ${product.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: onAddToCart,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.add_shopping_cart,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortOption extends StatelessWidget {
  final String title;
  final String value;
  final String currentValue;
  final VoidCallback onTap;

  const _SortOption({
    required this.title,
    required this.value,
    required this.currentValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == currentValue;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppTheme.primaryColor)
          : null,
      onTap: onTap,
    );
  }
}
