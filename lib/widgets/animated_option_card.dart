import 'package:flutter/material.dart';
import 'package:fixy_home_service/theme/app_theme.dart';

class AnimatedOptionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<OptionItem> options;
  final bool initiallyExpanded;

  const AnimatedOptionCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.options,
    this.initiallyExpanded = false,
  }) : super(key: key);

  @override
  State<AnimatedOptionCard> createState() => _AnimatedOptionCardState();
}

class _AnimatedOptionCardState extends State<AnimatedOptionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _iconRotationAnimation;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _iconRotationAnimation = Tween(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main option header - always visible
          InkWell(
            onTap: _toggleExpand,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon container
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.icon,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Title and subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: AppTheme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          style: AppTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Animated rotation arrow icon
                  RotationTransition(
                    turns: _iconRotationAnimation,
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expandable options
          ClipRect(
            child: SizeTransition(
              sizeFactor: _expandAnimation,
              child: Column(
                children: [
                  const Divider(height: 1),
                  ...widget.options
                      .map((option) => _buildOptionItem(option))
                      .toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionItem(OptionItem option) {
    return InkWell(
      onTap: option.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Icon(
              option.icon,
              color: option.highlighted
                  ? AppTheme.primaryColor
                  : AppTheme.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Text(
                option.title,
                style: AppTheme.textTheme.bodyMedium?.copyWith(
                  color: option.highlighted
                      ? AppTheme.primaryColor
                      : AppTheme.textPrimary,
                  fontWeight:
                      option.highlighted ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (option.badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: option.badgeColor?.withOpacity(0.1) ??
                      Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  option.badge!,
                  style: AppTheme.textTheme.bodySmall?.copyWith(
                    color: option.badgeColor ?? Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.textLight,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

class OptionItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool highlighted;
  final String? badge;
  final Color? badgeColor;

  const OptionItem({
    required this.title,
    required this.icon,
    required this.onTap,
    this.highlighted = false,
    this.badge,
    this.badgeColor,
  });
}
