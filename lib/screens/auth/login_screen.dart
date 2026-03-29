import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fixy_home_service/supabase/supabase_config.dart';
import 'package:fixy_home_service/screens/auth/register_screen.dart';
import 'package:fixy_home_service/screens/auth/otp_verification_screen.dart';
import 'package:fixy_home_service/screens/app_shell.dart';
import 'package:fixy_home_service/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Por favor completa todos los campos');
      return;
    }

    if (!_isValidEmail(email)) {
      _showError('Por favor ingresa un correo electrónico válido');
      return;
    }

    setState(() => _isLoading = true);

    try {
      debugPrint('🔐 [LOGIN] Intentando login con email: $email');

      final response = await SupabaseConfig.auth.signInWithPassword(
        email: email,
        password: password,
      );

      debugPrint(
          '🔐 [LOGIN] Respuesta: user=${response.user?.id}, session=${response.session != null}');

      if (!mounted) return;

      if (response.user != null) {
        _showSuccess('¡Bienvenido de vuelta!');
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AppShell()),
        );
      }
    } catch (e) {
      debugPrint('❌ [LOGIN] Error completo: $e');
      String errorMessage = 'Error al iniciar sesión';

      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('invalid_credentials') ||
          errorStr.contains('invalid login credentials')) {
        errorMessage =
            'Email o contraseña incorrectos. Verifica tus credenciales o regístrate si aún no tienes cuenta.';
      } else if (errorStr.contains('user not found')) {
        errorMessage = 'Usuario no encontrado. ¿Ya te registraste?';
      } else if (errorStr.contains('email not confirmed')) {
        errorMessage =
            'Debes confirmar tu email antes de iniciar sesión. Revisa tu correo.';
      } else if (errorStr.contains('rate limit')) {
        errorMessage =
            'Demasiados intentos. Espera un momento e intenta de nuevo.';
      } else if (errorStr.contains('network') ||
          errorStr.contains('connection')) {
        errorMessage = 'Problema de conexión. Verifica tu internet.';
      } else {
        errorMessage = 'Error: ${e.toString().split(':').last.trim()}';
      }

      _showError(errorMessage);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      debugPrint('🔑 [LOGIN] Iniciando Google Sign-In...');

      // Google Sign-In not implemented with SupabaseConfig
      debugPrint('🔑 [LOGIN] Google Sign-In no implementado aún');

      if (!mounted) return;

      _showError('No se pudo iniciar el flujo de autenticación con Google');
    } catch (e) {
      debugPrint('❌ [LOGIN] Error en Google Sign-In: $e');
      if (e.toString().contains('Error de conexión')) {
        _showError(
            'Debes configurar Google OAuth en tu Supabase Dashboard primero');
      } else {
        _showError('Error: ${e.toString()}');
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    debugPrint('🔘 [RESET] Botón "Olvidé mi contraseña" presionado');

    final emailController = TextEditingController();

    // Pre-fill if user typed something in the main email field
    if (_emailController.text.isNotEmpty &&
        _isValidEmail(_emailController.text)) {
      emailController.text = _emailController.text;
    }

    debugPrint('🖼️ [RESET] Mostrando diálogo de recuperación...');

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Recuperar contraseña',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingresa tu correo electrónico. Te enviaremos un código de 6 dígitos para restablecer tu contraseña.',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Correo electrónico',
                hintText: 'ejemplo@correo.com',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint('🔙 [RESET] Cancelar presionado');
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final email = emailController.text.trim();
              debugPrint('📤 [RESET] Enviar presionado con email: $email');
              Navigator.pop(context, email);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Enviar Código'),
          ),
        ],
      ),
    );

    debugPrint('🛑 [RESET] Diálogo cerrado. Resultado: $result');

    if (result != null && result.isNotEmpty) {
      if (!_isValidEmail(result)) {
        _showError('Por favor ingresa un correo electrónico válido');
        return;
      }

      setState(() => _isLoading = true);
      try {
        debugPrint('🚀 [RESET] Enviando código OTP a: $result');
        await SupabaseConfig.auth.signInWithOtp(email: result);

        if (!mounted) return;

        _showSuccess('¡Código enviado! Revisa tu correo electrónico.');

        // Navigate to OTP verification screen
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(email: result),
          ),
        );
      } catch (e) {
        debugPrint('❌ [RESET] Error al enviar código: $e');
        _showError(e.toString());
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      debugPrint('ℹ️ [RESET] No se ingresó email o se canceló');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline,
                color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Logo with Hero animation
                Hero(
                  tag: 'auth_logo',
                  child: SvgPicture.asset(
                    'assets/images/logo_en_color_azul.svg',
                    height: 60,
                  ),
                ),

                const SizedBox(height: 40),

                // Toggle Buttons
                Row(
                  children: [
                    Expanded(
                      child: _AuthToggleButton(
                        label: 'Iniciar sesión',
                        isSelected: true,
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _AuthToggleButton(
                        label: 'Registrarse',
                        isSelected: false,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen()),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 36),

                // Welcome Title
                const Text(
                  'Bienvenido nuevamente',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                    fontFamily: 'Gilroy',
                  ),
                ),

                const SizedBox(height: 32),

                // Email Field
                _AuthTextField(
                  controller: _emailController,
                  hintText: 'Ingrese su correo o número celular',
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 16),

                // Password Field
                _AuthTextField(
                  controller: _passwordController,
                  hintText: 'Ingrese su contraseña',
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.grey.shade400,
                      size: 24,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),

                const SizedBox(height: 8),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _handleForgotPassword,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 8),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      '¿Has olvidado tu contraseña?',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Remember Me Checkbox
                Row(
                  children: [
                    SizedBox(
                      height: 20,
                      width: 20,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (value) =>
                            setState(() => _rememberMe = value ?? false),
                        activeColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        side:
                            BorderSide(color: Colors.grey.shade400, width: 1.5),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Recordar cuenta',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(27),
                      ),
                      disabledBackgroundColor:
                          AppTheme.primaryColor.withValues(alpha: 0.6),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Iniciar sesión',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 32),

                // Divider with "Unirse con"
                Row(
                  children: [
                    Expanded(
                        child:
                            Divider(color: Colors.grey.shade300, thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Unirse con',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    Expanded(
                        child:
                            Divider(color: Colors.grey.shade300, thickness: 1)),
                  ],
                ),

                const SizedBox(height: 24),

                // Google Sign In Button with Hero animation
                Hero(
                  tag: 'google_button',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _handleGoogleSignIn,
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.grey.shade200, width: 1.5),
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/images/google_icon.svg',
                            width: 45,
                            height: 45,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AuthToggleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: isSelected
                ? null
                : Border.all(color: Colors.grey.shade300, width: 1.5),
            boxShadow: !isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.primaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;

  const _AuthTextField({
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 14,
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade300,
            fontWeight: FontWeight.w300,
          ),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 23, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide:
                const BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide:
                const BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide:
                const BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
        ),
      ),
    );
  }
}
