import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Script de diagnóstico para notificaciones FCM
class NotificationDiagnostics {
  static Future<void> runFullDiagnostics() async {
    debugPrint('\n🔍 === DIAGNÓSTICO DE NOTIFICACIONES FCM ===\n');
    
    // 1. Verificar Firebase
    await _checkFirebase();
    
    // 2. Verificar FCM Token
    await _checkFCMToken();
    
    // 3. Verificar Supabase
    await _checkSupabase();
    
    // 4. Verificar permisos
    await _checkPermissions();
    
    debugPrint('\n✅ === DIAGNÓSTICO COMPLETADO ===\n');
  }
  
  static Future<void> _checkFirebase() async {
    try {
      final apps = Firebase.apps;
      if (apps.isEmpty) {
        debugPrint('❌ Firebase NO inicializado');
      } else {
        debugPrint('✅ Firebase inicializado: ${apps.first.name}');
        debugPrint('   App ID: ${apps.first.options.appId}');
        debugPrint('   Project ID: ${apps.first.options.projectId}');
      }
    } catch (e) {
      debugPrint('❌ Error verificando Firebase: $e');
    }
  }
  
  static Future<void> _checkFCMToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        debugPrint('❌ FCM Token es NULL');
      } else {
        debugPrint('✅ FCM Token obtenido:');
        debugPrint('   ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
      }
    } catch (e) {
      debugPrint('❌ Error obteniendo FCM Token: $e');
    }
  }
  
  static Future<void> _checkSupabase() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      
      if (user == null) {
        debugPrint('⚠️ Usuario no autenticado en Supabase');
        return;
      }
      
      debugPrint('✅ Usuario autenticado: ${user.id}');
      
      // Verificar si fcm_token está guardado
      final response = await client
          .from('user_profiles')
          .select('fcm_token')
          .eq('id', user.id)
          .single();
      
      final fcmToken = response['fcm_token'];
      if (fcmToken == null) {
        debugPrint('❌ fcm_token NO guardado en user_profiles');
      } else {
        debugPrint('✅ fcm_token guardado en Supabase');
        debugPrint('   ${fcmToken.toString().substring(0, fcmToken.toString().length > 20 ? 20 : fcmToken.toString().length)}...');
      }
    } catch (e) {
      debugPrint('❌ Error verificando Supabase: $e');
    }
  }
  
  static Future<void> _checkPermissions() async {
    try {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      debugPrint('📱 Permisos de notificación:');
      debugPrint('   Autorización: ${settings.authorizationStatus}');
      debugPrint('   Alertas: ${settings.alert}');
      debugPrint('   Badge: ${settings.badge}');
      debugPrint('   Sonido: ${settings.sound}');
      
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        debugPrint('⚠️ Los permisos de notificación no están autorizados');
      }
    } catch (e) {
      debugPrint('❌ Error verificando permisos: $e');
    }
  }
}
