import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'supabase_config.dart';

/// Utility class for Supabase database operations
class SupabaseService {
  /// Select a single record from a table
  static Future<Map<String, dynamic>?> selectSingle(
    String table, {
    Map<String, dynamic>? filters,
    List<String>? columns,
  }) async {
    try {
      dynamic query;

      if (columns != null) {
        query = SupabaseConfig.client.from(table).select(columns.join(', '));
      } else {
        query = SupabaseConfig.client.from(table).select();
      }

      if (filters != null) {
        filters.forEach((key, value) {
          query = query.eq(key, value);
        });
      }

      final data = await query.limit(1);
      return data.isNotEmpty ? data.first : null;
    } catch (e) {
      debugPrint('❌ [SUPABASE_SERVICE] Error in selectSingle: $e');
      rethrow;
    }
  }

  /// Select multiple records from a table
  static Future<List<Map<String, dynamic>>> select(
    String table, {
    Map<String, dynamic>? filters,
    List<String>? columns,
    String? orderBy,
    bool ascending = true,
    int? limit,
  }) async {
    try {
      dynamic query;

      if (columns != null) {
        query = SupabaseConfig.client.from(table).select(columns.join(', '));
      } else {
        query = SupabaseConfig.client.from(table).select();
      }

      if (filters != null) {
        filters.forEach((key, value) {
          query = query.eq(key, value);
        });
      }

      if (orderBy != null) {
        query = query.order(orderBy, ascending: ascending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      return await query;
    } catch (e) {
      debugPrint('❌ [SUPABASE_SERVICE] Error in select: $e');
      rethrow;
    }
  }

  /// Insert a new record into a table
  static Future<List<Map<String, dynamic>>> insert(
    String table,
    Map<String, dynamic> data,
  ) async {
    try {
      return await SupabaseConfig.client.from(table).insert(data).select();
    } catch (e) {
      debugPrint('❌ [SUPABASE_SERVICE] Error in insert: $e');
      rethrow;
    }
  }

  /// Update records in a table
  static Future<void> update(
    String table,
    Map<String, dynamic> data, {
    Map<String, dynamic>? filters,
  }) async {
    try {
      dynamic query = SupabaseConfig.client.from(table).update(data);

      if (filters != null) {
        filters.forEach((key, value) {
          query = query.eq(key, value);
        });
      }

      await query;
    } catch (e) {
      debugPrint('❌ [SUPABASE_SERVICE] Error in update: $e');
      rethrow;
    }
  }

  /// Delete records from a table
  static Future<void> delete(
    String table, {
    Map<String, dynamic>? filters,
  }) async {
    try {
      dynamic query = SupabaseConfig.client.from(table).delete();

      if (filters != null) {
        filters.forEach((key, value) {
          query = query.eq(key, value);
        });
      }

      await query;
    } catch (e) {
      debugPrint('❌ [SUPABASE_SERVICE] Error in delete: $e');
      rethrow;
    }
  }

  /// Execute a raw SQL query
  static Future<List<Map<String, dynamic>>> raw(String sql) async {
    try {
      return await SupabaseConfig.client
          .rpc('execute_sql', params: {'query': sql});
    } catch (e) {
      debugPrint('❌ [SUPABASE_SERVICE] Error in raw query: $e');
      rethrow;
    }
  }
}

/// Authentication utility class
class SupabaseAuth {
  static GoTrueClient get _auth => SupabaseConfig.auth;

  /// Get current user
  static User? get currentUser => _auth.currentUser;

  /// Get current user ID
  static String? get currentUserId => currentUser?.id;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  /// Sign in with email and password
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('❌ [SUPABASE_AUTH] Error in signIn: $e');
      rethrow;
    }
  }

  /// Sign up with email and password
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? userData,
  }) async {
    try {
      return await _auth.signUp(
        email: email,
        password: password,
        data: userData,
      );
    } catch (e) {
      debugPrint('❌ [SUPABASE_AUTH] Error in signUp: $e');
      rethrow;
    }
  }

  /// Sign out current user
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('❌ [SUPABASE_AUTH] Error in signOut: $e');
      rethrow;
    }
  }

  /// Reset password
  static Future<void> resetPassword(String email) async {
    try {
      await _auth.resetPasswordForEmail(email);
    } catch (e) {
      debugPrint('❌ [SUPABASE_AUTH] Error in resetPassword: $e');
      rethrow;
    }
  }

  /// Update user password
  static Future<UserResponse> updatePassword(String newPassword) async {
    try {
      return await _auth.updateUser(
        UserAttributes(
          password: newPassword,
        ),
      );
    } catch (e) {
      debugPrint('❌ [SUPABASE_AUTH] Error in updatePassword: $e');
      rethrow;
    }
  }

  /// Update user metadata
  static Future<UserResponse> updateMetadata(
      Map<String, dynamic> metadata) async {
    try {
      return await _auth.updateUser(
        UserAttributes(
          data: metadata,
        ),
      );
    } catch (e) {
      debugPrint('❌ [SUPABASE_AUTH] Error in updateMetadata: $e');
      rethrow;
    }
  }
}
