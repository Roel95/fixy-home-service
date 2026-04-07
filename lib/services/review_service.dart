import 'package:flutter/material.dart';
import 'package:fixy_home_service/supabase/supabase_config.dart';

class ReviewService {
  /// Crea una nueva reseña y actualiza las estadísticas del proveedor
  static Future<bool> createReview({
    required String providerId,
    required String reservationId,
    required String userId,
    required int rating,
    String? comment,
  }) async {
    try {
      // Validar rating
      if (rating < 1 || rating > 5) {
        throw 'La calificación debe estar entre 1 y 5 estrellas';
      }

      final now = DateTime.now().toIso8601String();

      // 1. Insertar la reseña
      await SupabaseConfig.client.from('reviews').insert({
        'provider_id': providerId,
        'reservation_id': reservationId,
        'user_id': userId,
        'rating': rating,
        'comment': comment,
        'created_at': now,
        'updated_at': now,
      });

      // 2. Recalcular el rating promedio del proveedor
      final reviewsResponse = await SupabaseConfig.client
          .from('reviews')
          .select('rating')
          .eq('provider_id', providerId);

      final reviews = List<Map<String, dynamic>>.from(reviewsResponse);
      final totalReviews = reviews.length;
      final averageRating = totalReviews > 0
          ? reviews.fold<double>(0, (sum, r) => sum + (r['rating'] as int)) / totalReviews
          : 0.0;

      // 3. Actualizar estadísticas del proveedor
      await SupabaseConfig.client.from('providers').update({
        'rating': double.parse(averageRating.toStringAsFixed(1)),
        'total_reviews': totalReviews,
      }).eq('id', providerId);

      debugPrint('✅ [REVIEW_SERVICE] Reseña creada exitosamente');
      return true;
    } catch (e) {
      debugPrint('❌ [REVIEW_SERVICE] Error creando reseña: $e');
      return false;
    }
  }

  /// Verifica si el usuario ya dejó una reseña para esta reserva
  static Future<bool> hasReviewed({
    required String reservationId,
    required String userId,
  }) async {
    try {
      final response = await SupabaseConfig.client
          .from('reviews')
          .select('id')
          .eq('reservation_id', reservationId)
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('❌ [REVIEW_SERVICE] Error verificando reseña: $e');
      return false;
    }
  }
}
