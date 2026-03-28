import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fixy_home_service/screens/onboarding_screen.dart';
import 'package:fixy_home_service/screens/app_shell.dart';
import 'package:fixy_home_service/supabase/supabase_config.dart';
import 'package:fixy_home_service/utils/navigation_service.dart';
import 'package:fixy_home_service/screens/auth/reset_password_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// AuthWrapper that listens to Supabase auth state changes
/// and automatically navigates between authenticated and unauthenticated screens
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _onboardingCompleted = false;
  bool _isProcessingOAuthCallback = false;

  @override
  void initState() {
    super.initState();
    _listenToAuthChanges();
    _checkForOAuthCallback();
    _loadOnboardingFlag();
  }

  /// Check if this is an OAuth callback and wait for Supabase to process it
  Future<void> _checkForOAuthCallback() async {
    if (kIsWeb) {
      final uri = Uri.base;
      debugPrint('🌐 [AUTH_WRAPPER] URL actual: ${uri.toString()}');
      debugPrint('🌐 [AUTH_WRAPPER] Fragment: ${uri.fragment}');
      debugPrint('🌐 [AUTH_WRAPPER] Query params: ${uri.queryParameters}');

      // Check if this is a password recovery callback
      if (uri.fragment.contains('type=recovery')) {
        debugPrint(
            '🔑 [AUTH_WRAPPER] ¡Callback de recuperación de contraseña detectado!');
        setState(() => _isProcessingOAuthCallback = true);

        // Wait for Supabase to process the recovery token
        for (int i = 0; i < 20; i++) {
          await Future.delayed(const Duration(milliseconds: 500));
          final user = SupabaseConfig.auth.currentUser;

          debugPrint(
              '🔄 [AUTH_WRAPPER] Esperando sesión de recuperación... Intento ${i + 1}/20');
          debugPrint('👤 [AUTH_WRAPPER] Usuario: ${user?.email ?? "null"}');

          if (user != null && mounted) {
            debugPrint('✅ [AUTH_WRAPPER] ¡Sesión de recuperación procesada!');

            // Navigate to password reset screen
            NavigationService.clearRootScaffold();
            NavigationService.pushAndRemoveAll(
              MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
            );
            setState(() => _isProcessingOAuthCallback = false);
            return;
          }
        }

        debugPrint(
            '⚠️ [AUTH_WRAPPER] Timeout esperando sesión de recuperación');
        if (mounted) {
          setState(() => _isProcessingOAuthCallback = false);
        }
        return;
      }

      // IMPORTANT: With PKCE flow, Supabase automatically processes the callback
      // We just need to wait a bit for the session to be established
      // The callback may not always have visible parameters in the URL
      debugPrint(
          '⏳ [AUTH_WRAPPER] Esperando procesamiento de sesión (3 segundos)...');
      await Future.delayed(const Duration(milliseconds: 3000));

      final user = SupabaseConfig.auth.currentUser;
      debugPrint(
          '👤 [AUTH_WRAPPER] Usuario después de espera inicial: ${user?.email ?? "null"}');

      if (user != null) {
        debugPrint('✅ [AUTH_WRAPPER] ¡Usuario autenticado detectado!');
        setState(() => _isProcessingOAuthCallback = true);

        await _ensureUserProfileExists(user);

        NavigationService.clearRootScaffold();
        NavigationService.pushAndRemoveAll(
          MaterialPageRoute(builder: (_) => const AppShell()),
        );

        if (mounted) {
          setState(() => _isProcessingOAuthCallback = false);
        }
        return;
      }

      debugPrint(
          'ℹ️ [AUTH_WRAPPER] No hay sesión activa, continuando flujo normal');
      _checkInitialSession();
    } else {
      _checkInitialSession();
    }
  }

  /// Check if user is already authenticated on initialization
  Future<void> _checkInitialSession() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final user = SupabaseConfig.auth.currentUser;
    debugPrint('🔍 [AUTH_WRAPPER] Verificación inicial de sesión');
    debugPrint('👤 [AUTH_WRAPPER] Usuario actual: ${user?.email ?? "null"}');

    if (user != null && mounted) {
      debugPrint(
          '✅ [AUTH_WRAPPER] Sesión activa encontrada - forzando rebuild');
      NavigationService.clearRootScaffold();
      NavigationService.pushAndRemoveAll(
        MaterialPageRoute(builder: (_) => const AppShell()),
      );
      setState(() {});
    }
  }

  Future<void> _loadOnboardingFlag() async {
    final prefs = await SharedPreferences.getInstance();
    // Web helper: allow resetting onboarding via query param
    try {
      if (kIsWeb) {
        final uri = Uri.base;
        if (uri.queryParameters['reset_onboarding'] == '1') {
          debugPrint(
              '🧹 [AUTH_WRAPPER] Reset de onboarding solicitado por URL');
          await prefs.remove('onboarding_completed');
        }
      }
    } catch (e) {
      debugPrint(
          '⚠️ [AUTH_WRAPPER] Error leyendo URL para reset onboarding: $e');
    }

    final completed = prefs.getBool('onboarding_completed') ?? false;
    debugPrint('🏁 [AUTH_WRAPPER] Onboarding completed: $completed');
    if (mounted) setState(() => _onboardingCompleted = completed);
  }

  void _listenToAuthChanges() {
    SupabaseConfig.auth.onAuthStateChange.listen((authState) async {
      final user = authState.session?.user;

      debugPrint('🔐 [AUTH_WRAPPER_LISTENER] ===== AUTH STATE CHANGE =====');
      debugPrint('🔐 [AUTH_WRAPPER_LISTENER] Event: ${authState.event}');
      debugPrint('🔐 [AUTH_WRAPPER_LISTENER] User: ${user?.email ?? "null"}');
      debugPrint(
          '🔐 [AUTH_WRAPPER_LISTENER] Session: ${authState.session != null ? "Yes" : "No"}');

      // Skip initial session event (handled by _checkForOAuthCallback)
      if (authState.event == AuthChangeEvent.initialSession) {
        debugPrint(
            '🔐 [AUTH_WRAPPER_LISTENER] Initial session event - skipping');
        return;
      }

      // If user is authenticated (any event), ensure profile exists and navigate
      if (user != null) {
        debugPrint(
            '🔐 [AUTH_WRAPPER_LISTENER] Usuario autenticado: ${user.email}');
        debugPrint(
            '🔐 [AUTH_WRAPPER_LISTENER] Provider: ${user.appMetadata['provider']}');
        debugPrint(
            '🔐 [AUTH_WRAPPER_LISTENER] User metadata: ${user.userMetadata}');

        // Ensure profile exists for all authentication methods
        await _ensureUserProfileExists(user);

        // Navegar globalmente al Home para evitar quedar en Login u otra ruta
        if (mounted) {
          debugPrint(
              '🏠 [AUTH_WRAPPER_LISTENER] Navegando al Home (AppShell) y limpiando stack...');
          NavigationService.clearRootScaffold();
          NavigationService.pushAndRemoveAll(
            MaterialPageRoute(builder: (_) => const AppShell()),
          );
          setState(() {});
        }
      } else if (authState.event == AuthChangeEvent.signedOut) {
        debugPrint('🚪 [AUTH_WRAPPER_LISTENER] Usuario deslogueado');
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  Future<void> _ensureUserProfileExists(User user) async {
    try {
      // Check if profile already exists
      final existingProfile = await SupabaseConfig.client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (existingProfile == null) {
        debugPrint(
            '👤 [AUTH_WRAPPER] Creando perfil para usuario de Google...');

        // Extract name and avatar from Google metadata
        final name = user.userMetadata?['full_name'] ??
            user.userMetadata?['name'] ??
            user.email?.split('@')[0] ??
            'Usuario';

        final avatarUrl = user.userMetadata?['avatar_url'] ??
            user.userMetadata?['picture'] ??
            '';

        debugPrint('📝 [AUTH_WRAPPER] Nombre: $name');
        debugPrint('🖼️ [AUTH_WRAPPER] Avatar: $avatarUrl');

        // Create user profile
        await SupabaseConfig.client.from('users').insert({
          'id': user.id,
          'email': user.email ?? '',
          'name': name,
          'avatar_url': avatarUrl,
          'city': 'Lima',
          'has_notifications': true,
          'referral_code': _generateReferralCode(name),
          'reward_points': 0,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        debugPrint('✅ [AUTH_WRAPPER] Perfil de usuario creado exitosamente');
      } else {
        debugPrint('ℹ️ [AUTH_WRAPPER] El perfil ya existe');
      }
    } catch (e) {
      debugPrint('❌ [AUTH_WRAPPER] Error verificando/creando perfil: $e');
    }
  }

  String _generateReferralCode(String name) {
    final cleanName = name.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    final prefix = cleanName.length >= 4
        ? cleanName.substring(0, 4)
        : cleanName.padRight(4, 'X');
    final suffix =
        DateTime.now().millisecondsSinceEpoch.toString().substring(10);
    return '$prefix$suffix';
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while processing OAuth callback
    if (_isProcessingOAuthCallback) {
      debugPrint('⏳ [AUTH_WRAPPER] Procesando callback de OAuth...');
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 16),
              CircularProgressIndicator(),
              Text('Iniciando sesión con Google...'),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<AuthState>(
      stream: SupabaseConfig.auth.onAuthStateChange,
      initialData: AuthState(
        AuthChangeEvent.initialSession,
        SupabaseConfig.auth.currentSession,
      ),
      builder: (context, snapshot) {
        debugPrint('🔐 [AUTH_WRAPPER] ===== STREAM UPDATE =====');
        debugPrint('🔐 [AUTH_WRAPPER] Event: ${snapshot.data?.event}');
        debugPrint(
            '🔐 [AUTH_WRAPPER] ConnectionState: ${snapshot.connectionState}');
        debugPrint('🔐 [AUTH_WRAPPER] HasData: ${snapshot.hasData}');

        // Always check the current session directly from Supabase
        final currentUser = SupabaseConfig.auth.currentUser;
        debugPrint(
            '🔐 [AUTH_WRAPPER] Current User: ${currentUser?.email ?? "null"}');

        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          debugPrint('⏳ [AUTH_WRAPPER] Esperando inicialización...');
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If user is authenticated, go to app
        if (currentUser != null) {
          debugPrint(
              '✅ [AUTH_WRAPPER] Usuario autenticado: ${currentUser.email}');
          return const AppShell();
        }

        // Always show Onboarding first when there is no authenticated user.
        // Onboarding will navigate to Login/Register when completed.
        debugPrint(
            '🟦 [AUTH_WRAPPER] Usuario no autenticado - mostrando Onboarding primero');
        return const OnboardingScreen();
      },
    );
  }
}
