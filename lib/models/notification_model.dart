import 'package:flutter/material.dart';

enum NotificationType {
  reservation,
  payment,
  promotion,
  system,
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final String? actionId;
  final String? imageUrl;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.actionId,
    this.imageUrl,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    String? actionId,
    String? imageUrl,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      actionId: actionId ?? this.actionId,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  IconData getIcon() {
    switch (type) {
      case NotificationType.reservation:
        return Icons.calendar_today;
      case NotificationType.payment:
        return Icons.payment;
      case NotificationType.promotion:
        return Icons.local_offer;
      case NotificationType.system:
        return Icons.info_outline;
    }
  }

  Color getIconColor() {
    switch (type) {
      case NotificationType.reservation:
        return Colors.blue;
      case NotificationType.payment:
        return Colors.green;
      case NotificationType.promotion:
        return Colors.orange;
      case NotificationType.system:
        return Colors.purple;
    }
  }

  String getTimeAgo() {
    final difference = DateTime.now().difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays}d';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'actionId': actionId,
      'imageUrl': imageUrl,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Support both camelCase and snake_case for Supabase compatibility
    final timestampValue = json['timestamp'] ?? json['created_at'];
    final isReadValue =
        json['isRead'] ?? json['is_read'] ?? json['read'] ?? false;
    final actionIdValue = json['actionId'] ?? json['action_id'];
    final imageUrlValue = json['imageUrl'] ?? json['image_url'];

    return NotificationModel(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => NotificationType.system,
      ),
      timestamp: timestampValue is String
          ? DateTime.parse(timestampValue)
          : DateTime.now(),
      isRead: isReadValue,
      actionId: actionIdValue,
      imageUrl: imageUrlValue,
    );
  }
}
