import 'package:flutter/material.dart';
import 'package:fixy_home_service/models/service_model.dart';
import 'package:fixy_home_service/theme/app_theme.dart';
import 'dart:async';

class DealCard extends StatefulWidget {
  final ServiceModel service;
  final VoidCallback onTap;

  const DealCard({
    Key? key,
    required this.service,
    required this.onTap,
  }) : super(key: key);

  @override
  State<DealCard> createState() => _DealCardState();
}

class _DealCardState extends State<DealCard> {
  Timer? _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTimer());
  }

  void _updateTimer() {
    if (widget.service.discountExpiresAt != null) {
      setState(() {
        _timeLeft =
            widget.service.discountExpiresAt!.difference(DateTime.now());
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

  double get _discountPercentage {
    if (widget.service.originalPrice == null ||
        widget.service.originalPrice! <= 0) return 0;
    return ((widget.service.originalPrice! - widget.service.price) /
        widget.service.originalPrice! *
        100);
  }

  @override
  Widget build(BuildContext context) {
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
            // Image with discount badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(18)),
                  child: Image.network(
                    widget.service.imageUrl,
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
                // Discount percentage badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      '-${_discountPercentage.toStringAsFixed(0)}%',
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
                  // Timer
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                  // Title
                  Text(
                    widget.service.title,
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
                        '${widget.service.rating}',
                        style: AppTheme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        ' (${widget.service.reviews})',
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
                      if (widget.service.originalPrice != null) ...[
                        Text(
                          '${widget.service.currency}${widget.service.originalPrice!.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        '${widget.service.currency}${widget.service.price.toStringAsFixed(0)}',
                        style: AppTheme.textTheme.titleLarge?.copyWith(
                          color: const Color(0xFFFF6B6B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '/${widget.service.timeUnit}',
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
