import 'package:fixy_home_service/supabase/supabase_config.dart';
import 'package:flutter/foundation.dart';

/// Business-specific Supabase services
class SupabaseServices {
  /// Create a new reservation
  static Future<Map<String, dynamic>> createReservation({
    required String serviceId,
    required String providerId,
    required DateTime scheduledDate,
    required String duration,
    required Map<String, dynamic> selectedOptions,
    String? notes,
  }) async {
    try {
      final reservationData = {
        'service_id': serviceId,
        'provider_id': providerId,
        'user_id': SupabaseConfig.currentUserId,
        'scheduled_date': scheduledDate.toIso8601String(),
        'duration': duration,
        'selected_options': selectedOptions,
        'notes': notes,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      };

      final result = await SupabaseConfig.client
          .from('reservations')
          .insert(reservationData)
          .select()
          .single();

      debugPrint('✅ [SUPABASE_SERVICES] Reservation created: ${result['id']}');
      return result;
    } catch (e) {
      debugPrint('❌ [SUPABASE_SERVICES] Error creating reservation: $e');
      rethrow;
    }
  }

  /// Send notification to provider
  static Future<void> notifyProvider({
    required String providerId,
    required String reservationId,
    required String serviceName,
  }) async {
    try {
      final notificationData = {
        'user_id': providerId,
        'title': 'Nueva Reserva',
        'message': 'Tienes una nueva reserva para: $serviceName',
        'type': 'new_reservation',
        'data': {
          'reservation_id': reservationId,
          'service_name': serviceName,
        },
        'read': false,
        'created_at': DateTime.now().toIso8601String(),
      };

      await SupabaseConfig.client
          .from('notifications')
          .insert(notificationData);

      debugPrint(
          '✅ [SUPABASE_SERVICES] Notification inserted for provider: $providerId');

      // Send FCM push notification via Edge Function
      try {
        await SupabaseConfig.client.functions.invoke(
          'send-fcm-notification',
          body: {
            'user_id': providerId,
            'title': 'Nueva Reserva',
            'body': 'Tienes una nueva reserva para: $serviceName',
            'data': {
              'reservation_id': reservationId,
              'service_name': serviceName,
              'type': 'new_reservation',
            },
          },
        );
        debugPrint('✅ [SUPABASE_SERVICES] FCM notification sent to provider');
      } catch (fcmError) {
        debugPrint(
            '⚠️ [SUPABASE_SERVICES] FCM send failed (non-critical): $fcmError');
        // Don't rethrow - FCM failure shouldn't break the reservation flow
      }
    } catch (e) {
      debugPrint('❌ [SUPABASE_SERVICES] Error sending notification: $e');
      rethrow;
    }
  }

  /// Get user notifications
  static Future<List<Map<String, dynamic>>> getUserNotifications() async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) throw 'User not authenticated';

      final result = await SupabaseConfig.client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      debugPrint('❌ [SUPABASE_SERVICES] Error getting notifications: $e');
      rethrow;
    }
  }

  /// Mark notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await SupabaseConfig.client
          .from('notifications')
          .update({'read': true}).eq('id', notificationId);

      debugPrint(
          '✅ [SUPABASE_SERVICES] Notification marked as read: $notificationId');
    } catch (e) {
      debugPrint(
          '❌ [SUPABASE_SERVICES] Error marking notification as read: $e');
      rethrow;
    }
  }

  /// Get user reservations
  static Future<List<Map<String, dynamic>>> getUserReservations() async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) throw 'User not authenticated';

      final result = await SupabaseConfig.client.from('reservations').select('''
            *,
            services:service_id (
              id,
              title,
              price,
              currency,
              images
            ),
            providers:provider_id (
              id,
              business_name,
              profile_image_url
            )
          ''').eq('user_id', userId).order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      debugPrint('❌ [SUPABASE_SERVICES] Error getting user reservations: $e');
      rethrow;
    }
  }

  /// Update reservation status
  static Future<void> updateReservationStatus(
    String reservationId,
    String status,
  ) async {
    try {
      await SupabaseConfig.client.from('reservations').update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', reservationId);

      debugPrint(
          '✅ [SUPABASE_SERVICES] Reservation status updated: $reservationId -> $status');
    } catch (e) {
      debugPrint('❌ [SUPABASE_SERVICES] Error updating reservation status: $e');
      rethrow;
    }
  }

  /// Upload file to Supabase storage
  static Future<String> uploadFile({
    required Uint8List fileBytes,
    required String fileName,
    required String bucket,
  }) async {
    try {
      final path = '${SupabaseConfig.currentUserId}/$fileName';

      await SupabaseConfig.client.storage
          .from(bucket)
          .uploadBinary(path, fileBytes);

      final publicUrl =
          SupabaseConfig.client.storage.from(bucket).getPublicUrl(path);

      debugPrint('✅ [SUPABASE_SERVICES] File uploaded: $path');
      return publicUrl;
    } catch (e) {
      debugPrint('❌ [SUPABASE_SERVICES] Error uploading file: $e');
      rethrow;
    }
  }

  /// Delete file from Supabase storage
  static Future<void> deleteFile({
    required String fileName,
    required String bucket,
  }) async {
    try {
      final path = '${SupabaseConfig.currentUserId}/$fileName';

      await SupabaseConfig.client.storage.from(bucket).remove([path]);

      debugPrint('✅ [SUPABASE_SERVICES] File deleted: $path');
    } catch (e) {
      debugPrint('❌ [SUPABASE_SERVICES] Error deleting file: $e');
      rethrow;
    }
  }
}
