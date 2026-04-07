import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixy_home_service/models/service_model.dart';
import 'package:fixy_home_service/models/payment_model.dart';
import 'package:fixy_home_service/providers/payment_provider.dart';
import 'package:fixy_home_service/screens/payment_details_screen.dart';
import 'package:fixy_home_service/theme/app_theme.dart';
import 'package:fixy_home_service/utils/page_transitions.dart';

class ServicePaymentCard extends StatelessWidget {
  final ServiceModel service;

  const ServicePaymentCard({
    super.key,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Consumer<PaymentProvider>(
        builder: (context, paymentProvider, child) {
          // Create or get payment for this service
          WidgetsBinding.instance.addPostFrameCallback((_) {
            paymentProvider.createPaymentForService(service);
          });

          // Find payment for this service
          final payment = paymentProvider.payments.firstWhere(
            (p) => p.serviceId == service.id,
            orElse: () => PaymentModel.create(
              serviceId: service.id,
              totalAmount: service.price,
            ),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with service image and title
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Stack(
                  children: [
                    Image.network(
                      service.imageUrl,
                      height: 130,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 130,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported,
                            size: 40, color: Colors.grey),
                      ),
                    ),
                    _buildPaymentStatusBadge(payment.paymentStatus),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service title
                    Text(
                      service.title,
                      style: AppTheme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Location and price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: AppTheme.textLight,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              service.location,
                              style: AppTheme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                        Text(
                          '${service.currency}${service.price}/${service.timeUnit}',
                          style: AppTheme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.priceColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 24),

                    // Payment information
                    Text(
                      'Información de Pago',
                      style: AppTheme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Advance payment status
                    _buildPaymentItem(
                      'Adelanto (30%):',
                      '${service.currency}${payment.advanceAmount.toStringAsFixed(2)}',
                      payment.advancePaid,
                      isAdvance: true,
                      onPayPress: () => _navigateToPayment(context, true),
                    ),

                    const SizedBox(height: 12),

                    // Remaining payment status
                    _buildPaymentItem(
                      'Restante (70%):',
                      '${service.currency}${payment.remainingAmount.toStringAsFixed(2)}',
                      payment.remainingPaid,
                      isAdvance: false,
                      onPayPress: () => _navigateToPayment(context, false),
                      enabled: payment.advancePaid,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPaymentStatusBadge(String status) {
    Color color;
    String text;

    switch (status) {
      case 'not_paid':
        color = Colors.red;
        text = 'Pendiente';
        break;
      case 'advance_paid':
        color = Colors.orange;
        text = 'Adelanto pagado';
        break;
      case 'fully_paid':
        color = Colors.green;
        text = 'Pagado';
        break;
      default:
        color = Colors.grey;
        text = 'Desconocido';
    }

    return Positioned(
      top: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: AppTheme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentItem(
    String label,
    String amount,
    bool isPaid, {
    required bool isAdvance,
    required VoidCallback onPayPress,
    bool enabled = true,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTheme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              amount,
              style: AppTheme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (isPaid)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  'Pagado',
                  style: AppTheme.textTheme.bodySmall?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        else
          ElevatedButton(
            onPressed: enabled ? onPayPress : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              disabledBackgroundColor: Colors.grey.shade300,
            ),
            child: Text(
              'Pagar',
              style: AppTheme.textTheme.labelLarge,
            ),
          ),
      ],
    );
  }

  void _navigateToPayment(BuildContext context, bool isAdvancePayment) {
    Navigator.push(
      context,
      SlideRightRoute(
        page: PaymentDetailsScreen(
          service: service,
          isAdvancePayment: isAdvancePayment,
        ),
      ),
    );
  }
}
