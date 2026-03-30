import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio para gestionar administradores
class AdminService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Verificar si el usuario actual es administrador
  Future<bool> isCurrentUserAdmin() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // Verificar en la tabla users si is_admin es true
      final response = await _supabase
          .from('users')
          .select('is_admin')
          .eq('id', user.id)
          .single();

      return response['is_admin'] == true;
    } catch (e) {
      print('❌ Error verificando admin: $e');
      return false;
    }
  }

  /// Verificar si un usuario específico es admin
  Future<bool> isUserAdmin(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('is_admin')
          .eq('id', userId)
          .single();

      return response['is_admin'] == true;
    } catch (e) {
      print('❌ Error verificando admin: $e');
      return false;
    }
  }

  /// Asignar o quitar permisos de administrador
  Future<bool> setUserAdmin(String userId, bool isAdmin) async {
    try {
      await _supabase
          .from('users')
          .update({'is_admin': isAdmin}).eq('id', userId);

      print('✅ Permisos actualizados para usuario $userId: isAdmin=$isAdmin');
      return true;
    } catch (e) {
      print('❌ Error actualizando permisos: $e');
      return false;
    }
  }

  /// Obtener todos los usuarios con información de admin
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await _supabase
          .from('users')
          .select('id, email, is_admin, created_at')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error obteniendo usuarios: $e');
      return [];
    }
  }

  /// Buscar usuarios por email o nombre
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final response = await _supabase
          .from('users')
          .select('id, email, is_admin, created_at')
          .ilike('email', '%$query%')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error buscando usuarios: $e');
      return [];
    }
  }
}
