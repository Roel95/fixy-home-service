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
          .from('user_profiles')
          .select()
          .eq('user_id', userId)
          .single();

      return UserProfile.fromJson(data);
    } catch (e) {
      debugPrint('❌ [USER_SERVICE] Error getting user profile: $e');
      return null;
    }
  }

  /// Update user profile
  static Future<void> updateUserProfile(UserProfile profile) async {
    try {
      await SupabaseConfig.client
          .from('user_profiles')
          .update(profile.toJson())
          .eq('id', profile.id);
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
        'user_id': userId,
        'email': email,
        'name': name ?? email.split('@').first,
        'phone': '',
        'address': '',
        'city': '',
        'postal_code': '',
        'avatar_url': '',
        'preferences': {},
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final data = await SupabaseConfig.client
          .from('user_profiles')
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

      await SupabaseConfig.client.storage
          .from(_storageBucket)
          .uploadBinary(path, imageBytes);

      final publicUrl =
          SupabaseConfig.client.storage.from(_storageBucket).getPublicUrl(path);

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
}
