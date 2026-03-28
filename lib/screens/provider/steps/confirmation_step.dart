import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixy_home_service/providers/provider_onboarding_provider.dart';
import 'package:fixy_home_service/theme/app_theme.dart';

class ConfirmationStep extends StatelessWidget {
  const ConfirmationStep({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProviderOnboardingProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Confirmación', style: AppTheme.textTheme.displayLarge),
          const SizedBox(height: 8),
          Text(
            'Revisa tu información antes de enviar',
            style: AppTheme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          if (provider.profileImageBytes != null)
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryColor, width: 2),
                ),
                child: ClipOval(
                  child: Image.memory(provider.profileImageBytes!,
                      fit: BoxFit.cover),
                ),
              ),
            ),
          const SizedBox(height: 24),
          _SectionCard(
            title: 'Información Básica',
            icon: Icons.person,
            onEdit: () => provider.goToStep(0),
            children: [
              _InfoRow(label: 'Negocio', value: provider.businessName),
              _InfoRow(label: 'Descripción', value: provider.description),
              _InfoRow(label: 'Teléfono', value: provider.phone),
              _InfoRow(label: 'Email', value: provider.email),
              _InfoRow(label: 'Dirección', value: provider.address),
              _InfoRow(
                  label: 'Ciudad',
                  value: '${provider.city}, ${provider.postalCode}'),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Servicios',
            icon: Icons.work,
            onEdit: () => provider.goToStep(1),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: provider.selectedCategories.map((categoryId) {
                  final match = provider.availableCategories
                      .where((c) => c.id == categoryId);
                  final label =
                      match.isNotEmpty ? match.first.name : categoryId;
                  return Chip(
                    label: Text(label),
                    backgroundColor:
                        AppTheme.primaryColor.withValues(alpha: 0.1),
                    labelStyle: AppTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Experiencia',
            icon: Icons.star,
            onEdit: () => provider.goToStep(2),
            children: [
              _InfoRow(
                label: 'Años de experiencia',
                value: provider.yearsOfExperience == 0
                    ? 'Menos de 1 año'
                    : provider.yearsOfExperience >= 10
                        ? 'Más de 10 años'
                        : '${provider.yearsOfExperience} años',
              ),
              if (provider.certifications.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Certificaciones:', style: AppTheme.textTheme.bodySmall),
                const SizedBox(height: 4),
                ...provider.certifications.map((cert) => Padding(
                      padding: const EdgeInsets.only(left: 12, top: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.verified,
                              size: 16, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child:
                                Text(cert, style: AppTheme.textTheme.bodySmall),
                          ),
                        ],
                      ),
                    )),
              ],
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Disponibilidad',
            icon: Icons.calendar_today,
            onEdit: () => provider.goToStep(3),
            children: [
              ...provider.availability.weekSchedule.entries
                  .where((entry) => entry.value.isAvailable)
                  .map((entry) {
                final dayName = _getDayName(entry.key);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _InfoRow(
                    label: dayName,
                    value: '${entry.value.timeFrom} - ${entry.value.timeTo}',
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tu solicitud será revisada por nuestro equipo. Te contactaremos en 24-48 horas.',
                    style: AppTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getDayName(String key) {
    const dayNames = {
      'monday': 'Lunes',
      'tuesday': 'Martes',
      'wednesday': 'Miércoles',
      'thursday': 'Jueves',
      'friday': 'Viernes',
      'saturday': 'Sábado',
      'sunday': 'Domingo',
    };
    return dayNames[key] ?? key;
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onEdit;
  final List<Widget> children;

  const _SectionCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.onEdit,
    required this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(title, style: AppTheme.textTheme.titleMedium),
                ],
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit,
                    size: 20, color: AppTheme.primaryColor),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    Key? key,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: AppTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
