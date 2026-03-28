import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixy_home_service/providers/profile_provider.dart';
import 'package:fixy_home_service/models/profile_models.dart';
import 'package:fixy_home_service/theme/app_theme.dart';
import 'package:fixy_home_service/screens/profile/widgets/service_history_card.dart';
import 'package:fixy_home_service/screens/profile/widgets/reschedule_service_dialog.dart';

class ServiceHistoryTab extends StatefulWidget {
  const ServiceHistoryTab({Key? key}) : super(key: key);

  @override
  State<ServiceHistoryTab> createState() => _ServiceHistoryTabState();
}

class _ServiceHistoryTabState extends State<ServiceHistoryTab>
    with AutomaticKeepAliveClientMixin {
  ServiceStatus _selectedFilter = ServiceStatus.pending;
  bool _showAllServices = true;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        final serviceHistory = profileProvider.serviceHistory;

        // Filter services based on the selected filter
        final filteredServices = _showAllServices
            ? serviceHistory
            : serviceHistory
                .where((service) => service.status == _selectedFilter)
                .toList();

        return Column(
          children: [
            _buildFilterBar(),
            Expanded(
              child: filteredServices.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredServices.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: ServiceHistoryCard(
                            service: filteredServices[index],
                            onReschedule: _showRescheduleDialog,
                            onCancel: _showCancelConfirmation,
                            onViewInvoice: _showInvoice,
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Historial de Servicios',
            style: AppTheme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Todos', null),
                _buildFilterChip('Pendientes', ServiceStatus.pending),
                _buildFilterChip('En Progreso', ServiceStatus.inProgress),
                _buildFilterChip('Completados', ServiceStatus.completed),
                _buildFilterChip('Cancelados', ServiceStatus.cancelled),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, ServiceStatus? status) {
    final isSelected = (status == null && _showAllServices) ||
        (status != null && !_showAllServices && status == _selectedFilter);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (status == null) {
            _showAllServices = true;
          } else {
            _showAllServices = false;
            _selectedFilter = status;
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay servicios en esta categoría',
            style: AppTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Los servicios que solicites aparecerán aquí',
            style: AppTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showRescheduleDialog(ServiceHistory service) {
    showDialog(
      context: context,
      builder: (context) => RescheduleServiceDialog(
        service: service,
        onReschedule: (DateTime newDate, String newTime) {
          Provider.of<ProfileProvider>(context, listen: false)
              .rescheduleService(service.id, newDate, newTime);
          Navigator.of(context).pop();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Servicio reprogramado para ${newDate.day}/${newDate.month}/${newDate.year} a las $newTime'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _showCancelConfirmation(ServiceHistory service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Servicio'),
        content: Text(
          '¿Estás seguro de que deseas cancelar este servicio? ${service.status == ServiceStatus.inProgress ? 'Este servicio ya está en progreso.' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No, Mantener'),
          ),
          ElevatedButton(
            onPressed: service.status == ServiceStatus.pending
                ? () {
                    Provider.of<ProfileProvider>(context, listen: false)
                        .cancelService(service.id);
                    Navigator.of(context).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Servicio cancelado exitosamente'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey,
            ),
            child: const Text('Sí, Cancelar'),
          ),
        ],
      ),
    );
  }

  void _showInvoice(ServiceHistory service) {
    if (!service.isPaid || service.invoiceId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay factura disponible para este servicio'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // In a real app, you would open or download the invoice
    // For this demo, we'll just show a dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Factura'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Factura ID: ${service.invoiceId}'),
            const SizedBox(height: 8),
            Text('Servicio: ${service.serviceName}'),
            const SizedBox(height: 8),
            Text(
                'Fecha: ${service.date.day}/${service.date.month}/${service.date.year}'),
            const SizedBox(height: 8),
            Text(
                'Monto: ${service.currency}${service.amount.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text('Estado: ${service.isPaid ? 'Pagado' : 'Pendiente de pago'}'),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.download),
            label: const Text('Descargar PDF'),
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Descargando factura...'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
