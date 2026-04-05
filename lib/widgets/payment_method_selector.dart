import 'package:flutter/material.dart';
import 'package:fixy_home_service/theme/app_theme.dart';

class PaymentMethodSelector extends StatelessWidget {
  final String selectedMethod;
  final Function(String) onMethodSelected;

  const PaymentMethodSelector({
    Key? key,
    required this.selectedMethod,
    required this.onMethodSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Método de Pago',
          style: AppTheme.textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        _buildPaymentMethodCard(
          'card',
          'Tarjeta de Crédito/Débito',
          Icons.credit_card,
          'Visa, Mastercard, American Express',
        ),
        const SizedBox(height: 12),
        _buildPaymentMethodCard(
          'yape',
          'Yape',
          Icons.smartphone,
          'Pago mediante aplicación móvil',
        ),
        const SizedBox(height: 12),
        _buildPaymentMethodCard(
          'plin',
          'Plin',
          Icons.phone_android,
          'Transferencia bancaria instantánea',
        ),
        const SizedBox(height: 12),
        _buildPaymentMethodCard(
          'cash',
          'Efectivo',
          Icons.money,
          'Pago al momento de entrega',
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard(
    String methodId,
    String title,
    IconData icon,
    String subtitle,
  ) {
    final isSelected = selectedMethod == methodId;

    return GestureDetector(
      onTap: () => onMethodSelected(methodId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color:
                    isSelected ? AppTheme.primaryColor : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTheme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: methodId,
              groupValue: selectedMethod,
              onChanged: (value) => onMethodSelected(value!),
              activeColor: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
