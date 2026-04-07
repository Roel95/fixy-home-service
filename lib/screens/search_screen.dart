import 'package:flutter/material.dart';
import 'package:fixy_home_service/data/service_repository.dart';
import 'package:fixy_home_service/models/service_model.dart';
import 'package:fixy_home_service/screens/service_detail_screen.dart';
import 'package:fixy_home_service/theme/app_theme.dart';
import 'package:fixy_home_service/widgets/custom_search_bar.dart';
import 'package:fixy_home_service/widgets/filter_chip.dart' as custom_chip;
import 'package:fixy_home_service/widgets/price_range_slider.dart';
import 'package:fixy_home_service/widgets/service_list_item.dart';
import 'package:fixy_home_service/utils/page_transitions.dart';

class SearchScreen extends StatefulWidget {
  final String? initialFilter;
  final bool showCategoriesFirst;

  const SearchScreen({
    super.key,
    this.initialFilter,
    this.showCategoriesFirst = false,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final ServiceRepository _repository = ServiceRepository();
  late AnimationController _animationController;
  late Animation<double> _filtersAnimation;

  // Search and filter state
  String _searchQuery = '';
  String _selectedLocation = 'Todos';
  String _selectedDay = 'Todos';
  RangeValues _priceRange = const RangeValues(15, 40);
  bool _showFilters = false;

  // Lists for filters
  late List<String> _locations;
  late List<String> _availableDays;

  // Search results
  List<ServiceModel> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _availableDays = _repository.getAllAvailableDays();

    // Handle initial filter
    if (widget.initialFilter == 'popular') {
      _searchQuery = 'popular';
    }

    // Show filters if categories first
    _showFilters = widget.showCategoriesFirst;

    // Load data
    _loadInitialData();

    // Animation controller for filters
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _filtersAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Animate filters if showing categories first
    if (_showFilters) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animationController.forward();
      });
    }
  }

  Future<void> _loadInitialData() async {
    final locations = await _repository.getAllLocations();
    if (mounted) {
      setState(() {
        _locations = locations;
      });
    }
    await _performSearch();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
      if (_showFilters) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedLocation = 'Todos';
      _selectedDay = 'Todos';
      _priceRange = const RangeValues(15, 40);
      _performSearch();
    });
  }

  Future<void> _performSearch() async {
    final results = await _repository.searchServices(
      query: _searchQuery.isEmpty ? null : _searchQuery,
      location: _selectedLocation,
      minPrice: _priceRange.start,
      maxPrice: _priceRange.end,
      day: _selectedDay,
    );

    if (mounted) {
      setState(() {
        _searchResults = results;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Buscar Servicios',
          style: AppTheme.textTheme.titleLarge,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
              color:
                  _showFilters ? AppTheme.primaryColor : AppTheme.textPrimary,
            ),
            onPressed: _toggleFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: CustomSearchBar(
              placeholder: 'Busca un servicio o profesional',
              onTap: () {
                // Show keyboard when tapped
                FocusScope.of(context).requestFocus(FocusNode());
              },
              onSearch: _performSearch,
            ),
          ),

          // Quick filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final location in _locations.take(5))
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: custom_chip.CustomFilterChip(
                        label: location,
                        isSelected: _selectedLocation == location,
                        onTap: () {
                          setState(() {
                            _selectedLocation = location;
                            _performSearch();
                          });
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Expandable filters
          SizeTransition(
            sizeFactor: _filtersAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location dropdown
                  Text(
                    'Ubicación',
                    style: AppTheme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedLocation,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        style: AppTheme.textTheme.bodyMedium,
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedLocation = newValue!;
                            _performSearch();
                          });
                        },
                        items: _locations
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Price range slider
                  PriceRangeSlider(
                    minValue: 15,
                    maxValue: 40,
                    currentRange: _priceRange,
                    onChanged: (RangeValues values) {
                      setState(() {
                        _priceRange = values;
                        _performSearch();
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Availability days
                  Text(
                    'Disponibilidad',
                    style: AppTheme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final day in _availableDays)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: custom_chip.CustomFilterChip(
                              label: day,
                              isSelected: _selectedDay == day,
                              onTap: () {
                                setState(() {
                                  _selectedDay = day;
                                  _performSearch();
                                });
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Clear filters button
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(
                        Icons.refresh,
                        color: Colors.white,
                      ),
                      label: Text(
                        'Limpiar Filtros',
                        style: AppTheme.textTheme.labelLarge,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_searchResults.length} resultados',
                  style: AppTheme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_searchResults.isNotEmpty)
                  Row(
                    children: [
                      const Icon(
                        Icons.sort,
                        size: 18,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Ordenar',
                        style: AppTheme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Search results
          Expanded(
            child: _searchResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No se encontraron resultados',
                          style: AppTheme.textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Intenta con otros filtros',
                          style: AppTheme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      return ServiceListItem(
                        service: _searchResults[index],
                        onTap: () {
                          Navigator.push(
                            context,
                            SlideRightRoute(
                              page: ServiceDetailScreen(
                                service: _searchResults[index],
                              ),
                            ),
                          );
                        },
                        onReserve: () {
                          Navigator.push(
                            context,
                            SlideUpRoute(
                              page: ServiceDetailScreen(
                                service: _searchResults[index],
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
      floatingActionButton: AnimatedOpacity(
        opacity: _searchResults.isNotEmpty ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: FloatingActionButton(
          onPressed: () {
            // Scroll to top
          },
          backgroundColor: AppTheme.primaryColor,
          child: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
        ),
      ),
    );
  }
}
