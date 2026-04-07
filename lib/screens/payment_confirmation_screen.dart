import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixy_home_service/models/service_model.dart';
import 'package:fixy_home_service/providers/payment_provider.dart';
import 'package:fixy_home_service/screens/app_shell.dart';
import 'package:fixy_home_service/theme/app_theme.dart';
import 'package:fixy_home_service/widgets/payment_summary_card.dart';

class PaymentConfirmationScreen extends StatelessWidget {
  final ServiceModel service;
  final bool isAdvancePayment;

  const PaymentConfirmationScreen({
    super.key,
    required this.service,
    required this.isAdvancePayment,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PaymentProvider>(
      builder: (context, paymentProvider, child) {
        final payment = paymentProvider.currentPayment;
        if (payment == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            title: Text(
              'Confirmación de Pago',
              style: AppTheme.textTheme.titleLarge,
            ),
            centerTitle: true,
            automaticallyImplyLeading: false,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 16),

                // Success icon and message
                Container(
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
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 60,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '¡Pago realizado con éxito!',
                        style: AppTheme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isAdvancePayment
                            ? 'Has realizado el pago de adelanto correctamente.'
                            : 'Has completado el pago total del servicio.',
                        textAlign: TextAlign.center,
                        style: AppTheme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isAdvancePayment
                            ? 'El restante se pagará al finalizar el servicio.'
                            : 'Gracias por confiar en nuestros servicios.',
                        textAlign: TextAlign.center,
                        style: AppTheme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),

                // Payment details
                PaymentSummaryCard(
                  payment: payment,
                  service: service,
                ),

                // Next steps instructions
                Container(
                  margin: const EdgeInsets.only(top: 16),
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
                      Text(
                        isAdvancePayment
                            ? 'Próximos pasos:'
                            : 'Servicio completado:',
                        style: AppTheme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      _buildStepItem(
                        '1',
                        isAdvancePayment
                            ? 'El profesional ha sido notificado y te contactará pronto'
                            : 'Has completado todos los pagos para este servicio',
                        Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      _buildStepItem(
                        '2',
                        isAdvancePayment
                            ? 'Coordina con el profesional los detalles del servicio'
                            : 'No olvides calificar al profesional en tu historial de servicios',
                        Colors.orange,
                      ),
                      if (isAdvancePayment) ...[
                        const SizedBox(height: 16),
                        _buildStepItem(
                          '3',
                          'Realiza el pago final cuando el servicio esté completado',
                          Colors.green,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Button to return to home
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const AppShell()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('Volver al inicio'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // Navigate to service details or booking history
                  },
                  child: const Text(
                    'Ver detalles del servicio',
                    style: TextStyle(color: AppTheme.primaryColor),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepItem(String number, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTheme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
