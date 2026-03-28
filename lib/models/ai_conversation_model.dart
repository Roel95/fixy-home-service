class AIConversationMessage {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final List<dynamic>? visualOptions; // Products or services to display

  AIConversationMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.metadata,
    this.visualOptions,
  });

  factory AIConversationMessage.fromJson(Map<String, dynamic> json) =>
      AIConversationMessage(
        id: json['id'].toString(),
        role: json['role'] ?? '',
        content: json['content'] ?? '',
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'])
            : DateTime.now(),
        metadata: json['metadata'],
        visualOptions: json['visualOptions'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        if (metadata != null) 'metadata': metadata,
        if (visualOptions != null) 'visualOptions': visualOptions,
      };
}

class AIConversation {
  final String id;
  final String userId;
  final String title;
  final List<AIConversationMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  AIConversation({
    required this.id,
    required this.userId,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AIConversation.fromJson(Map<String, dynamic> json) => AIConversation(
        id: json['id'].toString(),
        userId: json['user_id'].toString(),
        title: json['title'] ?? 'Nueva conversación',
        messages: json['messages'] != null
            ? (json['messages'] as List)
                .map((m) => AIConversationMessage.fromJson(m))
                .toList()
            : [],
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : DateTime.now(),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'messages': messages.map((m) => m.toJson()).toList(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}
