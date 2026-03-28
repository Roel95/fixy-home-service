import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileInfoForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController postalCodeController;
  final bool isEditing;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const ProfileInfoForm({
    Key? key,
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.addressController,
    required this.cityController,
    required this.postalCodeController,
    required this.isEditing,
    required this.onSave,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            controller: nameController,
            enabled: isEditing,
            decoration: const InputDecoration(
              labelText: 'Nombre completo',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa tu nombre';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: emailController,
            enabled: isEditing,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa tu correo';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: phoneController,
            enabled: isEditing,
            decoration: const InputDecoration(
              labelText: 'Teléfono',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: addressController,
            enabled: isEditing,
            decoration: const InputDecoration(
              labelText: 'Dirección',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: cityController,
            enabled: isEditing,
            decoration: const InputDecoration(
              labelText: 'Ciudad',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: postalCodeController,
            enabled: isEditing,
            decoration: const InputDecoration(
              labelText: 'Código postal',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          if (isEditing)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onSave,
                    child: const Text('Guardar'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class ProfileImagePicker extends StatelessWidget {
  final String imageUrl;
  final Function(ImageSource) onImagePicked;
  final Uint8List? profileImageBytes;
  final VoidCallback? onDeletePhoto;

  const ProfileImagePicker({
    Key? key,
    required this.imageUrl,
    required this.onImagePicked,
    this.profileImageBytes,
    this.onDeletePhoto,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
