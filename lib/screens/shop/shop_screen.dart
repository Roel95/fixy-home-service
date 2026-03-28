import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixy_home_service/data/product_repository.dart';
import 'package:fixy_home_service/models/product_model.dart';
import 'package:fixy_home_service/providers/cart_provider.dart';
import 'package:fixy_home_service/screens/shop/product_detail_screen.dart';
import 'package:fixy_home_service/screens/shop/product_list_screen.dart';
import 'package:fixy_home_service/screens/shop/cart_screen.dart';
import 'package:fixy_home_service/screens/shop/search_products_screen.dart'
    as search;
import 'package:fixy_home_service/screens/shop/all_products_screen.dart';
import 'package:fixy_home_service/theme/app_theme.dart';
import 'package:fixy_home_service/widgets/product_card.dart';
import 'package:fixy_home_service/widgets/product_category_card.dart';
import 'package:fixy_home_service/widgets/deal_banner.dart';
import 'package:fixy_home_service/utils/page_transitions.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({Key? key}) : super(key: key);

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  late ProductRepository _repository;
  late List<ProductModel> _featuredProducts;
  late List<ProductModel> _onSaleProducts;
  late List<ProductCategoryModel> _categories;
  late AnimationController _animationController;
  PageController? _dealsPageController;
  Timer? _autoScrollTimer;
  int _currentDealPage = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository = ProductRepository();
    _featuredProducts = [];
    _onSaleProducts = [];
    _categories = [];

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animationController.forward();

    // Inicializar PageController para banners automáticos
    _dealsPageController = PageController(viewportFraction: 0.9);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });

    // Cargar datos de Supabase
    _loadData();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final featured =
          await _repository.getFeaturedProducts(forceRefresh: forceRefresh);
      final onSale =
          await _repository.getOnSaleProducts(forceRefresh: forceRefresh);
      final categories =
          await _repository.getProductCategories(forceRefresh: forceRefresh);

      if (mounted) {
        setState(() {
          _featuredProducts = featured;
          _onSaleProducts = onSale;
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error cargando productos: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Error cargando productos. Por favor intenta de nuevo.';
        });
      }
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _dealsPageController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showAddedToCartSnackbar(ProductModel product) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text('${product.name} agregado al carrito'),
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
              SlideUpRoute(page: const CartScreen()),
            );
          },
        ),
      ),
    );
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (_dealsPageController == null) return;
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_onSaleProducts.isEmpty || !_dealsPageController!.hasClients) return;

      final maxPage =
          _onSaleProducts.length > 5 ? 4 : _onSaleProducts.length - 1;
      if (_currentDealPage < maxPage) {
        _currentDealPage++;
      } else {
        _currentDealPage = 0;
      }

      _dealsPageController!.animateToPage(
        _currentDealPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentDealPage = page;
    });
  }

  Future<void> _refreshProducts() async {
    _currentDealPage = 0;
    if (_dealsPageController?.hasClients == true) {
      _dealsPageController!.jumpToPage(0);
    }
    // Forzar actualización desde Supabase
    await _loadData(forceRefresh: true);
    _startAutoScroll();
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar loading spinner durante carga inicial
    if (_isLoading && _featuredProducts.isEmpty && _categories.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                Text(
                  'Cargando productos...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Mostrar error con botón reintentar
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _refreshProducts,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshProducts,
          color: AppTheme.primaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Header con gradiente
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _animationController.value,
                      child: child,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                  colors: [
                                    Color(0xFF0066FF),
                                    Color(0xFF00C6FF)
                                  ],
                                ).createShader(bounds),
                                child: const Text(
                                  'Tienda',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 32,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Productos de ferretería y construcción',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Carrito con estilo moderno
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              SlideUpRoute(page: const CartScreen()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0066FF), Color(0xFF0052CC)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0066FF)
                                      .withValues(alpha: 0.3),
                                  offset: const Offset(0, 4),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                const Icon(Icons.shopping_cart,
                                    color: Colors.white, size: 24),
                                if (context.watch<CartProvider>().itemCount > 0)
                                  Positioned(
                                    right: -4,
                                    top: -4,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFF6B6B),
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 18,
                                        minHeight: 18,
                                      ),
                                      child: Text(
                                        '${context.watch<CartProvider>().itemCount}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Search bar moderno con sombra colorida
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _animationController.value,
                      child: Transform.translate(
                        offset:
                            Offset(0, 20 * (1 - _animationController.value)),
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          SlideRightRoute(
                              page: const search.SearchProductsScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0066FF)
                                  .withValues(alpha: 0.1),
                              offset: const Offset(0, 4),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: Colors.grey[400]),
                            const SizedBox(width: 12),
                            Text(
                              'Buscar productos...',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Special Deals section con estilo vibrante
                if (_onSaleProducts.isNotEmpty)
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _animationController.value,
                        child: Transform.translate(
                          offset:
                              Offset(0, 25 * (1 - _animationController.value)),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFF6B6B),
                                          Color(0xFFFF5252)
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFF6B6B)
                                              .withValues(alpha: 0.3),
                                          offset: const Offset(0, 4),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.local_offer,
                                        color: Colors.white, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Ofertas Especiales',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    SlideFadeRoute(
                                        page: const AllProductsScreen()),
                                  );
                                },
                                child: const Text(
                                  'Ver todo',
                                  style: TextStyle(
                                    color: Color(0xFF0066FF),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 160,
                          child: PageView.builder(
                            controller: _dealsPageController,
                            onPageChanged: _onPageChanged,
                            itemCount: _onSaleProducts.length > 5
                                ? 5
                                : _onSaleProducts.length,
                            itemBuilder: (context, index) {
                              final product = _onSaleProducts[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: DealBanner(
                                  product: product,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      SlideRightRoute(
                                        page: ProductDetailScreen(
                                          product: product,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        // Indicadores de página
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _onSaleProducts.length > 5
                                ? 5
                                : _onSaleProducts.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: _currentDealPage == index ? 24 : 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: _currentDealPage == index
                                    ? const Color(0xFF0066FF)
                                    : Colors.grey[300],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (_onSaleProducts.isNotEmpty) const SizedBox(height: 28),

                // Categories section con colores vibrantes
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _animationController.value,
                      child: Transform.translate(
                        offset:
                            Offset(0, 30 * (1 - _animationController.value)),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF7C4DFF),
                                    Color(0xFF5E35B1)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF7C4DFF)
                                        .withValues(alpha: 0.3),
                                    offset: const Offset(0, 4),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.category,
                                  color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Categorías',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 145,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(left: 20),
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            return ProductCategoryCard(
                              category: _categories[index],
                              onTap: () {
                                Navigator.push(
                                  context,
                                  SlideFadeRoute(
                                    page: ProductListScreen(
                                      category: _categories[index],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Featured products section con estrella dorada
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _animationController.value,
                      child: Transform.translate(
                        offset:
                            Offset(0, 40 * (1 - _animationController.value)),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFFD700),
                                        Color(0xFFFFA000)
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFFD700)
                                            .withValues(alpha: 0.3),
                                        offset: const Offset(0, 4),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.star,
                                      color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Productos Destacados',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  SlideRightRoute(
                                    page: const search.SearchProductsScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Ver más',
                                style: TextStyle(
                                  color: Color(0xFF0066FF),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 280,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(left: 20),
                          scrollDirection: Axis.horizontal,
                          itemCount: _featuredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _featuredProducts[index];
                            return ProductCard(
                              product: product,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  SlideRightRoute(
                                    page: ProductDetailScreen(
                                      product: product,
                                    ),
                                  ),
                                );
                              },
                              onAddToCart: () {
                                context.read<CartProvider>().addToCart(product);
                                _showAddedToCartSnackbar(product);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
