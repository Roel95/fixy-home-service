import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixy_home_service/models/service_model.dart';
import 'package:fixy_home_service/providers/payment_provider.dart';
import 'package:fixy_home_service/screens/payment_confirmation_screen.dart';
import 'package:fixy_home_service/screens/shop/culqi_payment_screen.dart';
import 'package:fixy_home_service/screens/shop/yape_qr_screen.dart';
import 'package:fixy_home_service/utils/page_transitions.dart';
import 'package:fixy_home_service/supabase/supabase_config.dart';
import 'package:fixy_home_service/theme/app_theme.dart';
import 'package:fixy_home_service/widgets/payment_summary_card.dart';
import 'package:fixy_home_service/widgets/payment_method_selector.dart';

class PaymentDetailsScreen extends StatefulWidget {
  final ServiceModel service;
  final bool isAdvancePayment;

  const PaymentDetailsScreen({
    Key? key,
    required this.service,
    this.isAdvancePayment = true,
  }) : super(key: key);

  @override
  State<PaymentDetailsScreen> createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();

    // Reset payment method when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final paymentProvider =
          Provider.of<PaymentProvider>(context, listen: false);
      paymentProvider.resetPaymentMethod();
      paymentProvider.createPaymentForService(widget.service);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.isAdvancePayment ? 'Pago de Adelanto' : 'Pago Final',
          style: AppTheme.textTheme.titleLarge,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<PaymentProvider>(
        builder: (context, paymentProvider, child) {
          final payment = paymentProvider.currentPayment;

          if (payment == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final isAdvanceAlreadyPaid = payment.advancePaid;

          // If trying to make advance payment but it's already paid, show message
          if (widget.isAdvancePayment && isAdvanceAlreadyPaid) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'El adelanto ya ha sido pagado',
                    style: AppTheme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Puedes proceder con el pago final cuando el servicio esté completado',
                    textAlign: TextAlign.center,
                    style: AppTheme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('Volver'),
                  ),
                ],
              ),
            );
          }

          // If trying to make remaining payment but advance is not paid, show message
          if (!widget.isAdvancePayment && !isAdvanceAlreadyPaid) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.orange,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Pago de adelanto pendiente',
                    style: AppTheme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Debes realizar el pago de adelanto antes de proceder con el pago final',
                    textAlign: TextAlign.center,
                    style: AppTheme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        SlideRightRoute(
                          page: PaymentDetailsScreen(
                            service: widget.service,
                            isAdvancePayment: true,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('Realizar pago de adelanto'),
                  ),
                ],
              ),
            );
          }

          return FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Payment information header
                  Text(
                    widget.isAdvancePayment
                        ? 'Pago de Adelanto (30%)'
                        : 'Pago Final (70%)',
                    style: AppTheme.textTheme.displayLarge?.copyWith(
                      fontSize: 22,
                    ),
                  ),
                  Text(
                    widget.isAdvancePayment
                        ? 'Este adelanto reserva tu servicio'
                        : 'Realiza el pago final para completar tu servicio',
                    style: AppTheme.textTheme.bodyMedium,
                  ),

                  // Payment summary
                  PaymentSummaryCard(
                    payment: payment,
                    service: widget.service,
                    showPaymentStatus: false,
                  ),

                  // Payment amount highlight
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Total a pagar ahora',
                          style: AppTheme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.isAdvancePayment
                              ? '${widget.service.currency}${payment.advanceAmount.toStringAsFixed(2)}'
                              : '${widget.service.currency}${payment.remainingAmount.toStringAsFixed(2)}',
                          style: AppTheme.textTheme.displayLarge?.copyWith(
                            fontSize: 28,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Payment method selector
                  PaymentMethodSelector(
                    selectedMethod: paymentProvider.selectedPaymentMethod,
                    onMethodSelected: (method) {
                      paymentProvider.selectPaymentMethod(method);
                    },
                  ),

                  // Error message if any
                  if (paymentProvider.paymentError != null)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              paymentProvider.paymentError!,
                              style: AppTheme.textTheme.bodyMedium?.copyWith(
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Pay button
                  ElevatedButton(
                    onPressed: paymentProvider.selectedPaymentMethod.isEmpty ||
                            paymentProvider.isProcessingPayment
                        ? null
                        : () => _processPayment(paymentProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: paymentProvider.isProcessingPayment
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Pagar ${widget.service.currency}${widget.isAdvancePayment ? payment.advanceAmount.toStringAsFixed(2) : payment.remainingAmount.toStringAsFixed(2)}',
                            style: AppTheme.textTheme.labelLarge
                                ?.copyWith(fontSize: 16),
                          ),
                  ),
                  const SizedBox(height: 16),
                  // Terms and conditions
                  Text(
                    'Al realizar el pago aceptas nuestros términos y condiciones.',
                    textAlign: TextAlign.center,
                    style: AppTheme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _processPayment(PaymentProvider paymentProvider) async {
    final selectedMethod = paymentProvider.selectedPaymentMethod;
    final payment = paymentProvider.currentPayment!;
    final amount = widget.isAdvancePayment
        ? payment.advanceAmount
        : payment.remainingAmount;

    // Handle different payment methods
    if (selectedMethod == 'card') {
      // Process with Culqi
      await _processWithCulqi(paymentProvider, amount);
    } else if (selectedMethod == 'yape') {
      // Process with Yape QR
      await _processWithYape(paymentProvider, amount);
    } else {
      // Process as cash or other methods
      await _processStandardPayment(paymentProvider);
    }
  }

  Future<void> _processWithCulqi(
    PaymentProvider paymentProvider,
    double amount,
  ) async {
    if (!mounted) return;

    // Open Culqi payment screen
    await Navigator.push(
      context,
      SlideUpRoute(
        page: CulqiPaymentScreen(
          amount: amount,
          currency: widget.service.currency,
          description:
              'Pago ${widget.isAdvancePayment ? "adelanto" : "final"} - ${widget.service.title}',
          email: SupabaseConfig.currentUser?.email ?? 'user@example.com',
          onPaymentSuccess: (paymentData) async {
            // Process the successful payment
            bool success;
            if (widget.isAdvancePayment) {
              success = await paymentProvider.processAdvancePayment(
                paymentData: paymentData,
              );
            } else {
              success = await paymentProvider.processRemainingPayment(
                paymentData: paymentData,
              );
            }

            if (success && mounted) {
              Navigator.pushReplacement(
                context,
                FadeRoute(
                  page: PaymentConfirmationScreen(
                    service: widget.service,
                    isAdvancePayment: widget.isAdvancePayment,
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _processWithYape(
    PaymentProvider paymentProvider,
    double amount,
  ) async {
    if (!mounted) return;

    // Open Yape QR screen
    await Navigator.push(
      context,
      SlideUpRoute(
        page: YapeQRScreen(
          amount: amount,
          orderId: paymentProvider.currentPayment!.id,
          phoneNumber: SupabaseConfig.currentUser?.phone ?? '',
          onPaymentSuccess: (paymentData) async {
            // Process the successful payment
            bool success;
            if (widget.isAdvancePayment) {
              success = await paymentProvider.processAdvancePayment(
                paymentData: paymentData,
              );
            } else {
              success = await paymentProvider.processRemainingPayment(
                paymentData: paymentData,
              );
            }

            if (success && mounted) {
              Navigator.pushReplacement(
                context,
                FadeRoute(
                  page: PaymentConfirmationScreen(
                    service: widget.service,
                    isAdvancePayment: widget.isAdvancePayment,
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _processStandardPayment(PaymentProvider paymentProvider) async {
    bool success;
    if (widget.isAdvancePayment) {
      success = await paymentProvider.processAdvancePayment();
    } else {
      success = await paymentProvider.processRemainingPayment();
    }

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        FadeRoute(
          page: PaymentConfirmationScreen(
            service: widget.service,
            isAdvancePayment: widget.isAdvancePayment,
          ),
        ),
      );
    }
  }
}
