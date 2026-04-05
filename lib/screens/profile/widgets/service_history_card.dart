import 'package:flutter/material.dart';
import 'package:fixy_home_service/models/profile_models.dart';
import 'package:fixy_home_service/theme/app_theme.dart';
import 'package:intl/intl.dart';

class ServiceHistoryCard extends StatelessWidget {
  final ServiceHistory service;
  final Function(ServiceHistory) onReschedule;
  final Function(ServiceHistory) onCancel;
  final Function(ServiceHistory) onViewInvoice;

  const ServiceHistoryCard({
    Key? key,
    required this.service,
    required this.onReschedule,
    required this.onCancel,
    required this.onViewInvoice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('dd MMM yyyy');
    final isUpcoming = service.date.isAfter(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service header with image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Stack(
              children: [
                Image.network(
                  service.serviceImageUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 120,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported,
                        size: 40, color: Colors.grey),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusBackgroundColor(service.status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: service.getStatusColor(),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          service.getStatusDisplayName(),
                          style: TextStyle(
                            color: service.getStatusColor(),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Service details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.serviceName,
                            style: AppTheme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Profesional: ${service.professionalName}',
                            style: AppTheme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${service.currency}${service.amount.toStringAsFixed(2)}',
                        style: AppTheme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Service date, time and location
                _buildInfoRow(
                  Icons.calendar_today,
                  'Fecha: ${dateFormatter.format(service.date)}',
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.access_time,
                  'Hora: ${service.time}',
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.location_on,
                  'Dirección: ${service.address}',
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.receipt,
                  'Estado de pago: ${service.isPaid ? 'Pagado' : 'Pendiente'}',
                  iconColor: service.isPaid ? Colors.green : Colors.orange,
                ),

                const Divider(height: 24),

                // Action buttons
                Row(
                  children: [
                    if (service.isPaid && service.invoiceId.isNotEmpty)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => onViewInvoice(service),
                          icon: const Icon(Icons.receipt_long, size: 16),
                          label: const Text('Ver Factura'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    if (isUpcoming &&
                        service.status == ServiceStatus.pending) ...[
                      if (service.isPaid && service.invoiceId.isNotEmpty)
                        const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => onReschedule(service),
                          icon: const Icon(Icons.event, size: 16),
                          label: const Text('Reprogramar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => onCancel(service),
                          icon: const Icon(Icons.cancel, size: 16),
                          label: const Text('Cancelar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ),
                    ],
                    if (!isUpcoming &&
                        service.status == ServiceStatus.completed &&
                        !service.isPaid)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Handle payment
                          },
                          icon: const Icon(Icons.payment, size: 16),
                          label: const Text('Pagar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {Color? iconColor}) {
    return Row(
      children: [
        Icon(
          icon,
          color: iconColor ?? AppTheme.textSecondary,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTheme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Color _getStatusBackgroundColor(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.pending:
        return Colors.orange.withValues(alpha: 0.1);
      case ServiceStatus.inProgress:
        return Colors.blue.withValues(alpha: 0.1);
      case ServiceStatus.completed:
        return Colors.green.withValues(alpha: 0.1);
      case ServiceStatus.cancelled:
        return Colors.red.withValues(alpha: 0.1);
    }
  }
}
