import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fixy_home_service/theme/app_theme.dart';
import 'package:fixy_home_service/widgets/animated_option_card.dart';
import 'package:fixy_home_service/providers/profile_provider.dart';
import 'package:fixy_home_service/screens/profile/tabs/profile_info_tab.dart';
import 'package:fixy_home_service/screens/profile/tabs/service_history_tab.dart';
import 'package:fixy_home_service/screens/profile/tabs/payment_methods_tab.dart';
import 'package:fixy_home_service/screens/profile/tabs/preferences_tab.dart';
import 'package:fixy_home_service/screens/profile/tabs/support_tab.dart';
import 'package:fixy_home_service/screens/profile/tabs/rewards_tab.dart';
import 'package:fixy_home_service/screens/profile/tabs/account_tab.dart';
import 'package:fixy_home_service/screens/profile/saved_addresses_screen.dart';
import 'package:fixy_home_service/screens/profile/profile_detail_screen.dart';
import 'package:fixy_home_service/screens/provider/provider_onboarding_screen.dart';
import 'package:fixy_home_service/screens/provider_dashboard/provider_dashboard_screen.dart';
import 'package:fixy_home_service/services/provider_service.dart';
import 'package:fixy_home_service/utils/page_transitions.dart';
import 'package:fixy_home_service/supabase/supabase_config.dart';
import 'package:fixy_home_service/screens/auth_wrapper.dart';

class ProfileOptionsScreen extends StatefulWidget {
  const ProfileOptionsScreen({Key? key}) : super(key: key);

  @override
  State<ProfileOptionsScreen> createState() => _ProfileOptionsScreenState();
}

class _ProfileOptionsScreenState extends State<ProfileOptionsScreen> {
  bool _isProvider = false;
  bool _isLoading = true;

  // Controlar la expansión de cada sección
  final Map<String, bool> _expandedSections = {
    'personal': false,
    'services': false,
    'payment': false,
    'provider': false,
    'settings': false,
    'rewards': false,
    'support': false,
    'account': false,
  };

  @override
  void initState() {
    super.initState();
    _checkProviderStatus();
  }

