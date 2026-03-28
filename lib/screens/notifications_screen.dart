import 'package:flutter/material.dart';
import 'package:fixy_home_service/models/notification_model.dart';
import 'package:fixy_home_service/services/notification_service.dart';
import 'package:fixy_home_service/supabase/supabase_config.dart';
import 'package:fixy_home_service/theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _showUnreadOnly = false;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final userId = SupabaseConfig.currentUserId;
    debugPrint('🔔 [NOTIFICATIONS] Loading notifications for user: $userId');

    if (userId == null) {
      debugPrint('❌ [NOTIFICATIONS] No authenticated user');
      setState(() {
        _error = 'Usuario no autenticado';
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      debugPrint(
          '🔔 [NOTIFICATIONS] Fetching from Supabase... (unread only: $_showUnreadOnly)');
      final data = _showUnreadOnly
          ? await NotificationService.getUnreadNotifications(userId)
          : await NotificationService.getUserNotifications(userId);

      debugPrint('🔔 [NOTIFICATIONS] Received ${data.length} notifications');

      setState(() {
        _notifications = data;
        _isLoading = false;
      });

      debugPrint(
          '✅ [NOTIFICATIONS] Loaded ${_notifications.length} notifications successfully');
    } catch (e) {
      debugPrint('❌ [NOTIFICATIONS] Error loading notifications: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _toggleFilter() {
    setState(() {
      _showUnreadOnly = !_showUnreadOnly;
    });
    _loadNotifications();
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    try {
      await NotificationService.markAsRead(notification.id);
      setState(() {
        _notifications = _notifications.map((n) {
          if (n.id == notification.id) {
            return n.copyWith(isRead: true);
          }
          return n;
        }).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al marcar como leída: $e')),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) return;

    try {
      await NotificationService.markAllAsRead(userId);
      setState(() {
        _notifications =
            _notifications.map((n) => n.copyWith(isRead: true)).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al marcar todas como leídas: $e')),
        );
      }
    }
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    try {
      await NotificationService.deleteNotification(notification.id);
      setState(() {
        _notifications.removeWhere((n) => n.id == notification.id);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar notificación: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Notificaciones',
            style: AppTheme.textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Notificaciones',
            style: AppTheme.textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                'Error al cargar notificaciones',
                style: AppTheme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _error!,
                  style: AppTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadNotifications,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notificaciones',
          style: AppTheme.textTheme.titleLarge?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Marcar todo',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppTheme.textPrimary),
            onSelected: (value) {
              if (value == 'filter') {
                _toggleFilter();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'filter',
                child: Row(
                  children: [
                    Icon(
                      _showUnreadOnly
                          ? Icons.filter_list_off
                          : Icons.filter_list,
                      size: 20,
                      color: AppTheme.textPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(_showUnreadOnly ? 'Mostrar todas' : 'Solo no leídas'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _notifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return _NotificationItem(
                  notification: notification,
                  onTap: () => _markAsRead(notification),
                  onDelete: () => _deleteNotification(notification),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none,
              size: 50,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _showUnreadOnly
                ? 'No tienes notificaciones nuevas'
                : 'No hay notificaciones',
            style: AppTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cuando tengas notificaciones, aparecerán aquí',
            style: AppTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationItem({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead
                ? Colors.white
                : AppTheme.primaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notification.isRead
                  ? Colors.grey.shade200
                  : AppTheme.primaryColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: notification.getIconColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  notification.getIcon(),
                  color: notification.getIconColor(),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTheme.textTheme.titleSmall?.copyWith(
                              fontWeight: notification.isRead
                                  ? FontWeight.w600
                                  : FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: AppTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notification.getTimeAgo(),
                      style: AppTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
