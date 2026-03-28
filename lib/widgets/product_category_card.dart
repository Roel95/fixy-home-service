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
          color: const Color(0xFFE8ECF3),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.white,
              offset: const Offset(-4, -4),
              blurRadius: 8,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              offset: const Offset(4, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: category.imageUrl != null
                  ? Image.asset(
                      category.imageUrl!,
                      width: double.infinity,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 90,
                        color: Colors.grey[100],
                        child: Icon(Icons.image,
                            size: 40, color: Colors.grey[400]),
                      ),
                    )
                  : Container(
                      height: 90,
                      color: Colors.grey[100],
                      child: Icon(Icons.category,
                          size: 40, color: Colors.grey[400]),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${category.productCount} items',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
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
  }
}
