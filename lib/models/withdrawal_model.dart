enum WithdrawalStatus {
  pending,
  processing,
  completed,
  rejected,
  cancelled,
}

class WithdrawalRequestModel {
  final String id;
  final String providerId;
  final double amount;
  final String currency;
  final String bankAccountNumber;
  final String bankName;
  final String accountHolderName;
  final WithdrawalStatus status;
  final DateTime requestedAt;
  final DateTime? processedAt;
  final String? processedBy;
  final String? rejectionReason;
  final String? transactionId;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  WithdrawalRequestModel({
    required this.id,
    required this.providerId,
    required this.amount,
    this.currency = 'S/',
    required this.bankAccountNumber,
    required this.bankName,
    required this.accountHolderName,
    this.status = WithdrawalStatus.pending,
    required this.requestedAt,
    this.processedAt,
    this.processedBy,
    this.rejectionReason,
    this.transactionId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WithdrawalRequestModel.fromJson(Map<String, dynamic> json) {
    return WithdrawalRequestModel(
      id: json['id'],
      providerId: json['provider_id'],
      amount: (json['amount']).toDouble(),
      currency: json['currency'] ?? 'S/',
      bankAccountNumber: json['bank_account_number'],
      bankName: json['bank_name'],
      accountHolderName: json['account_holder_name'],
      status: WithdrawalStatus.values.byName(json['status'] ?? 'pending'),
      requestedAt: DateTime.parse(json['requested_at']),
      processedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'])
          : null,
      processedBy: json['processed_by'],
      rejectionReason: json['rejection_reason'],
      transactionId: json['transaction_id'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider_id': providerId,
      'amount': amount,
      'currency': currency,
      'bank_account_number': bankAccountNumber,
      'bank_name': bankName,
      'account_holder_name': accountHolderName,
      'status': status.name,
      'requested_at': requestedAt.toIso8601String(),
      'processed_at': processedAt?.toIso8601String(),
      'processed_by': processedBy,
      'rejection_reason': rejectionReason,
      'transaction_id': transactionId,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get statusLabel {
    switch (status) {
      case WithdrawalStatus.pending:
        return 'Pendiente';
      case WithdrawalStatus.processing:
        return 'Procesando';
      case WithdrawalStatus.completed:
        return 'Completado';
      case WithdrawalStatus.rejected:
        return 'Rechazado';
      case WithdrawalStatus.cancelled:
        return 'Cancelado';
    }
  }

  WithdrawalRequestModel copyWith({
    String? id,
    String? providerId,
    double? amount,
    String? currency,
    String? bankAccountNumber,
    String? bankName,
    String? accountHolderName,
    WithdrawalStatus? status,
    DateTime? requestedAt,
    DateTime? processedAt,
    String? processedBy,
    String? rejectionReason,
    String? transactionId,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WithdrawalRequestModel(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankName: bankName ?? this.bankName,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      processedAt: processedAt ?? this.processedAt,
      processedBy: processedBy ?? this.processedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      transactionId: transactionId ?? this.transactionId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
