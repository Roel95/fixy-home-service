import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixy_home_service/providers/provider_dashboard_provider.dart';
import 'package:fixy_home_service/theme/app_theme.dart';
import 'package:fixy_home_service/models/review_model.dart';
import 'package:intl/intl.dart';

class ReviewsTab extends StatelessWidget {
  const ReviewsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<ProviderDashboardProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () async {
            if (provider.provider != null) {
              await provider.loadReviews();
            }
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildRatingSummary(provider),
              const SizedBox(height: 24),
              _buildSectionHeader('Reseñas de Clientes'),
              const SizedBox(height: 12),
              if (provider.reviews.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.rate_review_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay reseñas aún',
                          style: AppTheme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...provider.reviews.map((review) => _buildReviewCard(review)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRatingSummary(ProviderDashboardProvider provider) {
    if (provider.provider == null) return const SizedBox.shrink();

    final rating = provider.provider!.rating;
    final totalReviews = provider.provider!.totalReviews;

    // Calcular distribución de estrellas
    final starDistribution = <int, int>{};
    for (var i = 1; i <= 5; i++) {
      starDistribution[i] = provider.reviews.where((r) => r.rating == i).length;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Text(
                      rating.toStringAsFixed(1),
                      style: AppTheme.textTheme.displayLarge?.copyWith(
                        fontSize: 48,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return Icon(
                          index < rating.round()
                              ? Icons.star
                              : Icons.star_border,
                          color: AppTheme.starColor,
                          size: 20,
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalReviews reseñas',
                      style: AppTheme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 3,
                child: Column(
                  children: List.generate(5, (index) {
                    final star = 5 - index;
                    final count = starDistribution[star] ?? 0;
                    final percentage =
                        totalReviews > 0 ? (count / totalReviews) : 0.0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Text(
                            '$star',
                            style: AppTheme.textTheme.bodySmall,
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.star,
                            size: 12,
                            color: AppTheme.starColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percentage,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    AppTheme.starColor),
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            count.toString(),
                            style: AppTheme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTheme.textTheme.titleMedium,
        ),
      ],
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                child: Icon(
                  Icons.person,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Usuario #${review.userId.substring(0, 8)}',
                      style: AppTheme.textTheme.titleMedium
                          ?.copyWith(fontSize: 14),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy').format(review.createdAt),
                      style: AppTheme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.starColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: AppTheme.starColor,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      review.rating.toString(),
                      style: AppTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.starColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                review.comment!,
                style: AppTheme.textTheme.bodyMedium,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
