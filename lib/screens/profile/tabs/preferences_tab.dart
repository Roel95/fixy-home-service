import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixy_home_service/providers/profile_provider.dart';
import 'package:fixy_home_service/theme/app_theme.dart';
import 'package:fixy_home_service/models/profile_models.dart';

class PreferencesTab extends StatefulWidget {
  const PreferencesTab({Key? key}) : super(key: key);

  @override
  State<PreferencesTab> createState() => _PreferencesTabState();
}

class _PreferencesTabState extends State<PreferencesTab>
    with AutomaticKeepAliveClientMixin {
  final List<String> _availableLanguages = ['Español', 'English', 'Português'];
  final List<String> _availableRegions = [
    'Perú',
    'Colombia',
    'México',
    'Chile',
    'Argentina',
    'Ecuador',
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        if (profileProvider.userProfile == null) {
          return const Center(child: Text('No profile data available'));
        }

        final preferences = profileProvider.userProfile!.preferences;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Notifications section
            _buildSectionHeader('Notificaciones', Icons.notifications_none),
            const SizedBox(height: 16),
            _buildSwitchTile(
              'Notificaciones push',
              'Recibe alertas sobre tus servicios',
              preferences.pushNotifications,
              (value) => _updatePreferences(
                profileProvider,
                preferences.copyWith(pushNotifications: value),
              ),
            ),
            _buildSwitchTile(
              'Notificaciones por email',
              'Recibe actualizaciones en tu correo',
              preferences.emailNotifications,
              (value) => _updatePreferences(
                profileProvider,
                preferences.copyWith(emailNotifications: value),
              ),
            ),

            const SizedBox(height: 24),

            // Regional section
            _buildSectionHeader('Ajustes Regionales', Icons.language),
            const SizedBox(height: 16),
            _buildDropdownTile(
              'Idioma',
              preferences.language,
              _availableLanguages,
              (value) => _updatePreferences(
                profileProvider,
                preferences.copyWith(language: value),
              ),
            ),
            _buildDropdownTile(
              'Región',
              preferences.region,
              _availableRegions,
              (value) => _updatePreferences(
                profileProvider,
                preferences.copyWith(region: value),
              ),
            ),

            const SizedBox(height: 24),

            // Appearance section
            _buildSectionHeader('Apariencia', Icons.palette_outlined),
            const SizedBox(height: 16),
            _buildSwitchTile(
              'Modo oscuro',
              'Cambiar a tema oscuro',
              preferences.isDarkMode,
              (value) => _updatePreferences(
                profileProvider,
                preferences.copyWith(isDarkMode: value),
              ),
            ),

            const SizedBox(height: 24),

            // Security section
            _buildSectionHeader('Seguridad', Icons.lock_outline),
            const SizedBox(height: 16),
            _buildActionTile(
              'Cambiar contraseña',
              'Actualiza tu contraseña de acceso',
              Icons.password,
              () => _showChangePasswordDialog(),
            ),
            _buildActionTile(
              'Autenticación de dos factores',
              'Añade una capa extra de seguridad',
              Icons.security,
              () => _show2FADialog(),
            ),
            _buildActionTile(
              'Sesión',
              'Cerrar sesión en otros dispositivos',
              Icons.logout,
              () => _showLogoutOtherDevicesDialog(),
            ),
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

  Widget _buildSwitchTile(
      String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildDropdownTile(String title, String currentValue,
      List<String> items, Function(String) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTheme.textTheme.bodyLarge),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: currentValue,
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  onChanged(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
      String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _updatePreferences(
      ProfileProvider provider, UserPreferences newPreferences) {
    provider.updatePreferences(newPreferences);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preferencias actualizadas')),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Contraseña'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Contraseña actual',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Nueva contraseña',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirmar nueva contraseña',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
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
                    content: Text('Contraseña actualizada exitosamente')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );
  }

  void _show2FADialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Autenticación de Dos Factores'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'La autenticación de dos factores añade una capa extra de seguridad a tu cuenta.',
            ),
            const SizedBox(height: 16),
            const Text('Métodos disponibles:'),
            const SizedBox(height: 8),
            _buildTwoFactorMethodItem(
                'SMS', 'Recibe códigos por mensaje de texto'),
            const SizedBox(height: 8),
            _buildTwoFactorMethodItem('App de autenticación',
                'Usa Google Authenticator u otra app similar'),
            const SizedBox(height: 8),
            _buildTwoFactorMethodItem(
                'Email', 'Recibe códigos en tu dirección de correo'),
          ],
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

  Widget _buildTwoFactorMethodItem(String title, String description) {
    return ListTile(
      title: Text(title),
      subtitle: Text(description),
      trailing: OutlinedButton(
        onPressed: () {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Configurando $title...')),
          );
        },
        child: const Text('Configurar'),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showLogoutOtherDevicesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión en Otros Dispositivos'),
        content: const Text(
          'Esta acción cerrará la sesión en todos los dispositivos excepto en el que estás usando actualmente. ¿Deseas continuar?',
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
                    content: Text('Sesión cerrada en otros dispositivos')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}
