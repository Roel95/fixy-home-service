import 'package:flutter/material.dart';
import 'package:fixy_home_service/models/banner_model.dart';
import 'package:fixy_home_service/repositories/banner_repository.dart';
import 'package:fixy_home_service/theme/app_theme.dart';
import 'package:fixy_home_service/utils/image_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BannersTab extends StatefulWidget {
  const BannersTab({Key? key}) : super(key: key);

  @override
  State<BannersTab> createState() => _BannersTabState();
}

class _BannersTabState extends State<BannersTab>
    with SingleTickerProviderStateMixin {
  final BannerRepository _repository = BannerRepository();
  List<BannerModel> _banners = [];
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;
  String _selectedType = 'app';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadBanners();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedType = _tabController.index == 0 ? 'app' : 'shop';
      });
      _loadBanners();
    }
  }

  Future<void> _loadBanners() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final banners = await _repository.getBannersByType(_selectedType);
      setState(() {
        _banners = banners;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteBanner(BannerModel banner) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Banner'),
        content: Text(
            '¿Estás seguro de que deseas eliminar el banner "${banner.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _repository.deleteBanner(banner.id);
        _loadBanners();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Banner eliminado correctamente')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e')),
          );
        }
      }
    }
  }

  Future<void> _toggleBannerActive(BannerModel banner) async {
    try {
      await _repository.toggleBannerActive(banner.id, !banner.isActive);
      _loadBanners();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                banner.isActive ? 'Banner desactivado' : 'Banner activado'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showCreateEditDialog({BannerModel? banner}) {
    showDialog(
      context: context,
      builder: (context) => BannerFormDialog(
        banner: banner,
        type: _selectedType,
        onSave: (savedBanner) {
          _loadBanners();
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tabs para App y Shop
        TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(icon: Icon(Icons.phone_android), text: 'App'),
            Tab(icon: Icon(Icons.shopping_bag), text: 'Tienda'),
          ],
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Error: $_error'),
                          ElevatedButton(
                            onPressed: _loadBanners,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Banners de ${_selectedType == 'app' ? 'App' : 'Tienda'}',
                                style: AppTheme.textTheme.headlineMedium,
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _showCreateEditDialog(),
                                icon: const Icon(Icons.add),
                                label: const Text('Nuevo Banner'),
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
                          if (_banners.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(48),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.image_outlined,
                                      size: 64,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No hay banners ${_selectedType == 'app' ? 'de la app' : 'de la tienda'}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () => _showCreateEditDialog(),
                                      icon: const Icon(Icons.add),
                                      label: const Text('Crear primer banner'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ReorderableListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _banners.length,
                              onReorder: (oldIndex, newIndex) async {
                                setState(() {
                                  if (newIndex > oldIndex) newIndex--;
                                  final banner = _banners.removeAt(oldIndex);
                                  _banners.insert(newIndex, banner);
                                  // Update order values
                                  for (int i = 0; i < _banners.length; i++) {
                                    _banners[i] =
                                        _banners[i].copyWith(order: i);
                                  }
                                });
                                await _repository.updateBannerOrder(_banners);
                              },
                              itemBuilder: (context, index) {
                                final banner = _banners[index];
                                return _buildBannerCard(banner, index);
                              },
                            ),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildBannerCard(BannerModel banner, int index) {
    return Card(
      key: ValueKey(banner.id),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Imagen del banner
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                banner.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade200,
                  child: Icon(Icons.broken_image,
                      color: Colors.grey.shade400, size: 48),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Información
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        banner.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (banner.subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          banner.subtitle!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildChip(
                            banner.typeLabel,
                            banner.type == 'app'
                                ? Icons.phone_android
                                : Icons.shopping_bag,
                            banner.type == 'app' ? Colors.blue : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          _buildChip(
                            banner.actionTypeLabel,
                            Icons.touch_app,
                            Colors.green,
                          ),
                          if (!banner.isVisible) ...[
                            const SizedBox(width: 8),
                            _buildChip(
                              'Oculto',
                              Icons.visibility_off,
                              Colors.red,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Acciones
                Column(
                  children: [
                    IconButton(
                      icon: Icon(
                        banner.isActive
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: banner.isActive ? Colors.green : Colors.grey,
                      ),
                      onPressed: () => _toggleBannerActive(banner),
                      tooltip: banner.isActive ? 'Desactivar' : 'Activar',
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showCreateEditDialog(banner: banner),
                      tooltip: 'Editar',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteBanner(banner),
                      tooltip: 'Eliminar',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Diálogo para crear/editar banner
class BannerFormDialog extends StatefulWidget {
  final BannerModel? banner;
  final String type;
  final Function(BannerModel) onSave;

  const BannerFormDialog({
    Key? key,
    this.banner,
    required this.type,
    required this.onSave,
  }) : super(key: key);

  @override
  State<BannerFormDialog> createState() => _BannerFormDialogState();
}

class _BannerFormDialogState extends State<BannerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _repository = BannerRepository();
  bool _isLoading = false;
  ImagePickResult? _imageBytes;
  String? _existingImageUrl;

  late final _titleController =
      TextEditingController(text: widget.banner?.title ?? '');
  late final _subtitleController =
      TextEditingController(text: widget.banner?.subtitle ?? '');
  late final _actionIdController =
      TextEditingController(text: widget.banner?.actionId ?? '');
  late final _orderController = TextEditingController(
    text: widget.banner?.order.toString() ?? '0',
  );

  late String _type;
  late String _actionType;
  late bool _isActive;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _type = widget.banner?.type ?? widget.type;
    _actionType = widget.banner?.actionType ?? 'none';
    _isActive = widget.banner?.isActive ?? true;
    _existingImageUrl = widget.banner?.imageUrl;
    _startDate = widget.banner?.startDate;
    _endDate = widget.banner?.endDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _actionIdController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final bytes = await ImageUtils.pickImage();
    if (bytes != null) {
      setState(() => _imageBytes = bytes);
    }
  }

  Future<void> _saveBanner() async {
    if (!_formKey.currentState!.validate()) return;

    if (_existingImageUrl == null && _imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes seleccionar una imagen')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String imageUrl = _existingImageUrl ?? '';

      // Subir nueva imagen si se seleccionó una
      if (_imageBytes != null) {
        final fileName = 'banner_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await Supabase.instance.client.storage
            .from('banners')
            .uploadBinary(fileName, _imageBytes!.bytes);

        imageUrl = Supabase.instance.client.storage
            .from('banners')
            .getPublicUrl(fileName);
      }

      final banner = BannerModel(
        id: widget.banner?.id ?? '',
        title: _titleController.text.trim(),
        subtitle: _subtitleController.text.trim().isEmpty
            ? null
            : _subtitleController.text.trim(),
        imageUrl: imageUrl,
        type: _type,
        actionType: _actionType == 'none' ? null : _actionType,
        actionId: _actionIdController.text.trim().isEmpty
            ? null
            : _actionIdController.text.trim(),
        order: int.tryParse(_orderController.text) ?? 0,
        isActive: _isActive,
        startDate: _startDate,
        endDate: _endDate,
        createdAt: widget.banner?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final savedBanner = widget.banner == null
          ? await _repository.createBanner(banner)
          : await _repository.updateBanner(banner);

      widget.onSave(savedBanner);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.banner == null ? 'Nuevo Banner' : 'Editar Banner'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Selector de imagen
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: _imageBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(_imageBytes!.bytes,
                                fit: BoxFit.cover),
                          )
                        : _existingImageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  _existingImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _buildImagePlaceholder(),
                                ),
                              )
                            : _buildImagePlaceholder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Tipo (App/Tienda)
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(
                    labelText: 'Tipo',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'app', child: Text('App')),
                    DropdownMenuItem(value: 'shop', child: Text('Tienda')),
                  ],
                  onChanged: (value) => setState(() => _type = value!),
                ),
                const SizedBox(height: 16),

                // Título
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.trim().isEmpty == true
                      ? 'El título es requerido'
                      : null,
                ),
                const SizedBox(height: 16),

                // Subtítulo
                TextFormField(
                  controller: _subtitleController,
                  decoration: const InputDecoration(
                    labelText: 'Subtítulo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Tipo de acción
                DropdownButtonFormField<String>(
                  initialValue: _actionType,
                  decoration: const InputDecoration(
                    labelText: 'Acción al tocar',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'none', child: Text('Ninguna')),
                    DropdownMenuItem(value: 'product', child: Text('Producto')),
                    DropdownMenuItem(
                        value: 'category', child: Text('Categoría')),
                    DropdownMenuItem(value: 'service', child: Text('Servicio')),
                    DropdownMenuItem(value: 'url', child: Text('URL Externa')),
                  ],
                  onChanged: (value) => setState(() => _actionType = value!),
                ),
                const SizedBox(height: 16),

                // ID para la acción
                if (_actionType != 'none')
                  TextFormField(
                    controller: _actionIdController,
                    decoration: InputDecoration(
                      labelText: _actionType == 'url'
                          ? 'URL'
                          : 'ID del ${_actionTypeLabel()}',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                if (_actionType != 'none') const SizedBox(height: 16),

                // Orden
                TextFormField(
                  controller: _orderController,
                  decoration: const InputDecoration(
                    labelText: 'Orden',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Activo/Inactivo
                SwitchListTile(
                  title: const Text('Banner activo'),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveBanner,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.banner == null ? 'Crear' : 'Guardar'),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey.shade400),
        const SizedBox(height: 8),
        Text(
          'Toca para seleccionar imagen',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  String _actionTypeLabel() {
    switch (_actionType) {
      case 'product':
        return 'Producto';
      case 'category':
        return 'Categoría';
      case 'service':
        return 'Servicio';
      case 'url':
        return 'URL';
      default:
        return '';
    }
  }
}
