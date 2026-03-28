import 'package:fixy_home_service/supabase/supabase_config.dart';
import 'package:fixy_home_service/supabase/supabase_service.dart';
import 'package:fixy_home_service/models/provider_model.dart';

class ProviderService {
  /// Check if current user is a provider
  static Future<bool> isProvider() async {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) return false;

    try {
      final data = await SupabaseService.selectSingle(
        'providers',
        filters: {'user_id': userId},
      );
      return data != null;
    } catch (e) {
      return false;
    }
  }

  /// Get current user's provider profile
  static Future<ProviderModel?> getCurrentProviderProfile() async {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) return null;

    try {
      final data = await SupabaseService.selectSingle(
        'providers',
        filters: {'user_id': userId},
      );

      return data != null ? ProviderModel.fromJson(data) : null;
    } catch (e) {
      throw 'Error fetching provider profile: $e';
    }
  }

  /// Get provider by ID
  static Future<ProviderModel?> getProviderById(String providerId) async {
    try {
      final data = await SupabaseService.selectSingle(
        'providers',
        filters: {'id': providerId},
      );

      return data != null ? ProviderModel.fromJson(data) : null;
    } catch (e) {
      throw 'Error fetching provider: $e';
    }
  }

  /// Create new provider profile
  static Future<ProviderModel> createProvider(ProviderModel provider) async {
    try {
      final data = await SupabaseService.insert('providers', {
        'user_id': provider.userId,
        'business_name': provider.businessName,
        'description': provider.description,
        'profile_image_url': provider.profileImageUrl,
        'phone': provider.phone,
        'email': provider.email,
        'address': provider.address,
        'city': provider.city,
        'postal_code': provider.postalCode,
        'service_categories': provider.serviceCategories,
        'certifications': provider.certifications,
        'years_of_experience': provider.yearsOfExperience,
        'status': provider.status.name,
        'availability': provider.availability.toJson(),
        'is_verified': provider.isVerified,
        'verification_document_url': provider.verificationDocumentUrl,
      });

      return ProviderModel.fromJson(data.first);
    } catch (e) {
      throw 'Error creating provider: $e';
    }
  }

  /// Update provider profile
  static Future<void> updateProvider(ProviderModel provider) async {
    try {
      await SupabaseService.update(
        'providers',
        {
          'business_name': provider.businessName,
          'description': provider.description,
          'profile_image_url': provider.profileImageUrl,
          'phone': provider.phone,
          'email': provider.email,
          'address': provider.address,
          'city': provider.city,
          'postal_code': provider.postalCode,
          'service_categories': provider.serviceCategories,
          'certifications': provider.certifications,
          'years_of_experience': provider.yearsOfExperience,
          'status': provider.status.name,
          'availability': provider.availability.toJson(),
          'is_verified': provider.isVerified,
          'verification_document_url': provider.verificationDocumentUrl,
          'updated_at': DateTime.now().toIso8601String(),
        },
        filters: {'id': provider.id},
      );
    } catch (e) {
      throw 'Error updating provider: $e';
    }
  }

  /// Get all active providers by category
  static Future<List<ProviderModel>> getProvidersByCategory(
      String category) async {
    try {
      final data = await SupabaseConfig.client
          .from('providers')
          .select()
          .eq('status', 'active')
          .contains('service_categories', [category]).order('rating',
              ascending: false);

      return (data as List)
          .map((json) => ProviderModel.fromJson(json))
          .toList();
    } catch (e) {
      throw 'Error fetching providers by category: $e';
    }
  }

  /// Update provider status
  static Future<void> updateProviderStatus(
      String providerId, ProviderStatus status) async {
    try {
      await SupabaseService.update(
        'providers',
        {
          'status': status.name,
          'updated_at': DateTime.now().toIso8601String(),
        },
        filters: {'id': providerId},
      );
    } catch (e) {
      throw 'Error updating provider status: $e';
    }
  }

  /// Update provider availability
  static Future<void> updateProviderAvailability(
    String providerId,
    ProviderAvailability availability,
  ) async {
    try {
      await SupabaseService.update(
        'providers',
        {
          'availability': availability.toJson(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        filters: {'id': providerId},
      );
    } catch (e) {
      throw 'Error updating provider availability: $e';
    }
  }

  /// Update provider rating (called after service completion)
  static Future<void> updateProviderRating(
    String providerId,
    double newRating,
  ) async {
    try {
      final provider = await getProviderById(providerId);
      if (provider == null) return;

      final totalRating = (provider.rating * provider.totalReviews) + newRating;
      final newTotalReviews = provider.totalReviews + 1;
      final updatedRating = totalRating / newTotalReviews;

      await SupabaseService.update(
        'providers',
        {
          'rating': updatedRating,
          'total_reviews': newTotalReviews,
          'updated_at': DateTime.now().toIso8601String(),
        },
        filters: {'id': providerId},
      );
    } catch (e) {
      throw 'Error updating provider rating: $e';
    }
  }

  /// Increment completed jobs count
  static Future<void> incrementCompletedJobs(String providerId) async {
    try {
      final provider = await getProviderById(providerId);
      if (provider == null) return;

      await SupabaseService.update(
        'providers',
        {
          'completed_jobs': provider.completedJobs + 1,
          'updated_at': DateTime.now().toIso8601String(),
        },
        filters: {'id': providerId},
      );
    } catch (e) {
      throw 'Error incrementing completed jobs: $e';
    }
  }
}
