class PaymentModel {
  final String id;
  final String serviceId;
  final double totalAmount;
  final double advanceAmount; // 30% of total
  final double remainingAmount; // 70% of total
  final bool advancePaid;
  final bool remainingPaid;
  final DateTime? advancePaymentDate;
  final DateTime? remainingPaymentDate;
  final String paymentMethod;
  final String paymentStatus; // 'not_paid', 'advance_paid', 'fully_paid'
  final String? transactionId; // ID de transacción de Culqi/Yape
  final String? chargeId; // ID del cargo de Culqi

  PaymentModel({
    required this.id,
    required this.serviceId,
    required this.totalAmount,
    required this.advanceAmount,
    required this.remainingAmount,
    this.advancePaid = false,
    this.remainingPaid = false,
    this.advancePaymentDate,
    this.remainingPaymentDate,
    this.paymentMethod = '',
    this.paymentStatus = 'not_paid',
    this.transactionId,
    this.chargeId,
  });

  factory PaymentModel.create({
    required String serviceId,
    required double totalAmount,
  }) {
    final advanceAmount = (totalAmount * 0.3).roundToDouble();
    final remainingAmount = totalAmount - advanceAmount;

    return PaymentModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      serviceId: serviceId,
      totalAmount: totalAmount,
      advanceAmount: advanceAmount,
      remainingAmount: remainingAmount,
    );
  }

  PaymentModel copyWith({
    String? id,
    String? serviceId,
    double? totalAmount,
    double? advanceAmount,
    double? remainingAmount,
    bool? advancePaid,
    bool? remainingPaid,
    DateTime? advancePaymentDate,
    DateTime? remainingPaymentDate,
    String? paymentMethod,
    String? paymentStatus,
    String? transactionId,
    String? chargeId,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      totalAmount: totalAmount ?? this.totalAmount,
      advanceAmount: advanceAmount ?? this.advanceAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      advancePaid: advancePaid ?? this.advancePaid,
      remainingPaid: remainingPaid ?? this.remainingPaid,
      advancePaymentDate: advancePaymentDate ?? this.advancePaymentDate,
      remainingPaymentDate: remainingPaymentDate ?? this.remainingPaymentDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      transactionId: transactionId ?? this.transactionId,
      chargeId: chargeId ?? this.chargeId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceId': serviceId,
      'totalAmount': totalAmount,
      'advanceAmount': advanceAmount,
      'remainingAmount': remainingAmount,
      'advancePaid': advancePaid,
      'remainingPaid': remainingPaid,
      'advancePaymentDate': advancePaymentDate?.toIso8601String(),
      'remainingPaymentDate': remainingPaymentDate?.toIso8601String(),
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'transactionId': transactionId,
      'chargeId': chargeId,
    };
  }

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'],
      serviceId: json['serviceId'],
      totalAmount: json['totalAmount'],
      advanceAmount: json['advanceAmount'],
      remainingAmount: json['remainingAmount'],
      advancePaid: json['advancePaid'] ?? false,
      remainingPaid: json['remainingPaid'] ?? false,
      advancePaymentDate: json['advancePaymentDate'] != null
          ? DateTime.parse(json['advancePaymentDate'])
          : null,
      remainingPaymentDate: json['remainingPaymentDate'] != null
          ? DateTime.parse(json['remainingPaymentDate'])
          : null,
      paymentMethod: json['paymentMethod'] ?? '',
      paymentStatus: json['paymentStatus'] ?? 'not_paid',
      transactionId: json['transactionId'],
      chargeId: json['chargeId'],
    );
  }
}
