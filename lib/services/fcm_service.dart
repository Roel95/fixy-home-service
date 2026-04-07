import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Top-level background message handler (must be top-level or static)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 [FCM] Background message received: ${message.messageId}');
  await Firebase.initializeApp();
  await FCMService._showLocalNotification(message);
}

/// Service for handling Firebase Cloud Messaging (FCM) notifications
class FCMService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Initialize FCM service
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Request permission (iOS only, Android granted by default)
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint('🔔 [FCM] Permission status: ${settings.authorizationStatus}');

      // Set up background handler
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Set up foreground message handler
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Set up message opened handler (when user taps notification)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Initialize local notifications for foreground display
      await _initLocalNotifications();

      // Get and save FCM token
      await _updateFCMToken();

      // Listen for token refreshes
      _firebaseMessaging.onTokenRefresh.listen(_saveTokenToSupabase);

      _initialized = true;
      debugPrint('✅ [FCM] Service initialized successfully');
    } catch (e) {
      debugPrint('❌ [FCM] Failed to initialize: $e');
      rethrow;
    }
  }

  /// Initialize local notification plugin
  static Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    // Create Android notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Get FCM token and save to Supabase
  static Future<void> _updateFCMToken() async {
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _saveTokenToSupabase(token);
    }
  }

  /// Save FCM token to user profile in Supabase
  static Future<void> _saveTokenToSupabase(String token) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ [FCM] No user logged in, skipping token save');
        return;
      }

      await Supabase.instance.client.from('user_profiles').update({
        'fcm_token': token,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      debugPrint('✅ [FCM] Token saved to Supabase');
    } catch (e) {
      debugPrint('❌ [FCM] Failed to save token: $e');
    }
  }

  /// Handle messages when app is in foreground
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('🔔 [FCM] Foreground message received: ${message.messageId}');
    debugPrint('📨 [FCM] Title: ${message.notification?.title}');
    debugPrint('📝 [FCM] Body: ${message.notification?.body}');

    // Show local notification even when app is in foreground
    await _showLocalNotification(message);
  }

  /// Handle when user taps on notification
  static void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('🔔 [FCM] Message opened app: ${message.messageId}');
    debugPrint('📊 [FCM] Data: ${message.data}');

    // Handle navigation based on notification type
    _handleNotificationNavigation(message.data);
  }

  /// Handle local notification tap
  static void _handleNotificationTap(NotificationResponse response) {
    debugPrint('🔔 [FCM] Local notification tapped: ${response.payload}');
    if (response.payload != null) {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      _handleNotificationNavigation(data);
    }
  }

  /// Show local notification
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      playSound: true,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      notificationDetails,
      payload: jsonEncode(message.data),
    );
  }

  /// Navigate based on notification type
  static void _handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type'] as String?;

    switch (type) {
      case 'order':
        final orderId = data['order_id'];
        debugPrint('🛒 [FCM] Navigate to order: $orderId');
        // TODO: Navigate to order details
        break;
      case 'reservation':
        final reservationId = data['reservation_id'];
        debugPrint('📅 [FCM] Navigate to reservation: $reservationId');
        // TODO: Navigate to reservation details
        break;
      case 'provider_reservation':
        final reservationId = data['reservation_id'];
        debugPrint('👷 [FCM] Provider reservation received: $reservationId');
        // TODO: Navigate to provider reservation management
        break;
      default:
        debugPrint('ℹ️ [FCM] Unknown notification type: $type');
    }
  }

  /// Subscribe to a topic
  static Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    debugPrint('✅ [FCM] Subscribed to topic: $topic');
  }

  /// Unsubscribe from a topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    debugPrint('✅ [FCM] Unsubscribed from topic: $topic');
  }

  /// Delete FCM token (e.g., on logout)
  static Future<void> deleteToken() async {
    try {
      // Remove from Supabase first
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.from('user_profiles').update({
          'fcm_token': null,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', user.id);
      }

      // Delete from Firebase
      await _firebaseMessaging.deleteToken();
      debugPrint('✅ [FCM] Token deleted');
    } catch (e) {
      debugPrint('❌ [FCM] Failed to delete token: $e');
    }
  }
}
