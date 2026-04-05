import 'package:flutter/material.dart';
import 'package:fixy_home_service/models/payment_model.dart';
import 'package:fixy_home_service/models/service_model.dart';
import 'package:fixy_home_service/theme/app_theme.dart';

class PaymentSummaryCard extends StatelessWidget {
  final PaymentModel payment;
  final ServiceModel service;
  final bool showPaymentStatus;

  const PaymentSummaryCard({
    Key? key,
    required this.payment,
    required this.service,
    this.showPaymentStatus = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  service.imageUrl,
                  height: 60,
                  width: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 60,
                    width: 60,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported,
                        size: 30, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.title,
                      style: AppTheme.textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.location,
                      style: AppTheme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 32),

          // Payment breakdown
          Text(
            'Detalle de Pago',
            style: AppTheme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

          // Advance payment row
          _buildPaymentRow(
            'Adelanto (30%):',
            '${service.currency}${payment.advanceAmount.toStringAsFixed(2)}',
            isPaid: payment.advancePaid,
            paymentDate: payment.advancePaymentDate,
          ),
          const SizedBox(height: 8),

          // Remaining payment row
          _buildPaymentRow(
            'Monto restante (70%):',
            '${service.currency}${payment.remainingAmount.toStringAsFixed(2)}',
            isPaid: payment.remainingPaid,
            paymentDate: payment.remainingPaymentDate,
          ),
          const SizedBox(height: 8),

          // Total amount row
          _buildPaymentRow(
            'Monto total:',
            '${service.currency}${payment.totalAmount.toStringAsFixed(2)}',
            isTotal: true,
          ),

          if (showPaymentStatus && payment.advancePaid)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 32),
                Text(
                  'Método de pago:',
                  style: AppTheme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  _getFormattedPaymentMethod(payment.paymentMethod),
                  style: AppTheme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Estado:',
                      style: AppTheme.textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 8),
                    _buildStatusTag(payment.paymentStatus),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(
    String label,
    String amount, {
    bool isPaid = false,
    bool isTotal = false,
    DateTime? paymentDate,
  }) {
    final textStyle = isTotal
        ? AppTheme.textTheme.titleMedium
        : AppTheme.textTheme.bodyMedium;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textStyle,
        ),
        Row(
          children: [
            Text(
              amount,
              style: textStyle?.copyWith(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? AppTheme.primaryColor : AppTheme.textPrimary,
              ),
            ),
            if (!isTotal && paymentDate != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 16,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStatusTag(String status) {
    Color tagColor;
    String statusText;

    switch (status) {
      case 'not_paid':
        tagColor = Colors.red;
        statusText = 'Pendiente';
        break;
      case 'advance_paid':
        tagColor = Colors.orange;
        statusText = 'Adelanto pagado';
        break;
      case 'fully_paid':
        tagColor = Colors.green;
        statusText = 'Pagado completamente';
        break;
      default:
        tagColor = Colors.grey;
        statusText = 'Desconocido';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tagColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: tagColor.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        statusText,
        style: AppTheme.textTheme.bodySmall?.copyWith(
          color: tagColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getFormattedPaymentMethod(String method) {
    switch (method) {
      case 'card':
        return 'Tarjeta de Crédito/Débito';
      case 'yape':
        return 'Yape';
      case 'plin':
        return 'Plin';
      case 'cash':
        return 'Efectivo';
      default:
        return 'No especificado';
    }
  }
}
