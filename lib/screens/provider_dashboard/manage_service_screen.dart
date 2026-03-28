import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fixy_home_service/models/service_model.dart';
import 'package:fixy_home_service/services/user_service.dart';
import 'package:fixy_home_service/services/service_management_service.dart';
import 'package:fixy_home_service/theme/app_theme.dart';

class ManageServiceScreen extends StatefulWidget {
  final String providerId;
  final ServiceModel? service;

  const ManageServiceScreen({
    super.key,
    required this.providerId,
    this.service,
  });

  @override
  State<ManageServiceScreen> createState() => _ManageServiceScreenState();
}

class _ManageServiceScreenState extends State<ManageServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _locationController = TextEditingController();

  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  final _imagePicker = ImagePicker();

  String _selectedCategory = 'Limpieza y Mantenimiento';
  String _selectedCurrency = 'S/';
  String _selectedTimeUnit = 'hr';
  String _timeFrom = '08:00';
  String _timeTo = '18:00';

  final List<String> _selectedDays = [];
  final List<String> _weekDays = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo'
  ];

  final List<String> _categories = [
    'Limpieza y Mantenimiento',
    'Reparaciones',
    'Belleza',
    'Electricidad',
    'Plomería',
    'Jardinería',
    'Pintura',
    'Carpintería',
    'Tecnología',
    'Otros'
  ];

  bool _isLoading = false;
  bool get _isEditing => widget.service != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _titleController.text = widget.service!.title;
      _descriptionController.text = widget.service!.description;
      _priceController.text = widget.service!.price.toString();
      _imageUrlController.text = widget.service!.imageUrl;
      _locationController.text = widget.service!.location;
      _selectedCategory = widget.service!.category;
      _selectedCurrency = widget.service!.currency;
      _selectedTimeUnit = widget.service!.timeUnit;
      _timeFrom = widget.service!.timeFrom;
      _timeTo = widget.service!.timeTo;
      _selectedDays.addAll(widget.service!.availableDays);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageName = image.name;
        });
        debugPrint(
            '📷 [IMAGE_PICKER] Imagen seleccionada: ${image.name} (${bytes.length} bytes)');
      }
    } catch (e) {
      debugPrint('❌ [IMAGE_PICKER] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un día disponible')),
      );
      return;
    }

    // Validate image
    if (!_isEditing && _selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una imagen para el servicio')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      debugPrint('📝 [MANAGE_SERVICE] Iniciando guardado de servicio...');
      debugPrint('📝 [MANAGE_SERVICE] Provider ID: ${widget.providerId}');
      debugPrint(
          '📝 [MANAGE_SERVICE] Modo: ${_isEditing ? "Edición" : "Creación"}');

      // Upload image if a new one was selected
      String imageUrl = _imageUrlController.text.trim();
      if (_selectedImageBytes != null && _selectedImageName != null) {
        debugPrint('📤 [MANAGE_SERVICE] Subiendo imagen...');
        imageUrl = await UserService.uploadServiceImage(
          widget.providerId,
          _selectedImageBytes!,
          _selectedImageName!,
        );
        debugPrint('✅ [MANAGE_SERVICE] Imagen subida: $imageUrl');
      }

      final service = ServiceModel(
        id: widget.service?.id ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        rating: widget.service?.rating ?? 0.0,
        reviews: widget.service?.reviews ?? 0,
        price: double.parse(_priceController.text.trim()),
        currency: _selectedCurrency,
        timeUnit: _selectedTimeUnit,
        imageUrl: imageUrl,
        category: _selectedCategory,
        location: _locationController.text.trim(),
        availableDays: _selectedDays,
        timeFrom: _timeFrom,
        timeTo: _timeTo,
        providerId: widget.providerId,
      );

      debugPrint('📝 [MANAGE_SERVICE] Datos del servicio: ${service.toJson()}');

      if (_isEditing) {
        debugPrint(
            '📝 [MANAGE_SERVICE] Actualizando servicio ID: ${widget.service!.id}');
        await ServiceManagementService.updateService(
            widget.service!.id, service);
        debugPrint('✅ [MANAGE_SERVICE] Servicio actualizado exitosamente');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Servicio actualizado')),
          );
        }
      } else {
        debugPrint('📝 [MANAGE_SERVICE] Creando nuevo servicio...');
        await ServiceManagementService.createService(
            service, widget.providerId);
        debugPrint('✅ [MANAGE_SERVICE] Servicio creado exitosamente');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Servicio creado')),
          );
        }
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e, stackTrace) {
      debugPrint('❌ [MANAGE_SERVICE] Error: $e');
      debugPrint('❌ [MANAGE_SERVICE] StackTrace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Ver logs',
              onPressed: () {
                debugPrint('Error completo: $e\n$stackTrace');
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? 'Editar Servicio' : 'Nuevo Servicio',
          style: AppTheme.textTheme.titleLarge,
        ),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              onPressed: _saveService,
              icon: const Icon(Icons.check, color: AppTheme.primaryColor),
              tooltip: 'Guardar',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Información Básica Section
            _SectionTitle(title: '📝 Información Básica'),
            const SizedBox(height: 16),
            _ModernTextField(
              controller: _titleController,
              label: 'Título del servicio',
              hint: 'Ej: Reparación de computadoras',
              icon: Icons.title,
              validator: (v) =>
                  v?.trim().isEmpty ?? true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            _ModernTextField(
              controller: _descriptionController,
              label: 'Descripción',
              hint: 'Describe tu servicio en detalle...',
              icon: Icons.description,
              maxLines: 4,
              validator: (v) =>
                  v?.trim().isEmpty ?? true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            _ModernDropdown(
              value: _selectedCategory,
              label: 'Categoría',
              icon: Icons.category,
              items: _categories,
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
            const SizedBox(height: 32),

            // Precio y Disponibilidad Section
            _SectionTitle(title: '💰 Precio y Disponibilidad'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _ModernTextField(
                    controller: _priceController,
                    label: 'Precio',
                    hint: '0.00',
                    icon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v?.trim().isEmpty ?? true) return 'Requerido';
                      if (double.tryParse(v!) == null) return 'Inválido';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _ModernDropdown(
                    value: _selectedCurrency,
                    label: 'Moneda',
                    items: ['S/', 'USD', 'EUR'],
                    onChanged: (v) => setState(() => _selectedCurrency = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _ModernDropdown(
                    value: _selectedTimeUnit,
                    label: 'Unidad',
                    items: ['hr', 'día', 'visita'],
                    onChanged: (v) => setState(() => _selectedTimeUnit = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Ubicación e Imagen Section
            _SectionTitle(title: '📍 Ubicación e Imagen'),
            const SizedBox(height: 16),
            _ModernTextField(
              controller: _locationController,
              label: 'Ubicación',
              hint: 'Ej: Lima Centro, Miraflores',
              icon: Icons.location_on,
              validator: (v) =>
                  v?.trim().isEmpty ?? true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            _ImagePickerField(
              imageBytes: _selectedImageBytes,
              imageName: _selectedImageName,
              existingImageUrl: _isEditing ? _imageUrlController.text : null,
              onTap: _pickImage,
            ),
            const SizedBox(height: 32),

            // Días Disponibles Section
            _SectionTitle(title: '📅 Días Disponibles'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _weekDays.map((day) {
                final isSelected = _selectedDays.contains(day);
                return _DayChip(
                  label: day,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedDays.remove(day);
                      } else {
                        _selectedDays.add(day);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Horario de Atención Section
            _SectionTitle(title: '⏰ Horario de Atención'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _TimePickerField(
                    label: 'Desde',
                    value: _timeFrom,
                    onChanged: (v) => setState(() => _timeFrom = v),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _TimePickerField(
                    label: 'Hasta',
                    value: _timeTo,
                    onChanged: (v) => setState(() => _timeTo = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Save Button
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveService,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _isEditing ? 'Actualizar Servicio' : 'Crear Servicio',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// Custom Widgets
class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTheme.textTheme.titleMedium?.copyWith(
        fontSize: 18,
        color: AppTheme.textPrimary,
      ),
    );
  }
}

class _ModernTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final int maxLines;
  final TextInputType? keyboardType;

  const _ModernTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.validator,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: AppTheme.textTheme.bodyLarge,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppTheme.primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: validator,
      ),
    );
  }
}

class _ModernDropdown extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _ModernDropdown({
    required this.value,
    required this.label,
    this.icon,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon:
              icon != null ? Icon(icon, color: AppTheme.primaryColor) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DayChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppTheme.textLight,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _TimePickerField extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  const _TimePickerField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () async {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay(
              hour: int.parse(value.split(':')[0]),
              minute: int.parse(value.split(':')[1]),
            ),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: AppTheme.primaryColor,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (time != null) {
            onChanged(
                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon:
                const Icon(Icons.access_time, color: AppTheme.primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          child: Text(
            value,
            style: AppTheme.textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}

class _ImagePickerField extends StatelessWidget {
  final Uint8List? imageBytes;
  final String? imageName;
  final String? existingImageUrl;
  final VoidCallback onTap;

  const _ImagePickerField({
    this.imageBytes,
    this.imageName,
    this.existingImageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageBytes != null ||
        (existingImageUrl != null && existingImageUrl!.isNotEmpty);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.image, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Imagen del servicio',
                        style: AppTheme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (imageName != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            imageName!,
                            style: AppTheme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.upload,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              hasImage ? 'Cambiar' : 'Subir',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (hasImage)
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child: imageBytes != null
                    ? Image.memory(
                        imageBytes!,
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        existingImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                          child: Icon(Icons.broken_image,
                              size: 48, color: Colors.grey),
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
