import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:fixy_home_service/data/service_repository.dart';
import 'package:fixy_home_service/data/banner_repository.dart';
import 'package:fixy_home_service/data/video_repository.dart';
import 'package:fixy_home_service/models/category_model.dart';
import 'package:fixy_home_service/models/service_model.dart';
import 'package:fixy_home_service/models/banner_model.dart';
import 'package:fixy_home_service/models/video_model.dart';
import 'package:fixy_home_service/providers/profile_provider.dart';
import 'package:fixy_home_service/services/user_service.dart';
import 'package:fixy_home_service/services/notification_service.dart';
import 'package:fixy_home_service/screens/search_screen.dart';
import 'package:fixy_home_service/screens/ai_chat_screen.dart';
import 'package:fixy_home_service/screens/service_detail_screen.dart';
import 'package:fixy_home_service/screens/service_reservation_screen.dart';
import 'package:fixy_home_service/screens/notifications_screen.dart';
import 'package:fixy_home_service/screens/profile/profile_screen.dart';
import 'package:fixy_home_service/screens/reels_screen.dart';
import 'package:fixy_home_service/theme/app_theme.dart';
import 'package:fixy_home_service/widgets/category_card.dart';
import 'package:fixy_home_service/widgets/section_header.dart';
import 'package:fixy_home_service/widgets/service_card.dart';
import 'package:fixy_home_service/widgets/banner_carousel.dart';
import 'package:fixy_home_service/widgets/video_reel_card.dart';
import 'package:fixy_home_service/widgets/unified_deal_card.dart';
import 'package:fixy_home_service/widgets/recommended_service_card.dart';
import 'package:fixy_home_service/models/flash_deal_item.dart';
import 'package:fixy_home_service/screens/shop/product_detail_screen.dart';
import 'package:fixy_home_service/utils/page_transitions.dart';
import 'package:fixy_home_service/supabase/supabase_config.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToProfile;

  const HomeScreen({Key? key, this.onNavigateToProfile}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final ServiceRepository _repository = ServiceRepository();
  final BannerRepository _bannerRepository = BannerRepository();
  final VideoRepository _videoRepository = VideoRepository();
  String _userName = '';
  int _unreadNotificationCount = 0;

  // Animation controller for staggered animations
  late AnimationController _animationController;

  // Futures for data
  late Future<List<ServiceModel>> _popularServicesFuture;
  late Future<List<CategoryModel>> _categoriesFuture;
  late Future<List<BannerModel>> _bannersFuture;
  late Future<List<VideoModel>> _trendingVideosFuture;
  late Future<List<FlashDealItem>> _flashDealsFuture;
  late Future<List<ServiceModel>> _recommendedServicesFuture;

  @override
  void initState() {
    super.initState();
    _loadUserName();

    // Load data
    _loadData();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animationController.forward();

    // Load unread notification count
    _loadUnreadNotificationCount();
  }

  void _loadData() {
    _popularServicesFuture = _repository.getPopularServices();
    _categoriesFuture = _repository.getServiceCategories();
    _bannersFuture = _bannerRepository.getActiveBanners();
    _trendingVideosFuture = _videoRepository.getTrendingVideos();
    _flashDealsFuture = _repository.getCombinedFlashDeals();
    _recommendedServicesFuture = _repository.getRecommendedServices();
  }

  Future<void> _loadUserName() async {
    try {
      final userProfile = await UserService.getCurrentUserProfile();
      if (mounted && userProfile != null) {
        setState(() {
          _userName = userProfile.name;
        });
      }
    } catch (e) {
      debugPrint('Error loading user name: $e');
      // Usar nombre predeterminado en caso de error
      if (mounted) {
        setState(() {
          _userName = 'Usuario';
        });
      }
    }
  }

  Future<void> _loadUnreadNotificationCount() async {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) return;

    try {
      final count = await NotificationService.getUnreadCount(userId);
      if (mounted) {
        setState(() {
          _unreadNotificationCount = count;
        });
      }
    } catch (e) {
      debugPrint('Error loading notification count: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8ECF3),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Hidden Hero for tab bar animation
              Hero(
                tag: 'tab_icon_0',
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 24,
                    height: 24,
                    color: Colors.transparent,
                  ),
                ),
              ),

              // Neumorphic Header
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _animationController.value,
                    child: child,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '¡Hola, ${_userName.isEmpty ? 'Usuario' : _userName}!',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2D3748),
                                letterSpacing: -0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '¿Qué servicio necesitas hoy?',
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color(0xFF2D3748)
                                    .withValues(alpha: 0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          // Neumorphic notification button
                          Stack(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8ECF3),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    const BoxShadow(
                                      color: Color(0xFFFFFFFF),
                                      offset: Offset(-4, -4),
                                      blurRadius: 8,
                                      spreadRadius: 0,
                                    ),
                                    BoxShadow(
                                      color: const Color(0xFF2D3748)
                                          .withValues(alpha: 0.15),
                                      offset: const Offset(4, 4),
                                      blurRadius: 8,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        SlideUpRoute(
                                            page: const NotificationsScreen()),
                                      );
                                      _loadUnreadNotificationCount();
                                    },
                                    child: Center(
                                      child: SvgPicture.asset(
                                        'assets/images/notificaciones.svg',
                                        width: 22,
                                        height: 22,
                                        colorFilter: const ColorFilter.mode(
                                          Color(0xFF667EEA),
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (_unreadNotificationCount > 0)
                                Positioned(
                                  right: 6,
                                  top: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF6B6B),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFF6B6B)
                                              .withValues(alpha: 0.4),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Text(
                                      _unreadNotificationCount > 9
                                          ? '9+'
                                          : '$_unreadNotificationCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          // Neumorphic avatar
                          Consumer<ProfileProvider>(
                            builder: (context, profileProvider, child) {
                              final avatarUrl =
                                  profileProvider.userProfile?.avatarUrl;
                              return GestureDetector(
                                onTap: () {
                                  if (widget.onNavigateToProfile != null) {
                                    widget.onNavigateToProfile!();
                                  } else {
                                    Navigator.push(
                                      context,
                                      SlideRightRoute(
                                          page: const ProfileScreen()),
                                    );
                                  }
                                },
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8ECF3),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      const BoxShadow(
                                        color: Color(0xFFFFFFFF),
                                        offset: Offset(-4, -4),
                                        blurRadius: 8,
                                        spreadRadius: 0,
                                      ),
                                      BoxShadow(
                                        color: const Color(0xFF2D3748)
                                            .withValues(alpha: 0.15),
                                        offset: const Offset(4, 4),
                                        blurRadius: 8,
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: avatarUrl != null &&
                                            avatarUrl.isNotEmpty
                                        ? Image.network(
                                            avatarUrl,
                                            fit: BoxFit.cover,
                                          )
                                        : Center(
                                            child: Text(
                                              _userName.isNotEmpty
                                                  ? _userName[0].toUpperCase()
                                                  : 'U',
                                              style: const TextStyle(
                                                color: Color(0xFF667EEA),
                                                fontWeight: FontWeight.w900,
                                                fontSize: 20,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Neumorphic AI Search Bar
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _animationController.value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - _animationController.value)),
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        SlideRightRoute(page: const AIChatScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8ECF3),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF2D3748).withValues(alpha: 0.1),
                            offset: const Offset(6, 6),
                            blurRadius: 12,
                            spreadRadius: 0,
                          ),
                          const BoxShadow(
                            color: Color(0xFFFFFFFF),
                            offset: Offset(-6, -6),
                            blurRadius: 12,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8ECF3),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                const BoxShadow(
                                  color: Color(0xFFFFFFFF),
                                  offset: Offset(-2, -2),
                                  blurRadius: 6,
                                  spreadRadius: 0,
                                ),
                                BoxShadow(
                                  color: const Color(0xFF2D3748)
                                      .withValues(alpha: 0.15),
                                  offset: const Offset(2, 2),
                                  blurRadius: 6,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              color: Color(0xFF667EEA),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Describe tu problema...',
                              style: TextStyle(
                                fontSize: 15,
                                color: const Color(0xFF2D3748)
                                    .withValues(alpha: 0.5),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.mic,
                            color:
                                const Color(0xFF2D3748).withValues(alpha: 0.4),
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Banners carousel (MOVED TO TOP)
              FutureBuilder<List<BannerModel>>(
                future: _bannersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 160,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _animationController.value,
                        child: Transform.translate(
                          offset:
                              Offset(0, 20 * (1 - _animationController.value)),
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: BannerCarousel(
                        banners: snapshot.data!,
                        onBannerTap: (banner) {
                          if (banner.route != null &&
                              banner.routeParams != null) {
                            Navigator.push(
                              context,
                              SlideFadeRoute(
                                page: SearchScreen(
                                  initialFilter:
                                      banner.routeParams?['category'],
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Trending Videos section (MOVED BELOW BANNERS)
              FutureBuilder<List<VideoModel>>(
                future: _trendingVideosFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 240,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final videos = snapshot.data!;

                  return AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _animationController.value,
                        child: Transform.translate(
                          offset:
                              Offset(0, 25 * (1 - _animationController.value)),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8ECF3),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    const BoxShadow(
                                      color: Color(0xFFFFFFFF),
                                      offset: Offset(-3, -3),
                                      blurRadius: 6,
                                      spreadRadius: 0,
                                    ),
                                    BoxShadow(
                                      color: const Color(0xFF2D3748)
                                          .withValues(alpha: 0.15),
                                      offset: const Offset(3, 3),
                                      blurRadius: 6,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.play_circle_fill,
                                  color: Color(0xFF667EEA),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Text(
                                'Tendencias y Tips',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2D3748),
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 220,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(left: 20),
                            scrollDirection: Axis.horizontal,
                            itemCount: videos.length,
                            itemBuilder: (context, index) {
                              return VideoReelCard(
                                video: videos[index],
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ReelsScreen(
                                        videos: videos,
                                        initialIndex: index,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Flash Deals section
              FutureBuilder<List<FlashDealItem>>(
                future: _flashDealsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 280,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final deals = snapshot.data!;

                  return AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _animationController.value,
                        child: Transform.translate(
                          offset:
                              Offset(0, 30 * (1 - _animationController.value)),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8ECF3),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    const BoxShadow(
                                      color: Color(0xFFFFFFFF),
                                      offset: Offset(-3, -3),
                                      blurRadius: 6,
                                      spreadRadius: 0,
                                    ),
                                    BoxShadow(
                                      color: const Color(0xFF2D3748)
                                          .withValues(alpha: 0.15),
                                      offset: const Offset(3, 3),
                                      blurRadius: 6,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.local_fire_department,
                                  color: Color(0xFFFF6B6B),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Text(
                                'Ofertas Flash',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2D3748),
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8ECF3),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2D3748)
                                          .withValues(alpha: 0.08),
                                      offset: const Offset(3, 3),
                                      blurRadius: 6,
                                      spreadRadius: 0,
                                    ),
                                    const BoxShadow(
                                      color: Color(0xFFFFFFFF),
                                      offset: Offset(-3, -3),
                                      blurRadius: 6,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: const [
                                    Icon(Icons.whatshot,
                                        size: 14, color: Color(0xFFFF6B6B)),
                                    SizedBox(width: 4),
                                    Text(
                                      '¡Por tiempo limitado!',
                                      style: TextStyle(
                                        color: Color(0xFFFF6B6B),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 280,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(left: 20),
                            scrollDirection: Axis.horizontal,
                            itemCount: deals.length,
                            itemBuilder: (context, index) {
                              final deal = deals[index];
                              return UnifiedDealCard(
                                deal: deal,
                                onTap: () {
                                  if (deal.type == FlashDealType.service) {
                                    Navigator.push(
                                      context,
                                      SlideRightRoute(
                                        page: ServiceDetailScreen(
                                          service: deal.service!,
                                        ),
                                      ),
                                    );
                                  } else {
                                    Navigator.push(
                                      context,
                                      SlideRightRoute(
                                        page: ProductDetailScreen(
                                          product: deal.product!,
                                        ),
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Recommended For You section
              FutureBuilder<List<ServiceModel>>(
                future: _recommendedServicesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 240,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final recommended = snapshot.data!;

                  return AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _animationController.value,
                        child: Transform.translate(
                          offset:
                              Offset(0, 32 * (1 - _animationController.value)),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8ECF3),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    const BoxShadow(
                                      color: Color(0xFFFFFFFF),
                                      offset: Offset(-3, -3),
                                      blurRadius: 6,
                                      spreadRadius: 0,
                                    ),
                                    BoxShadow(
                                      color: const Color(0xFF2D3748)
                                          .withValues(alpha: 0.15),
                                      offset: const Offset(3, 3),
                                      blurRadius: 6,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.auto_awesome,
                                  color: Color(0xFF667EEA),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Text(
                                'Recomendado Para Ti',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2D3748),
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 230,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(left: 20),
                            scrollDirection: Axis.horizontal,
                            itemCount: recommended.length,
                            itemBuilder: (context, index) {
                              return RecommendedServiceCard(
                                service: recommended[index],
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    SlideRightRoute(
                                      page: ServiceDetailScreen(
                                        service: recommended[index],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Popular services section
              FutureBuilder<List<ServiceModel>>(
                future: _popularServicesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 280,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _animationController.value,
                          child: Transform.translate(
                            offset: Offset(
                                0, 35 * (1 - _animationController.value)),
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'Servicios Populares',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: AppTheme.textSecondary
                                      .withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.home_repair_service_outlined,
                                  size: 48,
                                  color: AppTheme.textSecondary
                                      .withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No hay servicios disponibles',
                                  style:
                                      AppTheme.textTheme.titleMedium?.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Los servicios aparecerán aquí cuando estén disponibles',
                                  style:
                                      AppTheme.textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final services = snapshot.data!;

                  return AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _animationController.value,
                        child: Transform.translate(
                          offset:
                              Offset(0, 35 * (1 - _animationController.value)),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        SectionHeader(
                          title: 'Servicios Populares',
                          onViewMore: () {
                            Navigator.push(
                              context,
                              SlideFadeRoute(
                                page: const SearchScreen(
                                  initialFilter: 'popular',
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 260,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(left: 20),
                            scrollDirection: Axis.horizontal,
                            itemCount: services.length,
                            itemBuilder: (context, index) {
                              return ServiceCard(
                                service: services[index],
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    SlideRightRoute(
                                      page: ServiceDetailScreen(
                                        service: services[index],
                                      ),
                                    ),
                                  );
                                },
                                onReserve: () {
                                  Navigator.push(
                                    context,
                                    SlideUpRoute(
                                      page: ServiceReservationScreen(
                                        service: services[index],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Categories section
              FutureBuilder<List<CategoryModel>>(
                future: _categoriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 150,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final categories = snapshot.data!;

                  return AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _animationController.value,
                        child: Transform.translate(
                          offset:
                              Offset(0, 40 * (1 - _animationController.value)),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        SectionHeader(
                          title: 'Categorías',
                          onViewMore: () {
                            Navigator.push(
                              context,
                              SlideFadeRoute(
                                page: const SearchScreen(
                                  showCategoriesFirst: true,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 130,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(left: 20),
                            scrollDirection: Axis.horizontal,
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              return CategoryCard(
                                category: categories[index],
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    SlideFadeRoute(
                                      page: const SearchScreen(
                                        showCategoriesFirst: true,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
