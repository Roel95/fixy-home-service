import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixy_home_service/providers/profile_provider.dart';
import 'package:fixy_home_service/services/notification_service.dart';
import 'package:fixy_home_service/supabase/supabase_config.dart';
import 'package:fixy_home_service/theme/app_theme.dart';

class ReservationConfirmationScreen extends StatefulWidget {
  final String serviceId;
  final String serviceTitle;
  final String serviceImage;
  final String providerId;
  final String providerName;
  final String providerPhone;
  final DateTime bookingDate;
  final String timeSlot;
  final double price;
  final String currency;
  final String? address;

  const ReservationConfirmationScreen({
    super.key,
    required this.serviceId,
    required this.serviceTitle,
    required this.serviceImage,
    required this.providerId,
    required this.providerName,
    required this.providerPhone,
    required this.bookingDate,
    required this.timeSlot,
    required this.price,
    required this.currency,
    this.address,
  });

  @override
  State<ReservationConfirmationScreen> createState() =>
      _ReservationConfirmationScreenState();
}

class _ReservationConfirmationScreenState
    extends State<ReservationConfirmationScreen> {
  bool _isLoading = false;
  bool _isConfirmed = false;

  double get _advanceAmount => widget.price * 0.30;
  double get _remainingAmount => widget.price * 0.70;

  Future<void> _confirmReservation() async {
    setState(() => _isLoading = true);
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) throw Exception('Usuario no autenticado');

      final profileProvider = context.read<ProfileProvider>();
      final profile = profileProvider.userProfile;

      final data = await SupabaseConfig.client
          .from('reservations')
          .insert({
            'user_id': userId,
            'service_id': widget.serviceId,
            'service_name': widget.serviceTitle,
            'service_image_url': widget.serviceImage,
            'provider_id': widget.providerId,
            'provider_name': widget.providerName,
            'provider_phone': widget.providerPhone,
            'status': 'pending',
            'scheduled_date': widget.bookingDate.toIso8601String(),
            'scheduled_time': widget.timeSlot,
            'address': widget.address ?? profile?.address ?? '',
            'amount': widget.price,
            'currency': widget.currency,
            'is_paid': false,
            'notes': 'Reserva creada desde Asistente IA',
            'duration': 60,
            'booking_method': 'ai_assistant',
          })
          .select()
          .single();

      await SupabaseConfig.client.from('provider_bookings').insert({
        'provider_id': widget.providerId,
        'reservation_id': data['id'],
        'status': 'pending',
      });

      // Notificar al proveedor que tiene una nueva reserva
      await NotificationService.createNotification(
        userId: widget.providerId,
        title: '🔔 Nueva reserva recibida',
        body:
            'Un cliente reservó "${widget.serviceTitle}" para el ${widget.bookingDate.day}/${widget.bookingDate.month}/${widget.bookingDate.year} a las ${widget.timeSlot}',
        type: 'new_booking',
        data: {
          'reservation_id': data['id'],
          'service_name': widget.serviceTitle,
          'scheduled_date': widget.bookingDate.toIso8601String(),
          'scheduled_time': widget.timeSlot,
          'address': widget.address ?? '',
        },
      );

      // Notificar al cliente que su reserva fue creada
      await NotificationService.createNotification(
        userId: userId,
        title: '✅ Reserva confirmada',
        body:
            'Tu reserva de "${widget.serviceTitle}" fue creada para el ${widget.bookingDate.day}/${widget.bookingDate.month}/${widget.bookingDate.year} a las ${widget.timeSlot}',
        type: 'booking_confirmed',
        data: {
          'reservation_id': data['id'],
          'service_name': widget.serviceTitle,
        },
      );

      setState(() {
        _isConfirmed = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Confirmar Reserva'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: _isConfirmed ? _buildSuccessView() : _buildConfirmationView(),
    );
  }

  Widget _buildConfirmationView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
              'Detalle del Servicio',
              Column(
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.serviceImage,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.home_repair_service,
                                color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.serviceTitle,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(Icons.calendar_today,
                                  size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                  '${widget.bookingDate.day}/${widget.bookingDate.month}/${widget.bookingDate.year}',
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.grey)),
                            ]),
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(Icons.access_time,
                                  size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(widget.timeSlot,
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.grey)),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              )),
          const SizedBox(height: 16),
          Consumer<ProfileProvider>(
            builder: (context, profileProvider, _) {
              final profile = profileProvider.userProfile;
              return _buildSection(
                  'Tus Datos',
                  Column(
                    children: [
                      _buildDetailRow(
                          Icons.person, 'Nombre', profile?.name ?? ''),
                      _buildDetailRow(
                          Icons.phone, 'Teléfono', profile?.phone ?? ''),
                      _buildDetailRow(
                          Icons.location_on,
                          'Dirección',
                          widget.address ??
                              profile?.address ??
                              'No registrada'),
                    ],
                  ));
            },
          ),
          const SizedBox(height: 16),
          _buildSection(
              'Resumen de Pago',
              Column(
                children: [
                  _buildPaymentRow('Total del servicio',
                      '${widget.currency} ${widget.price.toStringAsFixed(2)}'),
                  const Divider(),
                  _buildPaymentRow('Adelanto (30%)',
                      '${widget.currency} ${_advanceAmount.toStringAsFixed(2)}',
                      isHighlighted: true),
                  _buildPaymentRow('Resto al finalizar (70%)',
                      '${widget.currency} ${_remainingAmount.toStringAsFixed(2)}',
                      isGrey: true),
                ],
              )),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF6366F1), size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Se requiere un adelanto del 30% para confirmar tu reserva. El resto se paga al finalizar el servicio.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6366F1)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _confirmReservation,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Pagar adelanto ${widget.currency} ${_advanceAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                  color: Colors.green.shade50, shape: BoxShape.circle),
              child:
                  const Icon(Icons.check_circle, color: Colors.green, size: 60),
            ),
            const SizedBox(height: 24),
            const Text('¡Reserva Confirmada!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              'Tu reserva de "${widget.serviceTitle}" fue creada exitosamente. El proveedor te contactará pronto.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Ver Mis Reservaciones',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF6366F1)),
          const SizedBox(width: 12),
          Text('$label: ',
              style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value,
      {bool isHighlighted = false, bool isGrey = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 14,
                color: isGrey ? Colors.grey : AppTheme.textPrimary,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              )),
          Text(value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isHighlighted
                    ? const Color(0xFF6366F1)
                    : isGrey
                        ? Colors.grey
                        : AppTheme.textPrimary,
              )),
        ],
      ),
    );
  }
}
