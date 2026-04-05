import 'package:fixy_home_service/supabase/supabase_config.dart';
import 'package:fixy_home_service/models/notification_model.dart';
import 'package:flutter/foundation.dart';

/// Notification service for handling notification operations
class NotificationService {
  /// Get user notifications
  static Future<List<NotificationModel>> getUserNotifications(
      String userId) async {
    try {
      final data = await SupabaseConfig.client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return data.map((json) => NotificationModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ [NOTIFICATION_SERVICE] Error getting notifications: $e');
      return [];
    }
  }

  /// Get unread notifications
  static Future<List<NotificationModel>> getUnreadNotifications(
      String userId) async {
    try {
      final data = await SupabaseConfig.client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('read', false)
          .order('created_at', ascending: false);

      return data.map((json) => NotificationModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint(
          '❌ [NOTIFICATION_SERVICE] Error getting unread notifications: $e');
      return [];
    }
  }

  /// Get unread count
  static Future<int> getUnreadCount(String userId) async {
    try {
      final result = await SupabaseConfig.client
          .from('notifications')
          .select('count')
          .eq('user_id', userId)
          .eq('read', false)
          .count();

      return result.count;
    } catch (e) {
      debugPrint('❌ [NOTIFICATION_SERVICE] Error getting unread count: $e');
      return 0;
    }
  }

  /// Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      await SupabaseConfig.client
          .from('notifications')
          .update({'read': true}).eq('id', notificationId);
    } catch (e) {
      debugPrint(
          '❌ [NOTIFICATION_SERVICE] Error marking notification as read: $e');
      rethrow;
    }
  }

  /// Mark all notifications as read
  static Future<void> markAllAsRead(String userId) async {
    try {
      await SupabaseConfig.client
          .from('notifications')
          .update({'read': true}).eq('user_id', userId);
    } catch (e) {
      debugPrint(
          '❌ [NOTIFICATION_SERVICE] Error marking all notifications as read: $e');
      rethrow;
    }
  }

  /// Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await SupabaseConfig.client
          .from('notifications')
          .delete()
          .eq('id', notificationId);
    } catch (e) {
      debugPrint('❌ [NOTIFICATION_SERVICE] Error deleting notification: $e');
      rethrow;
    }
  }

  /// Create notification
  static Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      await SupabaseConfig.client.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': body,
        'type': type,
        'data': data,
        'read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('❌ [NOTIFICATION_SERVICE] Error creating notification: $e');
      rethrow;
    }
  }
}
