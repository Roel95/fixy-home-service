import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fixy_home_service/screens/splash_screen.dart';
import 'package:fixy_home_service/screens/provider_dashboard/provider_dashboard_screen.dart';
import 'package:fixy_home_service/screens/provider_dashboard/withdraw_screen.dart';
import 'package:fixy_home_service/screens/provider_dashboard/provider_profile_screen.dart';
import 'package:fixy_home_service/screens/reviews/submit_review_screen.dart';
import 'package:fixy_home_service/screens/auth/reset_password_screen.dart';
import 'package:fixy_home_service/screens/app_shell.dart';
import 'package:fixy_home_service/providers/payment_provider.dart';
import 'package:fixy_home_service/providers/profile_provider.dart';
import 'package:fixy_home_service/providers/reservation_provider.dart';
import 'package:fixy_home_service/providers/cart_provider.dart';
import 'package:fixy_home_service/providers/favorites_provider.dart';
import 'package:fixy_home_service/providers/provider_dashboard_provider.dart';
import 'package:fixy_home_service/supabase/supabase_config.dart';
import 'package:fixy_home_service/utils/navigation_service.dart';
import 'package:fixy_home_service/services/fcm_service.dart';
import 'package:fixy_home_service/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Supabase PRIMERO siempre
  try {
    await SupabaseConfig.initialize();
    debugPrint('✅ [MAIN] Supabase initialized');
  } catch (e) {
    debugPrint('❌ [MAIN] Supabase failed: $e');
  }

  // Inicializar Firebase por separado (opcional, no crítico)
  try {
    await Firebase.initializeApp();
    await FCMService.initialize();
    debugPrint('✅ [MAIN] Firebase initialized');
  } catch (e) {
    debugPrint('⚠️ [MAIN] Firebase failed (non-critical): $e');
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _handleDeepLinks();
  }

  void _handleDeepLinks() {
    try {
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        final event = data.event;
        debugPrint('🔗 [DEEP_LINK] Auth event: $event');

        if (event == AuthChangeEvent.passwordRecovery) {
          NavigationService.pushAndRemoveAll(
            MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
          );
        }
      });
    } catch (e) {
      debugPrint('⚠️ [DEEP_LINK] Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => ReservationProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => ProviderDashboardProvider()),
      ],
      child: MaterialApp(
        title: 'Fixy Home Service',
        theme: lightTheme.copyWith(
          textTheme: lightTheme.textTheme.apply(fontFamily: 'Lufga'),
        ),
        debugShowCheckedModeBanner: false,
        navigatorKey: NavigationService.navigatorKey,
        home: const SplashScreen(),
        routes: {
          '/home': (context) => const AppShell(),
          '/withdraw': (context) => const WithdrawScreen(),
          '/provider-dashboard': (context) {
            final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
            return ProviderDashboardScreen(userId: userId);
          },
          '/provider-profile': (context) => const ProviderProfileScreen(),
          '/submit-review': (context) => const SubmitReviewScreen(
                providerId: '',
                reservationId: '',
                providerName: '',
              ),
          '/reset-password': (context) => const ResetPasswordScreen(),
        },
      ),
    );
  }
}
