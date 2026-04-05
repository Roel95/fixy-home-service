import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fixy_home_service/theme/app_theme.dart';
import 'package:fixy_home_service/screens/auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();

  late AnimationController _textAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Selecciona',
      titleBold: 'un especialista',
      description:
          '¡En sólo un minuto tendrás tu propio maestro! Disfruta de los más de 10 servicios que tenemos para ti',
      imagePath: 'assets/images/especialista.png',
      backgroundColor: const Color(0xFF00D4AA),
      useAsset: true,
    ),
    OnboardingPage(
      title: 'IA que',
      titleBold: 'diagnostica problemas',
      description:
          'Sube una foto y nuestra IA te dirá qué problema tienes y cuál es la mejor solución',
      imagePath: '',
      backgroundColor: const Color(0xFF6C63FF),
      useAsset: false,
      icon: Icons.psychology_outlined,
    ),
    OnboardingPage(
      title: 'Agenda y paga',
      titleBold: 'de forma segura',
      description:
          'Reserva en segundos. Todos nuestros especialistas están verificados y el pago es 100% seguro',
      imagePath: '',
      backgroundColor: AppTheme.primaryColor,
      useAsset: false,
      icon: Icons.verified_user_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _textAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _textAnimationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _textAnimationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    _textAnimationController.reset();
    _textAnimationController.forward();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) {
      // Mantener AuthWrapper en el stack para que escuche el estado de autenticación
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        itemCount: _pages.length,
        itemBuilder: (context, index) {
          return OnboardingPageWidget(
            page: _pages[index],
            isLastPage: index == _pages.length - 1,
            pageIndex: index,
            totalPages: _pages.length,
            fadeAnimation: _fadeAnimation,
            slideAnimation: _slideAnimation,
            onNext: () {
              if (index < _pages.length - 1) {
                _pageController.animateToPage(
                  index + 1,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOutCubic,
                );
              } else {
                _completeOnboarding();
              }
            },
            onSkip: _completeOnboarding,
          );
        },
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String titleBold;
  final String description;
  final String imagePath;
  final Color backgroundColor;
  final bool useAsset;
  final IconData? icon;

  OnboardingPage({
    required this.title,
    required this.titleBold,
    required this.description,
    required this.imagePath,
    required this.backgroundColor,
    this.useAsset = true,
    this.icon,
  });
}

class _DotPattern extends StatelessWidget {
  final Color color;

  const _DotPattern({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(120, 120),
      painter: _DotPatternPainter(color: color),
    );
  }
}

class _DotPatternPainter extends CustomPainter {
  final Color color;

  _DotPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    const dotSize = 3.0;
    const spacing = 10.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotSize / 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class OnboardingPageWidget extends StatefulWidget {
  final OnboardingPage page;
  final bool isLastPage;
  final int pageIndex;
  final int totalPages;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const OnboardingPageWidget({
    super.key,
    required this.page,
    required this.isLastPage,
    required this.pageIndex,
    required this.totalPages,
    required this.fadeAnimation,
    required this.slideAnimation,
    required this.onNext,
    required this.onSkip,
  });

  @override
  State<OnboardingPageWidget> createState() => _OnboardingPageWidgetState();
}

class _OnboardingPageWidgetState extends State<OnboardingPageWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topHeight = screenHeight * 0.58;

    return Stack(
      children: [
        // Top section with background color and image/icon
        Container(
          height: topHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.page.backgroundColor,
          ),
          child: Stack(
            children: [
              // Dot pattern decoration (top right - larger)
              Positioned(
                top: 24,
                right: 12,
                child: const _DotPattern(color: Colors.white),
              ),
              // Dot pattern decoration (middle left - smaller)
              Positioned(
                top: 200,
                left: 28,
                child: Transform.scale(
                  scale: 0.5,
                  child: const _DotPattern(color: Colors.white),
                ),
              ),
              // Main content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      // Page indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          widget.totalPages,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: index == widget.pageIndex ? 32 : 8,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: index == widget.pageIndex
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: widget.page.useAsset &&
                                  widget.page.imagePath.isNotEmpty
                              ? FadeTransition(
                                  opacity: widget.fadeAnimation,
                                  child: Image.asset(
                                    widget.page.imagePath,
                                    fit: BoxFit.cover,
                                    height: double.infinity,
                                    width: double.infinity,
                                  ),
                                )
                              : widget.page.icon != null
                                  ? FadeTransition(
                                      opacity: widget.fadeAnimation,
                                      child: Container(
                                        width: 240,
                                        height: 240,
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          widget.page.icon,
                                          size: 140,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Floating white card overlapping the colored section
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          top: topHeight - 60,
          child: FadeTransition(
            opacity: widget.fadeAnimation,
            child: SlideTransition(
              position: widget.slideAnimation,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(87),
                    topRight: Radius.circular(87),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
                  child: Column(
                    children: [
                      // Title
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                            height: 1.3,
                            fontFamily: 'Gilroy',
                          ),
                          children: [
                            TextSpan(
                              text: widget.page.title,
                              style: const TextStyle(
                                color: Color(0xFF007AFF),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            TextSpan(
                              text: ' ${widget.page.titleBold}',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Description
                      Text(
                        widget.page.description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          height: 1.6,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const Spacer(),
                      // Button
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: GestureDetector(
                          onTapDown: (_) => _scaleController.forward(),
                          onTapUp: (_) {
                            _scaleController.reverse();
                            widget.onNext();
                          },
                          onTapCancel: () => _scaleController.reverse(),
                          child: Container(
                            width: 220,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF007AFF),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF007AFF)
                                      .withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Text(
                              widget.isLastPage ? 'Empezar' : 'Siguiente',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontFamily: 'Gilroy',
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
