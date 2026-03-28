import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Supabase configuration for FixyHomeService
class SupabaseConfig {
  static const String supabaseUrl = 'https://ksikyeqjhifznsvrsfln.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtzaWt5ZXFqaGlmem5zdnJzZmxuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEwOTE2NDgsImV4cCI6MjA3NjY2NzY0OH0.iIaAKpU7jzPnTRI2p59fFiYxfPzYb7S6scZYptRENLE';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: anonKey,
      debug: kDebugMode,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
    );
  }

  /// Test connection to Supabase
  static Future<bool> testConnection() async {
    try {
      debugPrint('🔍 [SUPABASE] Testing connection...');
      await client.from('profiles').select('count').count();
      debugPrint('✅ [SUPABASE] Connection successful');
      return true;
    } catch (e) {
      debugPrint('❌ [SUPABASE] Connection failed: $e');
      return false;
    }
  }

  /// Get current user ID (null if not authenticated)
  static String? get currentUserId => auth.currentUser?.id;

  /// Get current user (null if not authenticated)
  static User? get currentUser => auth.currentUser;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;
}
