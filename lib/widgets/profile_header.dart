import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fixy_home_service/models/user_model.dart';
import 'package:fixy_home_service/theme/app_theme.dart';

class ProfileHeader extends StatelessWidget {
  final UserModel user;
  final VoidCallback onNotificationTap;
  final VoidCallback onProfileTap;

  const ProfileHeader({
    Key? key,
    required this.user,
    required this.onNotificationTap,
    required this.onProfileTap,
  }) : super(key: key);

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) {
      return 'Buenos días';
    } else if (hour >= 12 && hour < 20) {
      return 'Buenas tardes';
    } else {
      return 'Buenas noches';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Profile avatar
          GestureDetector(
            onTap: onProfileTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  user.avatarUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.person,
                          size: 24, color: Colors.grey),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: AppTheme.textTheme.bodySmall,
                ),
                Text(
                  user.name,
                  style: AppTheme.textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Notification bell
          Stack(
            children: [
              IconButton(
                icon: SvgPicture.asset(
                  'assets/images/notificaciones.svg',
                  width: 28,
                  height: 28,
                  colorFilter: ColorFilter.mode(
                    AppTheme.textPrimary,
                    BlendMode.srcIn,
                  ),
                ),
                onPressed: onNotificationTap,
              ),
              if (user.hasNotifications)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppTheme.notificationColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
