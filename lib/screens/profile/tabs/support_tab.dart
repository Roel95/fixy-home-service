import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixy_home_service/providers/profile_provider.dart';
import 'package:fixy_home_service/theme/app_theme.dart';
import 'package:fixy_home_service/models/profile_models.dart';

class SupportTab extends StatefulWidget {
  const SupportTab({Key? key}) : super(key: key);

  @override
  State<SupportTab> createState() => _SupportTabState();
}

class _SupportTabState extends State<SupportTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        final faqs = profileProvider.faqs;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Support options
            _buildSupportOptions(),

            const SizedBox(height: 24),

            // FAQs section
            Text(
              'Preguntas Frecuentes',
              style: AppTheme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // FAQs list
            ...faqs.map((faq) => _buildFaqItem(faq, profileProvider)).toList(),

            const SizedBox(height: 24),

            // Report a problem
            _buildReportProblemSection(),
          ],
        );
      },
    );
  }

  Widget _buildSupportOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Soporte y Ayuda',
          style: AppTheme.textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSupportCard(
                'Chat con Soporte',
                'Habla con un agente en vivo',
                Icons.chat_bubble_outline,
                Colors.blue,
                () => _startSupportChat(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSupportCard(
                'Llamada Telefónica',
                'Habla directamente con soporte',
                Icons.phone_outlined,
                Colors.green,
                () => _callSupport(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSupportCard(
                'Email',
                'Envíanos un mensaje',
                Icons.email_outlined,
                Colors.orange,
                () => _emailSupport(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSupportCard(
                'Centro de Ayuda',
                'Busca artículos y tutoriales',
                Icons.help_outline,
                Colors.purple,
                () => _openHelpCenter(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSupportCard(String title, String subtitle, IconData icon,
      Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(FAQ faq, ProfileProvider profileProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          faq.question,
          style: AppTheme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        initiallyExpanded: faq.isExpanded,
        onExpansionChanged: (expanded) {
          profileProvider.toggleFaqExpanded(faq.id);
        },
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            faq.answer,
            style: AppTheme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.thumb_up_outlined, size: 16),
                label: const Text('Útil'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gracias por tu feedback')),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.thumb_down_outlined, size: 16),
                label: const Text('No útil'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gracias por tu feedback')),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportProblemSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reportar un Problema',
            style: AppTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Cuéntanos sobre cualquier problema que hayas experimentado o envíanos tus sugerencias para mejorar nuestra aplicación.',
            style: AppTheme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Describe el problema o sugerencia...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  // Add screenshot logic here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Captura de pantalla adjuntada')),
                  );
                },
                icon: const Icon(Icons.photo_camera),
                label: const Text('Adjuntar captura'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.primaryColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Reporte enviado. ¡Gracias por tu feedback!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Enviar Reporte'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _startSupportChat() {
    // In a real app, this would start a support chat
    // For now, we'll just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Iniciando chat con soporte...')),
    );
  }

  void _callSupport() {
    // In a real app, this would start a support call
    // For now, we'll just show a dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Llamar a Soporte'),
        content: const Text(
            'Línea de atención: +51 987 654 321\n\nHorario: Lunes a Viernes 9am - 6pm'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Llamando a soporte...')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Llamar'),
          ),
        ],
      ),
    );
  }

  void _emailSupport() {
    // In a real app, this would open an email app
    // For now, we'll just show a dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enviar Email a Soporte'),
        content:
            const Text('Dirección de correo: soporte@serviciosdreamflow.com'),
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
                    content: Text('Abriendo aplicación de correo...')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Enviar Email'),
          ),
        ],
      ),
    );
  }

  void _openHelpCenter() {
    // In a real app, this would open a help center screen or website
    // For now, we'll just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Abriendo Centro de Ayuda...')),
    );
  }
}
