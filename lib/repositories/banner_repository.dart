import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/banner_model.dart';

/// Repository para gestionar operaciones CRUD de banners en Supabase
class BannerRepository {
  final SupabaseClient _client;
  static const String tableName = 'banners';

  BannerRepository() : _client = Supabase.instance.client;

  /// Obtener todos los banners
  Future<List<BannerModel>> getAllBanners() async {
    try {
      final response = await _client
          .from(tableName)
          .select()
          .order('order', ascending: true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => BannerModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching banners: $e');
      throw Exception('Error al obtener banners: $e');
    }
  }

  /// Obtener banners por tipo (app o shop)
  Future<List<BannerModel>> getBannersByType(String type) async {
    try {
      final response = await _client
          .from(tableName)
          .select()
          .eq('type', type)
          .order('order', ascending: true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => BannerModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching banners by type: $e');
      throw Exception('Error al obtener banners: $e');
    }
  }

  /// Obtener banners activos por tipo (para mostrar en la app)
  Future<List<BannerModel>> getActiveBannersByType(String type) async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await _client
          .from(tableName)
          .select()
          .eq('type', type)
          .eq('is_active', true)
          .or('start_date.is.null,start_date.lte.$now')
          .or('end_date.is.null,end_date.gte.$now')
          .order('order', ascending: true);

      return (response as List)
          .map((json) => BannerModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching active banners: $e');
      throw Exception('Error al obtener banners activos: $e');
    }
  }

  /// Obtener un banner por ID
  Future<BannerModel?> getBannerById(String id) async {
    try {
      final response = await _client
          .from(tableName)
          .select()
          .eq('id', id)
          .single();

      return BannerModel.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching banner by id: $e');
      return null;
    }
  }

  /// Crear un nuevo banner
  Future<BannerModel> createBanner(BannerModel banner) async {
    try {
      final json = banner.toInsertJson();
      final response = await _client
          .from(tableName)
          .insert(json)
          .select()
          .single();

      return BannerModel.fromJson(response);
    } catch (e) {
      debugPrint('Error creating banner: $e');
      throw Exception('Error al crear banner: $e');
    }
  }

  /// Actualizar un banner existente
  Future<BannerModel> updateBanner(BannerModel banner) async {
    try {
      final json = banner.toUpdateJson();
      final response = await _client
          .from(tableName)
          .update(json)
          .eq('id', banner.id)
          .select()
          .single();

      return BannerModel.fromJson(response);
    } catch (e) {
      debugPrint('Error updating banner: $e');
      throw Exception('Error al actualizar banner: $e');
    }
  }

  /// Eliminar un banner
  Future<void> deleteBanner(String id) async {
    try {
      await _client
          .from(tableName)
          .delete()
          .eq('id', id);
    } catch (e) {
      debugPrint('Error deleting banner: $e');
      throw Exception('Error al eliminar banner: $e');
    }
  }

  /// Actualizar orden de los banners
  Future<void> updateBannerOrder(List<BannerModel> banners) async {
    try {
      final batch = banners.map((banner) async {
        await _client
            .from(tableName)
            .update({'order': banner.order})
            .eq('id', banner.id);
      }).toList();

      await Future.wait(batch);
    } catch (e) {
      debugPrint('Error updating banner order: $e');
      throw Exception('Error al actualizar orden de banners: $e');
    }
  }

  /// Toggle estado activo/inactivo de un banner
  Future<BannerModel> toggleBannerActive(String id, bool isActive) async {
    try {
      final response = await _client
          .from(tableName)
          .update({'is_active': isActive})
          .eq('id', id)
          .select()
          .single();

      return BannerModel.fromJson(response);
    } catch (e) {
      debugPrint('Error toggling banner active state: $e');
      throw Exception('Error al cambiar estado del banner: $e');
    }
  }
}
