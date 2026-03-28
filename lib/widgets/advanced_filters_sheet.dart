import 'package:flutter/material.dart';
import 'package:fixy_home_service/theme/app_theme.dart';

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

  bool get hasActiveFilters =>
      minPrice > 0 ||
      maxPrice < 500 ||
      selectedBrands.isNotEmpty ||
      minRating > 0 ||
      onlyInStock ||
      onlyOnSale;

  void reset() {
    minPrice = 0;
    maxPrice = 500;
    selectedBrands = [];
    minRating = 0;
    onlyInStock = false;
    onlyOnSale = false;
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
      selectedBrands: selectedBrands ?? List.from(this.selectedBrands),
      minRating: minRating ?? this.minRating,
      onlyInStock: onlyInStock ?? this.onlyInStock,
      onlyOnSale: onlyOnSale ?? this.onlyOnSale,
    );
  }
}

class AdvancedFiltersSheet extends StatefulWidget {
  final ProductFilters initialFilters;
  final Function(ProductFilters) onApply;

  const AdvancedFiltersSheet({
    Key? key,
    required this.initialFilters,
    required this.onApply,
  }) : super(key: key);

  static void show(
    BuildContext context,
    ProductFilters initialFilters,
    Function(ProductFilters) onApply,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdvancedFiltersSheet(
        initialFilters: initialFilters,
        onApply: onApply,
      ),
    );
  }

  @override
  State<AdvancedFiltersSheet> createState() => _AdvancedFiltersSheetState();
}

class _AdvancedFiltersSheetState extends State<AdvancedFiltersSheet> {
  late ProductFilters _filters;
  final List<String> _availableBrands = [
    'DeWalt',
    'Stanley',
    'Makita',
    'Bosch',
    'Truper',
    'Sherwin-Williams',
    'Comex',
    'Cemex',
  ];

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters.copyWith();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtros',
                  style: AppTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filters.reset();
                    });
                  },
                  child: Text(
                    'Limpiar',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price range
                  Text(
                    'Rango de Precio',
                    style: AppTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'S/ ${_filters.minPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      Expanded(
                        child: RangeSlider(
                          values:
                              RangeValues(_filters.minPrice, _filters.maxPrice),
                          min: 0,
                          max: 500,
                          divisions: 50,
                          activeColor: AppTheme.primaryColor,
                          onChanged: (RangeValues values) {
                            setState(() {
                              _filters.minPrice = values.start;
                              _filters.maxPrice = values.end;
                            });
                          },
                        ),
                      ),
                      Text(
                        'S/ ${_filters.maxPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Brands
                  Text(
                    'Marcas',
                    style: AppTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableBrands.map((brand) {
                      final isSelected =
                          _filters.selectedBrands.contains(brand);
                      return FilterChip(
                        label: Text(brand),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _filters.selectedBrands.add(brand);
                            } else {
                              _filters.selectedBrands.remove(brand);
                            }
                          });
                        },
                        selectedColor:
                            AppTheme.primaryColor.withValues(alpha: 0.2),
                        checkmarkColor: AppTheme.primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Rating
                  Text(
                    'Calificación Mínima',
                    style: AppTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(5, (index) {
                      final rating = (index + 1).toDouble();
                      final isSelected = _filters.minRating >= rating;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _filters.minRating =
                                _filters.minRating == rating ? 0 : rating;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : Colors.grey.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 16,
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${index + 1}+',
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                        : AppTheme.textSecondary,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 24),

                  // Additional filters
                  Text(
                    'Otros Filtros',
                    style: AppTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Solo productos en stock'),
                    value: _filters.onlyInStock,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (value) {
                      setState(() {
                        _filters.onlyInStock = value ?? false;
                      });
                    },
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Solo productos en oferta'),
                    value: _filters.onlyOnSale,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (value) {
                      setState(() {
                        _filters.onlyOnSale = value ?? false;
                      });
                    },
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Apply button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: () {
                  widget.onApply(_filters);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Aplicar Filtros',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
