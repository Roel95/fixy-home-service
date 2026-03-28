import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixy_home_service/providers/provider_dashboard_provider.dart';
import 'package:fixy_home_service/theme/app_theme.dart';
import 'package:fixy_home_service/models/transaction_model.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsTab extends StatelessWidget {
  const AnalyticsTab();

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
              await provider.loadProviderData(provider.provider!.userId);
            }
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildStatsCards(provider),
              const SizedBox(height: 20),
              _buildEarningsChart(provider),
              const SizedBox(height: 20),
              _buildPerformanceMetrics(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsCards(ProviderDashboardProvider provider) {
    final stats = [
      {
        'title': 'Servicios Completados',
        'value': provider.provider?.completedJobs.toString() ?? '0',
        'icon': Icons.check_circle_outline,
        'color': Colors.green,
      },
      {
        'title': 'Calificación Promedio',
        'value': provider.provider?.rating.toStringAsFixed(1) ?? '0.0',
        'icon': Icons.star_outline,
        'color': AppTheme.starColor,
      },
      {
        'title': 'Total Reseñas',
        'value': provider.provider?.totalReviews.toString() ?? '0',
        'icon': Icons.rate_review_outlined,
        'color': Colors.blue,
      },
      {
        'title': 'Reservas Activas',
        'value': provider.bookings
            .where((b) => b.status.name == 'accepted')
            .length
            .toString(),
        'icon': Icons.pending_actions_outlined,
        'color': Colors.orange,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (stat['color'] as Color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      stat['icon'] as IconData,
                      color: stat['color'] as Color,
                      size: 20,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stat['value'] as String,
                    style: AppTheme.textTheme.titleLarge?.copyWith(
                      fontSize: 24,
                      color: stat['color'] as Color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stat['title'] as String,
                    style: AppTheme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEarningsChart(ProviderDashboardProvider provider) {
    // Agrupar transacciones por mes
    final monthlyEarnings = <int, double>{};
    final now = DateTime.now();

    for (var i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);
      monthlyEarnings[month.month] = 0.0;
    }

    for (var transaction in provider.transactions) {
      if (transaction.type == TransactionType.earning &&
          transaction.status == TransactionStatus.completed) {
        final month = transaction.createdAt.month;
        if (monthlyEarnings.containsKey(month)) {
          monthlyEarnings[month] =
              (monthlyEarnings[month] ?? 0) + transaction.amount;
        }
      }
    }

    final maxY = monthlyEarnings.values.isEmpty
        ? 100.0
        : monthlyEarnings.values.reduce((a, b) => a > b ? a : b) * 1.2;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                'Ganancias Mensuales',
                style: AppTheme.textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: monthlyEarnings.isEmpty
                ? Center(
                    child: Text(
                      'No hay datos disponibles',
                      style: AppTheme.textTheme.bodySmall,
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const months = [
                                'Ene',
                                'Feb',
                                'Mar',
                                'Abr',
                                'May',
                                'Jun',
                                'Jul',
                                'Ago',
                                'Sep',
                                'Oct',
                                'Nov',
                                'Dic'
                              ];
                              final index = value.toInt();
                              if (index >= 0 && index < months.length) {
                                return Text(
                                  months[index],
                                  style: AppTheme.textTheme.bodySmall
                                      ?.copyWith(fontSize: 10),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxY / 5,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.shade200,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: monthlyEarnings.entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key - 1,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value,
                              color: AppTheme.primaryColor,
                              width: 16,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics(ProviderDashboardProvider provider) {
    final acceptanceRate = provider.bookings.isEmpty
        ? 0.0
        : (provider.bookings.where((b) => b.status.name == 'accepted').length /
                provider.bookings.length) *
            100;

    final avgResponseTime = '< 1 hora'; // Placeholder

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                'Métricas de Rendimiento',
                style: AppTheme.textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildMetricRow(
            'Tasa de Aceptación',
            '${acceptanceRate.toStringAsFixed(1)}%',
            Icons.thumb_up_outlined,
            Colors.green,
            acceptanceRate / 100,
          ),
          const SizedBox(height: 16),
          _buildMetricRow(
            'Tiempo de Respuesta',
            avgResponseTime,
            Icons.timer_outlined,
            Colors.blue,
            0.8,
          ),
          const SizedBox(height: 16),
          _buildMetricRow(
            'Satisfacción del Cliente',
            '${((provider.provider?.rating ?? 0) / 5 * 100).toStringAsFixed(0)}%',
            Icons.sentiment_satisfied_alt_outlined,
            AppTheme.starColor,
            (provider.provider?.rating ?? 0) / 5,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(
      String label, String value, IconData icon, Color color, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTheme.textTheme.bodyMedium,
                  ),
                  Text(
                    value,
                    style: AppTheme.textTheme.titleMedium?.copyWith(
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
