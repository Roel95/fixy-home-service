import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixy_home_service/providers/profile_provider.dart';
import 'package:fixy_home_service/theme/app_theme.dart';
import 'package:fixy_home_service/screens/legal/terms_conditions_screen.dart';
import 'package:fixy_home_service/screens/legal/privacy_policy_screen.dart';
import 'package:fixy_home_service/screens/shop/orders_history_screen.dart';
import 'package:fixy_home_service/supabase/supabase_config.dart';
import 'package:fixy_home_service/supabase/supabase_service.dart';
import 'package:fixy_home_service/screens/auth_wrapper.dart';

class AccountTab extends StatefulWidget {
  const AccountTab({Key? key}) : super(key: key);

  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Account options section
            _buildSectionHeader(
                'Opciones de Cuenta', Icons.account_circle_outlined),
            const SizedBox(height: 16),
            _buildAccountOptionCard(
              'Mis Pedidos',
              'Ver historial de compras',
              Icons.shopping_bag_outlined,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const OrdersHistoryScreen()),
                );
              },
            ),
            _buildAccountOptionCard(
              'Exportar Datos',
              'Descarga toda tu información',
              Icons.download_outlined,
              () => _exportUserData(),
            ),
            _buildAccountOptionCard(
              'Historial de Sesión',
              'Revisa tu actividad reciente',
              Icons.history,
              () => _viewLoginHistory(),
            ),
            _buildAccountOptionCard(
              'Notificaciones de Seguridad',
              'Alerta sobre accesos sospechosos',
              Icons.security,
              () => _toggleSecurityAlerts(),
            ),

            const SizedBox(height: 24),

            // Legal section
            _buildSectionHeader('Legal', Icons.gavel_outlined),
            const SizedBox(height: 16),
            _buildAccountOptionCard(
              'Términos y Condiciones',
              'Revisa nuestros términos',
              Icons.description_outlined,
              () => _viewTermsAndConditions(),
            ),
            _buildAccountOptionCard(
              'Política de Privacidad',
              'Cómo manejamos tus datos',
              Icons.privacy_tip_outlined,
              () => _viewPrivacyPolicy(),
            ),
            _buildAccountOptionCard(
              'Licencias de Terceros',
              'Librerías y recursos utilizados',
              Icons.integration_instructions_outlined,
              () => _viewThirdPartyLicenses(),
            ),

            const SizedBox(height: 24),

            // Account actions section
            _buildSectionHeader(
                'Acciones', Icons.admin_panel_settings_outlined),
            const SizedBox(height: 16),
            _buildAccountActionCard(
              'Eliminar Cuenta',
              'Eliminar permanentemente tu cuenta y datos',
              Icons.delete_forever,
              Colors.red,
              () => _showDeleteAccountConfirmation(),
            ),

            const SizedBox(height: 24),

            // App information
            _buildAppInfo(),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountOptionCard(
      String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildAccountActionCard(String title, String subtitle, IconData icon,
      Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        onTap: onTap,
      ),
    );
  }

  Widget _buildAppInfo() {
    return Center(
      child: Column(
        children: [
          const FlutterLogo(size: 60),
          const SizedBox(height: 16),
          Text(
            'Service Marketplace App',
            style: AppTheme.textTheme.titleMedium,
          ),
          Text(
            'Versión 1.0.0',
            style: AppTheme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            '© 2023 DreamFlow. Todos los derechos reservados.',
            style: AppTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }

  void _exportUserData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exportar Datos'),
        content: const Text(
          'Se generará un archivo con todos tus datos personales, historial de servicios, pagos y preferencias. Este proceso puede tardar unos minutos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Exportando datos. Recibirás un email cuando esté listo.'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Exportar'),
          ),
        ],
      ),
    );
  }

  void _viewLoginHistory() {
    // In a real app, this would show the login history
    // For now, we'll just show a dialog with mock data
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Historial de Sesión'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildLoginHistoryItem(
                'Ahora',
                'Este dispositivo',
                'Lima, Perú',
                true,
              ),
              _buildLoginHistoryItem(
                'Ayer, 15:30',
                'iPhone 13',
                'Lima, Perú',
                false,
              ),
              _buildLoginHistoryItem(
                '15 May, 09:45',
                'MacBook Pro',
                'Lima, Perú',
                false,
              ),
              _buildLoginHistoryItem(
                '10 May, 18:20',
                'Windows PC',
                'Lima, Perú',
                false,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginHistoryItem(
      String time, String device, String location, bool isCurrentDevice) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCurrentDevice
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCurrentDevice ? Icons.phone_android : Icons.devices,
              color: isCurrentDevice ? Colors.green : Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      device,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      time,
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  location,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                if (isCurrentDevice) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Sesión actual',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleSecurityAlerts() {
    // In a real app, this would toggle security alerts
    // For now, we'll just show a dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notificaciones de Seguridad'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: Text('Inicios de sesión nuevos'),
              subtitle: Text(
                  'Recibe alertas cuando ingreses desde un nuevo dispositivo'),
              value: true,
              onChanged: null,
            ),
            SwitchListTile(
              title: Text('Cambios en la cuenta'),
              subtitle:
                  Text('Recibe alertas cuando se modifiquen datos importantes'),
              value: true,
              onChanged: null,
            ),
            SwitchListTile(
              title: Text('Actividad sospechosa'),
              subtitle: Text('Recibe alertas sobre comportamientos inusuales'),
              value: true,
              onChanged: null,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Preferencias de seguridad actualizadas'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _viewTermsAndConditions() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const TermsConditionsScreen(),
      ),
    );
  }

  void _viewPrivacyPolicy() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PrivacyPolicyScreen(),
      ),
    );
  }

  void _viewThirdPartyLicenses() {
    // In a real app, this would open the third-party licenses
    // For now, we'll just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Abriendo Licencias de Terceros...')),
    );
  }

  void _showLogoutConfirmation() {
    debugPrint('🔵 [LOGOUT] Mostrando diálogo de confirmación...');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint('❌ [LOGOUT] Cancelado por usuario');
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              debugPrint('🟢 [LOGOUT] ===== BOTÓN PRESIONADO =====');
              try {
                debugPrint('🚪 [LOGOUT] ===== INICIO CIERRE DE SESIÓN =====');
                debugPrint(
                    '🚪 [LOGOUT] Usuario ANTES: ${SupabaseConfig.currentUser?.email}');

                // Close confirmation dialog
                Navigator.of(dialogContext).pop();

                // Clear provider state first
                if (mounted) {
                  debugPrint('🧹 [LOGOUT] Limpiando estado de providers...');
                  context.read<ProfileProvider>().clearSession();
                }

                // Sign out from Supabase
                debugPrint(
                    '🔐 [LOGOUT] Llamando a SupabaseConfig.auth.signOut()...');
                await SupabaseConfig.auth.signOut();

                debugPrint('✅ [LOGOUT] Sesión cerrada exitosamente');
                debugPrint(
                    '🚪 [LOGOUT] Usuario DESPUÉS: ${SupabaseConfig.currentUser?.email ?? "null"}');

                // CRITICAL: Add delay to let Supabase auth state propagate
                await Future.delayed(const Duration(milliseconds: 800));

                // Navigate to AuthWrapper and clear all navigation stack
                if (mounted) {
                  debugPrint(
                      '🔄 [LOGOUT] Limpiando stack de navegación y volviendo a AuthWrapper...');
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AuthWrapper()),
                    (route) => false,
                  );

                  debugPrint('✅ [LOGOUT] ===== LOGOUT COMPLETADO =====');
                }
              } catch (e, stackTrace) {
                debugPrint('❌ [LOGOUT] ERROR: $e');
                debugPrint('❌ [LOGOUT] StackTrace: $stackTrace');

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al cerrar sesión: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountConfirmation() {
    bool confirmDelete = false;
    final controller = TextEditingController();
    final rootContext = context;

    showDialog(
      context: rootContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setState) {
          return AlertDialog(
            title: const Text('Eliminar Cuenta'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Esta acción eliminará permanentemente tu cuenta y todos tus datos. Esta acción no se puede deshacer.',
                  style: TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Para confirmar, escribe "ELIMINAR" en el campo de abajo:',
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'ELIMINAR',
                  ),
                  onChanged: (value) {
                    setState(() {
                      confirmDelete = value == 'ELIMINAR';
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: confirmDelete
                    ? () async {
                        Navigator.of(dialogContext).pop();

                        try {
                          final userId = SupabaseConfig.currentUserId;

                          if (userId == null) {
                            throw 'No hay usuario autenticado';
                          }

                          debugPrint(
                              '🗑️ [DELETE ACCOUNT] Eliminando cuenta...');

                          // Delete user profile data
                          await SupabaseService.delete('users',
                              filters: {'id': userId});

                          // Delete related data (optional - RLS should handle cascade)
                          await SupabaseService.delete('user_preferences',
                              filters: {'user_id': userId});
                          await SupabaseService.delete('payment_methods',
                              filters: {'user_id': userId});
                          await SupabaseService.delete('service_history',
                              filters: {'user_id': userId});
                          await SupabaseService.delete('reservations',
                              filters: {'user_id': userId});

                          debugPrint('✅ [DELETE ACCOUNT] Datos eliminados');

                          // Clear provider state
                          if (mounted) {
                            rootContext.read<ProfileProvider>().clearSession();
                          }

                          // Sign out from Supabase
                          await SupabaseConfig.auth.signOut();

                          debugPrint('✅ [DELETE ACCOUNT] Cuenta eliminada');

                          // Navigate to AuthWrapper and clear all stack
                          if (mounted) {
                            Navigator.of(rootContext).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (_) => const AuthWrapper()),
                              (route) => false,
                            );
                          }
                        } catch (e) {
                          debugPrint('❌ [DELETE ACCOUNT] ERROR: $e');
                          if (mounted) {
                            ScaffoldMessenger.of(rootContext).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey,
                ),
                child: const Text('Eliminar Cuenta'),
              ),
            ],
          );
        },
      ),
    );
  }
}
