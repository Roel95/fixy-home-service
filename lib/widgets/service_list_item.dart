import 'package:flutter/material.dart';
import 'package:fixy_home_service/models/service_model.dart';
import 'package:fixy_home_service/theme/app_theme.dart';

class ServiceListItem extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onTap;
  final VoidCallback onReserve;

  const ServiceListItem({
    Key? key,
    required this.service,
    required this.onTap,
    required this.onReserve,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service image and location
            Stack(
              children: [
                Hero(
                  tag: 'service-${service.id}',
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: Image.network(
                      service.imageUrl,
                      height: 130,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 130,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported,
                              size: 40, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                ),
                // Location
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          service.location,
                          style: AppTheme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Service details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    service.title,
                    style: AppTheme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Description
                  Text(
                    service.description,
                    style: AppTheme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Price and availability
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price
                      Text(
                        '${service.currency}${service.price}/${service.timeUnit}',
                        style: AppTheme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.priceColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Availability days
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            color: AppTheme.textSecondary,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${service.availableDays.length} días',
                            style: AppTheme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Rating and reserve button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Rating
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: AppTheme.starColor,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${service.rating}',
                            style: AppTheme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${service.reviews})',
                            style: AppTheme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      // Reserve button
                      ElevatedButton(
                        onPressed: onReserve,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Reservar'),
                      ),
                    ],
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
