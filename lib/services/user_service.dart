import 'package:fixy_home_service/supabase/supabase_config.dart';
import 'package:fixy_home_service/models/profile_models.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Bucket unificado para archivos de la app (excluye product-images)
const String _storageBucket = 'app-storage';

/// User service for handling user-related operations
class UserService {
  /// Get current user profile
  static Future<UserProfile?> getCurrentUserProfile() async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) return null;

      final data = await SupabaseConfig.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      // Obtener nombre del metadata de Supabase Auth si el perfil no tiene nombre válido
      String name = data['name']?.toString() ?? '';
      if (name.isEmpty ||
          name.contains('@') ||
          RegExp(r'^\d+').hasMatch(name)) {
        // Intentar obtener nombre del metadata de Supabase Auth
        final authUser = SupabaseConfig.currentUser;
        final metadataName = authUser?.userMetadata?['name'] as String?;

        if (metadataName != null && metadataName.isNotEmpty) {
          name = metadataName;
        } else {
          // Fallback: extraer del email
          final email = data['email']?.toString() ?? authUser?.email ?? '';
          name = _extractNameFromEmail(email);
        }

        // Actualizar el nombre en la base de datos
        await SupabaseConfig.client.from('users').update({
          'name': name,
          'updated_at': DateTime.now().toIso8601String()
        }).eq('id', userId);
      }

      // Crear el perfil con el nombre limpio
      final cleanedData = Map<String, dynamic>.from(data);
      cleanedData['name'] = name;

      return UserProfile.fromJson(cleanedData);
    } catch (e) {
      debugPrint('❌ [USER_SERVICE] Error getting user profile: $e');
      return null;
    }
  }

  /// Update user profile
  static Future<void> updateUserProfile(UserProfile profile) async {
    try {
      // Mapear solo los campos que existen en la tabla users
      final updateData = {
        'name': profile.name,
        'email': profile.email,
        'phone': profile.phone,
        'avatar_url': profile.avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };

      debugPrint('📝 [USER_SERVICE] Actualizando perfil: ${profile.id}');
      debugPrint('📍 [USER_SERVICE] Datos: $updateData');

      await SupabaseConfig.client
          .from('users')
          .update(updateData)
          .eq('id', profile.id);

      debugPrint('✅ [USER_SERVICE] Perfil actualizado exitosamente');
    } catch (e) {
      debugPrint('❌ [USER_SERVICE] Error updating user profile: $e');
      rethrow;
    }
  }

  /// Create user profile
  static Future<UserProfile?> createUserProfile(String userId, String email,
      {String? name}) async {
    try {
      final newProfile = {
        'id': userId, // En tabla users, el campo es 'id' no 'user_id'
        'email': email,
        'name': name ?? email.split('@').first,
        'phone': '',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final data = await SupabaseConfig.client
          .from('users')
          .insert(newProfile)
          .select()
          .single();

      debugPrint('✅ [USER_SERVICE] Perfil creado para usuario: $userId');
      return UserProfile.fromJson(data);
    } catch (e) {
      debugPrint('❌ [USER_SERVICE] Error creating user profile: $e');
      return null;
    }
  }

  /// Upload profile image
  static Future<String> uploadProfileImage(
      String userId, Uint8List imageBytes) async {
    try {
      final fileName = 'profile_$userId.jpg';
      final path = 'profiles/$fileName';

      // Intentar eliminar archivo existente primero (para evitar error 409)
      try {
        await SupabaseConfig.client.storage.from(_storageBucket).remove([path]);
        debugPrint('🗑️ [USER_SERVICE] Archivo anterior eliminado');
      } catch (e) {
        // Si no existe, ignorar el error
        debugPrint(
            'ℹ️ [USER_SERVICE] No había archivo anterior o error al eliminar: $e');
      }

      // Subir nuevo archivo
      await SupabaseConfig.client.storage
          .from(_storageBucket)
          .uploadBinary(path, imageBytes);

      final publicUrl =
          SupabaseConfig.client.storage.from(_storageBucket).getPublicUrl(path);

      debugPrint('✅ [USER_SERVICE] Imagen subida exitosamente: $publicUrl');
      return publicUrl;
    } on StorageException catch (e) {
      debugPrint(
          '❌ [USER_SERVICE] Storage error: ${e.message}, status: ${e.statusCode}');

      // Error 404 puede ser bucket no existe o no tiene permisos
      if (e.statusCode == '404' ||
          e.message.toLowerCase().contains('not found')) {
        throw Exception('No se pudo subir la imagen. Posibles causas:\n'
            '1. El bucket "app-storage" no existe\n'
            '2. No tienes permisos (RLS policies)\n'
            '3. Error de conexión\n\n'
            'Verifica en Supabase Dashboard > Storage.');
      }

      if (e.statusCode == '403' ||
          e.message.toLowerCase().contains('security') ||
          e.message.toLowerCase().contains('policy') ||
          e.message.toLowerCase().contains('permission') ||
          e.message.toLowerCase().contains('unauthorized')) {
        throw Exception(
            'Error de permisos. Debes configurar las políticas RLS en Supabase:\n'
            '1. Ve a Storage > app-storage > Policies\n'
            '2. Agrega política INSERT para usuarios autenticados\n'
            '3. Agrega política SELECT para todos');
      }

      rethrow;
    } catch (e) {
      debugPrint('❌ [USER_SERVICE] Error uploading profile image: $e');
      rethrow;
    }
  }

  /// Delete profile image
  static Future<void> deleteProfileImage(String userId) async {
    try {
      final path = 'profiles/profile_$userId.jpg';
      await SupabaseConfig.client.storage.from(_storageBucket).remove([path]);
    } catch (e) {
      debugPrint('❌ [USER_SERVICE] Error deleting profile image: $e');
      rethrow;
    }
  }

  /// Upload service image
  static Future<String> uploadServiceImage(
    String providerId,
    Uint8List imageBytes,
    String fileName,
  ) async {
    try {
      final path = 'services/$providerId/$fileName';

      await SupabaseConfig.client.storage
          .from(_storageBucket)
          .uploadBinary(path, imageBytes);

      final publicUrl =
          SupabaseConfig.client.storage.from(_storageBucket).getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      debugPrint('❌ [USER_SERVICE] Error uploading service image: $e');
      rethrow;
    }
  }

  /// Add payment method
  static Future<void> addPaymentMethod(
      String userId, PaymentMethod method) async {
    try {
      await SupabaseConfig.client.from('payment_methods').insert({
        'user_id': userId,
        'type': method.type.name,
        'card_number': method.cardNumber,
        'card_holder_name': method.cardHolderName,
        'expiry_date': method.expiryDate,
        'app_name': method.appName,
        'account_number': method.accountNumber,
        'is_default': method.isDefault,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('❌ [USER_SERVICE] Error adding payment method: $e');
      rethrow;
    }
  }

  /// Remove payment method
  static Future<void> removePaymentMethod(String methodId) async {
    try {
      await SupabaseConfig.client
          .from('payment_methods')
          .delete()
          .eq('id', methodId);
    } catch (e) {
      debugPrint('❌ [USER_SERVICE] Error removing payment method: $e');
      rethrow;
    }
  }

  /// Extraer nombre presentable del email
  static String _extractNameFromEmail(String email) {
    if (email.isEmpty) return 'Usuario';

    // Obtener parte local del email (antes del @)
    String localPart = email.split('@').first;

    // Quitar números al inicio (como "20001995")
    localPart = localPart.replaceAll(RegExp(r'^\d+'), '');

    // Si quedó vacío, usar "Usuario"
    if (localPart.isEmpty) return 'Usuario';

    // Separar por puntos, guiones bajos o guiones
    List<String> parts = localPart.split(RegExp(r'[._-]'));

    // Capitalizar cada parte
    parts = parts.map((part) {
      if (part.isEmpty) return '';
      return part[0].toUpperCase() + part.substring(1).toLowerCase();
    }).toList();

    // Unir con espacios
    return parts.join(' ').trim();
  }
}
