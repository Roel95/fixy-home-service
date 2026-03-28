import 'package:fixy_home_service/models/video_model.dart';
import 'package:fixy_home_service/services/pexels_service.dart';
import 'package:flutter/foundation.dart';

class VideoRepository {
  // Caché de videos para evitar llamadas repetidas
  static List<VideoModel>? _cachedVideos;
  static DateTime? _lastFetchTime;
  static const _cacheDuration = Duration(hours: 1);

  /// Obtiene videos trending desde Pexels con caché
  Future<List<VideoModel>> getTrendingVideos() async {
    try {
      // Verificar si el caché es válido
      if (_cachedVideos != null && _lastFetchTime != null) {
        final cacheAge = DateTime.now().difference(_lastFetchTime!);
        if (cacheAge < _cacheDuration) {
          debugPrint('Returning cached videos');
          return _cachedVideos!;
        }
      }

      // Obtener videos desde Pexels (50 videos de múltiples categorías)
      debugPrint('Fetching fresh videos from Pexels');
      final videos = await PexelsService.getTrendingVideos(totalVideos: 50);

      // Guardar en caché
      _cachedVideos = videos;
      _lastFetchTime = DateTime.now();

      return videos;
    } catch (e) {
      debugPrint('Error fetching trending videos: $e');

      // Si hay videos en caché, devolverlos aunque estén vencidos
      if (_cachedVideos != null && _cachedVideos!.isNotEmpty) {
        debugPrint('Returning expired cache due to error');
        return _cachedVideos!;
      }

      // Devolver lista vacía en caso de error total
      return [];
    }
  }

  /// Obtiene videos por categoría específica
  Future<List<VideoModel>> getVideosByCategory(String category) async {
    try {
      return await PexelsService.getVideosByCategory(category, perPage: 5);
    } catch (e) {
      debugPrint('Error fetching videos by category: $e');
      return [];
    }
  }

  /// Limpia el caché de videos
  void clearCache() {
    _cachedVideos = null;
    _lastFetchTime = null;
  }
}
