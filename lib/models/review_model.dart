class ReviewModel {
  final String id;
  final String providerId;
  final String userId;
  final String? reservationId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReviewModel({
    required this.id,
    required this.providerId,
    required this.userId,
    this.reservationId,
    required this.rating,
    this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'],
      providerId: json['provider_id'],
      userId: json['user_id'],
      reservationId: json['reservation_id'],
      rating: json['rating'],
      comment: json['comment'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider_id': providerId,
      'user_id': userId,
      'reservation_id': reservationId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ReviewModel copyWith({
    String? id,
    String? providerId,
    String? userId,
    String? reservationId,
    int? rating,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      userId: userId ?? this.userId,
      reservationId: reservationId ?? this.reservationId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
