import 'package:flutter/foundation.dart';
import 'package:fixy_home_service/models/profile_models.dart';

/// FAQ service for handling frequently asked questions
class FAQService {
  /// Get all FAQs
  static Future<List<FAQ>> getFAQs() async {
    try {
      // Mock data for now - replace with actual Supabase call
      return FAQ.getMockFAQs();
    } catch (e) {
      debugPrint('❌ [FAQ_SERVICE] Error getting FAQs: $e');
      return [];
    }
  }

  /// Get FAQs by category (placeholder for future implementation)
  static Future<List<FAQ>> getFAQsByCategory(String category) async {
    try {
      final allFAQs = await getFAQs();
      // For now, return all FAQs since FAQ model doesn't have category field
      return allFAQs;
    } catch (e) {
      debugPrint('❌ [FAQ_SERVICE] Error getting FAQs by category: $e');
      return [];
    }
  }
}
