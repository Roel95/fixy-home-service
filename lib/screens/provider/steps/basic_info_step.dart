import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixy_home_service/providers/provider_onboarding_provider.dart';
import 'package:fixy_home_service/theme/app_theme.dart';
import 'package:file_picker/file_picker.dart';

class BasicInfoStep extends StatelessWidget {
  const BasicInfoStep({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProviderOnboardingProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Información Básica', style: AppTheme.textTheme.displayLarge),
          const SizedBox(height: 8),
          Text(
            'Cuéntanos sobre tu negocio o servicios',
            style: AppTheme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Center(child: _ProfileImagePicker()),
          const SizedBox(height: 24),
          _InputField(
            label: 'Nombre del Negocio *',
            hint: 'Ej: Servicios de Plomería Juan',
            value: provider.businessName,
            onChanged: provider.setBusinessName,
          ),
          const SizedBox(height: 16),
          _InputField(
            label: 'Descripción *',
            hint: 'Describe tus servicios y experiencia',
            value: provider.description,
            onChanged: provider.setDescription,
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          _InputField(
            label: 'Teléfono *',
            hint: '+1 234 567 8900',
            value: provider.phone,
            onChanged: provider.setPhone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _InputField(
            label: 'Email *',
            hint: 'tu@email.com',
            value: provider.email,
            onChanged: provider.setEmail,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _InputField(
            label: 'Dirección *',
            hint: 'Calle, número, colonia',
            value: provider.address,
            onChanged: provider.setAddress,
          ),
          const SizedBox(height: 16),
          _InputField(
            label: 'Ciudad *',
            hint: 'Ciudad',
            value: provider.city,
            onChanged: provider.setCity,
          ),
        ],
      ),
    );
  }
}

class _ProfileImagePicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProviderOnboardingProvider>();

    return GestureDetector(
      onTap: () => _pickImage(context, provider),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: provider.profileImageBytes != null
              ? Image.memory(provider.profileImageBytes!, fit: BoxFit.cover)
              : Container(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: const Icon(Icons.add_a_photo,
                      size: 40, color: AppTheme.primaryColor),
                ),
        ),
      ),
    );
  }

  Future<void> _pickImage(
      BuildContext context, ProviderOnboardingProvider provider) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.first.bytes != null) {
        provider.setProfileImage(result.files.first.bytes!);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
      }
    }
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final String hint;
  final String value;
  final Function(String) onChanged;
  final int maxLines;
  final TextInputType keyboardType;

  const _InputField({
    required this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary.withValues(alpha: 0.8),
              ),
            ),
          ),
          TextField(
            controller: TextEditingController(text: value)
              ..selection = TextSelection.collapsed(offset: value.length),
            onChanged: onChanged,
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
