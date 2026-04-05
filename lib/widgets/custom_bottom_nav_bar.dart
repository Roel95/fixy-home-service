import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fixy_home_service/theme/app_theme.dart';
import 'package:lottie/lottie.dart';

class CustomBottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback? onAITap;

  const CustomBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    this.onAITap,
  }) : super(key: key);

  @override
  State<CustomBottomNav> createState() => _CustomBottomNavState();
}

class _CustomBottomNavState extends State<CustomBottomNav>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onAIButtonPressed() {
    setState(() => _isPressed = true);
    _animationController.forward().then((_) {
      widget.onAITap?.call();
      _animationController.reverse();
      setState(() => _isPressed = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, 'assets/images/casa_relleno-06.svg', 'Home',
              widget.currentIndex),
          _buildNavItem(
              1, 'assets/images/carrito.svg', 'Tienda', widget.currentIndex),
          _buildNavItemWithBadge(
              2, 'assets/images/reservas.svg', 'Reservas', widget.currentIndex,
              showBadge: false),
          _buildNavItem(3, 'assets/images/perfil_relleno-06.svg', 'Perfil',
              widget.currentIndex),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      int index, String svgPath, String label, int currentIdx) {
    final isSelected = currentIdx == index;
    return Flexible(
      child: InkWell(
        onTap: () => widget.onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Hero(
              tag: 'tab_icon_$index',
              child: SvgPicture.asset(
                svgPath,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  isSelected ? AppTheme.primaryColor : AppTheme.textLight,
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textLight,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItemWithBadge(
      int index, String svgPath, String label, int currentIdx,
      {bool showBadge = false}) {
    final isSelected = currentIdx == index;
    return Flexible(
      child: InkWell(
        onTap: () => widget.onTap(index),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Hero(
                  tag: 'tab_icon_$index',
                  child: SvgPicture.asset(
                    svgPath,
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      isSelected ? AppTheme.primaryColor : AppTheme.textLight,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color:
                        isSelected ? AppTheme.primaryColor : AppTheme.textLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
            if (showBadge)
              Positioned(
                top: 8,
                right: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAICenterButton() {
    return Flexible(
      child: GestureDetector(
        onTap: _onAIButtonPressed,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: _isPressed ? 0.85 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF4FC3F7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF667EEA).withValues(alpha: 0.3),
                        blurRadius: _isPressed ? 16 : 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Lottie.asset(
                          'assets/documents/AI_logo_Foriday.json',
                          width: 36,
                          height: 36,
                          fit: BoxFit.contain,
                          repeat: true,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.mic,
                            color: Color(0xFF667EEA),
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'IA',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _isPressed
                      ? const Color(0xFF4FC3F7)
                      : const Color(0xFF667EEA),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
