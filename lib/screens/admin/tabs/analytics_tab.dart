import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fixy_home_service/services/order_service.dart';

/// Pestaña de análisis y estadísticas del admin
/// Muestra gráficos de ventas, pedidos y métricas clave
class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  final OrderService _orderService = OrderService();

  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<OrderModel> _recentOrders = [];

  // Período seleccionado
  String _selectedPeriod = '7d'; // 7d, 30d, 90d, 1y

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      DateTime startDate;

      switch (_selectedPeriod) {
        case '7d':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case '30d':
          startDate = now.subtract(const Duration(days: 30));
          break;
        case '90d':
          startDate = now.subtract(const Duration(days: 90));
          break;
        case '1y':
          startDate = now.subtract(const Duration(days: 365));
          break;
        default:
          startDate = now.subtract(const Duration(days: 30));
      }

      final stats = await _orderService.getOrderStats(
        startDate: startDate,
        endDate: now,
      );

      final recentOrders = await _orderService.getRecentOrders(limit: 5);

      setState(() {
        _stats = stats;
        _recentOrders = recentOrders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period selector
          _buildPeriodSelector(),
          const SizedBox(height: 20),

          // Stats cards
          _buildStatsGrid(),
          const SizedBox(height: 24),

          // Sales chart
          _buildSalesChart(),
          const SizedBox(height: 24),

          // Recent orders
          _buildRecentOrdersSection(),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = [
      {'value': '7d', 'label': '7 días'},
      {'value': '30d', 'label': '30 días'},
      {'value': '90d', 'label': '3 meses'},
      {'value': '1y', 'label': '1 año'},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECF3),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D3748).withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
          const BoxShadow(
            color: Colors.white,
            blurRadius: 4,
            offset: Offset(-2, -2),
          ),
        ],
      ),
      child: Row(
        children: periods.map((period) {
          final isSelected = _selectedPeriod == period['value'];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedPeriod = period['value']!);
                _loadAnalytics();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color:
                      isSelected ? const Color(0xFF667EEA) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  period['label']!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? Colors.white : const Color(0xFF2D3748),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final totalSales = (_stats['total_sales'] as num?)?.toDouble() ?? 0.0;
    final totalOrders = (_stats['total_orders'] as num?)?.toInt() ?? 0;

    // Calcular promedio por pedido
    final avgOrderValue = totalOrders > 0 ? totalSales / totalOrders : 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Ventas Totales',
                'S/ ${totalSales.toStringAsFixed(2)}',
                Icons.attach_money,
                const Color(0xFF34C759),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Pedidos',
                totalOrders.toString(),
                Icons.shopping_bag,
                const Color(0xFF667EEA),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Promedio por Pedido',
                'S/ ${avgOrderValue.toStringAsFixed(2)}',
                Icons.trending_up,
                const Color(0xFFFF9500),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Productos Vendidos',
                _calculateTotalItems().toString(),
                Icons.inventory,
                const Color(0xFF5856D6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  int _calculateTotalItems() {
    int total = 0;
    for (final order in _recentOrders) {
      total += order.totalItems;
    }
    return total;
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECF3),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D3748).withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
          const BoxShadow(
            color: Colors.white,
            blurRadius: 4,
            offset: Offset(-2, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF2D3748).withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChart() {
    // Datos de ejemplo para el gráfico
    // En producción, estos vendrían del backend
    final spots = [
      const FlSpot(0, 500),
      const FlSpot(1, 800),
      const FlSpot(2, 600),
      const FlSpot(3, 1200),
      const FlSpot(4, 900),
      const FlSpot(5, 1500),
      const FlSpot(6, 2000),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECF3),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D3748).withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
          const BoxShadow(
            color: Colors.white,
            blurRadius: 4,
            offset: Offset(-2, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ventas (últimos 7 días)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 500,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: const Color(0xFF2D3748).withValues(alpha: 0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final days = [
                          'Lun',
                          'Mar',
                          'Mié',
                          'Jue',
                          'Vie',
                          'Sáb',
                          'Dom'
                        ];
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              days[value.toInt()],
                              style: TextStyle(
                                fontSize: 11,
                                color: const Color(0xFF2D3748)
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 500,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          'S/${value.toInt()}',
                          style: TextStyle(
                            fontSize: 10,
                            color:
                                const Color(0xFF2D3748).withValues(alpha: 0.6),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 2500,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFF667EEA),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF667EEA).withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrdersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Pedidos Recientes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navegar a la pestaña de pedidos
              },
              child: const Text(
                'Ver todos',
                style: TextStyle(
                  color: Color(0xFF667EEA),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _recentOrders.isEmpty
            ? _buildEmptyRecentOrders()
            : Column(
                children: _recentOrders
                    .map((order) => _buildOrderItem(order))
                    .toList(),
              ),
      ],
    );
  }

  Widget _buildEmptyRecentOrders() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECF3),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D3748).withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
          const BoxShadow(
            color: Colors.white,
            blurRadius: 4,
            offset: Offset(-2, -2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 48,
              color: const Color(0xFF2D3748).withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'No hay pedidos recientes',
              style: TextStyle(
                color: const Color(0xFF2D3748).withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECF3),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D3748).withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
          const BoxShadow(
            color: Colors.white,
            blurRadius: 4,
            offset: Offset(-2, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF667EEA).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.shopping_bag,
              color: Color(0xFF667EEA),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${order.orderNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  order.userName ?? 'Cliente desconocido',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF2D3748).withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'S/ ${order.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF667EEA),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatDate(order.createdAt),
                style: TextStyle(
                  fontSize: 11,
                  color: const Color(0xFF2D3748).withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
