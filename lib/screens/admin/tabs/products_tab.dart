import 'package:flutter/material.dart';
import 'package:fixy_home_service/models/product_model.dart';
import 'package:fixy_home_service/data/product_repository.dart';
import 'package:fixy_home_service/services/image_upload_service.dart';

/// Pestaña de gestión de productos del admin
/// Permite crear, editar, eliminar y gestionar productos de la tienda
class ProductsTab extends StatefulWidget {
  const ProductsTab({super.key});

  @override
  State<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab> {
  final ProductRepository _repository = ProductRepository();
  final ImageUploadService _imageService = ImageUploadService();

  List<ProductModel> _products = [];
  List<ProductCategoryModel> _categories = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final products = await _repository.getProducts();
      final categories = await _repository.getProductCategories();
      setState(() {
        _products = products;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error cargando datos: $e');
    }
  }

  List<ProductModel> get _filteredProducts {
    if (_searchQuery.isEmpty) return _products;
    return _products
        .where((p) =>
            p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.brand.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.category.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header con búsqueda y botón agregar
        _buildHeader(),

        // Lista de productos
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredProducts.isEmpty
                  ? _buildEmptyState()
                  : _buildProductList(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Stats cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Productos',
                  _products.length.toString(),
                  Icons.inventory_2,
                  const Color(0xFF667EEA),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'En Stock',
                  _products.where((p) => p.stock > 0).length.toString(),
                  Icons.check_circle,
                  const Color(0xFF34C759),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Ofertas',
                  _products.where((p) => p.isOnSale).length.toString(),
                  Icons.local_offer,
                  const Color(0xFFFF9500),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Search bar
          Row(
            children: [
              Expanded(
                child: Container(
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
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Buscar productos...',
                      prefixIcon:
                          const Icon(Icons.search, color: Color(0xFF667EEA)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      hintStyle: TextStyle(
                        color: const Color(0xFF2D3748).withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildAddButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
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
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: const Color(0xFF2D3748).withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () => _showProductForm(),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667EEA).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildProductList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(ProductModel product) {
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
          onTap: () => _showProductForm(product: product),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Product image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    product.images.isNotEmpty ? product.images.first : '',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 80,
                      height: 80,
                      color: const Color(0xFF667EEA).withOpacity(0.1),
                      child: const Icon(Icons.image, color: Color(0xFF667EEA)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Product info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF2D3748),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.brand,
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF2D3748).withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStockColor(product.stock)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${product.stock} unid.',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _getStockColor(product.stock),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (product.isOnSale)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF3B30).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'OFERTA',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFFF3B30),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Price and actions
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'S/ ${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF667EEA),
                      ),
                    ),
                    if (product.originalPrice != null)
                      Text(
                        'S/ ${product.originalPrice!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8E8E93),
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildActionButton(
                          Icons.edit,
                          const Color(0xFF007AFF),
                          () => _showProductForm(product: product),
                        ),
                        const SizedBox(width: 8),
                        _buildActionButton(
                          Icons.delete,
                          const Color(0xFFFF3B30),
                          () => _confirmDelete(product),
                        ),
                      ],
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

  Color _getStockColor(int stock) {
    if (stock == 0) return const Color(0xFFFF3B30);
    if (stock < 10) return const Color(0xFFFF9500);
    return const Color(0xFF34C759);
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: const Color(0xFF2D3748).withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay productos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D3748).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega tu primer producto a la tienda',
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF2D3748).withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showProductForm(),
            icon: const Icon(Icons.add),
            label: const Text('Agregar Producto'),
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF3B30),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmDelete(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFE8ECF3),
        title: const Text('Eliminar Producto'),
        content: Text('¿Estás seguro de eliminar "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteProduct(product);
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

  Future<void> _deleteProduct(ProductModel product) async {
    try {
      // TODO: Implementar eliminación en el repositorio
      setState(() {
        _products.removeWhere((p) => p.id == product.id);
      });
      _showSuccess('Producto eliminado');
    } catch (e) {
      _showError('Error al eliminar: $e');
    }
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

  void _showProductForm({ProductModel? product}) {
    // TODO: Implementar formulario de producto
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFE8ECF3),
      builder: (context) => ProductFormSheet(
        product: product,
        categories: _categories,
        onSave: (savedProduct) async {
          await _loadData();
          Navigator.pop(context);
          _showSuccess(
              product == null ? 'Producto creado' : 'Producto actualizado');
        },
      ),
    );
  }
}

/// Widget del formulario de producto (para crear/editar)
class ProductFormSheet extends StatefulWidget {
  final ProductModel? product;
  final List<ProductCategoryModel> categories;
  final Function(ProductModel) onSave;

  const ProductFormSheet({
    super.key,
    this.product,
    required this.categories,
    required this.onSave,
  });

  @override
  State<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _priceController;
  late TextEditingController _originalPriceController;
  late TextEditingController _stockController;
  late TextEditingController _descriptionController;

  List<String> _images = [];
  String? _selectedCategory;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _brandController = TextEditingController(text: widget.product?.brand ?? '');
    _priceController =
        TextEditingController(text: widget.product?.price.toString() ?? '');
    _originalPriceController = TextEditingController(
        text: widget.product?.originalPrice?.toString() ?? '');
    _stockController =
        TextEditingController(text: widget.product?.stock.toString() ?? '0');
    _descriptionController =
        TextEditingController(text: widget.product?.description ?? '');
    _images = List.from(widget.product?.images ?? []);
    _selectedCategory = widget.product?.category;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
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
                      widget.product == null
                          ? 'Nuevo Producto'
                          : 'Editar Producto',
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
                        // Image upload section
                        _buildImageSection(),
                        const SizedBox(height: 24),

                        // Basic info
                        _buildSectionTitle('Información Básica'),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _nameController,
                          label: 'Nombre del producto',
                          icon: Icons.label,
                          validator: (v) =>
                              v?.isEmpty ?? true ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _brandController,
                          label: 'Marca',
                          icon: Icons.business,
                          validator: (v) =>
                              v?.isEmpty ?? true ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 12),
                        _buildCategoryDropdown(),
                        const SizedBox(height: 24),

                        // Pricing
                        _buildSectionTitle('Precios'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _priceController,
                                label: 'Precio actual',
                                icon: Icons.attach_money,
                                keyboardType: TextInputType.number,
                                validator: (v) =>
                                    v?.isEmpty ?? true ? 'Requerido' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                controller: _originalPriceController,
                                label: 'Precio anterior (opcional)',
                                icon: Icons.money_off,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Inventory
                        _buildSectionTitle('Inventario'),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _stockController,
                          label: 'Stock disponible',
                          icon: Icons.inventory,
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              v?.isEmpty ?? true ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 24),

                        // Description
                        _buildSectionTitle('Descripción'),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _descriptionController,
                          label: 'Descripción del producto',
                          icon: Icons.description,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 32),

                        // Save button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveProduct,
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
                                    widget.product == null
                                        ? 'Crear Producto'
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

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Imágenes del Producto'),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _images.length + 1,
            itemBuilder: (context, index) {
              if (index == _images.length) {
                return _buildAddImageButton();
              }
              return _buildImageItem(_images[index], index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _addImage,
      child: Container(
        width: 100,
        height: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE8ECF3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            style: BorderStyle.solid,
            width: 2,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              color: Color(0xFF667EEA),
              size: 32,
            ),
            SizedBox(height: 8),
            Text(
              'Agregar',
              style: TextStyle(
                color: Color(0xFF667EEA),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageItem(String imageUrl, int index) {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
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
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.category, color: Color(0xFF667EEA)),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              hintText: 'Selecciona una categoría',
              hintStyle: TextStyle(
                color: const Color(0xFF2D3748).withOpacity(0.5),
              ),
            ),
            items: widget.categories.map((category) {
              return DropdownMenuItem(
                value: category.id,
                child: Text(category.name),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedCategory = value),
            validator: (v) => v == null ? 'Selecciona una categoría' : null,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2D3748),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
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
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
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

  Future<void> _addImage() async {
    // TODO: Implementar selección y subida de imagen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Imagen'),
        content: const Text('Selecciona una opción:'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Abrir cámara
            },
            child: const Text('Cámara'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Abrir galería
            },
            child: const Text('Galería'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showUrlInputDialog();
            },
            child: const Text('URL'),
          ),
        ],
      ),
    );
  }

  void _showUrlInputDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('URL de la imagen'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'https://ejemplo.com/imagen.jpg',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() => _images.add(controller.text));
              }
              Navigator.pop(context);
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final product = ProductModel(
        id: widget.product?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        brand: _brandController.text,
        category: _selectedCategory ?? 'general',
        price: double.tryParse(_priceController.text) ?? 0,
        originalPrice: _originalPriceController.text.isEmpty
            ? null
            : double.tryParse(_originalPriceController.text),
        stock: int.tryParse(_stockController.text) ?? 0,
        images: _images,
        description: _descriptionController.text,
        specifications: widget.product?.specifications ?? [],
        rating: widget.product?.rating ?? 0,
        reviewCount: widget.product?.reviewCount ?? 0,
      );

      widget.onSave(product);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
