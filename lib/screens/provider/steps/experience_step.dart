import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixy_home_service/providers/provider_onboarding_provider.dart';
import 'package:fixy_home_service/theme/app_theme.dart';

class ExperienceStep extends StatelessWidget {
  const ExperienceStep({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProviderOnboardingProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Experiencia y Certificaciones',
              style: AppTheme.textTheme.displayLarge),
          const SizedBox(height: 8),
          Text(
            'Cuéntanos sobre tu trayectoria profesional',
            style: AppTheme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Text('Años de Experiencia *', style: AppTheme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _ExperienceChip(
                label: 'Menos de 1 año',
                value: 0,
                selectedValue: provider.yearsOfExperience,
                onSelected: provider.setYearsOfExperience,
              ),
              _ExperienceChip(
                label: '1-3 años',
                value: 2,
                selectedValue: provider.yearsOfExperience,
                onSelected: provider.setYearsOfExperience,
              ),
              _ExperienceChip(
                label: '3-5 años',
                value: 4,
                selectedValue: provider.yearsOfExperience,
                onSelected: provider.setYearsOfExperience,
              ),
              _ExperienceChip(
                label: '5-10 años',
                value: 7,
                selectedValue: provider.yearsOfExperience,
                onSelected: provider.setYearsOfExperience,
              ),
              _ExperienceChip(
                label: 'Más de 10 años',
                value: 10,
                selectedValue: provider.yearsOfExperience,
                onSelected: provider.setYearsOfExperience,
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text('Certificaciones (Opcional)',
              style: AppTheme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Agrega certificaciones o cursos relevantes',
            style: AppTheme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: TextEditingController(
                        text: provider.currentCertification)
                      ..selection = TextSelection.collapsed(
                          offset: provider.currentCertification.length),
                    onChanged: provider.setCurrentCertification,
                    decoration: InputDecoration(
                      hintText: 'Ej: Certificado de Electricista',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: provider.addCertification,
                  icon: const Icon(Icons.add, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (provider.certifications.isNotEmpty) ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.certifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final cert = provider.certifications[index];
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified,
                          color: AppTheme.primaryColor, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(cert, style: AppTheme.textTheme.bodyMedium),
                      ),
                      IconButton(
                        onPressed: () => provider.removeCertification(cert),
                        icon: const Icon(Icons.delete,
                            color: Colors.red, size: 20),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _ExperienceChip extends StatelessWidget {
  final String label;
  final int value;
  final int selectedValue;
  final Function(int) onSelected;

  const _ExperienceChip({
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedValue == value;

    return GestureDetector(
      onTap: () => onSelected(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            else
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Text(
          label,
          style: AppTheme.textTheme.bodyMedium?.copyWith(
            color: isSelected ? Colors.white : AppTheme.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
