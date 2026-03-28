import 'package:fixy_home_service/models/banner_model.dart';
import 'package:fixy_home_service/supabase/supabase_config.dart';

class BannerRepository {
  // Get active banners from Supabase
  Future<List<BannerModel>> getActiveBanners() async {
    try {
      final response = await SupabaseConfig.client
          .from('banners')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => BannerModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error loading banners: $e');
      return [];
    }
  }

  // Get banners by category
  Future<List<BannerModel>> getBannersByCategory(String categoryId) async {
    try {
      final allBanners = await getActiveBanners();
      return allBanners.where((banner) {
        return banner.routeParams?['category'] == categoryId;
      }).toList();
    } catch (e) {
      print('Error loading banners by category: $e');
      return [];
    }
  }

  // Get banner by ID
  Future<BannerModel?> getBannerById(String id) async {
    try {
      final response = await SupabaseConfig.client
          .from('banners')
          .select()
          .eq('id', id)
          .single();

      return BannerModel.fromJson(response);
    } catch (e) {
      print('Error loading banner: $e');
      return null;
    }
  }
}
