import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fixy_home_service/theme/app_theme.dart';

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _dniController = TextEditingController();
  final _experienceController = TextEditingController();

  String? _specialty;
  final List<String> _specialties = [
    'Plomería',
    'Electricidad',
    'Limpieza',
    'Carpintería',
    'Albañilería',
    'Pintura',
    'Jardinería',
    'Gasfitería',
    'Cerrajería',
    'Electrodomésticos',
    'Aire Acondicionado',
    'Otros',
  ];

  File? _imageFile;
  bool _isLoading = false;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadProviderData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _whatsappController.dispose();
    _dniController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _loadProviderData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('users')
          .select(
              'full_name, phone, email, avatar_url, bio, specialty, years_experience, dni, whatsapp')
          .eq('id', user.id)
          .single();

      setState(() {
        _nameController.text = response['full_name'] ?? '';
        _phoneController.text = response['phone'] ?? '';
        _emailController.text = response['email'] ?? user.email ?? '';
        _bioController.text = response['bio'] ?? '';
        _whatsappController.text = response['whatsapp'] ?? '';
        _dniController.text = response['dni'] ?? '';
        _experienceController.text =
            response['years_experience']?.toString() ?? '';
        _specialty = response['specialty'];
        _avatarUrl = response['avatar_url'];
      });
    } catch (e) {
      debugPrint('Error loading provider data: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return _avatarUrl;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;

    try {
      final fileExt = _imageFile!.path.split('.').last;
      final fileName = '${user.id}_avatar.$fileExt';
      final filePath = 'avatars/$fileName';

      await Supabase.instance.client.storage.from('provider-avatars').upload(
          filePath, _imageFile!,
          fileOptions: FileOptions(upsert: true));

      final imageUrl = Supabase.instance.client.storage
          .from('provider-avatars')
          .getPublicUrl(filePath);

      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('No hay usuario autenticado');

      // Subir imagen si hay una nueva
      final avatarUrl = await _uploadImage();

      // Actualizar datos en Supabase
      await Supabase.instance.client.from('users').update({
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'bio': _bioController.text.trim(),
        'avatar_url': avatarUrl,
        'whatsapp': _whatsappController.text.trim(),
        'dni': _dniController.text.trim(),
        'years_experience':
            int.tryParse(_experienceController.text.trim()) ?? 0,
        'specialty': _specialty,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      setState(() {
        _avatarUrl = avatarUrl;
        _imageFile = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar
              _buildAvatarSection(),
              const SizedBox(height: 30),

              // Campos del formulario
              _buildTextField(
                controller: _nameController,
                label: 'Nombre completo',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa tu nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              _buildTextField(
                controller: _dniController,
                label: 'DNI',
                icon: Icons.badge_outlined,
                keyboardType: TextInputType.number,
                hint: 'Documento de identidad',
              ),
              const SizedBox(height: 20),

              _buildTextField(
                controller: _phoneController,
                label: 'Teléfono',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa tu teléfono';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              _buildTextField(
                controller: _whatsappController,
                label: 'WhatsApp',
                icon: Icons.chat_outlined,
                keyboardType: TextInputType.phone,
                hint: 'Número de WhatsApp (opcional)',
              ),
              const SizedBox(height: 20),

              _buildTextField(
                controller: _emailController,
                label: 'Correo electrónico',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                enabled: false,
              ),
              const SizedBox(height: 20),

              // Dropdown de especialidad
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _specialty,
                    isExpanded: true,
                    hint: Row(
                      children: [
                        Icon(Icons.work_outline,
                            color: AppTheme.primaryColor, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Selecciona tu especialidad',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    items: _specialties.map((String specialty) {
                      return DropdownMenuItem<String>(
                        value: specialty,
                        child: Text(specialty),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _specialty = newValue;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              _buildTextField(
                controller: _experienceController,
                label: 'Años de experiencia',
                icon: Icons.schedule_outlined,
                keyboardType: TextInputType.number,
                hint: 'Ej: 5',
              ),
              const SizedBox(height: 20),

              _buildTextField(
                controller: _bioController,
                label: 'Biografía / Descripción',
                icon: Icons.description_outlined,
                maxLines: 3,
                hint: 'Describe tu experiencia y especialidad...',
              ),
              const SizedBox(height: 40),

              // Botón guardar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveProfile,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isLoading ? 'Guardando...' : 'Guardar cambios'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Esta información será visible para los usuarios cuando reserves sus servicios.',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                width: 3,
              ),
            ),
            child: ClipOval(
              child: _imageFile != null
                  ? Image.file(_imageFile!, fit: BoxFit.cover)
                  : _avatarUrl != null && _avatarUrl!.isNotEmpty
                      ? Image.network(_avatarUrl!, fit: BoxFit.cover)
                      : Container(
                          color: Colors.grey.shade200,
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.grey.shade400,
                          ),
                        ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? hint,
    int maxLines = 1,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: enabled,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryColor),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
      ),
    );
  }
}
