import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

/// Resultado de selección de imagen
class ImagePickResult {
  final Uint8List bytes;
  final String extension;
  final String? originalPath;

  ImagePickResult({
    required this.bytes,
    required this.extension,
    this.originalPath,
  });
}

/// Utilidades para manejo de imágenes
class ImageUtils {
  static final ImagePicker _picker = ImagePicker();

  /// Selecciona una imagen de la galería
  static Future<ImagePickResult?> pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile == null) return null;

      final bytes = await pickedFile.readAsBytes();
      final extension = pickedFile.name.split('.').last.toLowerCase();

      return ImagePickResult(
        bytes: bytes,
        extension: extension,
        originalPath: pickedFile.path,
      );
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  /// Toma una foto con la cámara
  static Future<ImagePickResult?> takePhoto() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile == null) return null;

      final bytes = await pickedFile.readAsBytes();

      return ImagePickResult(
        bytes: bytes,
        extension: 'jpg',
        originalPath: pickedFile.path,
      );
    } catch (e) {
      print('Error taking photo: $e');
      return null;
    }
  }
}
