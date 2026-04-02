import 'package:fixy_home_service/models/service_model.dart';
import 'package:fixy_home_service/models/category_model.dart';
import 'package:fixy_home_service/models/user_model.dart';
import 'package:fixy_home_service/models/provider_model.dart';
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
      print('>>> QUERY: categories table, is_active=true');
      final response = await SupabaseConfig.client
          .from('categories')
          .select()
          .eq('is_active', true)
          .order('name', ascending: true);

      print('>>> RESPONSE: ${response.length} rows');
      if (response.isNotEmpty) {
        print('>>> FIRST ROW: ${response.first}');
      }

      return (response as List)
          .map((json) => CategoryModel.fromJson(json))
          .toList();
    } catch (e, stackTrace) {
      print('>>> ERROR loading categories: $e');
      print('>>> STACK: $stackTrace');
      return [];
    }
  }

  // Get all service categories (including inactive) for admin
  Future<List<CategoryModel>> getAllServiceCategories() async {
    try {
      final response = await SupabaseConfig.client
          .from('categories')
          .select()
          .order('name', ascending: true);

      return (response as List)
          .map((json) => CategoryModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error loading all categories: $e');
      return [];
    }
  }

  // Create service category
  Future<CategoryModel?> createServiceCategory(CategoryModel category) async {
    try {
      final response = await SupabaseConfig.client
          .from('categories')
          .insert({
            'name': category.name,
            'image_url': category.imageUrl,
            'price': category.price,
            'currency': category.currency,
            'time_unit': category.timeUnit,
            'is_active': category.isActive,
          })
          .select()
          .single();

      return CategoryModel.fromJson(response);
    } catch (e) {
      print('Error creating category: $e');
      return null;
    }
  }

  // Update service category
  Future<CategoryModel?> updateServiceCategory(CategoryModel category) async {
    try {
      final response = await SupabaseConfig.client
          .from('categories')
          .update({
            'name': category.name,
            'image_url': category.imageUrl,
            'price': category.price,
            'currency': category.currency,
            'time_unit': category.timeUnit,
            'is_active': category.isActive,
          })
          .eq('id', category.id)
          .select()
          .single();

      return CategoryModel.fromJson(response);
    } catch (e) {
      print('Error updating category: $e');
      return null;
    }
  }

  // Delete service category
  Future<bool> deleteServiceCategory(String id) async {
    try {
      await SupabaseConfig.client.from('categories').delete().eq('id', id);
      return true;
    } catch (e) {
      print('Error deleting category: $e');
      return false;
    }
  }

  // ==================== PROVIDER MANAGEMENT ====================

  /// Get all providers with optional status filter
  Future<List<ProviderModel>> getProviders({ProviderStatus? status}) async {
    try {
      var query = SupabaseConfig.client.from('providers').select();

      if (status != null) {
        query = query.eq('status', status.name);
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map((json) => ProviderModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching providers: $e');
      return [];
    }
  }

  /// Get pending providers (for admin approval)
  Future<List<ProviderModel>> getPendingProviders() async {
    return getProviders(status: ProviderStatus.pending);
  }

  /// Get provider by ID
  Future<ProviderModel?> getProviderById(String id) async {
    try {
      final response = await SupabaseConfig.client
          .from('providers')
          .select()
          .eq('id', id)
          .single();

      return ProviderModel.fromJson(response);
    } catch (e) {
      print('Error fetching provider: $e');
      return null;
    }
  }

  /// Update provider status (approve/reject/suspend)
  Future<bool> updateProviderStatus(
      String providerId, ProviderStatus newStatus) async {
    try {
      await SupabaseConfig.client
          .from('providers')
          .update({'status': newStatus.name}).eq('id', providerId);

      print('✅ Provider $providerId status updated to ${newStatus.name}');
      return true;
    } catch (e) {
      print('Error updating provider status: $e');
      return false;
    }
  }

  /// Approve provider (convenience method)
  Future<bool> approveProvider(String providerId) async {
    return updateProviderStatus(providerId, ProviderStatus.active);
  }

  /// Reject/Suspend provider (convenience method)
  Future<bool> rejectProvider(String providerId) async {
    return updateProviderStatus(providerId, ProviderStatus.inactive);
  }

  /// Get only active providers (for client search)
  Future<List<ProviderModel>> getActiveProviders() async {
    return getProviders(status: ProviderStatus.active);
  }
}
