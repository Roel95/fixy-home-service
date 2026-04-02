import 'package:flutter/material.dart';
import 'package:fixy_home_service/screens/admin/tabs/products_tab.dart';
import 'package:fixy_home_service/screens/admin/tabs/orders_tab.dart';
import 'package:fixy_home_service/screens/admin/tabs/categories_tab.dart';
import 'package:fixy_home_service/screens/admin/tabs/service_categories_tab.dart';
import 'package:fixy_home_service/screens/admin/tabs/providers_tab.dart';
import 'package:fixy_home_service/screens/admin/tabs/analytics_tab.dart';
import 'package:fixy_home_service/screens/admin/tabs/users_tab.dart';

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
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });
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
                color: const Color(0xFF667EEA).withOpacity(0.1),
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
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECF3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D3748).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.shopping_bag, 'Productos', 0),
              _buildNavItem(Icons.receipt_long, 'Pedidos', 1),
              _buildNavItem(Icons.category, 'Cat. Productos', 2),
              _buildNavItem(Icons.home_repair_service, 'Cat. Servicios', 3),
              _buildNavItem(Icons.engineering, 'Proveedores', 4),
              _buildNavItem(Icons.analytics, 'Análisis', 5),
              _buildNavItem(Icons.people, 'Usuarios', 6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
          _tabController.animateTo(index);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF667EEA).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF667EEA)
                  : const Color(0xFF2D3748).withOpacity(0.6),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF667EEA)
                    : const Color(0xFF2D3748).withOpacity(0.6),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
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
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacementNamed('/home');
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
