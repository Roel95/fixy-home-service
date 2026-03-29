import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fixy_home_service/models/saved_address_model.dart';

class AddressService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtener todas las direcciones del usuario actual
  Future<List<SavedAddress>> getUserAddresses() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final response = await _supabase
          .from('saved_addresses')
          .select()
          .eq('user_id', user.id)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => SavedAddress.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error obteniendo direcciones: $e');
      return [];
    }
  }

  /// Agregar nueva dirección
  Future<SavedAddress?> addAddress(SavedAddress address) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Si es la primera dirección o se marca como default, actualizar las demás
      if (address.isDefault) {
        await _unsetDefaultAddresses(user.id);
      }

      final data = address.toInsertJson();
      data['user_id'] = user.id;

      final response = await _supabase
          .from('saved_addresses')
          .insert(data)
          .select()
          .single();

      return SavedAddress.fromJson(response);
    } catch (e) {
      print('❌ Error agregando dirección: $e');
      return null;
    }
  }

  /// Actualizar dirección existente
  Future<SavedAddress?> updateAddress(SavedAddress address) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Si se marca como default, quitar default de las demás
      if (address.isDefault) {
        await _unsetDefaultAddresses(user.id, exceptId: address.id);
      }

      final data = address.toInsertJson();
      data.remove('user_id');
      data.remove('created_at');

      final response = await _supabase
          .from('saved_addresses')
          .update(data)
          .eq('id', address.id)
          .eq('user_id', user.id)
          .select()
          .single();

      return SavedAddress.fromJson(response);
    } catch (e) {
      print('❌ Error actualizando dirección: $e');
      return null;
    }
  }

  /// Eliminar dirección
  Future<bool> deleteAddress(String addressId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      await _supabase
          .from('saved_addresses')
          .delete()
          .eq('id', addressId)
          .eq('user_id', user.id);

      return true;
    } catch (e) {
      print('❌ Error eliminando dirección: $e');
      return false;
    }
  }

  /// Establecer dirección como principal
  Future<bool> setDefaultAddress(String addressId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Primero quitar default de todas
      await _unsetDefaultAddresses(user.id);

      // Luego establecer la nueva como default
      await _supabase
          .from('saved_addresses')
          .update({'is_default': true})
          .eq('id', addressId)
          .eq('user_id', user.id);

      return true;
    } catch (e) {
      print('❌ Error estableciendo dirección principal: $e');
      return false;
    }
  }

  /// Quitar flag de default de todas las direcciones del usuario
  Future<void> _unsetDefaultAddresses(String userId, {String? exceptId}) async {
    try {
      var query = _supabase
          .from('saved_addresses')
          .update({'is_default': false})
          .eq('user_id', userId);

      if (exceptId != null) {
        query = query.neq('id', exceptId);
      }

      await query;
    } catch (e) {
      print('❌ Error actualizando direcciones: $e');
    }
  }

  /// Obtener dirección principal del usuario
  Future<SavedAddress?> getDefaultAddress() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final response = await _supabase
          .from('saved_addresses')
          .select()
          .eq('user_id', user.id)
          .eq('is_default', true)
          .maybeSingle();

      if (response == null) {
        // Si no hay default, devolver la primera
        final addresses = await getUserAddresses();
        return addresses.isNotEmpty ? addresses.first : null;
      }

      return SavedAddress.fromJson(response);
    } catch (e) {
      print('❌ Error obteniendo dirección principal: $e');
      return null;
    }
  }
}
