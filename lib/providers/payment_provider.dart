import 'package:flutter/material.dart';
import 'package:fixy_home_service/models/payment_model.dart';
import 'package:fixy_home_service/models/service_model.dart';
import 'package:fixy_home_service/supabase/supabase_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PaymentProvider extends ChangeNotifier {
  Map<String, dynamic>? _reservationData;
  List<PaymentModel> _payments = [];
  PaymentModel? _currentPayment;
  String _selectedPaymentMethod = '';
  bool _isProcessingPayment = false;
  String? _paymentError;

  List<PaymentModel> get payments => _payments;
  PaymentModel? get currentPayment => _currentPayment;
  String get selectedPaymentMethod => _selectedPaymentMethod;
  bool get isProcessingPayment => _isProcessingPayment;
  String? get paymentError => _paymentError;

  Future<void> loadPayments() async {
    final prefs = await SharedPreferences.getInstance();
    final paymentsJson = prefs.getString('payments');
    if (paymentsJson != null) {
      final List<dynamic> decodedList = jsonDecode(paymentsJson);
      _payments =
          decodedList.map((item) => PaymentModel.fromJson(item)).toList();
      notifyListeners();
    }
  }

  Future<void> savePayments() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedPayments =
        jsonEncode(_payments.map((payment) => payment.toJson()).toList());
    await prefs.setString('payments', encodedPayments);
  }

  void setCurrentPayment(PaymentModel payment) {
    _currentPayment = payment;
    notifyListeners();
  }

  Future<PaymentModel> createPaymentForService(ServiceModel service) async {
    final existingPaymentIndex =
        _payments.indexWhere((p) => p.serviceId == service.id);
    if (existingPaymentIndex >= 0) {
      _currentPayment = _payments[existingPaymentIndex];
      notifyListeners();
      return _currentPayment!;
    }
    final newPayment = PaymentModel.create(
      serviceId: service.id,
      totalAmount: service.price,
    );
    _payments.add(newPayment);
    _currentPayment = newPayment;
    await savePayments();
    notifyListeners();
    return newPayment;
  }

  void selectPaymentMethod(String method) {
    _selectedPaymentMethod = method;
    notifyListeners();
  }

  Future<bool> processAdvancePayment(
      {Map<String, dynamic>? paymentData}) async {
    if (_currentPayment == null || _selectedPaymentMethod.isEmpty) {
      _paymentError = 'No se pudo procesar el pago. Falta información.';
      notifyListeners();
      return false;
    }
    try {
      _isProcessingPayment = true;
      _paymentError = null;
      notifyListeners();
      if (paymentData == null) await Future.delayed(const Duration(seconds: 2));
      final updatedPayment = _currentPayment!.copyWith(
        advancePaid: true,
        advancePaymentDate: DateTime.now(),
        paymentMethod: _selectedPaymentMethod,
        paymentStatus: 'advance_paid',
        transactionId: paymentData?['transactionId'],
        chargeId: paymentData?['chargeId'],
      );
      final index = _payments.indexWhere((p) => p.id == _currentPayment!.id);
      if (index >= 0) {
        _payments[index] = updatedPayment;
        _currentPayment = updatedPayment;
      }
      await savePayments();
      if (_reservationData != null) {
        try {
          final reservation = await SupabaseServices.createReservation(
            serviceId: _reservationData!['serviceId'],
            providerId: _reservationData!['providerId'],
            scheduledDate: _reservationData!['scheduledDate'],
            duration: _reservationData!['duration'],
            selectedOptions: _reservationData!['selectedOptions'],
            notes: _reservationData!['notes'],
          );
          await SupabaseServices.notifyProvider(
            providerId: _reservationData!['providerId'],
            reservationId: reservation['id'],
            serviceName: _reservationData!['serviceName'],
          );
        } catch (e) {
          debugPrint('❌ [PAYMENT] Error creando reserva: $e');
        }
      }
      _isProcessingPayment = false;
      notifyListeners();
      return true;
    } catch (e) {
      _paymentError = 'Error al procesar el pago: ${e.toString()}';
      _isProcessingPayment = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> processRemainingPayment(
      {Map<String, dynamic>? paymentData}) async {
    if (_currentPayment == null || !_currentPayment!.advancePaid) {
      _paymentError =
          'Debe realizar el pago inicial antes de completar el pago.';
      notifyListeners();
      return false;
    }
    try {
      _isProcessingPayment = true;
      _paymentError = null;
      notifyListeners();
      if (paymentData == null) await Future.delayed(const Duration(seconds: 2));
      final updatedPayment = _currentPayment!.copyWith(
        remainingPaid: true,
        remainingPaymentDate: DateTime.now(),
        paymentStatus: 'fully_paid',
        transactionId: paymentData?['transactionId'],
        chargeId: paymentData?['chargeId'],
      );
      final index = _payments.indexWhere((p) => p.id == _currentPayment!.id);
      if (index >= 0) {
        _payments[index] = updatedPayment;
        _currentPayment = updatedPayment;
      }
      await savePayments();
      _isProcessingPayment = false;
      notifyListeners();
      return true;
    } catch (e) {
      _paymentError = 'Error al procesar el pago final: ${e.toString()}';
      _isProcessingPayment = false;
      notifyListeners();
      return false;
    }
  }

  void clearPaymentError() {
    _paymentError = null;
    notifyListeners();
  }

  void resetPaymentMethod() {
    _selectedPaymentMethod = '';
    notifyListeners();
  }

  void setReservationData(Map<String, dynamic> data) {
    _reservationData = data;
    notifyListeners();
  }
}
