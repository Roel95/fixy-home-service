import 'package:fixy_home_service/models/service_model.dart';
import 'package:fixy_home_service/models/category_model.dart';
import 'package:fixy_home_service/models/user_model.dart';
import 'package:fixy_home_service/models/flash_deal_item.dart';
import 'package:fixy_home_service/supabase/supabase_config.dart';
import 'package:fixy_home_service/data/product_repository.dart';

class ServiceRepository {
  // Current user
  UserModel getCurrentUser() {
    return UserModel(
      id: '1',
      name: 'Mary Cruz',
      email: 'mary.cruz@example.com',
      avatarUrl:
          'https://ui-avatars.com/api/?name=Mary+Cruz&background=667EEA&color=fff&size=200',
      hasNotifications: true,
      referralCode: 'MARY2024',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Get popular services from Supabase with provider info
  Future<List<ServiceModel>> getPopularServices() async {
    try {
      final response = await SupabaseConfig.client.from('services').select('''
          *,
          providers:provider_id (
            id,
            business_name,
            profile_image_url,
            rating
          )
        ''').eq('is_active', true).order('rating', ascending: false).limit(10);

      return (response as List).map((json) {
        final provider = json['providers'];
        return ServiceModel.fromJson({
          ...json,
          if (provider != null) ...{
            'provider_name': provider['business_name'],
            'provider_image_url': provider['profile_image_url'],
            'provider_rating': provider['rating'],
          }
        });
      }).toList();
    } catch (e) {
      print('Error loading popular services: $e');
      return [];
    }
  }

  // Search services with filters and provider info
  Future<List<ServiceModel>> searchServices({
    String? query,
    String? location,
    double? minPrice,
    double? maxPrice,
    String? day,
  }) async {
    try {
      var queryBuilder = SupabaseConfig.client.from('services').select('''
          *,
          providers:provider_id (
            id,
            business_name,
            profile_image_url,
            rating
          )
        ''').eq('is_active', true);

      // Apply filters
      if (query != null && query.isNotEmpty) {
        queryBuilder = queryBuilder.or(
            'title.ilike.%$query%,description.ilike.%$query%,category.ilike.%$query%');
      }

      if (location != null && location.isNotEmpty && location != 'Todos') {
        queryBuilder = queryBuilder.eq('location', location);
      }

      if (minPrice != null) {
        queryBuilder = queryBuilder.gte('price', minPrice);
      }

      if (maxPrice != null) {
        queryBuilder = queryBuilder.lte('price', maxPrice);
      }

      final response = await queryBuilder;
      List<ServiceModel> services = (response as List).map((json) {
        final provider = json['providers'];
        return ServiceModel.fromJson({
          ...json,
          if (provider != null) ...{
            'provider_name': provider['business_name'],
            'provider_image_url': provider['profile_image_url'],
            'provider_rating': provider['rating'],
          }
        });
      }).toList();

      // Filter by day (array contains)
      if (day != null && day.isNotEmpty && day != 'Todos') {
        services = services
            .where((service) => service.availableDays.contains(day))
            .toList();
      }

      return services;
    } catch (e) {
      print('Error searching services: $e');
      return [];
    }
  }

  // Get all available locations
  Future<List<String>> getAllLocations() async {
    try {
      final response = await SupabaseConfig.client
          .from('services')
          .select('location')
          .eq('is_active', true);

      Set<String> locations = {};
      for (var item in response as List) {
        if (item['location'] != null &&
            item['location'].toString().isNotEmpty) {
          locations.add(item['location']);
        }
      }

      return ['Todos', ...locations.toList()..sort()];
    } catch (e) {
      print('Error loading locations: $e');
      return ['Todos'];
    }
  }

  // Get flash deals (services with active discounts)
  Future<List<ServiceModel>> getFlashDeals() async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await SupabaseConfig.client
          .from('services')
          .select('''
          *,
          providers:provider_id (
            id,
            business_name,
            profile_image_url,
            rating
          )
        ''')
          .eq('is_active', true)
          .eq('has_discount', true)
          .gt('discount_expires_at', now)
          .order('discount_expires_at', ascending: true)
          .limit(5);

      return (response as List).map((json) {
        final provider = json['providers'];
        return ServiceModel.fromJson({
          ...json,
          if (provider != null) ...{
            'provider_name': provider['business_name'],
            'provider_image_url': provider['profile_image_url'],
            'provider_rating': provider['rating'],
          }
        });
      }).toList();
    } catch (e) {
      print('Error loading flash deals: $e');
      return [];
    }
  }

  // Get combined flash deals (services + products with discounts)
  Future<List<FlashDealItem>> getCombinedFlashDeals() async {
    try {
      final List<FlashDealItem> allDeals = [];
      final productRepo = ProductRepository();

      // Obtener servicios con descuento
      final services = await getFlashDeals();
      allDeals.addAll(services.map((s) => FlashDealItem.fromService(s)));

      // Obtener productos en oferta
      final products = await productRepo.getOnSaleProducts();
      allDeals.addAll(products.map((p) => FlashDealItem.fromProduct(p)));

      // Mezclar y limitar a 10 items
      allDeals.shuffle();
      return allDeals.take(10).toList();
    } catch (e) {
      print('Error loading combined flash deals: $e');
      return [];
    }
  }

  // Get recommended services (highest rated in user's preferred categories)
  Future<List<ServiceModel>> getRecommendedServices() async {
    try {
      final response = await SupabaseConfig.client
          .from('services')
          .select('''
          *,
          providers:provider_id (
            id,
            business_name,
            profile_image_url,
            rating
          )
        ''')
          .eq('is_active', true)
          .gte('rating', 4.5)
          .order('rating', ascending: false)
          .order('reviews', ascending: false)
          .limit(8);

      return (response as List).map((json) {
        final provider = json['providers'];
        return ServiceModel.fromJson({
          ...json,
          if (provider != null) ...{
            'provider_name': provider['business_name'],
            'provider_image_url': provider['profile_image_url'],
            'provider_rating': provider['rating'],
          }
        });
      }).toList();
    } catch (e) {
      print('Error loading recommended services: $e');
      return [];
    }
  }

  // Get all available days
  List<String> getAllAvailableDays() {
    return [
      'Todos',
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo'
    ];
  }

  // Get service categories from Supabase
  Future<List<CategoryModel>> getServiceCategories() async {
    try {
      final response = await SupabaseConfig.client
          .from('categories')
          .select()
          .eq('is_active', true)
          .order('name', ascending: true);

      return (response as List)
          .map((json) => CategoryModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error loading categories: $e');
      return [];
    }
  }
}
