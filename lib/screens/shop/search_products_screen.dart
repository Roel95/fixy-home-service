import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fixy_home_service/data/product_repository.dart';
import 'package:fixy_home_service/models/product_model.dart';
import 'package:fixy_home_service/providers/cart_provider.dart';
import 'package:fixy_home_service/screens/shop/product_detail_screen.dart';
import 'package:fixy_home_service/screens/shop/cart_screen.dart';
import 'package:fixy_home_service/theme/app_theme.dart';
import 'package:fixy_home_service/utils/page_transitions.dart';
import 'package:fixy_home_service/widgets/cart_badge.dart';
import 'package:fixy_home_service/services/product_service.dart';

class SearchProductsScreen extends StatefulWidget {
  const SearchProductsScreen({Key? key}) : super(key: key);

  @override
  State<SearchProductsScreen> createState() => _SearchProductsScreenState();
}

class _SearchProductsScreenState extends State<SearchProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ProductRepository _repository = ProductRepository();
  late ProductService _productService;
  List<ProductModel> _searchResults = [];
  List<ProductModel> _allProducts = [];
  List<ProductModel> _suggestions = [];
  bool _isLoading = false;
  bool _showSuggestions = false;
  String _lastQuery = '';

  // Filtros
  String? _selectedCategory;
  String? _selectedBrand;
  double? _minPrice;
  double? _maxPrice;
  bool _onlyOnSale = false;
  bool _onlyInStock = false;

  // Historial
  List<String> _searchHistory = [];
  static const String _historyKey = 'search_history';
  static const int _maxHistoryItems = 10;

  // Categorías y marcas disponibles
  List<String> _categories = [];
  List<String> _brands = [];

  Timer? _debounceTimer;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _productService = ProductService();
    _loadSearchHistory();
    _loadAllProducts(forceRefresh: true);
    _productService.subscribeToChanges(_onProductChanged);
    _focusNode.addListener(_onFocusChange);
  }

  void _onProductChanged(ProductChangeEvent event) {
    print('🔄 Producto cambiado en SearchScreen: ${event.type}');
    if (mounted) {
      _loadAllProducts();
    }
  }

  @override
  void dispose() {
    _productService.unsubscribeFromChanges(_onProductChanged);
    _debounceTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      if (_searchController.text.isEmpty && _focusNode.hasFocus) {
        _showSuggestions = false;
      }
    });
  }

  Future<void> _loadAllProducts({bool forceRefresh = false}) async {
    try {
      final products =
          await _repository.getAllProducts(forceRefresh: forceRefresh);
      setState(() {
        _allProducts = products;
        _extractFilters();
      });
    } catch (e) {
      debugPrint('Error cargando productos: $e');
    }
  }

  void _extractFilters() {
    final Set<String> cats = {};
    final Set<String> brs = {};
    for (final p in _allProducts) {
      if (p.category.isNotEmpty) cats.add(p.category);
      if (p.brand.isNotEmpty) brs.add(p.brand);
    }
    setState(() {
      _categories = cats.toList()..sort();
      _brands = brs.toList()..sort();
    });
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory = prefs.getStringList(_historyKey) ?? [];
    });
  }

  Future<void> _saveSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_historyKey, _searchHistory);
  }

  void _addToHistory(String query) {
    if (query.isEmpty) return;
    setState(() {
      _searchHistory.remove(query);
      _searchHistory.insert(0, query);
      if (_searchHistory.length > _maxHistoryItems) {
        _searchHistory = _searchHistory.sublist(0, _maxHistoryItems);
      }
    });
    _saveSearchHistory();
  }

  void _removeFromHistory(String query) {
    setState(() {
      _searchHistory.remove(query);
    });
    _saveSearchHistory();
  }

  void _updateSuggestions(String query) {
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    final lower = query.toLowerCase();
    final matches = _allProducts
        .where((p) {
          return p.name.toLowerCase().contains(lower) ||
              p.brand.toLowerCase().contains(lower);
        })
        .take(5)
        .toList();

    setState(() {
      _suggestions = matches;
      _showSuggestions = true;
    });
  }

  Future<void> _performSearch(String query) async {
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _lastQuery = '';
        _showSuggestions = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _lastQuery = query;
      _showSuggestions = false;
    });

    try {
      List<ProductModel> results = await _repository.searchProducts(query);

      // Aplicar filtros adicionales
      results = _applyFilters(results);

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }

      _addToHistory(query);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error buscando: $e')),
        );
      }
    }
  }

  List<ProductModel> _applyFilters(List<ProductModel> products) {
    return products.where((p) {
      if (_selectedCategory != null && p.category != _selectedCategory)
        return false;
      if (_selectedBrand != null && p.brand != _selectedBrand) return false;
      if (_minPrice != null && p.price < _minPrice!) return false;
      if (_maxPrice != null && p.price > _maxPrice!) return false;
      if (_onlyOnSale && !p.isOnSale) return false;
      if (_onlyInStock && p.stock <= 0) return false;
      return true;
    }).toList();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (query.isEmpty) {
        setState(() => _showSuggestions = false);
      } else {
        _updateSuggestions(query);
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _suggestions = [];
      _showSuggestions = false;
      _lastQuery = '';
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedBrand = null;
      _minPrice = null;
      _maxPrice = null;
      _onlyOnSale = false;
      _onlyInStock = false;
    });
    if (_lastQuery.isNotEmpty) {
      _performSearch(_lastQuery);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF0066FF)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Buscar productos...',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 15,
              ),
              prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: _clearSearch,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (query) {
              setState(() {});
              _onSearchChanged(query);
            },
            onSubmitted: (query) => _performSearch(query),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF0066FF)),
            onPressed: () => _performSearch(_searchController.text),
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildBody(),
          if (_showSuggestions && _suggestions.isNotEmpty) _buildSuggestions(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Mostrar historial cuando está vacío y hay foco
    if (_lastQuery.isEmpty &&
        _searchController.text.isEmpty &&
        _searchHistory.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Búsquedas recientes',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _searchHistory.clear());
                    _saveSearchHistory();
                  },
                  child: const Text('Limpiar'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _searchHistory.length,
              itemBuilder: (context, index) {
                final query = _searchHistory[index];
                return ListTile(
                  leading: const Icon(Icons.history, color: Colors.grey),
                  title: Text(query),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => _removeFromHistory(query),
                  ),
                  onTap: () {
                    _searchController.text = query;
                    _performSearch(query);
                  },
                );
              },
            ),
          ),
        ],
      );
    }

    if (_searchController.text.isEmpty && _lastQuery.isEmpty) {
      return _buildEmptyState();
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No se encontraron resultados para "$_lastQuery"',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Filtros rápidos
        _buildQuickFilters(),
        // Resultados
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final product = _searchResults[index];
              return _ProductCard(
                product: product,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProductDetailScreen(product: product),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickFilters() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filtros activos
          if (_selectedCategory != null ||
              _selectedBrand != null ||
              _onlyOnSale ||
              _onlyInStock)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_selectedCategory != null)
                    Chip(
                      label: Text(_selectedCategory!),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() => _selectedCategory = null);
                        _performSearch(_lastQuery);
                      },
                    ),
                  if (_selectedBrand != null)
                    Chip(
                      label: Text(_selectedBrand!),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() => _selectedBrand = null);
                        _performSearch(_lastQuery);
                      },
                    ),
                  if (_onlyOnSale)
                    Chip(
                      label: const Text('En oferta'),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() => _onlyOnSale = false);
                        _performSearch(_lastQuery);
                      },
                    ),
                  if (_onlyInStock)
                    Chip(
                      label: const Text('En stock'),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() => _onlyInStock = false);
                        _performSearch(_lastQuery);
                      },
                    ),
                  if (_selectedCategory != null ||
                      _selectedBrand != null ||
                      _onlyOnSale ||
                      _onlyInStock)
                    ActionChip(
                      label: const Text('Limpiar todo'),
                      onPressed: _clearFilters,
                    ),
                ],
              ),
            ),
          // Botones de filtros
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Categorías
                if (_categories.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: PopupMenuButton<String>(
                      child: _FilterChip(
                        label: 'Categoría',
                        isActive: _selectedCategory != null,
                        onTap: () {},
                      ),
                      itemBuilder: (context) => _categories
                          .map((cat) => PopupMenuItem(
                                value: cat,
                                child: Text(cat),
                              ))
                          .toList(),
                      onSelected: (value) {
                        setState(() => _selectedCategory = value);
                        _performSearch(_lastQuery);
                      },
                    ),
                  ),
                // Marcas
                if (_brands.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: PopupMenuButton<String>(
                      child: _FilterChip(
                        label: 'Marca',
                        isActive: _selectedBrand != null,
                        onTap: () {},
                      ),
                      itemBuilder: (context) => _brands
                          .map((brand) => PopupMenuItem(
                                value: brand,
                                child: Text(brand),
                              ))
                          .toList(),
                      onSelected: (value) {
                        setState(() => _selectedBrand = value);
                        _performSearch(_lastQuery);
                      },
                    ),
                  ),
                // Precio
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: PopupMenuButton<String>(
                    child: _FilterChip(
                      label: 'Precio',
                      isActive: _minPrice != null || _maxPrice != null,
                      onTap: () {},
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                          value: '0-50', child: Text('S/ 0 - 50')),
                      const PopupMenuItem(
                          value: '50-100', child: Text('S/ 50 - 100')),
                      const PopupMenuItem(
                          value: '100-200', child: Text('S/ 100 - 200')),
                      const PopupMenuItem(
                          value: '200+', child: Text('S/ 200+')),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case '0-50':
                          _minPrice = 0;
                          _maxPrice = 50;
                          break;
                        case '50-100':
                          _minPrice = 50;
                          _maxPrice = 100;
                          break;
                        case '100-200':
                          _minPrice = 100;
                          _maxPrice = 200;
                          break;
                        case '200+':
                          _minPrice = 200;
                          _maxPrice = null;
                          break;
                      }
                      _performSearch(_lastQuery);
                    },
                  ),
                ),
                // Oferta
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('En oferta'),
                    selected: _onlyOnSale,
                    onSelected: (selected) {
                      setState(() => _onlyOnSale = selected);
                      _performSearch(_lastQuery);
                    },
                  ),
                ),
                // Stock
                FilterChip(
                  label: const Text('En stock'),
                  selected: _onlyInStock,
                  onSelected: (selected) {
                    setState(() => _onlyInStock = selected);
                    _performSearch(_lastQuery);
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }

  // Método _buildSuggestions movido dentro de la clase
  Widget _buildSuggestions() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Sugerencias',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
            ..._suggestions.map((product) => ListTile(
                  leading:
                      const Icon(Icons.lightbulb_outline, color: Colors.amber),
                  title: Text(product.name),
                  subtitle: Text('S/ ${product.price.toStringAsFixed(2)}'),
                  onTap: () {
                    _searchController.text = product.name;
                    _performSearch(product.name);
                  },
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final popularCategories = [
      {
        'name': 'Herramientas',
        'icon': Icons.construction,
        'color': const Color(0xFF0066FF)
      },
      {
        'name': 'Pintura',
        'icon': Icons.format_paint,
        'color': const Color(0xFFFF6B35)
      },
      {
        'name': 'Plomería',
        'icon': Icons.water_drop,
        'color': const Color(0xFF00C9A7)
      },
      {
        'name': 'Electricidad',
        'icon': Icons.electrical_services,
        'color': const Color(0xFFFFB800)
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'Categorías',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: popularCategories.map((category) {
              return GestureDetector(
                onTap: () {
                  _searchController.text = category['name'] as String;
                  _performSearch(category['name'] as String);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        category['icon'] as IconData,
                        size: 16,
                        color: category['color'] as Color,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        category['name'] as String,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          if (_allProducts.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Populares',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _allProducts.take(5).length,
                    itemBuilder: (context, index) {
                      final product = _allProducts[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProductDetailScreen(product: product),
                            ),
                          );
                        },
                        child: Container(
                          width: 130,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(8)),
                                child: product.images.isNotEmpty
                                    ? Image.network(
                                        product.images.first,
                                        width: 130,
                                        height: 90,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        width: 130,
                                        height: 90,
                                        color: Colors.grey[100],
                                        child: Icon(Icons.image_not_supported,
                                            color: Colors.grey[400]),
                                      ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'S/ ${product.price.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Color(0xFF0066FF),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0066FF) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[700],
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen del producto
              Stack(
                children: [
                  SizedBox(
                    height: 140,
                    width: double.infinity,
                    child: product.images.isNotEmpty
                        ? Image.network(
                            product.images.first,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[100],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: Colors.grey[100],
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                size: 48,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey[100],
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              size: 48,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                  // Badge de descuento
                  if (product.isOnSale)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3B30),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '-${product.discountPercentage.toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  // Badge de agotado
                  if (product.stock <= 0)
                    Positioned.fill(
                      child: Container(
                        color: Colors.white.withValues(alpha: 0.7),
                        child: const Center(
                          child: Text(
                            'AGOTADO',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // Información del producto
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre del producto
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Precio
                    Row(
                      children: [
                        if (product.isOnSale) ...[
                          Text(
                            'S/ ${product.originalPrice?.toStringAsFixed(2) ?? product.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          'S/ ${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFF0066FF),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Marca
                    if (product.brand.isNotEmpty)
                      Text(
                        product.brand,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Clase para filtros de productos
class ProductFilters {
  double minPrice;
  double maxPrice;
  List<String> selectedBrands;
  double minRating;
  bool onlyInStock;
  bool onlyOnSale;

  ProductFilters({
    this.minPrice = 0,
    this.maxPrice = 500,
    this.selectedBrands = const [],
    this.minRating = 0,
    this.onlyInStock = false,
    this.onlyOnSale = false,
  });

  bool get hasActiveFilters {
    return minPrice > 0 ||
        maxPrice < 500 ||
        selectedBrands.isNotEmpty ||
        minRating > 0 ||
        onlyInStock ||
        onlyOnSale;
  }

  ProductFilters copyWith({
    double? minPrice,
    double? maxPrice,
    List<String>? selectedBrands,
    double? minRating,
    bool? onlyInStock,
    bool? onlyOnSale,
  }) {
    return ProductFilters(
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      selectedBrands: selectedBrands ?? this.selectedBrands,
      minRating: minRating ?? this.minRating,
      onlyInStock: onlyInStock ?? this.onlyInStock,
      onlyOnSale: onlyOnSale ?? this.onlyOnSale,
    );
  }
}

// Clase para mostrar filtros avanzados
class AdvancedFiltersSheet {
  static void show(
    BuildContext context,
    ProductFilters currentFilters,
    Function(ProductFilters) onApply,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _AdvancedFiltersContent(
          initialFilters: currentFilters,
          onApply: onApply,
        );
      },
    );
  }
}

class _AdvancedFiltersContent extends StatefulWidget {
  final ProductFilters initialFilters;
  final Function(ProductFilters) onApply;

  const _AdvancedFiltersContent({
    required this.initialFilters,
    required this.onApply,
  });

  @override
  State<_AdvancedFiltersContent> createState() =>
      _AdvancedFiltersContentState();
}

class _AdvancedFiltersContentState extends State<_AdvancedFiltersContent> {
  late ProductFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters.copyWith();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filtros Avanzados',
                style: AppTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Rango de precio
          Text(
            'Rango de Precio',
            style: AppTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Min',
                    prefixText: 'S/ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _filters.minPrice = double.tryParse(value) ?? 0;
                    });
                  },
                  controller: TextEditingController(
                    text: _filters.minPrice.toStringAsFixed(0),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Max',
                    prefixText: 'S/ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _filters.maxPrice = double.tryParse(value) ?? 500;
                    });
                  },
                  controller: TextEditingController(
                    text: _filters.maxPrice.toStringAsFixed(0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Switch filtros
          SwitchListTile(
            title: const Text('Solo en stock'),
            value: _filters.onlyInStock,
            onChanged: (value) {
              setState(() {
                _filters.onlyInStock = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Solo en oferta'),
            value: _filters.onlyOnSale,
            onChanged: (value) {
              setState(() {
                _filters.onlyOnSale = value;
              });
            },
          ),
          const SizedBox(height: 20),
          // Botones
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _filters = ProductFilters();
                    });
                  },
                  child: const Text('Limpiar'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_filters);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Aplicar'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class ProductListScreen extends StatefulWidget {
  final ProductCategoryModel category;

  const ProductListScreen({
    Key? key,
    required this.category,
  }) : super(key: key);

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late ProductRepository _repository;
  late List<ProductModel> _products;
  List<ProductModel> _filteredProducts = [];
  String _sortBy = 'featured';
  ProductFilters _filters = ProductFilters();

  @override
  void initState() {
    super.initState();
    _repository = ProductRepository();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products =
        await _repository.getProductsByCategory(widget.category.id);
    if (mounted) {
      setState(() {
        _products = products;
        _applyFiltersAndSorting();
      });
    }
  }

  Future<void> _refreshProducts() async {
    await Future.delayed(const Duration(milliseconds: 800));
    _loadProducts();
  }

  void _applyFiltersAndSorting() {
    setState(() {
      // Apply filters
      _filteredProducts = _products.where((p) {
        if (p.price < _filters.minPrice || p.price > _filters.maxPrice)
          return false;
        if (_filters.selectedBrands.isNotEmpty &&
            !_filters.selectedBrands.contains(p.brand)) return false;
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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.category.name,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_filteredProducts.length} de ${_products.length} productos',
              style: TextStyle(
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
                          Icon(Icons.filter_list,
                              size: 20, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            _filters.hasActiveFilters
                                ? 'Filtros (${_getActiveFiltersCount()})'
                                : 'Filtros',
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sort,
                              size: 20, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
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
            child: RefreshIndicator(
              onRefresh: _refreshProducts,
              color: AppTheme.primaryColor,
              child: _filteredProducts.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height - 250,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inventory_2_outlined,
                                    size: 80, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text(
                                  'No hay productos disponibles',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 16,
                                  ),
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
                                page: ProductDetailScreen(product: product),
                              ),
                            );
                          },
                          onAddToCart: () {
                            context.read<CartProvider>().addToCart(product);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: Colors.white),
                                    SizedBox(width: 12),
                                    Expanded(
                                        child: Text('Agregado al carrito')),
                                  ],
                                ),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
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
                      style: TextStyle(
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
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      'S/ ${product.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
      trailing:
          isSelected ? Icon(Icons.check, color: AppTheme.primaryColor) : null,
      onTap: onTap,
    );
  }
}
