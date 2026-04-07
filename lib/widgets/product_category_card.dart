import 'package:flutter/material.dart';
import 'package:fixy_home_service/models/product_model.dart';
import 'package:fixy_home_service/theme/app_theme.dart';

class ProductCategoryCard extends StatelessWidget {
  final ProductCategoryModel category;
  final VoidCallback onTap;

  const ProductCategoryCard({
    Key? key,
    required this.category,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon area
              Container(
                height: 90,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Center(
                  child: Icon(
                    _getCategoryIcon(category.name),
                    size: 40,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              // Category info
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${category.productCount} items',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
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

  IconData _getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('seguridad')) return Icons.security;
    if (lower.contains('plomería') || lower.contains('plomeria'))
      return Icons.plumbing;
    if (lower.contains('pintura')) return Icons.format_paint;
    if (lower.contains('eléctrico') || lower.contains('electrico'))
      return Icons.electrical_services;
    if (lower.contains('carpintería') || lower.contains('carpinteria'))
      return Icons.chair;
    if (lower.contains('jardinería') || lower.contains('jardineria'))
      return Icons.yard;
    if (lower.contains('limpieza')) return Icons.cleaning_services;
    if (lower.contains('cerrajería') || lower.contains('cerrajeria'))
      return Icons.lock;
    if (lower.contains('climatización') || lower.contains('climatizacion'))
      return Icons.ac_unit;
    if (lower.contains('construcción') || lower.contains('construccion'))
      return Icons.construction;
    return Icons.category;
  }
}
