import 'package:flutter/foundation.dart';
import 'package:fixy_home_service/models/service_model.dart';
import 'package:fixy_home_service/supabase/supabase_config.dart';

/// Service management service for handling provider services
class ServiceManagementService {
  /// Get services by provider ID
  static Future<List<ServiceModel>> getServicesByProviderId(
      String providerId) async {
    try {
      final data = await SupabaseConfig.client
          .from('services')
          .select()
          .eq('provider_id', providerId)
          .order('created_at', ascending: false);

      return data.map((json) => ServiceModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ [SERVICE_MANAGEMENT] Error getting services: $e');
      return [];
    }
  }

  /// Toggle service status (active/inactive)
  static Future<bool> toggleServiceStatus(
      String serviceId, bool isActive) async {
    try {
      await SupabaseConfig.client
          .from('services')
          .update({'is_active': isActive}).eq('id', serviceId);

      debugPrint('✅ [SERVICE_MANAGEMENT] Service status toggled: $serviceId');
      return true;
    } catch (e) {
      debugPrint('❌ [SERVICE_MANAGEMENT] Error toggling service status: $e');
      return false;
    }
  }

  /// Create new service
  static Future<ServiceModel?> createService(
      ServiceModel service, String providerId) async {
    try {
      final json = service.toJson();
      json['provider_id'] = providerId;
      final data = await SupabaseConfig.client
          .from('services')
          .insert(json)
          .select()
          .single();

      return ServiceModel.fromJson(data);
    } catch (e) {
      debugPrint('❌ [SERVICE_MANAGEMENT] Error creating service: $e');
      return null;
    }
  }

  /// Update service
  static Future<bool> updateService(
      String serviceId, ServiceModel service) async {
    try {
      await SupabaseConfig.client
          .from('services')
          .update(service.toJson())
          .eq('id', serviceId);

      debugPrint('✅ [SERVICE_MANAGEMENT] Service updated: $serviceId');
      return true;
    } catch (e) {
      debugPrint('❌ [SERVICE_MANAGEMENT] Error updating service: $e');
      return false;
    }
  }

  /// Delete service
  static Future<bool> deleteService(String serviceId) async {
    try {
      await SupabaseConfig.client.from('services').delete().eq('id', serviceId);

      debugPrint('✅ [SERVICE_MANAGEMENT] Service deleted: $serviceId');
      return true;
    } catch (e) {
      debugPrint('❌ [SERVICE_MANAGEMENT] Error deleting service: $e');
      return false;
    }
  }
}
