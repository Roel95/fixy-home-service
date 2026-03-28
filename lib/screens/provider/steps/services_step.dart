import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixy_home_service/providers/provider_onboarding_provider.dart';
import 'package:fixy_home_service/theme/app_theme.dart';

class ServicesStep extends StatefulWidget {
  const ServicesStep({Key? key}) : super(key: key);

  @override
  State<ServicesStep> createState() => _ServicesStepState();
}

class _ServicesStepState extends State<ServicesStep> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderOnboardingProvider>().loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProviderOnboardingProvider>();
    final categories = provider.availableCategories;
    final isLoading = provider.isLoadingCategories;
    final error = provider.categoriesError;

    Widget buildCategories() {
      if (isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      if (error != null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              error,
              style: AppTheme.textTheme.bodyMedium?.copyWith(color: Colors.red),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context
                  .read<ProviderOnboardingProvider>()
                  .loadCategories(forceRefresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        );
      }

      if (categories.isEmpty) {
        return Text(
          'Aún no hay categorías disponibles. Intenta más tarde.',
          style: AppTheme.textTheme.bodyMedium,
        );
      }

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = provider.selectedCategories.contains(category.id);

          return _ServiceCategoryCard(
            name: category.name,
            imageUrl: category.imageUrl,
            isSelected: isSelected,
            onTap: () => provider.toggleCategory(category.id),
          );
        },
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Servicios que Ofreces', style: AppTheme.textTheme.displayLarge),
          const SizedBox(height: 8),
          Text(
            'Selecciona todos los servicios que puedes proporcionar',
            style: AppTheme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          buildCategories(),
          const SizedBox(height: 16),
          if (provider.selectedCategories.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 12),
            Text('Seleccionados:', style: AppTheme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: provider.selectedCategories.map((categoryId) {
                final match = provider.availableCategories
                    .where((c) => c.id == categoryId);
                final label = match.isNotEmpty ? match.first.name : categoryId;
                return Chip(
                  label: Text(label),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => provider.toggleCategory(categoryId),
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  labelStyle: AppTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _ServiceCategoryCard extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServiceCategoryCard({
    Key? key,
    required this.name,
    required this.imageUrl,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final highlightColor = isSelected ? Colors.white : AppTheme.primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CategoryVisual(imageUrl: imageUrl, highlightColor: highlightColor),
            const SizedBox(height: 8),
            Text(
              name,
              textAlign: TextAlign.center,
              style: AppTheme.textTheme.bodyMedium?.copyWith(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryVisual extends StatelessWidget {
  final String? imageUrl;
  final Color highlightColor;

  const _CategoryVisual({
    Key? key,
    required this.imageUrl,
    required this.highlightColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.category, size: 32, color: highlightColor);
          },
        ),
      );
    }

    return Icon(Icons.category, size: 32, color: highlightColor);
  }
}
