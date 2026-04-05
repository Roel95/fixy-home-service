import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:fixy_home_service/models/category_model.dart';
import 'package:fixy_home_service/data/service_repository.dart';
import 'package:fixy_home_service/theme/app_theme.dart';
import 'package:fixy_home_service/utils/image_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ServiceCategoriesTab extends StatefulWidget {
  const ServiceCategoriesTab({Key? key}) : super(key: key);

  @override
  State<ServiceCategoriesTab> createState() => _ServiceCategoriesTabState();
}

class _ServiceCategoriesTabState extends State<ServiceCategoriesTab> {
  final ServiceRepository _repository = ServiceRepository();
  List<CategoryModel> _categories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final categories = await _repository.getAllServiceCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error: $_error'),
            ElevatedButton(
              onPressed: _loadCategories,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Categorías de Servicios',
                style: AppTheme.textTheme.headlineMedium,
              ),
              ElevatedButton.icon(
                onPressed: _showCreateDialog,
                icon: const Icon(Icons.add),
                label: const Text('Nueva Categoría'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_categories.isEmpty)
            Container(
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.folder_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay categorías de servicios',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Crea una nueva categoría para empezar',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            _buildCategoriesList(),
        ],
      ),
    );
  }

  Widget _buildCategoriesList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return _buildCategoryCard(category);
      },
    );
  }

  Widget _buildCategoryCard(CategoryModel category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Imagen más grande
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: category.imageUrl.isNotEmpty
                  ? Image.network(
                      category.imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                    )
                  : _buildPlaceholderImage(),
            ),
            const SizedBox(width: 20),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${category.currency}${category.price.toStringAsFixed(0)}/${category.timeUnit}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: category.isActive
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      category.isActive ? 'Activo' : 'Inactivo',
                      style: TextStyle(
                        color: category.isActive
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Botones de acción más grandes
            Column(
              children: [
                IconButton(
                  onPressed: () => _showEditDialog(category),
                  icon: const Icon(Icons.edit, color: Colors.blue, size: 28),
                  tooltip: 'Editar',
                ),
                IconButton(
                  onPressed: () => _showDeleteDialog(category),
                  icon: const Icon(Icons.delete, color: Colors.red, size: 28),
                  tooltip: 'Eliminar',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.image_not_supported,
        color: Colors.grey.shade400,
        size: 32,
      ),
    );
  }

  void _showCreateDialog() {
    _showCategoryDialog(category: null);
  }

  void _showEditDialog(CategoryModel category) {
    _showCategoryDialog(category: category);
  }

  void _showCategoryDialog({CategoryModel? category}) {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    final priceController = TextEditingController(
      text: category != null ? category.price.toString() : '0.00',
    );
    final currency = category?.currency ?? 'S/';
    final timeUnit = category?.timeUnit ?? 'hr';
    bool isActive = category?.isActive ?? true;
    String? imageUrl = category?.imageUrl;
    Uint8List? imageBytes;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Editar Categoría' : 'Nueva Categoría'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image picker
                GestureDetector(
                  onTap: () async {
                    final result = await ImageUtils.pickImage();
                    if (result != null) {
                      setDialogState(() {
                        imageBytes = result.bytes;
                        imageUrl = null;
                      });
                    }
                  },
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: imageBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              imageBytes!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : imageUrl != null && imageUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.image_not_supported,
                                          color: Colors.grey.shade400),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Cambiar',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate,
                                      color: Colors.grey.shade400, size: 32),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Agregar imagen',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre *',
                    hintText: 'Ej: Limpieza de Hogar',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Precio base *',
                          hintText: '0.00',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('S/'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('/hr'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Activo:'),
                    const SizedBox(width: 12),
                    Switch(
                      value: isActive,
                      onChanged: (value) {
                        setDialogState(() {
                          isActive = value;
                        });
                      },
                      activeThumbColor: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('El nombre es obligatorio'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);
                _saveCategory(
                  id: category?.id,
                  name: nameController.text,
                  price: double.tryParse(priceController.text) ?? 0,
                  currency: currency,
                  timeUnit: timeUnit,
                  isActive: isActive,
                  imageBytes: imageBytes,
                  existingImageUrl: category?.imageUrl,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text(isEditing ? 'Guardar' : 'Crear'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCategory({
    String? id,
    required String name,
    required double price,
    required String currency,
    required String timeUnit,
    required bool isActive,
    Uint8List? imageBytes,
    String? existingImageUrl,
  }) async {
    setState(() => _isLoading = true);

    try {
      String? imageUrl = existingImageUrl;

      // Upload image if new image selected
      if (imageBytes != null) {
        try {
          final fileName =
              'category_${DateTime.now().millisecondsSinceEpoch}.jpg';
          await Supabase.instance.client.storage
              .from('images')
              .uploadBinary(fileName, imageBytes);
          imageUrl = Supabase.instance.client.storage
              .from('images')
              .getPublicUrl(fileName);
        } catch (storageError) {
          print('Storage bucket error: $storageError');
          // Si falla el bucket, guardar sin imagen o con imagen existente
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Advertencia: No se pudo subir la imagen. El bucket de almacenamiento no existe.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      final category = CategoryModel(
        id: id ?? '',
        name: name,
        imageUrl: imageUrl ?? '',
        price: price,
        currency: currency,
        timeUnit: timeUnit,
        isActive: isActive,
      );

      if (id == null) {
        // Create
        await _repository.createServiceCategory(category);
      } else {
        // Update
        await _repository.updateServiceCategory(category);
      }

      await _loadCategories();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showDeleteDialog(CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Categoría'),
        content: Text(
          '¿Estás seguro de que deseas eliminar "${category.name}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              final success =
                  await _repository.deleteServiceCategory(category.id);
              if (success) {
                await _loadCategories();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Categoría eliminada correctamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error al eliminar la categoría'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
