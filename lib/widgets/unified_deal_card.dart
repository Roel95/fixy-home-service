import 'package:flutter/material.dart';
import 'package:fixy_home_service/models/flash_deal_item.dart';
import 'package:fixy_home_service/theme/app_theme.dart';
import 'dart:async';

class UnifiedDealCard extends StatefulWidget {
  final FlashDealItem deal;
  final VoidCallback onTap;

  const UnifiedDealCard({
    Key? key,
    required this.deal,
    required this.onTap,
  }) : super(key: key);

  @override
  State<UnifiedDealCard> createState() => _UnifiedDealCardState();
}

class _UnifiedDealCardState extends State<UnifiedDealCard> {
  Timer? _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.deal.expiresAt != null) {
      _updateTimer();
      _timer =
          Timer.periodic(const Duration(seconds: 1), (_) => _updateTimer());
    }
  }

  void _updateTimer() {
    if (widget.deal.expiresAt != null) {
      setState(() {
        _timeLeft = widget.deal.expiresAt!.difference(DateTime.now());
        if (_timeLeft.isNegative) _timeLeft = Duration.zero;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isService = widget.deal.type == FlashDealType.service;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFF6B6B).withValues(alpha: 0.1),
              const Color(0xFFFFD93D).withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B6B).withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with discount badge and type badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(18)),
                  child: Image.network(
                    widget.deal.imageUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 140,
                      color: Colors.grey[300],
                      child:
                          const Icon(Icons.image, size: 50, color: Colors.grey),
                    ),
                  ),
                ),
                // Type badge (Servicio/Producto)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isService ? Colors.blue : Colors.purple,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isService
                              ? Icons.home_repair_service
                              : Icons.shopping_bag,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isService ? 'Servicio' : 'Producto',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Discount percentage badge
                if (widget.deal.hasDiscount)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Text(
                        '-${widget.deal.discountPercentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timer (solo para servicios con fecha de expiración)
                  if (widget.deal.expiresAt != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time,
                              size: 14, color: Color(0xFFFF6B6B)),
                          const SizedBox(width: 4),
                          Text(
                            'Termina en ${_formatTime(_timeLeft)}',
                            style: const TextStyle(
                              color: Color(0xFFFF6B6B),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  // Title
                  Text(
                    widget.deal.title,
                    style: AppTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Rating
                  Row(
                    children: [
                      const Icon(Icons.star,
                          color: Color(0xFFFFC107), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.deal.rating}',
                        style: AppTheme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        ' (${widget.deal.reviewCount})',
                        style: AppTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Prices
                  Row(
                    children: [
                      if (widget.deal.originalPrice != null &&
                          widget.deal.hasDiscount) ...[
                        Text(
                          'S/${widget.deal.originalPrice!.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        'S/${widget.deal.price.toStringAsFixed(0)}',
                        style: AppTheme.textTheme.titleLarge?.copyWith(
                          color: const Color(0xFFFF6B6B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isService)
                        Text(
                          '/hr',
                          style: AppTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
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
