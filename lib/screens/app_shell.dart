import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixy_home_service/screens/home_screen.dart';
import 'package:fixy_home_service/screens/profile/profile_screen.dart';
import 'package:fixy_home_service/screens/reservations/current_service_status_screen.dart';
import 'package:fixy_home_service/screens/shop/shop_screen.dart';
import 'package:fixy_home_service/widgets/custom_bottom_nav_bar.dart';
import 'package:fixy_home_service/widgets/floating_al_button.dart';
import 'package:fixy_home_service/widgets/voice_booking_dialog.dart';
import 'package:fixy_home_service/providers/reservation_provider.dart';
import 'package:fixy_home_service/providers/cart_provider.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  // Placeholder screens
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _initScreens();
    _loadCart();
  }

  /// Cargar carrito del usuario desde Supabase al iniciar
  Future<void> _loadCart() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    await cartProvider.loadCart();
  }

  void _initScreens() {
    _screens = [
      HomeScreen(onNavigateToProfile: () => _onTabTapped(3)),
      const ShopScreen(),
      ChangeNotifierProvider(
        create: (_) => ReservationProvider(),
        child: const CurrentServiceStatusScreen(),
      ),
      const ProfileScreen(),
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openVoiceBookingDialog() {
    showDialog(
      context: context,
      builder: (context) => const VoiceBookingDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          // Botón flotante de IA (oculto en pantalla de perfil y reservas)
          if (_currentIndex != 2 && _currentIndex != 3)
            const FloatingAIButton(),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        onAITap: _openVoiceBookingDialog,
      ),
    );
  }
}
