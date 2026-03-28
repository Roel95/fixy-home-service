import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fixy_home_service/screens/splash_screen.dart';
import 'package:fixy_home_service/screens/provider_dashboard/provider_dashboard_screen.dart';
import 'package:fixy_home_service/screens/app_shell.dart';
import 'package:fixy_home_service/screens/auth/reset_password_screen.dart';
import 'package:fixy_home_service/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fixy_home_service/providers/payment_provider.dart';
import 'package:fixy_home_service/providers/profile_provider.dart';
import 'package:fixy_home_service/providers/reservation_provider.dart';
import 'package:fixy_home_service/providers/cart_provider.dart';
import 'package:fixy_home_service/providers/favorites_provider.dart';
import 'package:fixy_home_service/providers/provider_dashboard_provider.dart';
import 'package:fixy_home_service/supabase/supabase_config.dart';
import 'package:fixy_home_service/utils/navigation_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Supabase
    await SupabaseConfig.initialize();

    // Test connection
    final isConnected = await SupabaseConfig.testConnection();
    if (!isConnected) {
      debugPrint(
          '⚠️ [MAIN] Supabase connection test failed, but app will continue');
    }
  } catch (e) {
    debugPrint('❌ [MAIN] Failed to initialize Supabase: $e');
    // You might want to show an error dialog or handle this gracefully
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

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
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      debugPrint('🔗 [DEEP_LINK] Auth event: $event');

      if (event == AuthChangeEvent.passwordRecovery) {
        debugPrint(
            '🔐 [DEEP_LINK] Password recovery detected - navigating to reset screen');
        NavigationService.pushAndRemoveAll(
          MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
        );
      }
    });
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
        theme: lightTheme,
        debugShowCheckedModeBanner: false,
        navigatorKey: NavigationService.navigatorKey,
        home: const SplashScreen(),
        routes: {
          '/home': (context) => const AppShell(),
          '/provider-dashboard': (context) {
            final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
            return ProviderDashboardScreen(userId: userId);
          },
          '/reset-password': (context) => const ResetPasswordScreen(),
        },
      ),
    );
  }
}
