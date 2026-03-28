import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:fixy_home_service/models/video_model.dart';

class PexelsService {
  static const String _apiKey =
      'gcr6sy00J8vMQ0ky0ENm7kU5o16HdYcwxyGf9IHqBx9pz9Cm0mOs7XHX';
  static const String _baseUrl = 'https://api.pexels.com/videos';

  // Categorías relevantes para construcción y remodelación
  static const List<String> _searchQueries = [
    'home renovation',
    'interior design',
    'construction',
    'home improvement',
    'modern kitchen',
    'bathroom remodel',
    'architecture',
    'home decor',
    'flooring installation',
    'painting walls',
    'carpentry',
    'building materials',
  ];

  /// Obtiene videos de Pexels basados en búsquedas relevantes
  static Future<List<VideoModel>> getTrendingVideos(
      {int totalVideos = 50}) async {
    try {
      final List<VideoModel> allVideos = [];
      final Set<String> seenVideoIds = {};

      debugPrint('🎬 Buscando $totalVideos videos en Pexels...');

      // Buscar en múltiples categorías para obtener más videos
      final int videosPerQuery = (totalVideos / _searchQueries.length).ceil();

      for (final query in _searchQueries) {
        if (allVideos.length >= totalVideos) break;

        debugPrint('🔍 Buscando: "$query"');

        final url =
            Uri.parse('$_baseUrl/search?query=$query&per_page=$videosPerQuery');

        final response = await http.get(
          url,
          headers: {
            'Authorization': _apiKey,
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final videos = data['videos'] as List;

          debugPrint('  ✅ ${videos.length} videos encontrados');

          for (final videoJson in videos) {
            try {
              final videoId = videoJson['id'].toString();

              // Evitar duplicados
              if (seenVideoIds.contains(videoId)) continue;

              final videoModel = _parseVideo(videoJson);
              if (videoModel != null) {
                allVideos.add(videoModel);
                seenVideoIds.add(videoId);

                if (allVideos.length >= totalVideos) break;
              }
            } catch (e) {
              debugPrint('⚠️ Error parsing video: $e');
            }
          }
        } else {
          debugPrint('❌ Error fetching "$query": ${response.statusCode}');
        }
      }

      debugPrint('🎉 Total de videos procesados: ${allVideos.length}');
      return allVideos;
    } catch (e, stackTrace) {
      debugPrint('❌ Error in getTrendingVideos: $e');
      debugPrint('StackTrace: $stackTrace');
      return [];
    }
  }

  /// Busca videos por categoría específica
  static Future<List<VideoModel>> getVideosByCategory(String category,
      {int perPage = 5}) async {
    try {
      final url =
          Uri.parse('$_baseUrl/search?query=$category&per_page=$perPage');

      final response = await http.get(
        url,
        headers: {
          'Authorization': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final videos = data['videos'] as List;

        final List<VideoModel> videosList = [];
        for (final videoJson in videos) {
          try {
            final videoModel = _parseVideo(videoJson);
            if (videoModel != null) {
              videosList.add(videoModel);
            }
          } catch (e) {
            debugPrint('Error parsing video: $e');
          }
        }
        return videosList;
      } else {
        debugPrint('Error fetching videos by category: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error in getVideosByCategory: $e');
      return [];
    }
  }

  /// Parsea un video de Pexels al modelo de la app
  static VideoModel? _parseVideo(Map<String, dynamic> json) {
    try {
      final videoFiles = json['video_files'] as List?;
      if (videoFiles == null || videoFiles.isEmpty) return null;

      // Buscar el mejor video quality (preferir SD o HD para mejor rendimiento web)
      final videoFile = videoFiles.firstWhere(
        (file) => file['quality'] == 'sd' || file['quality'] == 'hd',
        orElse: () => videoFiles.first,
      );

      final videoUrl = videoFile['link'] as String?;
      if (videoUrl == null) return null;

      final thumbnailUrl = json['image'] as String? ?? '';
      final duration = json['duration'] as int? ?? 0;
      final user = json['user'] as Map<String, dynamic>?;
      final userName = user?['name'] as String? ?? 'Pexels User';

      // Generar título y categoría basado en tags o usar el usuario
      final tags =
          (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [];
      final category = _determineCategory(tags);
      final title = _generateTitle(tags, userName);

      return VideoModel(
        id: json['id'].toString(),
        title: title,
        thumbnailUrl: thumbnailUrl,
        videoUrl: videoUrl,
        category: category,
        duration: duration,
        description: 'Video por $userName',
      );
    } catch (e) {
      debugPrint('Error in _parseVideo: $e');
      return null;
    }
  }

  /// Determina la categoría basándose en los tags
  static String _determineCategory(List<String> tags) {
    if (tags.any((tag) => tag.toLowerCase().contains('kitchen')))
      return 'Cocinas';
    if (tags.any((tag) => tag.toLowerCase().contains('bathroom')))
      return 'Baños';
    if (tags.any((tag) => tag.toLowerCase().contains('floor'))) return 'Pisos';
    if (tags.any((tag) =>
        tag.toLowerCase().contains('design') ||
        tag.toLowerCase().contains('interior'))) return 'Diseño';
    if (tags.any((tag) =>
        tag.toLowerCase().contains('construction') ||
        tag.toLowerCase().contains('building'))) return 'Construcción';
    if (tags.any((tag) => tag.toLowerCase().contains('material')))
      return 'Materiales';
    return 'Remodelación';
  }

  /// Genera un título atractivo basándose en los tags
  static String _generateTitle(List<String> tags, String userName) {
    if (tags.isEmpty) return 'Ideas para tu Hogar';

    final mainTag = tags.first;
    final titleMap = {
      'kitchen': 'Ideas para Cocinas Modernas',
      'bathroom': 'Inspiración para Baños',
      'living': 'Diseño de Salas',
      'bedroom': 'Ideas para Dormitorios',
      'floor': 'Tendencias en Pisos',
      'wall': 'Decoración de Paredes',
      'paint': 'Técnicas de Pintura',
      'construction': 'Construcción Moderna',
      'renovation': 'Remodelación Paso a Paso',
      'design': 'Diseño Interior',
      'architecture': 'Arquitectura Contemporánea',
      'home': 'Mejoras para tu Hogar',
    };

    for (final entry in titleMap.entries) {
      if (mainTag.toLowerCase().contains(entry.key)) {
        return entry.value;
      }
    }

    return 'Ideas de ${tags.first}';
  }
}
