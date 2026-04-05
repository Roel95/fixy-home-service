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
    _loadCategoriesIfActive();
  }

  @override
  void didUpdateWidget(ServicesStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadCategoriesIfActive();
  }

  void _loadCategoriesIfActive() {
    final provider = context.read<ProviderOnboardingProvider>();
    if (provider.availableCategories.isEmpty && !provider.isLoadingCategories) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.loadCategories();
      });
    }
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
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      error,
                      style:
                          TextStyle(color: Colors.red.shade700, fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => context
                    .read<ProviderOnboardingProvider>()
                    .loadCategories(forceRefresh: true),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      if (categories.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(Icons.category_outlined,
                  size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                'Aún no hay categorías disponibles. Intenta más tarde.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
          ),
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
      child: Builder(builder: (context) {
        debugPrint(
            '🔍 ServicesStep: isLoading=$isLoading, categories=${categories.length}, error=$error');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Servicios que Ofreces',
              style: AppTheme.textTheme.displayLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Selecciona todos los servicios que puedes proporcionar',
              style: AppTheme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            buildCategories(),
            const SizedBox(height: 16),
            if (provider.selectedCategories.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seleccionados',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
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
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () => provider.toggleCategory(categoryId),
                          backgroundColor:
                              AppTheme.primaryColor.withValues(alpha: 0.1),
                          side: BorderSide(
                              color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      }),
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
