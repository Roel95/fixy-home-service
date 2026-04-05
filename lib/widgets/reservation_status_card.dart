import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fixy_home_service/models/reservation_status_model.dart';
import 'package:fixy_home_service/theme/app_theme.dart';

class ReservationStatusCard extends StatelessWidget {
  final ReservationStatusModel reservation;
  final VoidCallback onContactProvider;
  final VoidCallback onCancelReservation;
  final VoidCallback onViewDetails;

  const ReservationStatusCard({
    Key? key,
    required this.reservation,
    required this.onContactProvider,
    required this.onCancelReservation,
    required this.onViewDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECF3),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          const BoxShadow(
            color: Color(0xFFFFFFFF),
            offset: Offset(-4, -4),
            blurRadius: 8,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF2D3748).withValues(alpha: 0.15),
            offset: const Offset(4, 4),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with service image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Stack(
              children: [
                // Service image
                Image.network(
                  reservation.serviceImageUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported,
                        size: 50, color: Colors.grey),
                  ),
                ),
                // Gradient overlay for better text visibility
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                      stops: const [0.6, 1.0],
                    ),
                  ),
                ),
                // Service name
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reservation.serviceName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 3,
                                color: Colors.black45),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fecha: ${DateFormat('dd MMM yyyy').format(reservation.scheduledDate)} · ${reservation.scheduledTime}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          shadows: [
                            Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 3,
                                color: Colors.black45),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Status pill
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          reservation.getStatusIcon(),
                          color: reservation.getStatusColor(),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          reservation.getStatusDisplayName(),
                          style: TextStyle(
                            color: Colors.white,
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

          // Provider details
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Provider section
                Row(
                  children: [
                    // Provider image
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Image.network(
                          reservation.providerImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.person,
                                size: 30, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Provider info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Profesional:',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            reservation.providerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Estimated arrival for onTheWay status
                    if (reservation.status == ReservationStatus.onTheWay &&
                        reservation.estimatedArrival != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Llegada estimada',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('HH:mm')
                                  .format(reservation.estimatedArrival!),
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on_outlined,
                        color: Colors.grey[600], size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reservation.address,
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),

                if (reservation.notes != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.notes_outlined,
                          color: Colors.grey[600], size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reservation.notes!,
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onContactProvider,
                        icon: const Icon(Icons.phone_outlined, size: 18),
                        label: const Text('Contactar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            reservation.status == ReservationStatus.cancelled
                                ? onViewDetails
                                : onCancelReservation,
                        icon: Icon(
                            reservation.status == ReservationStatus.cancelled
                                ? Icons.info_outline
                                : Icons.cancel_outlined,
                            size: 18),
                        label: Text(
                            reservation.status == ReservationStatus.cancelled
                                ? 'Detalles'
                                : 'Cancelar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              reservation.status == ReservationStatus.cancelled
                                  ? AppTheme.primaryColor
                                  : Colors.red,
                          side: BorderSide(
                            color: reservation.status ==
                                    ReservationStatus.cancelled
                                ? AppTheme.primaryColor
                                : Colors.red,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
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
}
