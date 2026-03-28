import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:fixy_home_service/supabase/supabase_config.dart';

/// Service for processing payments with Culqi
/// Requires a Supabase Edge Function to handle server-side logic
class CulqiService {
  // Para desarrollo, usa tus claves de prueba de Culqi
  // IMPORTANTE: La clave secreta debe estar en el Edge Function, NO aquí
  static const String culqiPublicKey =
      'pk_test_XXXXXXXX'; // Reemplazar con tu clave pública

  /// Create a card token (client-side)
  /// This is safe to do from the app as it only uses the public key
  static Future<Map<String, dynamic>> createToken({
    required String cardNumber,
    required String cvv,
    required String expirationMonth,
    required String expirationYear,
    required String email,
  }) async {
    try {
      debugPrint('💳 [CULQI] Creando token de tarjeta...');

      final response = await http.post(
        Uri.parse('https://secure.culqi.com/v2/tokens'),
        headers: {
          'Authorization': 'Bearer $culqiPublicKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'card_number': cardNumber.replaceAll(' ', ''),
          'cvv': cvv,
          'expiration_month': expirationMonth,
          'expiration_year': expirationYear,
          'email': email,
        }),
      );

      debugPrint('💳 [CULQI] Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        debugPrint('✅ [CULQI] Token creado: ${data['id']}');
        return data;
      } else {
        final error = jsonDecode(response.body);
        debugPrint('❌ [CULQI] Error: ${error['user_message']}');
        throw Exception(error['user_message'] ?? 'Error al procesar tarjeta');
      }
    } catch (e) {
      debugPrint('❌ [CULQI] Exception: $e');
      rethrow;
    }
  }

  /// Process payment using Supabase Edge Function (server-side)
  /// This calls your Edge Function which securely uses the secret key
  static Future<Map<String, dynamic>> processPayment({
    required String token,
    required double amount,
    required String currency,
    required String description,
    required String email,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      debugPrint('💰 [CULQI] Procesando pago...');
      debugPrint('💰 Monto: $currency ${amount.toStringAsFixed(2)}');

      // Convert amount to cents (Culqi requires amount in cents)
      final amountInCents = (amount * 100).round();

      final response = await SupabaseConfig.client.functions.invoke(
        'process-culqi-payment',
        body: {
          'token': token,
          'amount': amountInCents,
          'currency_code': currency == 'S/' ? 'PEN' : 'USD',
          'description': description,
          'email': email,
          'metadata': metadata ?? {},
        },
      );

      debugPrint('💰 [CULQI] Edge Function response: ${response.status}');

      if (response.status == 200) {
        final data = response.data as Map<String, dynamic>;

        if (data['success'] == true) {
          debugPrint('✅ [CULQI] Pago exitoso: ${data['chargeId']}');
          return data;
        } else {
          debugPrint('❌ [CULQI] Pago rechazado: ${data['error']}');
          throw Exception(data['error'] ?? 'Pago rechazado');
        }
      } else {
        debugPrint('❌ [CULQI] Error del servidor: ${response.data}');
        throw Exception('Error al procesar el pago');
      }
    } catch (e) {
      debugPrint('❌ [CULQI] Exception al procesar pago: $e');
      rethrow;
    }
  }

  /// Generate Yape QR Code (for Yape empresarial)
  /// This is a simplified version - actual implementation depends on your Yape contract
  static Future<Map<String, dynamic>> generateYapeQR({
    required double amount,
    required String orderId,
    required String phoneNumber,
  }) async {
    try {
      debugPrint('📱 [YAPE] Generando QR...');
      debugPrint('📱 Monto: S/ ${amount.toStringAsFixed(2)}');
      debugPrint('📱 Orden: $orderId');

      final response = await SupabaseConfig.client.functions.invoke(
        'generate-yape-qr',
        body: {
          'amount': amount,
          'order_id': orderId,
          'phone_number': phoneNumber,
        },
      );

      if (response.status == 200) {
        final data = response.data as Map<String, dynamic>;
        debugPrint('✅ [YAPE] QR generado: ${data['qrCode']}');
        return data;
      } else {
        debugPrint('❌ [YAPE] Error: ${response.data}');
        throw Exception('Error al generar código QR');
      }
    } catch (e) {
      debugPrint('❌ [YAPE] Exception: $e');
      rethrow;
    }
  }

  /// Check Yape payment status
  static Future<Map<String, dynamic>> checkYapePaymentStatus(
      String transactionId) async {
    try {
      debugPrint('🔍 [YAPE] Verificando estado del pago...');

      final response = await SupabaseConfig.client.functions.invoke(
        'check-yape-payment',
        body: {'transaction_id': transactionId},
      );

      if (response.status == 200) {
        final data = response.data as Map<String, dynamic>;
        debugPrint('✅ [YAPE] Estado: ${data['status']}');
        return data;
      } else {
        throw Exception('Error al verificar estado del pago');
      }
    } catch (e) {
      debugPrint('❌ [YAPE] Exception: $e');
      rethrow;
    }
  }

  /// Validate card number using Luhn algorithm
  static bool validateCardNumber(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(' ', '');

    if (cleanNumber.length < 13 || cleanNumber.length > 19) {
      return false;
    }

    int sum = 0;
    bool alternate = false;

    for (int i = cleanNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cleanNumber[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit = (digit % 10) + 1;
        }
      }

      sum += digit;
      alternate = !alternate;
    }

    return (sum % 10 == 0);
  }

  /// Get card brand from card number
  static String getCardBrand(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(' ', '');

    if (cleanNumber.startsWith('4')) return 'Visa';
    if (cleanNumber.startsWith(RegExp(r'^5[1-5]'))) return 'Mastercard';
    if (cleanNumber.startsWith(RegExp(r'^3[47]'))) return 'Amex';
    if (cleanNumber.startsWith('6011') ||
        cleanNumber.startsWith(RegExp(r'^65'))) return 'Discover';
    if (cleanNumber.startsWith(RegExp(r'^35'))) return 'JCB';

    return 'Desconocida';
  }

  /// Format card number with spaces
  static String formatCardNumber(String input) {
    final cleaned = input.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < cleaned.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(cleaned[i]);
    }

    return buffer.toString();
  }
}
