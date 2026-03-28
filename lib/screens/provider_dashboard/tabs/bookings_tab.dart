import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixy_home_service/providers/provider_dashboard_provider.dart';
import 'package:fixy_home_service/theme/app_theme.dart';
import 'package:fixy_home_service/models/provider_booking_model.dart';
import 'package:intl/intl.dart';

class BookingsTab extends StatelessWidget {
  const BookingsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<ProviderDashboardProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final newBookings = provider.bookings
            .where((b) => b.status == ProviderBookingStatus.newBooking)
            .toList();
        final activeBookings = provider.bookings
            .where((b) => b.status == ProviderBookingStatus.accepted)
            .toList();
        final completedBookings = provider.bookings
            .where((b) => b.status == ProviderBookingStatus.completed)
            .toList();

        return RefreshIndicator(
          onRefresh: () async {
            if (provider.provider != null) {
              await provider.loadBookings();
            }
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              if (newBookings.isNotEmpty) ...[
                _buildSectionHeader('Nuevas Reservas', newBookings.length),
                const SizedBox(height: 12),
                ...newBookings.map(
                    (booking) => _buildBookingCard(context, booking, provider)),
                const SizedBox(height: 16),
              ],
              if (activeBookings.isNotEmpty) ...[
                _buildSectionHeader('Reservas Activas', activeBookings.length),
                const SizedBox(height: 12),
                ...activeBookings.map(
                    (booking) => _buildBookingCard(context, booking, provider)),
                const SizedBox(height: 16),
              ],
              if (completedBookings.isNotEmpty) ...[
                _buildSectionHeader('Completadas', completedBookings.length),
                const SizedBox(height: 12),
                ...completedBookings.map(
                    (booking) => _buildBookingCard(context, booking, provider)),
              ],
              if (provider.bookings.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_busy_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay reservas',
                          style: AppTheme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, int count) {
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
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: AppTheme.textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingCard(BuildContext context, ProviderBookingModel booking,
      ProviderDashboardProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(booking.status).withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(booking.status)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        booking.statusLabel,
                        style: AppTheme.textTheme.bodySmall?.copyWith(
                          color: _getStatusColor(booking.status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('dd/MM/yyyy').format(booking.createdAt),
                      style: AppTheme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 20,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reserva #${booking.id.substring(0, 8)}',
                        style: AppTheme.textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                if (booking.providerNotes != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.note_outlined,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            booking.providerNotes!,
                            style: AppTheme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (booking.status == ProviderBookingStatus.newBooking)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _showRejectDialog(context, booking, provider),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Rechazar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final success =
                            await provider.acceptBooking(booking.id);
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Reserva aceptada'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Aceptar'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(ProviderBookingStatus status) {
    switch (status) {
      case ProviderBookingStatus.newBooking:
        return Colors.blue;
      case ProviderBookingStatus.accepted:
        return Colors.green;
      case ProviderBookingStatus.rejected:
        return Colors.red;
      case ProviderBookingStatus.completed:
        return Colors.purple;
      case ProviderBookingStatus.cancelled:
        return Colors.grey;
    }
  }

  void _showRejectDialog(BuildContext context, ProviderBookingModel booking,
      ProviderDashboardProvider provider) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Reserva'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Motivo del rechazo',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor ingrese un motivo'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final success = await provider.rejectBooking(
                booking.id,
                reasonController.text.trim(),
              );

              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reserva rechazada'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }
}
