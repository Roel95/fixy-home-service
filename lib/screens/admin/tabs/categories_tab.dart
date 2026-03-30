import 'package:flutter/material.dart';
import 'package:fixy_home_service/data/product_repository.dart';
import 'package:fixy_home_service/models/product_model.dart';

/// Pestaña de gestión de categorías del admin
/// Permite crear, editar y eliminar categorías de productos
class CategoriesTab extends StatefulWidget {
  const CategoriesTab({super.key});

  @override
  State<CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends State<CategoriesTab> {
  final ProductRepository _repository = ProductRepository();

  List<ProductCategoryModel> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final categories = await _repository.getCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error cargando categorías: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Categorías',
                  _categories.length.toString(),
                  Icons.category,
                  const Color(0xFF667EEA),
                ),
              ),
              const SizedBox(width: 16),
              _buildAddButton(),
            ],
          ),
        ),

        // Categories list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _categories.isEmpty
                  ? _buildEmptyState()
                  : _buildCategoriesList(),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECF3),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D3748).withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
          const BoxShadow(
            color: Colors.white,
            blurRadius: 4,
            offset: Offset(-2, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: const Color(0xFF2D3748).withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () => _showCategoryForm(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667EEA).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.add, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Nueva',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return _buildCategoryCard(category);
      },
    );
  }

  Widget _buildCategoryCard(ProductCategoryModel category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECF3),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D3748).withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
          const BoxShadow(
            color: Colors.white,
            blurRadius: 4,
            offset: Offset(-2, -2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showCategoryForm(category: category),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Category icon/image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF667EEA).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: category.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            category.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.category,
                                    color: Color(0xFF667EEA)),
                          ),
                        )
                      : const Icon(Icons.category,
                          color: Color(0xFF667EEA), size: 28),
                ),
                const SizedBox(width: 16),

                // Category info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      if (category.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          category.description!,
                          style: TextStyle(
                            fontSize: 13,
                            color: const Color(0xFF2D3748).withOpacity(0.6),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF667EEA).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${category.productCount ?? 0} productos',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF667EEA),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildActionButton(
                      Icons.edit,
                      const Color(0xFF007AFF),
                      () => _showCategoryForm(category: category),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      Icons.delete,
                      const Color(0xFFFF3B30),
                      () => _confirmDelete(category),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 80,
            color: const Color(0xFF2D3748).withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay categorías',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D3748).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea tu primera categoría de productos',
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF2D3748).withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCategoryForm(),
            icon: const Icon(Icons.add),
            label: const Text('Crear Categoría'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryForm({ProductCategoryModel? category}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFE8ECF3),
      builder: (context) => CategoryFormSheet(
        category: category,
        onSave: (savedCategory) async {
          await _loadCategories();
          Navigator.pop(context);
          _showSuccess(
              category == null ? 'Categoría creada' : 'Categoría actualizada');
        },
      ),
    );
  }

  void _confirmDelete(ProductCategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFE8ECF3),
        title: const Text('Eliminar Categoría'),
        content: Text(
            '¿Estás seguro de eliminar "${category.name}"?\n\nEsta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteCategory(category);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B30),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(ProductCategoryModel category) async {
    try {
      // TODO: Implementar eliminación
      setState(() {
        _categories.removeWhere((c) => c.id == category.id);
      });
      _showSuccess('Categoría eliminada');
    } catch (e) {
      _showError('Error al eliminar: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF3B30),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF34C759),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Formulario para crear/editar categorías
class CategoryFormSheet extends StatefulWidget {
  final ProductCategoryModel? category;
  final Function(ProductCategoryModel) onSave;

  const CategoryFormSheet({
    super.key,
    this.category,
    required this.onSave,
  });

  @override
  State<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _imageUrlController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.category?.description ?? '');
    _imageUrlController =
        TextEditingController(text: widget.category?.imageUrl ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFE8ECF3),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8ECF3),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2D3748).withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.category == null
                          ? 'Nueva Categoría'
                          : 'Editar Categoría',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Form
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image preview
                        if (_imageUrlController.text.isNotEmpty)
                          Container(
                            width: double.infinity,
                            height: 150,
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: NetworkImage(_imageUrlController.text),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),

                        // Image URL
                        _buildTextField(
                          controller: _imageUrlController,
                          label: 'URL de la imagen (opcional)',
                          icon: Icons.image,
                          onChanged: (value) => setState(() {}),
                        ),
                        const SizedBox(height: 16),

                        // Name
                        _buildTextField(
                          controller: _nameController,
                          label: 'Nombre de la categoría',
                          icon: Icons.label,
                          validator: (v) =>
                              v?.isEmpty ?? true ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),

                        // Description
                        _buildTextField(
                          controller: _descriptionController,
                          label: 'Descripción (opcional)',
                          icon: Icons.description,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 32),

                        // Save button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveCategory,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF667EEA),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : Text(
                                    widget.category == null
                                        ? 'Crear Categoría'
                                        : 'Guardar Cambios',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    void Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECF3),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D3748).withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
          const BoxShadow(
            color: Colors.white,
            blurRadius: 4,
            offset: Offset(-2, -2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        maxLines: maxLines,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF667EEA)),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final category = ProductCategoryModel(
        id: widget.category?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        imageUrl:
            _imageUrlController.text.isEmpty ? null : _imageUrlController.text,
        productCount: widget.category?.productCount ?? 0,
      );

      widget.onSave(category);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
