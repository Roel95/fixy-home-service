import 'package:flutter/material.dart';
import 'package:fixy_home_service/models/saved_address_model.dart';
import 'package:fixy_home_service/services/address_service.dart';
import 'package:fixy_home_service/theme/app_theme.dart';
import 'package:uuid/uuid.dart';

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({Key? key}) : super(key: key);

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  final AddressService _addressService = AddressService();
  List<SavedAddress> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);
    final addresses = await _addressService.getUserAddresses();
    setState(() {
      _addresses = addresses;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Direcciones Guardadas',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D3748),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEditDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadAddresses,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _addresses.length,
                    itemBuilder: (context, index) {
                      return _buildAddressCard(_addresses[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No tienes direcciones guardadas',
            style: AppTheme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega una dirección para usarla en tus reservas',
            style: AppTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddEditDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Agregar Dirección'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(SavedAddress address) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getIconForType(address.iconType),
            color: AppTheme.primaryColor,
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Text(
              address.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (address.isDefault) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Principal',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              address.address,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            if (address.city != null || address.postalCode != null)
              Text(
                [
                  if (address.city != null) address.city!,
                  if (address.postalCode != null) address.postalCode!,
                ].join(', '),
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            if (address.reference != null)
              Text(
                'Ref: ${address.reference}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) async {
            switch (value) {
              case 'edit':
                _showAddEditDialog(address: address);
                break;
              case 'delete':
                _confirmDelete(address);
                break;
              case 'default':
                await _addressService.setDefaultAddress(address.id);
                _loadAddresses();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            if (!address.isDefault)
              const PopupMenuItem(
                value: 'default',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 20),
                    SizedBox(width: 8),
                    Text('Hacer principal'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'home':
        return Icons.home;
      case 'work':
        return Icons.business;
      case 'apartment':
        return Icons.apartment;
      case 'store':
        return Icons.store;
      case 'family':
        return Icons.family_restroom;
      default:
        return Icons.location_on;
    }
  }

  void _confirmDelete(SavedAddress address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Dirección'),
        content: Text('¿Estás seguro de eliminar "${address.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _addressService.deleteAddress(address.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dirección eliminada'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadAddresses();
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

  void _showAddEditDialog({SavedAddress? address}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddressFormBottomSheet(
        address: address,
        onSave: (savedAddress) async {
          if (address == null) {
            await _addressService.addAddress(savedAddress);
          } else {
            await _addressService.updateAddress(savedAddress);
          }
          _loadAddresses();
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(address == null
                    ? 'Dirección agregada'
                    : 'Dirección actualizada'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }
}

class AddressFormBottomSheet extends StatefulWidget {
  final SavedAddress? address;
  final Function(SavedAddress) onSave;

  const AddressFormBottomSheet({
    Key? key,
    this.address,
    required this.onSave,
  }) : super(key: key);

  @override
  State<AddressFormBottomSheet> createState() =>
      _AddressFormBottomSheetState();
}

class _AddressFormBottomSheetState extends State<AddressFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _postalCodeController;
  late final TextEditingController _referenceController;
  late String _selectedIcon;
  late bool _isDefault;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.address?.name ?? '');
    _addressController =
        TextEditingController(text: widget.address?.address ?? '');
    _cityController =
        TextEditingController(text: widget.address?.city ?? '');
    _postalCodeController =
        TextEditingController(text: widget.address?.postalCode ?? '');
    _referenceController =
        TextEditingController(text: widget.address?.reference ?? '');
    _selectedIcon = widget.address?.iconType ?? 'home';
    _isDefault = widget.address?.isDefault ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.address == null
                      ? 'Agregar Dirección'
                      : 'Editar Dirección',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  controller: _nameController,
                  label: 'Nombre',
                  hint: 'Ej: Casa, Trabajo, Mamá',
                  icon: Icons.label,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Ingresa un nombre' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _addressController,
                  label: 'Dirección',
                  hint: 'Ej: Av. Principal 123',
                  icon: Icons.location_on,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Ingresa la dirección' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _cityController,
                        label: 'Ciudad',
                        hint: 'Ej: Lima',
                        icon: Icons.location_city,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _postalCodeController,
                        label: 'Código Postal',
                        hint: 'Ej: 15001',
                        icon: Icons.local_post_office,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _referenceController,
                  label: 'Referencia (opcional)',
                  hint: 'Ej: Frente al parque, Casa azul',
                  icon: Icons.info,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Tipo de dirección',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  children: [
                    _buildIconOption('home', Icons.home, 'Casa'),
                    _buildIconOption('work', Icons.business, 'Trabajo'),
                    _buildIconOption('apartment', Icons.apartment, 'Dpto'),
                    _buildIconOption('store', Icons.store, 'Tienda'),
                    _buildIconOption('family', Icons.family_restroom, 'Familiar'),
                    _buildIconOption('other', Icons.location_on, 'Otro'),
                  ],
                ),
                const SizedBox(height: 24),
                CheckboxListTile(
                  value: _isDefault,
                  onChanged: (value) {
                    setState(() => _isDefault = value ?? false);
                  },
                  title: const Text('Hacer dirección principal'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      widget.address == null ? 'Agregar' : 'Guardar',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: validator,
    );
  }

  Widget _buildIconOption(String type, IconData icon, String label) {
    final isSelected = _selectedIcon == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedIcon = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.grey[100],
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      final address = SavedAddress(
        id: widget.address?.id ?? const Uuid().v4(),
        userId: widget.address?.userId ?? '',
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        reference: _referenceController.text.trim(),
        iconType: _selectedIcon,
        isDefault: _isDefault,
        createdAt: widget.address?.createdAt ?? DateTime.now(),
      );
      widget.onSave(address);
    }
  }
}
