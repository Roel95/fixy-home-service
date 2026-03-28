import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixy_home_service/providers/provider_onboarding_provider.dart';
import 'package:fixy_home_service/screens/provider/steps/basic_info_step.dart';
import 'package:fixy_home_service/screens/provider/steps/services_step.dart';
import 'package:fixy_home_service/screens/provider/steps/experience_step.dart';
import 'package:fixy_home_service/screens/provider/steps/availability_step.dart';
import 'package:fixy_home_service/screens/provider/steps/confirmation_step.dart';
import 'package:fixy_home_service/theme/app_theme.dart';

class ProviderOnboardingScreen extends StatelessWidget {
  const ProviderOnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProviderOnboardingProvider(),
      child: const _ProviderOnboardingContent(),
    );
  }
}

class _ProviderOnboardingContent extends StatelessWidget {
  const _ProviderOnboardingContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProviderOnboardingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Conviértete en Proveedor',
            style: AppTheme.textTheme.titleLarge),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _StepIndicator(currentStep: provider.currentStep),
          Expanded(
            child: IndexedStack(
              index: provider.currentStep,
              children: const [
                BasicInfoStep(),
                ServicesStep(),
                ExperienceStep(),
                AvailabilityStep(),
                ConfirmationStep(),
              ],
            ),
          ),
          _NavigationButtons(),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;

  const _StepIndicator({Key? key, required this.currentStep}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(5, (index) {
          final isActive = index == currentStep;
          final isCompleted = index < currentStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: isCompleted || isActive
                          ? AppTheme.primaryColor
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (index < 4) const SizedBox(width: 4),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _NavigationButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProviderOnboardingProvider>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (provider.currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: provider.previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppTheme.primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Atrás',
                  style: AppTheme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
          if (provider.currentStep > 0) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: provider.isLoading
                  ? null
                  : () => _handleNext(context, provider),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: provider.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      provider.currentStep == 4
                          ? 'Enviar Solicitud'
                          : 'Siguiente',
                      style: AppTheme.textTheme.labelLarge,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNext(
      BuildContext context, ProviderOnboardingProvider provider) async {
    if (provider.currentStep == 4) {
      final success = await provider.submitOnboarding();
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('¡Solicitud enviada con éxito! Te contactaremos pronto.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else if (provider.error != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${provider.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      bool canProceed = false;
      String? errorMessage;

      switch (provider.currentStep) {
        case 0:
          canProceed = provider.isStep1Valid;
          errorMessage = 'Por favor completa todos los campos obligatorios';
          break;
        case 1:
          canProceed = provider.isStep2Valid;
          errorMessage = 'Selecciona al menos una categoría de servicio';
          break;
        case 2:
          canProceed = provider.isStep3Valid;
          errorMessage = 'Indica tus años de experiencia';
          break;
        case 3:
          canProceed = true;
          break;
      }

      if (canProceed) {
        provider.nextStep();
      } else if (errorMessage != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
}
