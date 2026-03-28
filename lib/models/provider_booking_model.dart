enum ProviderBookingStatus {
  newBooking,
  accepted,
  rejected,
  completed,
  cancelled,
}

class ProviderBookingModel {
  final String id;
  final String providerId;
  final String reservationId;
  final ProviderBookingStatus status;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;
  final String? rejectionReason;
  final String? providerNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProviderBookingModel({
    required this.id,
    required this.providerId,
    required this.reservationId,
    required this.status,
    this.acceptedAt,
    this.rejectedAt,
    this.rejectionReason,
    this.providerNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProviderBookingModel.fromJson(Map<String, dynamic> json) {
    String status = json['status'] ?? 'newBooking';
    // Mapear 'new' a 'newBooking'
    if (status == 'new') status = 'newBooking';

    return ProviderBookingModel(
      id: json['id'],
      providerId: json['provider_id'],
      reservationId: json['reservation_id'],
      status: ProviderBookingStatus.values.byName(status),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'])
          : null,
      rejectedAt: json['rejected_at'] != null
          ? DateTime.parse(json['rejected_at'])
          : null,
      rejectionReason: json['rejection_reason'],
      providerNotes: json['provider_notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    // Convertir 'newBooking' a 'new' para la base de datos
    String statusName =
        status == ProviderBookingStatus.newBooking ? 'new' : status.name;

    return {
      'id': id,
      'provider_id': providerId,
      'reservation_id': reservationId,
      'status': statusName,
      'accepted_at': acceptedAt?.toIso8601String(),
      'rejected_at': rejectedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
      'provider_notes': providerNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get statusLabel {
    switch (status) {
      case ProviderBookingStatus.newBooking:
        return 'Nueva';
      case ProviderBookingStatus.accepted:
        return 'Aceptada';
      case ProviderBookingStatus.rejected:
        return 'Rechazada';
      case ProviderBookingStatus.completed:
        return 'Completada';
      case ProviderBookingStatus.cancelled:
        return 'Cancelada';
    }
  }

  ProviderBookingModel copyWith({
    String? id,
    String? providerId,
    String? reservationId,
    ProviderBookingStatus? status,
    DateTime? acceptedAt,
    DateTime? rejectedAt,
    String? rejectionReason,
    String? providerNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProviderBookingModel(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      reservationId: reservationId ?? this.reservationId,
      status: status ?? this.status,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      providerNotes: providerNotes ?? this.providerNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