  Future<void> _checkProviderStatus() async {
    try {
      final isProvider = await ProviderService.isProvider();
      if (mounted) {
        setState(() {
          _isProvider = isProvider;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProvider = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      color: const Color(0xFFE8ECF3),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: Column(
          children: [
            _buildExpandableCard(
              context,
              'personal',
              'Información Personal',
              'Gestiona tu perfil y datos personales',
              Icons.person_outline,
              [
                OptionItem(
                  title: 'Editar Perfil',
                  icon: Icons.edit,
                  onTap: () => _navigateToScreen(
                      context, 'Perfil', const ProfileInfoTab()),
                ),
                OptionItem(
                  title: 'Cambiar Foto de Perfil',
                  icon: Icons.camera_alt,
                  onTap: () async {
                    debugPrint(
                        '🖱️ [PROFILE] Cambiar Foto de Perfil presionado');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Seleccionando imagen...'),
                        duration: Duration(seconds: 2),
                      ),
                    );

                    final profileProvider =
                        Provider.of<ProfileProvider>(context, listen: false);
                    await profileProvider.pickProfileImage(ImageSource.gallery);

                    if (context.mounted) {
                      if (profileProvider.errorMessage != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Error: ${profileProvider.errorMessage}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        profileProvider.clearError();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('¡Foto de perfil actualizada!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                ),
                OptionItem(
                  title: 'Direcciones Guardadas',
                  icon: Icons.location_on_outlined,
                  onTap: () => _showAddressesScreen(context),
                ),
              ],
            ),

            _buildExpandableCard(
              context,
              'services',
              'Mis Servicios',
              'Revisa tu actividad y reservas',
              Icons.history,
              [
                OptionItem(
                  title: 'Historial de Servicios',
                  icon: Icons.assignment_outlined,
                  onTap: () => _navigateToScreen(context,
                      'Historial de Servicios', const ServiceHistoryTab()),
                ),
                OptionItem(
                  title: 'Reservas Pendientes',
                  icon: Icons.pending_actions,
                  onTap: () => _showPendingReservations(context),
                ),
                OptionItem(
                  title: 'Servicios Favoritos',
                  icon: Icons.favorite_border,
                  onTap: () => _showFavoriteServices(context),
                ),
              ],
            ),

            _buildExpandableCard(
              context,
              'payment',
              'Pagos',
              'Gestiona tus métodos de pago y facturas',
              Icons.payment_outlined,
              [
                OptionItem(
                  title: 'Métodos de Pago',
                  icon: Icons.credit_card_outlined,
                  onTap: () => _navigateToScreen(
                      context, 'Métodos de Pago', const PaymentMethodsTab()),
                ),
                OptionItem(
                  title: 'Historial de Pagos',
                  icon: Icons.receipt_long_outlined,
                  onTap: () => _showPaymentHistory(context),
                ),
                OptionItem(
                  title: 'Facturas',
                  icon: Icons.description_outlined,
                  onTap: () => _showInvoices(context),
                ),
              ],
            ),

            // Mostrar sección según si es proveedor o no
            if (_isProvider)
              _buildExpandableCard(
                context,
                'provider',
                'Mi Panel de Proveedor',
                'Gestiona tus servicios y ganancias',
                Icons.business_center,
                [
                  OptionItem(
                    title: 'Ver Panel de Proveedor',
                    icon: Icons.dashboard_outlined,
                    onTap: () => _navigateToProviderDashboard(context),
                    highlighted: true,
                  ),
                  OptionItem(
                    title: 'Gestionar Servicios',
                    icon: Icons.settings_outlined,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Próximamente: Gestionar servicios')),
                      );
                    },
                  ),
                ],
              )
            else
              _buildExpandableCard(
                context,
                'provider',
                'Conviértete en Proveedor',
                'Ofrece tus servicios y genera ingresos',
                Icons.work_outline,
                [
                  OptionItem(
                    title: 'Registrarse como Proveedor',
                    icon: Icons.badge_outlined,
                    onTap: () => _handleProviderOnboarding(context),
                    badge: 'Nuevo',
                    badgeColor: AppTheme.secondaryColor,
                    highlighted: true,
                  ),
                  OptionItem(
                    title: '¿Cómo funciona?',
                    icon: Icons.info_outline,
                    onTap: () {
                      _showProviderInfoDialog(context);
                    },
                  ),
                ],
              ),

            _buildExpandableCard(
              context,
              'settings',
              'Configuración',
              'Personaliza la aplicación',
              Icons.settings_outlined,
              [
                OptionItem(
                  title: 'Preferencias',
                  icon: Icons.tune_outlined,
                  onTap: () => _navigateToScreen(
                      context, 'Preferencias', const PreferencesTab()),
                ),
                OptionItem(
                  title: 'Notificaciones',
                  icon: Icons.notifications_outlined,
                  onTap: () => _showNotificationSettings(context),
                ),
                OptionItem(
                  title: 'Idioma y Región',
                  icon: Icons.language_outlined,
                  onTap: () => _showLanguageSettings(context),
                ),
              ],
            ),

            _buildExpandableCard(
              context,
              'rewards',
              'Recompensas',
              'Consulta tus puntos y códigos promocionales',
              Icons.card_giftcard_outlined,
              [
                OptionItem(
                  title: 'Mis Puntos',
                  icon: Icons.stars_outlined,
                  onTap: () => _navigateToScreen(
                      context, 'Recompensas', const RewardsTab()),
                ),
                OptionItem(
                  title: 'Invitar Amigos',
                  icon: Icons.person_add_outlined,
                  onTap: () => _showReferralProgram(context),
                ),
                OptionItem(
                  title: 'Promociones',
                  icon: Icons.local_offer_outlined,
                  onTap: () => _showPromotions(context),
                ),
              ],
            ),

            _buildExpandableCard(
              context,
              'support',
              'Ayuda y Soporte',
              'Contacta con nosotros si necesitas ayuda',
              Icons.help_outline_outlined,
              [
                OptionItem(
                  title: 'Centro de Ayuda',
                  icon: Icons.support_outlined,
                  onTap: () => _navigateToScreen(
                      context, 'Ayuda y Soporte', const SupportTab()),
                ),
                OptionItem(
                  title: 'Preguntas Frecuentes',
                  icon: Icons.question_answer_outlined,
                  onTap: () => _showFAQs(context),
                ),
                OptionItem(
                  title: 'Contactar Soporte',
                  icon: Icons.headset_mic_outlined,
                  onTap: () => _showContactSupport(context),
                ),
              ],
            ),

            _buildExpandableCard(
              context,
              'account',
              'Cuenta',
              'Gestiona tu cuenta y privacidad',
              Icons.account_circle_outlined,
              [
                OptionItem(
                  title: 'Seguridad',
                  icon: Icons.security_outlined,
                  onTap: () =>
                      _navigateToScreen(context, 'Cuenta', const AccountTab()),
                ),
                OptionItem(
                  title: 'Privacidad',
                  icon: Icons.privacy_tip_outlined,
                  onTap: () => _showPrivacySettings(context),
                ),
                OptionItem(
                  title: 'Cerrar Sesión',
                  icon: Icons.logout_outlined,
                  onTap: () {
                    _showLogoutConfirmation(context);
                  },
                  highlighted: true,
                ),
              ],
            ),

            const SizedBox(height: 16),
            Text(
              'Versión 1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFF2D3748).withValues(alpha: 0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _showTermsAndConditions(context),
              child: const Text(
                'Términos y Condiciones',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF667EEA),
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableCard(
    BuildContext context,
    String sectionKey,
    String title,
    String subtitle,
    IconData icon,
    List<OptionItem> options,
  ) {
    final isExpanded = _expandedSections[sectionKey] ?? false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECF3),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          const BoxShadow(
            color: Color(0xFFFFFFFF),
            offset: Offset(-4, -4),
            blurRadius: 8,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF2D3748).withValues(alpha: 0.15),
            offset: const Offset(4, 4),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          color: const Color(0xFFE8ECF3),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _expandedSections[sectionKey] = !isExpanded;
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8ECF3),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            const BoxShadow(
                              color: Color(0xFFFFFFFF),
                              offset: Offset(-3, -3),
                              blurRadius: 6,
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: const Color(0xFF2D3748)
                                  .withValues(alpha: 0.15),
                              offset: const Offset(3, 3),
                              blurRadius: 6,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          color: const Color(0xFF667EEA),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2D3748),
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 13,
                                color: const Color(0xFF2D3748)
                                    .withValues(alpha: 0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: const Color(0xFF2D3748).withValues(alpha: 0.5),
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: isExpanded
                    ? Column(
                        children: [
                          ...options.map((option) {
                            return _buildOptionItem(option);
                          }).toList(),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionItem(OptionItem option) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: option.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Icon(
                option.icon,
                size: 20,
                color: const Color(0xFF667EEA),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  option.title,
                  style: TextStyle(
                    fontWeight: option.highlighted == true
                        ? FontWeight.w700
                        : FontWeight.w600,
                    fontSize: 14,
                    color: option.highlighted == true
                        ? const Color(0xFF667EEA)
                        : const Color(0xFF2D3748),
                  ),
                ),
              ),
              if (option.badge != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667EEA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    option.badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: const Color(0xFF2D3748).withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToScreen(BuildContext context, String title, Widget screen) {
    Navigator.push(
      context,
      SlideRightRoute(
        page: ProfileDetailScreen(
          title: title,
          content: screen,
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                debugPrint(
                    '🚪 [LOGOUT] Iniciando cierre de sesión desde ProfileOptionsScreen...');
                await SupabaseConfig.auth.signOut();
                await Future.delayed(const Duration(milliseconds: 800));
                if (context.mounted) {
                  debugPrint('🔄 [LOGOUT] Navegando a AuthWrapper...');
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) => const AuthWrapper()),
                    (route) => false,
                  );
                  debugPrint('✅ [LOGOUT] Cierre de sesión completado');
                }
              } catch (e) {
                debugPrint('❌ [LOGOUT] Error: $e');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Error al cerrar sesión: ${e.toString()}')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  void _handleProviderOnboarding(BuildContext context) async {
    final isAlreadyProvider = await ProviderService.isProvider();

    if (context.mounted) {
      if (isAlreadyProvider) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ya estás registrado como proveedor'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        Navigator.push(
          context,
          SlideRightRoute(
            page: const ProviderOnboardingScreen(),
          ),
        );
      }
    }
  }

  void _showProviderInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cómo funciona?'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Conviértete en proveedor y empieza a ofrecer tus servicios:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _InfoStep(
                number: '1',
                title: 'Regístrate',
                description:
                    'Completa el formulario con tu información profesional',
              ),
              const SizedBox(height: 12),
              _InfoStep(
                number: '2',
                title: 'Verificación',
                description:
                    'Nuestro equipo revisará tu solicitud en 24-48 horas',
              ),
              const SizedBox(height: 12),
              _InfoStep(
                number: '3',
                title: 'Recibe clientes',
                description:
                    'Una vez aprobado, empezarás a recibir solicitudes de servicios',
              ),
              const SizedBox(height: 12),
              _InfoStep(
                number: '4',
                title: 'Genera ingresos',
                description:
                    'Cobra por tus servicios y construye tu reputación',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleProviderOnboarding(context);
            },
            child: const Text('Empezar'),
          ),
        ],
      ),
    );
  }

  void _showAddressesScreen(BuildContext context) {
    Navigator.push(
      context,
      SlideRightRoute(
        page: const SavedAddressesScreen(),
      ),
    );
  }

  void _showPendingReservations(BuildContext context) {
    Navigator.push(
      context,
      SlideRightRoute(
        page: Scaffold(
          appBar: AppBar(title: const Text('Reservas Pendientes')),
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 3,
            itemBuilder: (context, index) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.withOpacity(0.1),
                  child:
                      const Icon(Icons.pending_actions, color: Colors.orange),
                ),
                title: Text('Servicio ${index + 1}'),
                subtitle: Text(
                    'Pendiente de confirmación\n${DateTime.now().add(Duration(days: index + 1)).toString().split(' ')[0]}'),
                isThreeLine: true,
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Ver detalles de reserva ${index + 1}')),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFavoriteServices(BuildContext context) {
    Navigator.push(
      context,
      SlideRightRoute(
        page: Scaffold(
          appBar: AppBar(title: const Text('Servicios Favoritos')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No tienes servicios favoritos',
                  style: AppTheme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Marca servicios como favoritos para verlos aquí',
                  style: AppTheme.textTheme.bodySmall
                      ?.copyWith(color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPaymentHistory(BuildContext context) {
    Navigator.push(
      context,
      SlideRightRoute(
        page: Scaffold(
          appBar: AppBar(title: const Text('Historial de Pagos')),
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 5,
            itemBuilder: (context, index) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.withOpacity(0.1),
                  child: const Icon(Icons.check_circle, color: Colors.green),
                ),
                title: Text('Pago #${1000 + index}'),
                subtitle: Text(
                    '${DateTime.now().subtract(Duration(days: index * 7)).toString().split(' ')[0]}\nTarjeta ****1234'),
                isThreeLine: true,
                trailing: Text(
                  '\$${25 + (index * 5)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showInvoices(BuildContext context) {
    Navigator.push(
      context,
      SlideRightRoute(
        page: Scaffold(
          appBar: AppBar(title: const Text('Facturas')),
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 4,
            itemBuilder: (context, index) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading:
                    const Icon(Icons.receipt, color: AppTheme.primaryColor),
                title: Text('Factura #F-${2024000 + index}'),
                subtitle: Text(DateTime.now()
                    .subtract(Duration(days: index * 15))
                    .toString()
                    .split(' ')[0]),
                trailing: IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Descargando factura...')),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showNotificationSettings(BuildContext context) {
    Navigator.push(
      context,
      SlideRightRoute(
        page: Scaffold(
          appBar: AppBar(title: const Text('Configuración de Notificaciones')),
          body: ListView(
            children: [
              SwitchListTile(
                title: const Text('Notificaciones Push'),
                subtitle: const Text('Recibe notificaciones en tu dispositivo'),
                value: true,
                onChanged: (value) {},
              ),
              SwitchListTile(
                title: const Text('Notificaciones por Email'),
                subtitle: const Text('Recibe correos con actualizaciones'),
                value: true,
                onChanged: (value) {},
              ),
              SwitchListTile(
                title: const Text('Promociones y Ofertas'),
                subtitle:
                    const Text('Recibe notificaciones de ofertas especiales'),
                value: false,
                onChanged: (value) {},
              ),
              SwitchListTile(
                title: const Text('Actualizaciones de Servicios'),
                subtitle: const Text('Estado de tus reservas y servicios'),
                value: true,
                onChanged: (value) {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageSettings(BuildContext context) {
    Navigator.push(
      context,
      SlideRightRoute(
        page: Scaffold(
          appBar: AppBar(title: const Text('Idioma y Región')),
          body: ListView(
            children: [
              RadioListTile(
                title: const Text('Español'),
                subtitle: const Text('Spanish'),
                value: 'es',
                groupValue: 'es',
                onChanged: (value) {},
              ),
              RadioListTile(
                title: const Text('English'),
                subtitle: const Text('Inglés'),
                value: 'en',
                groupValue: 'es',
                onChanged: (value) {},
              ),
              const Divider(),
              const ListTile(
                title: Text('Región',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ListTile(
                title: const Text('País'),
                subtitle: const Text('México'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReferralProgram(BuildContext context) {
    Navigator.push(
      context,
      SlideRightRoute(
        page: Scaffold(
          appBar: AppBar(title: const Text('Invitar Amigos')),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.card_giftcard,
                    size: 80, color: AppTheme.primaryColor),
                const SizedBox(height: 24),
                const Text(
                  '¡Invita a tus amigos y gana!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Comparte tu código y ambos recibirán 100 puntos cuando tu amigo realice su primera reserva',
                  style: AppTheme.textTheme.bodyMedium
                      ?.copyWith(color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryColor, width: 2),
                  ),
                  child: const Text(
                    'MARY2024',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                      letterSpacing: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Código copiado al portapapeles')),
                    );
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Compartir Código'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPromotions(BuildContext context) {
    Navigator.push(
      context,
      SlideRightRoute(
        page: Scaffold(
          appBar: AppBar(title: const Text('Promociones')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildPromotionCard(
                '30% de descuento',
                'En servicios de limpieza',
                'Válido hasta el 31 de Diciembre',
                Colors.blue,
              ),
              const SizedBox(height: 12),
              _buildPromotionCard(
                '2x1 en pinturas',
                'Compra una lata y lleva otra gratis',
                'Solo por tiempo limitado',
                Colors.orange,
              ),
              const SizedBox(height: 12),
              _buildPromotionCard(
                'Envío gratis',
                'En compras mayores a \$50',
                'Aplica para tienda online',
                Colors.green,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromotionCard(
      String title, String subtitle, String validity, Color color) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.local_offer, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle),
                  const SizedBox(height: 4),
                  Text(
                    validity,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFAQs(BuildContext context) {
    Navigator.push(
      context,
      SlideRightRoute(
        page: Scaffold(
          appBar: AppBar(title: const Text('Preguntas Frecuentes')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildFAQItem(
                '¿Cómo puedo cancelar un servicio?',
                'Puedes cancelar un servicio hasta 24 horas antes de la fecha programada sin costo alguno. Ve a "Mis Servicios" y selecciona "Cancelar".',
              ),
              _buildFAQItem(
                '¿Cuándo se me cobrará?',
                'El cobro se realiza al momento de confirmar la reserva. Aceptamos tarjetas de crédito, débito y PayPal.',
              ),
              _buildFAQItem(
                '¿Puedo cambiar la fecha de mi servicio?',
                'Sí, puedes reprogramar tu servicio hasta 12 horas antes. Solo ve al detalle del servicio y selecciona "Reprogramar".',
              ),
              _buildFAQItem(
                '¿Cómo funcionan los puntos de recompensa?',
                'Ganas 1 punto por cada dólar gastado. Puedes canjear 100 puntos por \$5 de descuento.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title:
          Text(question, style: const TextStyle(fontWeight: FontWeight.w600)),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(answer, style: TextStyle(color: Colors.grey[700])),
        ),
      ],
    );
  }

  void _showContactSupport(BuildContext context) {
    Navigator.push(
      context,
      SlideRightRoute(
        page: Scaffold(
          appBar: AppBar(title: const Text('Contactar Soporte')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading:
                      const Icon(Icons.email, color: AppTheme.primaryColor),
                  title: const Text('Email'),
                  subtitle: const Text('soporte@fixyhome.com'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Abriendo cliente de correo...')),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading:
                      const Icon(Icons.phone, color: AppTheme.primaryColor),
                  title: const Text('Teléfono'),
                  subtitle: const Text('+1 (555) 123-4567'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Llamando a soporte...')),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.chat, color: AppTheme.primaryColor),
                  title: const Text('Chat en vivo'),
                  subtitle: const Text('Lun-Vie 9:00 AM - 6:00 PM'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Iniciando chat...')),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacySettings(BuildContext context) {
    Navigator.push(
      context,
      SlideRightRoute(
        page: Scaffold(
          appBar: AppBar(title: const Text('Privacidad')),
          body: ListView(
            children: [
              SwitchListTile(
                title: const Text('Perfil Público'),
                subtitle: const Text('Otros usuarios pueden ver tu perfil'),
                value: false,
                onChanged: (value) {},
              ),
              SwitchListTile(
                title: const Text('Compartir Datos de Uso'),
                subtitle: const Text('Ayúdanos a mejorar la app'),
                value: true,
                onChanged: (value) {},
              ),
              const Divider(),
              ListTile(
                title: const Text('Política de Privacidad'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showTermsAndConditions(context),
              ),
              ListTile(
                title: const Text('Eliminar Cuenta'),
                textColor: Colors.red,
                trailing: const Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.red),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Eliminar Cuenta'),
                      content: const Text(
                          '¿Estás seguro? Esta acción no se puede deshacer.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          child: const Text('Eliminar'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToProviderDashboard(BuildContext context) async {
    // Obtener el ID del usuario actual
    final currentUser = SupabaseConfig.client.auth.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para acceder al panel'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Verificar si el usuario es proveedor
    try {
      final response = await SupabaseConfig.client
          .from('providers')
          .select('id')
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (response == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Primero debes registrarte como proveedor'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Navegar al dashboard
      if (context.mounted) {
        Navigator.push(
          context,
          SlideRightRoute(
            page: ProviderDashboardScreen(userId: currentUser.id),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showTermsAndConditions(BuildContext context) {
    Navigator.push(
      context,
      SlideRightRoute(
        page: Scaffold(
          appBar: AppBar(title: const Text('Términos y Condiciones')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Términos y Condiciones de Uso',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'Última actualización: ${DateTime.now().toString().split(' ')[0]}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                const Text(
                  '1. Aceptación de Términos\n\n'
                  'Al acceder y usar FixyHomeService, aceptas estar sujeto a estos términos y condiciones.\n\n'
                  '2. Uso del Servicio\n\n'
                  'Debes tener al menos 18 años para usar este servicio. Eres responsable de mantener la confidencialidad de tu cuenta.\n\n'
                  '3. Privacidad\n\n'
                  'Tu privacidad es importante para nosotros. Consulta nuestra Política de Privacidad para más información.\n\n'
                  '4. Modificaciones\n\n'
                  'Nos reservamos el derecho de modificar estos términos en cualquier momento.\n\n'
                  '5. Contacto\n\n'
                  'Si tienes preguntas sobre estos términos, contáctanos a soporte@fixyhome.com',
                  style: TextStyle(height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoStep extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const _InfoStep({
    Key? key,
    required this.number,
    required this.title,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
