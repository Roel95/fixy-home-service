import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fixy_home_service/supabase/supabase_config.dart';
import 'package:uuid/uuid.dart';

/// Servicio para subir imágenes a Supabase Storage
class ImageUploadService {
  final SupabaseClient _client = SupabaseConfig.client;
  final ImagePicker _picker = ImagePicker();

  /// Bucket de Supabase para imágenes de productos
  static const String _bucketName = 'product-images';

  // ============================================
  // SELECCIÓN DE IMÁGENES
  // ============================================

  /// Seleccionar imagen desde la galería
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print('❌ Error seleccionando imagen de galería: $e');
      return null;
    }
  }

  /// Tomar foto con la cámara
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print('❌ Error tomando foto: $e');
      return null;
    }
  }

  /// Seleccionar múltiples imágenes
  Future<List<File>> pickMultipleImages({int maxImages = 5}) async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      final files =
          pickedFiles.take(maxImages).map((file) => File(file.path)).toList();

      return files;
    } catch (e) {
      print('❌ Error seleccionando múltiples imágenes: $e');
      return [];
    }
  }

  // ============================================
  // SUBIDA A SUPABASE
  // ============================================

  /// Subir una imagen a Supabase Storage
  /// Retorna la URL pública de la imagen
  Future<String?> uploadImage(File imageFile, {String? folder}) async {
    try {
      // Generar nombre único para el archivo
      final String fileName = const Uuid().v4();
      final String extension = _getFileExtension(imageFile.path);
      final String path = folder != null
          ? '$folder/$fileName.$extension'
          : '$fileName.$extension';

      print('📤 Subiendo imagen: $path');

      // Subir archivo a Supabase
      await _client.storage.from(_bucketName).upload(path, imageFile);

      // Obtener URL pública
      final String publicUrl =
          _client.storage.from(_bucketName).getPublicUrl(path);

      print('✅ Imagen subida: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('❌ Error subiendo imagen: $e');
      return null;
    }
  }

  /// Subir múltiples imágenes
  Future<List<String>> uploadMultipleImages(List<File> imageFiles,
      {String? folder}) async {
    final List<String> urls = [];

    for (final file in imageFiles) {
      final url = await uploadImage(file, folder: folder);
      if (url != null) {
        urls.add(url);
      }
    }

    return urls;
  }

  /// Subir imagen desde URL externa (para importar)
  Future<String?> uploadImageFromUrl(String externalUrl,
      {String? folder}) async {
    try {
      // Descargar imagen temporalmente
      final response = await HttpClient().getUrl(Uri.parse(externalUrl));
      final httpResponse = await response.close();

      if (httpResponse.statusCode == 200) {
        final List<List<int>> chunks = [];
        await for (final chunk in httpResponse) {
          chunks.add(chunk);
        }
        final bytes = <int>[];
        for (final chunk in chunks) {
          bytes.addAll(chunk);
        }
        final tempFile =
            File('${Directory.systemTemp.path}/${const Uuid().v4()}.jpg');
        await tempFile.writeAsBytes(bytes);

        // Subir a Supabase
        final result = await uploadImage(tempFile, folder: folder);

        // Limpiar archivo temporal
        await tempFile.delete();

        return result;
      }

      return null;
    } catch (e) {
      print('❌ Error subiendo imagen desde URL: $e');
      return null;
    }
  }

  // ============================================
  // GESTIÓN DE IMÁGENES
  // ============================================

  /// Eliminar una imagen de Supabase Storage
  Future<bool> deleteImage(String imageUrl) async {
    try {
      // Extraer el path de la URL
      final path = _extractPathFromUrl(imageUrl);
      if (path == null) return false;

      await _client.storage.from(_bucketName).remove([path]);
      print('✅ Imagen eliminada: $path');
      return true;
    } catch (e) {
      print('❌ Error eliminando imagen: $e');
      return false;
    }
  }

  /// Eliminar múltiples imágenes
  Future<bool> deleteMultipleImages(List<String> imageUrls) async {
    try {
      final paths = imageUrls
          .map((url) => _extractPathFromUrl(url))
          .where((path) => path != null)
          .cast<String>()
          .toList();

      if (paths.isEmpty) return true;

      await _client.storage.from(_bucketName).remove(paths);
      print('✅ ${paths.length} imágenes eliminadas');
      return true;
    } catch (e) {
      print('❌ Error eliminando imágenes: $e');
      return false;
    }
  }

  /// Actualizar imagen (eliminar anterior y subir nueva)
  Future<String?> updateImage(String? oldImageUrl, File newImageFile,
      {String? folder}) async {
    // Eliminar imagen anterior si existe
    if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
      await deleteImage(oldImageUrl);
    }

    // Subir nueva imagen
    return await uploadImage(newImageFile, folder: folder);
  }

  // ============================================
  // MÉTODOS AUXILIARES
  // ============================================

  String _getFileExtension(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'webp'].contains(extension)
        ? extension
        : 'jpg';
  }

  String? _extractPathFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      // Encontrar el índice del bucket name
      final bucketIndex = pathSegments.indexOf(_bucketName);
      if (bucketIndex >= 0 && bucketIndex < pathSegments.length - 1) {
        return pathSegments.sublist(bucketIndex + 1).join('/');
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Verificar si el bucket existe, si no, crearlo
  Future<void> ensureBucketExists() async {
    try {
      await _client.storage.getBucket(_bucketName);
    } catch (e) {
      // Bucket no existe, intentar crearlo
      try {
        await _client.storage.createBucket(
          _bucketName,
          const BucketOptions(
            public: true, // Hacer el bucket público para acceso directo
          ),
        );
        print('✅ Bucket $_bucketName creado');
      } catch (e) {
        print('❌ Error creando bucket: $e');
      }
    }
  }
}
