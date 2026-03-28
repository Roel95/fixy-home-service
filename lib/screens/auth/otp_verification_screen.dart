import 'package:flutter/material.dart';
import 'package:fixy_home_service/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fixy_home_service/screens/auth/reset_password_screen.dart';
import 'package:fixy_home_service/theme/app_theme.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor ingresa el código de 6 dígitos')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      debugPrint(
          '🔐 [OTP_VERIFY] Verificando código OTP para: ${widget.email}');
      debugPrint('🔐 [OTP_VERIFY] Código ingresado: $otp');

      final response = await SupabaseConfig.auth.verifyOTP(
        email: widget.email,
        token: otp,
        type: OtpType.signup,
      );

      debugPrint('✅ [OTP_VERIFY] OTP verificado exitosamente');
      debugPrint(
          '👤 [OTP_VERIFY] Usuario autenticado: ${response.user?.email}');
      debugPrint('🎫 [OTP_VERIFY] Sesión creada: ${response.session != null}');

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Código verificado correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Wait a moment before navigating
        await Future.delayed(const Duration(milliseconds: 800));

        if (mounted) {
          // Navigate to Reset Password Screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ [OTP_VERIFY] Error al verificar OTP: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Código inválido o expirado. ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendCode() async {
    try {
      debugPrint('🔄 [OTP_RESEND] Reenviando código OTP a: ${widget.email}');
      await SupabaseConfig.auth.signInWithOtp(email: widget.email);

      debugPrint('✅ [OTP_RESEND] Código reenviado exitosamente');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Código reenviado exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [OTP_RESEND] Error al reenviar código: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al reenviar código: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Icon(
                Icons.mark_email_read_outlined,
                size: 60,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 24),
              const Text(
                'Verificación de Código',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Hemos enviado un código de 6 dígitos a ${widget.email}. Ingrésalo para continuar.',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  counterText: "",
                  hintText: '000000',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade300,
                    letterSpacing: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppTheme.primaryColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleVerify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Verificar',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: _isLoading ? null : _resendCode,
                  child: const Text(
                    '¿No recibiste el código? Reenviar',
                    style: TextStyle(color: AppTheme.primaryColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
