import 'package:flutter/material.dart';
import 'package:fixy_home_service/services/order_service.dart';

/// Pestaña de gestión de pedidos del admin
/// Permite ver, filtrar y actualizar el estado de los pedidos
class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  final OrderService _orderService = OrderService();

  List<OrderModel> _orders = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedStatus;

  final List<Map<String, dynamic>> _statusFilters = [
    {'value': null, 'label': 'Todos', 'color': 0xFF667EEA},
    {'value': 'pending', 'label': 'Pendientes', 'color': 0xFFFF9500},
    {'value': 'processing', 'label': 'Procesando', 'color': 0xFF007AFF},
    {'value': 'shipped', 'label': 'Enviados', 'color': 0xFF5856D6},
    {'value': 'delivered', 'label': 'Entregados', 'color': 0xFF34C759},
    {'value': 'cancelled', 'label': 'Cancelados', 'color': 0xFFFF3B30},
  ];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await _orderService.getUserOrders();
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error cargando pedidos: $e');
    }
  }

  List<OrderModel> get _filteredOrders {
    return _orders.where((order) {
      // Filtrar por búsqueda
      final searchLower = _searchQuery.toLowerCase();
      final matchesOrderNumber =
          order.orderNumber.toLowerCase().contains(searchLower) ?? false;
      final matchesUserName =
          order.userName?.toLowerCase().contains(searchLower) ?? false;
      final matchesSearch =
          _searchQuery.isEmpty || matchesOrderNumber || matchesUserName;

      // Filtrar por estado
      final matchesStatus =
          _selectedStatus == null || order.status == _selectedStatus;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildStatusFilter(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredOrders.isEmpty
                  ? _buildEmptyState()
                  : _buildOrdersList(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Pedidos',
                  _orders.length.toString(),
                  Icons.shopping_bag,
                  const Color(0xFF667EEA),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Pendientes',
                  _orders.where((o) => o.status == 'pending').length.toString(),
                  Icons.pending,
                  const Color(0xFFFF9500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search bar
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE8ECF3),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2D3748).withOpacity(0.1),
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
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Buscar por número o cliente...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF667EEA)),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                hintStyle: TextStyle(
                  color: const Color(0xFF2D3748).withOpacity(0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECF3),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D3748).withOpacity(0.1),
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: const Color(0xFF2D3748).withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _statusFilters.length,
        itemBuilder: (context, index) {
          final filter = _statusFilters[index];
          final isSelected = _selectedStatus == filter['value'];
          final color = Color(filter['color'] as int);

          return GestureDetector(
            onTap: () =>
                setState(() => _selectedStatus = filter['value'] as String?),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withOpacity(0.1)
                    : const Color(0xFFE8ECF3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? color : Colors.transparent,
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? null
                    : [
                        BoxShadow(
                          color: const Color(0xFF2D3748).withOpacity(0.05),
                          blurRadius: 2,
                          offset: const Offset(1, 1),
                        ),
                        const BoxShadow(
                          color: Colors.white,
                          blurRadius: 2,
                          offset: Offset(-1, -1),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected)
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Text(
                    filter['label'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? color
                          : const Color(0xFF2D3748).withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrdersList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredOrders.length,
      itemBuilder: (context, index) {
        final order = _filteredOrders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final statusColor = _getStatusColor(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECF3),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D3748).withOpacity(0.1),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showOrderModelDetails(order),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pedido #${order.orderNumber}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(order.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(0xFF2D3748).withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        order.statusText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Customer info
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF667EEA).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.person_outline,
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
                            order.userName ?? 'Cliente desconocido',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (order.userEmail != null)
                            Text(
                              order.userEmail!,
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(0xFF2D3748).withOpacity(0.6),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Items count and total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${order.totalItems} productos',
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF2D3748).withOpacity(0.7),
                      ),
                    ),
                    Text(
                      'S/ ${order.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF667EEA),
                      ),
                    ),
                  ],
                ),

                // Actions
                if (order.status != 'cancelled' && order.status != 'delivered')
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildActionButton(
                          'Actualizar Estado',
                          const Color(0xFF667EEA),
                          () => _showUpdateStatusDialog(order),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFF9500);
      case 'processing':
        return const Color(0xFF007AFF);
      case 'shipped':
        return const Color(0xFF5856D6);
      case 'delivered':
        return const Color(0xFF34C759);
      case 'cancelled':
        return const Color(0xFFFF3B30);
      default:
        return const Color(0xFF667EEA);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 80,
            color: const Color(0xFF2D3748).withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay pedidos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D3748).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Los pedidos aparecerán aquí',
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF2D3748).withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderModelDetails(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFE8ECF3),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFFE8ECF3),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8ECF3),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2D3748).withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pedido #${order.orderNumber}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status
                        _buildDetailSection('Estado del Pedido', [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getStatusColor(order.status)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _getStatusIcon(order.status),
                                  color: _getStatusColor(order.status),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  order.statusText,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _getStatusColor(order.status),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]),

                        const SizedBox(height: 24),

                        // Customer
                        _buildDetailSection('Información del Cliente', [
                          _buildDetailRow('Nombre', order.userName ?? 'N/A'),
                          _buildDetailRow('Email', order.userEmail ?? 'N/A'),
                          _buildDetailRow(
                              'Teléfono',
                              (order.shippingAddress['phone'] ?? 'N/A')
                                  .toString()),
                        ]),

                        const SizedBox(height: 24),

                        // Shipping address
                        _buildDetailSection('Dirección de Envío', [
                          _buildDetailRow(
                              'Dirección',
                              (order.shippingAddress['address_line_1'] ?? 'N/A')
                                  .toString()),
                          if (order.shippingAddress['address_line_2'] != null)
                            _buildDetailRow(
                                'Referencia',
                                order.shippingAddress['address_line_2']
                                    .toString()),
                          _buildDetailRow(
                              'Ciudad',
                              (order.shippingAddress['city'] ?? 'N/A')
                                  .toString()),
                          _buildDetailRow(
                              'País',
                              (order.shippingAddress['country'] ?? 'Perú')
                                  .toString()),
                        ]),

                        const SizedBox(height: 24),

                        // Items
                        _buildDetailSection(
                          'Productos',
                          order.items
                              .map((item) =>
                                  '${item.productName} x${item.quantity}')
                              .toList(),
                        ),

                        const SizedBox(height: 24),

                        // Totals
                        _buildDetailSection('Totales', [
                          _buildDetailRow('Subtotal',
                              'S/ ${order.subtotal.toStringAsFixed(2)}'),
                          _buildDetailRow('Envío',
                              'S/ ${order.shipping.toStringAsFixed(2)}'),
                          if (order.discount > 0)
                            _buildDetailRow('Descuento',
                                '-S/ ${order.discount.toStringAsFixed(2)}'),
                          const Divider(),
                          _buildDetailRow(
                              'TOTAL', 'S/ ${order.total.toStringAsFixed(2)}',
                              isBold: true,
                              valueColor: const Color(0xFF667EEA)),
                        ]),

                        const SizedBox(height: 24),

                        // Payment info
                        _buildDetailSection('Información de Pago', [
                          _buildDetailRow(
                              'Método', order.paymentMethod ?? 'N/A'),
                          _buildDetailRow('Estado', order.paymentStatusText),
                        ]),

                        if (order.trackingNumber != null) ...[
                          const SizedBox(height: 24),
                          _buildDetailSection('Seguimiento', [
                            _buildDetailRow(
                                'Número de tracking', order.trackingNumber!),
                          ]),
                        ],

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // Actions
                if (order.status != 'cancelled' && order.status != 'delivered')
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8ECF3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2D3748).withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        if (order.status == 'pending')
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _updateOrderStatus(order, 'processing');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF007AFF),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('Procesar Pedido'),
                            ),
                          ),
                        if (order.status == 'processing') ...[
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _showTrackingInputDialog(order);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5856D6),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('Marcar Enviado'),
                            ),
                          ),
                        ],
                        if (order.status == 'shipped')
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _updateOrderStatus(order, 'delivered');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF34C759),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('Marcar Entregado'),
                            ),
                          ),
                        const SizedBox(width: 12),
                        if (order.status != 'delivered')
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _confirmCancelOrder(order);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF3B30),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 24),
                            ),
                            child: const Text('Cancelar'),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailSection(String title, List<dynamic> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE8ECF3),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2D3748).withOpacity(0.05),
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
            children: items.map((item) {
              if (item is Widget) return item;
              if (item is String)
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              return const SizedBox.shrink();
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF2D3748).withOpacity(0.7),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? const Color(0xFF2D3748),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending;
      case 'processing':
        return Icons.sync;
      case 'shipped':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  void _showUpdateStatusDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFE8ECF3),
        title: const Text('Actualizar Estado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (order.status == 'pending')
              _buildStatusOption('Procesar Pedido', 'processing',
                  const Color(0xFF007AFF), order),
            if (order.status == 'processing')
              _buildStatusOption(
                  'Marcar Enviado', 'shipped', const Color(0xFF5856D6), order),
            if (order.status == 'shipped')
              _buildStatusOption('Marcar Entregado', 'delivered',
                  const Color(0xFF34C759), order),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOption(
      String label, String status, Color color, OrderModel order) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(_getStatusIcon(status), color: color),
      ),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        if (status == 'shipped') {
          _showTrackingInputDialog(order);
        } else {
          _updateOrderStatus(order, status);
        }
      },
    );
  }

  void _showTrackingInputDialog(OrderModel order) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFE8ECF3),
        title: const Text('Número de Tracking'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Ej: TRK123456789',
            prefixIcon: Icon(Icons.local_shipping),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _updateOrderStatus(order, 'shipped',
                  trackingNumber: controller.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5856D6),
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateOrderStatus(OrderModel order, String newStatus,
      {String? trackingNumber}) async {
    try {
      await _orderService.updateOrderStatus(order.id, newStatus);
      _loadOrders();
      _showSuccess('Estado actualizado');
    } catch (e) {
      _showError('Error actualizando estado: $e');
    }
  }

  void _confirmCancelOrder(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFE8ECF3),
        title: const Text('Cancelar Pedido'),
        content: const Text('¿Estás seguro de cancelar este pedido?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _orderService.cancelOrder(order.id);
              _loadOrders();
              _showSuccess('Pedido cancelado');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B30),
            ),
            child: const Text('Sí, Cancelar'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF3B30),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF34C759),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
