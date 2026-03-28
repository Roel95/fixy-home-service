import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fixy_home_service/theme/app_theme.dart';

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
    return Stack(
      children: [
        // Profile image with ring
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.3),
                Colors.white.withValues(alpha: 0.1),
              ],
            ),
          ),
          padding: const EdgeInsets.all(4),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(65),
              child: profileImageBytes != null
                  ? Image.memory(
                      profileImageBytes!,
                      fit: BoxFit.cover,
                    )
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.white.withValues(alpha: 0.3),
                          child: const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),

        // Edit button with better visibility
        Positioned(
          bottom: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _showImageSourceSelector(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt,
                color: AppTheme.primaryColor,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showImageSourceSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Cambiar foto de perfil',
                  style: AppTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildImageOption(
                context,
                Icons.photo_camera,
                'Tomar foto',
                AppTheme.primaryColor,
                () {
                  Navigator.pop(context);
                  onImagePicked(ImageSource.camera);
                },
              ),
              const Divider(height: 1),
              _buildImageOption(
                context,
                Icons.photo_library,
                'Elegir de la galería',
                AppTheme.primaryColor,
                () {
                  Navigator.pop(context);
                  onImagePicked(ImageSource.gallery);
                },
              ),
              if (profileImageBytes != null ||
                  (imageUrl.isNotEmpty &&
                      !imageUrl.contains('placeholder'))) ...[
                const Divider(height: 1),
                _buildImageOption(
                  context,
                  Icons.delete_outline,
                  'Eliminar foto',
                  Colors.red,
                  () {
                    Navigator.pop(context);
                    onDeletePhoto?.call();
                  },
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageOption(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: AppTheme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
