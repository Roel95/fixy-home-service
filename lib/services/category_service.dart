import 'package:flutter/foundation.dart';
import 'package:fixy_home_service/supabase/supabase_config.dart';

/// Service for managing categories from Supabase
class CategoryService {
  /// Get all active categories from database
  static Future<List<String>> getCategories() async {
    try {
      final data = await SupabaseConfig.client
          .from('categories')
          .select('name')
          .eq('is_active', true)
          .order('name');

      final categories = data.map<String>((row) => row['name'] as String).toList();
      
      debugPrint('✅ [CATEGORY_SERVICE] Categorías cargadas: ${categories.length}');
      return categories;
    } catch (e) {
      debugPrint('❌ [CATEGORY_SERVICE] Error cargando categorías: $e');
      // Return default categories if database fails
      return [
        'Limpieza y Mantenimiento',
        'Reparaciones',
        'Belleza',
        'Electricidad',
        'Plomería',
        'Jardinería',
        'Pintura',
        'Carpintería',
        'Tecnología',
        'Otros'
      ];
    }
  }
}
