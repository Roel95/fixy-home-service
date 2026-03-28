import 'package:fixy_home_service/supabase/supabase_config.dart';
import 'package:fixy_home_service/models/profile_models.dart';
import 'package:flutter/foundation.dart';

/// Service history service for handling service history operations
class ServiceHistoryService {
  /// Get user service history
  static Future<List<ServiceHistory>> getUserServiceHistory(String userId) async {
    try {
      final data = await SupabaseConfig.client
          .from('service_history')
          .select()
          .eq('user_id', userId)
          .order('completed_at', ascending: false);

      return data.map((json) => ServiceHistory.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ [SERVICE_HISTORY_SERVICE] Error getting service history: $e');
      return [];
    }
  }

  /// Add service history record
  static Future<void> addServiceHistory(ServiceHistory history) async {
    try {
      await SupabaseConfig.client
          .from('service_history')
          .insert(history.toJson());
    } catch (e) {
      debugPrint('❌ [SERVICE_HISTORY_SERVICE] Error adding service history: $e');
      rethrow;
    }
  }

  /// Update service history
  static Future<void> updateServiceHistory(ServiceHistory history) async {
    try {
      await SupabaseConfig.client
          .from('service_history')
          .update(history.toJson())
          .eq('id', history.id);
    } catch (e) {
      debugPrint('❌ [SERVICE_HISTORY_SERVICE] Error updating service history: $e');
      rethrow;
    }
  }
}
