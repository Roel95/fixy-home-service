import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:fixy_home_service/services/culqi_service.dart';
import 'package:fixy_home_service/theme/app_theme.dart';

class YapeQRScreen extends StatefulWidget {
  final double amount;
  final String orderId;
  final String phoneNumber;
  final Function(Map<String, dynamic>) onPaymentSuccess;

  const YapeQRScreen({
    Key? key,
    required this.amount,
    required this.orderId,
    required this.phoneNumber,
    required this.onPaymentSuccess,
  }) : super(key: key);

  @override
  State<YapeQRScreen> createState() => _YapeQRScreenState();
}

class _YapeQRScreenState extends State<YapeQRScreen> {
  String? _qrData;
  String? _transactionId;
  bool _isLoading = true;
  bool _isChecking = false;
  String _paymentStatus = 'pending';
  Timer? _pollingTimer;
  int _secondsRemaining = 300; // 5 minutes timeout

  @override
  void initState() {
    super.initState();
    _generateQR();
    _startCountdown();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _generateQR() async {
    try {
      final response = await CulqiService.generateYapeQR(
        amount: widget.amount,
        orderId: widget.orderId,
        phoneNumber: widget.phoneNumber,
      );

      if (mounted) {
        setState(() {
          _qrData = response['qrCode'];
          _transactionId = response['transactionId'];
          _isLoading = false;
        });

        // Start polling for payment status
        _startPolling();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar QR: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_transactionId == null || _paymentStatus != 'pending') {
        timer.cancel();
        return;
      }

      await _checkPaymentStatus();
    });
  }

  void _startCountdown() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _secondsRemaining <= 0 || _paymentStatus != 'pending') {
        timer.cancel();
        return;
      }

      setState(() => _secondsRemaining--);
    });
  }

  Future<void> _checkPaymentStatus() async {
    if (_isChecking || _transactionId == null) return;

    setState(() => _isChecking = true);

    try {
      final response =
          await CulqiService.checkYapePaymentStatus(_transactionId!);

      if (mounted) {
        setState(() {
          _paymentStatus = response['status'];
          _isChecking = false;
        });

        if (_paymentStatus == 'completed') {
          _pollingTimer?.cancel();
          widget.onPaymentSuccess(response);

          // Show success and close
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            Navigator.pop(context);
          }
        } else if (_paymentStatus == 'failed' || _paymentStatus == 'expired') {
          _pollingTimer?.cancel();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8ECF3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8ECF3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3748)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pagar con Yape',
          style: TextStyle(
            color: const Color(0xFF2D3748),
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Status indicator
                  if (_paymentStatus != 'pending')
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: _paymentStatus == 'completed'
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _paymentStatus == 'completed'
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _paymentStatus == 'completed'
                                ? Icons.check_circle
                                : Icons.error,
                            color: _paymentStatus == 'completed'
                                ? Colors.green
                                : Colors.red,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _paymentStatus == 'completed'
                                  ? '¡Pago recibido exitosamente!'
                                  : 'Pago no completado',
                              style: TextStyle(
                                color: _paymentStatus == 'completed'
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Amount card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6F2DA8), Color(0xFF9B4DCA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6F2DA8).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Total a pagar',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'S/ ${widget.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // QR Code
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        if (_qrData != null)
                          QrImageView(
                            data: _qrData!,
                            version: QrVersions.auto,
                            size: 250,
                            backgroundColor: Colors.white,
                          )
                        else
                          Container(
                            width: 250,
                            height: 250,
                            color: Colors.grey[200],
                            child: const Center(
                              child: Text('Error generando QR'),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Countdown timer
                        if (_paymentStatus == 'pending')
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.timer,
                                    size: 16, color: Colors.orange.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'Expira en ${_formatTime(_secondsRemaining)}',
                                  style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Instructions
                  Container(
                    padding: const EdgeInsets.all(20),
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
                        const Text(
                          'Cómo pagar con Yape',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInstructionStep(
                          1,
                          'Abre tu app de Yape',
                          Icons.phone_android,
                        ),
                        _buildInstructionStep(
                          2,
                          'Toca "Yapear" y luego "Escanear QR"',
                          Icons.qr_code_scanner,
                        ),
                        _buildInstructionStep(
                          3,
                          'Escanea este código QR',
                          Icons.center_focus_strong,
                        ),
                        _buildInstructionStep(
                          4,
                          'Confirma el pago en tu app',
                          Icons.check_circle_outline,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Check status button
                  if (_paymentStatus == 'pending')
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _isChecking ? null : _checkPaymentStatus,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppTheme.primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _isChecking
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(Icons.refresh, color: AppTheme.primaryColor),
                        label: Text(
                          'Verificar estado del pago',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildInstructionStep(int step, String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF6F2DA8).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$step',
                style: const TextStyle(
                  color: Color(0xFF6F2DA8),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
