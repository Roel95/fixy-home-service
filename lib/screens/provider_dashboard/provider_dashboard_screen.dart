import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixy_home_service/providers/provider_dashboard_provider.dart';
import 'package:fixy_home_service/theme/app_theme.dart';
import 'package:fixy_home_service/screens/provider_dashboard/tabs/earnings_tab.dart';
import 'package:fixy_home_service/screens/provider_dashboard/tabs/bookings_tab.dart';
import 'package:fixy_home_service/screens/provider_dashboard/tabs/reviews_tab.dart';
import 'package:fixy_home_service/screens/provider_dashboard/tabs/analytics_tab.dart';
import 'package:fixy_home_service/screens/provider_dashboard/tabs/services_tab.dart';

class ProviderDashboardScreen extends StatefulWidget {
  final String userId;

  const ProviderDashboardScreen({required this.userId});

  @override
  State<ProviderDashboardScreen> createState() =>
      _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    // Cargar datos del proveedor
    Future.microtask(() {
      context.read<ProviderDashboardProvider>().loadProviderData(widget.userId);
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
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildBalanceCard(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  EarningsTab(),
                  BookingsTab(),
                  ServicesTab(),
                  ReviewsTab(),
                  AnalyticsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Panel de Proveedor',
                style: AppTheme.textTheme.titleLarge,
              ),
              Consumer<ProviderDashboardProvider>(
                builder: (context, provider, _) {
                  if (provider.provider == null) return const SizedBox.shrink();
                  return Text(
                    provider.provider!.businessName,
                    style: AppTheme.textTheme.bodySmall,
                  );
                },
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // TODO: Navegar a configuración
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Consumer<ProviderDashboardProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Balance Disponible',
                        style: AppTheme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'S/ ${provider.availableBalance.toStringAsFixed(2)}',
                        style: AppTheme.textTheme.displayLarge?.copyWith(
                          color: Colors.white,
                          fontSize: 32,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Total Ganado',
                      'S/ ${provider.totalEarned.toStringAsFixed(2)}',
                      Icons.trending_up,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Pendiente',
                      'S/ ${provider.pendingWithdrawal.toStringAsFixed(2)}',
                      Icons.schedule,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: provider.availableBalance >= 10
                      ? () => _showWithdrawalSheet(context)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.payment),
                  label: const Text('Solicitar Retiro'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTheme.textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTheme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: AppTheme.textSecondary,
        indicator: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: AppTheme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        tabs: const [
          Tab(text: 'Ganancias'),
          Tab(text: 'Reservas'),
          Tab(text: 'Servicios'),
          Tab(text: 'Reseñas'),
          Tab(text: 'Análisis'),
        ],
      ),
    );
  }

  void _showWithdrawalSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const WithdrawalSheet(),
    );
  }
}

class WithdrawalSheet extends StatefulWidget {
  const WithdrawalSheet();

  @override
  State<WithdrawalSheet> createState() => _WithdrawalSheetState();
}

class _WithdrawalSheetState extends State<WithdrawalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountHolderController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _amountController.dispose();
    _accountNumberController.dispose();
    _bankNameController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProviderDashboardProvider>();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Solicitar Retiro',
                          style: AppTheme.textTheme.titleLarge,
                        ),
                        Text(
                          'Disponible: S/ ${provider.availableBalance.toStringAsFixed(2)}',
                          style: AppTheme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Monto a retirar',
                  prefixText: 'S/ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppTheme.backgroundColor,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese un monto';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Monto inválido';
                  }
                  if (amount < 10) {
                    return 'Monto mínimo: S/ 10.00';
                  }
                  if (amount > provider.availableBalance) {
                    return 'Fondos insuficientes';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _accountNumberController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Número de cuenta',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppTheme.backgroundColor,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese el número de cuenta';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bankNameController,
                decoration: InputDecoration(
                  labelText: 'Banco',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppTheme.backgroundColor,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese el nombre del banco';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _accountHolderController,
                decoration: InputDecoration(
                  labelText: 'Titular de la cuenta',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppTheme.backgroundColor,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese el titular de la cuenta';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'El retiro será procesado en 24-48 horas hábiles',
                        style: AppTheme.textTheme.bodySmall?.copyWith(
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _submitWithdrawal,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Solicitar Retiro'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitWithdrawal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    final provider = context.read<ProviderDashboardProvider>();
    final success = await provider.requestWithdrawal(
      amount: double.parse(_amountController.text),
      bankAccountNumber: _accountNumberController.text,
      bankName: _bankNameController.text,
      accountHolderName: _accountHolderController.text,
    );

    setState(() => _isProcessing = false);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitud de retiro enviada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Error al procesar retiro'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
