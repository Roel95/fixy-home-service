import 'package:flutter/material.dart';
import 'package:fixy_home_service/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AITooltip extends StatefulWidget {
  final Widget child;

  const AITooltip({super.key, required this.child});

  @override
  State<AITooltip> createState() => _AITooltipState();
}

class _AITooltipState extends State<AITooltip>
    with SingleTickerProviderStateMixin {
  bool _showTooltip = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenTooltip = prefs.getBool('has_seen_ai_tooltip') ?? false;

    if (!hasSeenTooltip) {
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        setState(() => _showTooltip = true);
        _animationController.forward();

        // Auto-hide after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          _hideTooltip();
        });
      }
    }
  }

  Future<void> _hideTooltip() async {
    if (!mounted) return;

    await _animationController.reverse();
    setState(() => _showTooltip = false);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_ai_tooltip', true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (_showTooltip)
          Positioned(
            right: 0,
            bottom: -10,
            child: GestureDetector(
              onTap: _hideTooltip,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: Container(
                        width: 240,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF667EEA)
                                  .withValues(alpha: 0.5),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.tips_and_updates,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '💡 ¡Prueba el Asistente IA!',
                                    style:
                                        AppTheme.textTheme.bodyLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _hideTooltip,
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Describe tu problema y te ayudaremos a encontrar la solución perfecta',
                              style: AppTheme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.95),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
