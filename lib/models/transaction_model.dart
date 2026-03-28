enum TransactionType {
  earning,
  withdrawal,
  refund,
  commission,
}

enum TransactionStatus {
  pending,
  completed,
  failed,
  cancelled,
}

class TransactionModel {
  final String id;
  final String providerId;
  final String? reservationId;
  final TransactionType type;
  final double amount;
  final String currency;
  final String description;
  final TransactionStatus status;
  final double balanceAfter;
  final DateTime createdAt;
  final DateTime updatedAt;

  TransactionModel({
    required this.id,
    required this.providerId,
    this.reservationId,
    required this.type,
    required this.amount,
    this.currency = 'S/',
    required this.description,
    this.status = TransactionStatus.completed,
    required this.balanceAfter,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      providerId: json['provider_id'],
      reservationId: json['reservation_id'],
      type: TransactionType.values.byName(json['type']),
      amount: (json['amount']).toDouble(),
      currency: json['currency'] ?? 'S/',
      description: json['description'],
      status: TransactionStatus.values.byName(json['status'] ?? 'completed'),
      balanceAfter: (json['balance_after']).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider_id': providerId,
      'reservation_id': reservationId,
      'type': type.name,
      'amount': amount,
      'currency': currency,
      'description': description,
      'status': status.name,
      'balance_after': balanceAfter,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get typeLabel {
    switch (type) {
      case TransactionType.earning:
        return 'Ganancia';
      case TransactionType.withdrawal:
        return 'Retiro';
      case TransactionType.refund:
        return 'Reembolso';
      case TransactionType.commission:
        return 'Comisión';
    }
  }

  String get statusLabel {
    switch (status) {
      case TransactionStatus.pending:
        return 'Pendiente';
      case TransactionStatus.completed:
        return 'Completado';
      case TransactionStatus.failed:
        return 'Fallido';
      case TransactionStatus.cancelled:
        return 'Cancelado';
    }
  }
}
