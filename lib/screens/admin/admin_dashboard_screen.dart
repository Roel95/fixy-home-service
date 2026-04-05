import 'package:flutter/material.dart';
import 'package:fixy_home_service/screens/admin/tabs/products_tab.dart';
import 'package:fixy_home_service/screens/admin/tabs/orders_tab.dart';
import 'package:fixy_home_service/screens/admin/tabs/categories_tab.dart';
import 'package:fixy_home_service/screens/admin/tabs/service_categories_tab.dart';
import 'package:fixy_home_service/screens/admin/tabs/providers_tab.dart';
import 'package:fixy_home_service/screens/admin/tabs/analytics_tab.dart';
import 'package:fixy_home_service/screens/admin/tabs/users_tab.dart';
import 'package:fixy_home_service/screens/admin/tabs/banners_tab.dart';
import 'package:fixy_home_service/supabase/supabase_config.dart';

/// Dashboard principal para administradores de la tienda
/// Gestiona productos, pedidos, categorías y análisis
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8ECF3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8ECF3),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF667EEA).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.admin_panel_settings,
                color: Color(0xFF667EEA),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Panel Admin',
              style: TextStyle(
                color: Color(0xFF2D3748),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF2D3748)),
            onPressed: () => _showLogoutConfirmation(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFF667EEA),
          labelColor: const Color(0xFF667EEA),
          unselectedLabelColor: const Color(0xFF718096),
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(icon: Icon(Icons.shopping_bag), text: 'Productos'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Pedidos'),
            Tab(icon: Icon(Icons.category), text: 'Cat. Productos'),
            Tab(icon: Icon(Icons.home_repair_service), text: 'Cat. Servicios'),
            Tab(icon: Icon(Icons.engineering), text: 'Proveedores'),
            Tab(icon: Icon(Icons.analytics), text: 'Análisis'),
            Tab(icon: Icon(Icons.people), text: 'Usuarios'),
            Tab(icon: Icon(Icons.image), text: 'Banners'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          ProductsTab(),
          OrdersTab(),
          CategoriesTab(),
          ServiceCategoriesTab(),
          ProvidersTab(),
          AnalyticsTab(),
          UsersTab(),
          BannersTab(),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFE8ECF3),
        title: const Text('Cerrar Sesión'),
        content: const Text(
            '¿Estás seguro de que quieres salir del panel de administrador?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Cerrar sesión en Supabase
              await SupabaseConfig.client.auth.signOut();
              // Navegar a login y eliminar historial
              if (context.mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
            ),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }
}
