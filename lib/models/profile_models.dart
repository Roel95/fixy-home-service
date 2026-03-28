import 'package:flutter/material.dart';

// Extended user profile model
class UserProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String avatarUrl;
  final String address;
  final String city;
  final String postalCode;
  final bool hasNotifications;
  final List<PaymentMethod> paymentMethods;
  final UserPreferences preferences;
  final String referralCode;
  final int rewardPoints;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    required this.address,
    required this.city,
    required this.postalCode,
    this.hasNotifications = false,
    required this.paymentMethods,
    required this.preferences,
    required this.referralCode,
    required this.rewardPoints,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    String? address,
    String? city,
    String? postalCode,
    bool? hasNotifications,
    List<PaymentMethod>? paymentMethods,
    UserPreferences? preferences,
    String? referralCode,
    int? rewardPoints,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      address: address ?? this.address,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      hasNotifications: hasNotifications ?? this.hasNotifications,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      preferences: preferences ?? this.preferences,
      referralCode: referralCode ?? this.referralCode,
      rewardPoints: rewardPoints ?? this.rewardPoints,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString() ??
          'https://ui-avatars.com/api/?name=${json['name']?.toString() ?? 'User'}',
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? 'Lima',
      postalCode: json['postal_code']?.toString() ?? '',
      hasNotifications: json['has_notifications'] ?? false,
      paymentMethods: (json['paymentMethods'] as List<dynamic>?)
              ?.map((e) => PaymentMethod.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      preferences: json['preferences'] != null
          ? UserPreferences.fromJson(
              json['preferences'] as Map<String, dynamic>)
          : UserPreferences(),
      referralCode: json['referral_code']?.toString() ?? '',
      rewardPoints: (json['reward_points'] is int) ? json['reward_points'] : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'address': address,
      'city': city,
      'postalCode': postalCode,
      'hasNotifications': hasNotifications,
      'paymentMethods': paymentMethods.map((e) => e.toJson()).toList(),
      'preferences': preferences.toJson(),
      'referralCode': referralCode,
      'rewardPoints': rewardPoints,
    };
  }

  factory UserProfile.mockProfile() {
    return UserProfile(
      id: '1',
      name: 'Mary Cruz',
      email: 'mary.cruz@example.com',
      phone: '+51 987 654 321',
      avatarUrl: 'https://randomuser.me/api/portraits/women/32.jpg',
      address: 'Av. Javier Prado 1640',
      city: 'Lima',
      postalCode: '15046',
      hasNotifications: true,
      paymentMethods: [
        PaymentMethod(
          id: '1',
          type: PaymentMethodType.creditCard,
          cardNumber: '**** **** **** 4581',
          cardHolderName: 'Mary Cruz',
          expiryDate: '12/25',
          isDefault: true,
        ),
        PaymentMethod(
          id: '2',
          type: PaymentMethodType.paymentApp,
          appName: 'Yape',
          accountNumber: 'mary.cruz@yape',
          isDefault: false,
        ),
      ],
      preferences: UserPreferences(
        pushNotifications: true,
        emailNotifications: true,
        language: 'Español',
        region: 'Perú',
        isDarkMode: false,
      ),
      referralCode: 'MARYC21',
      rewardPoints: 350,
    );
  }
}

enum PaymentMethodType { creditCard, debitCard, paymentApp, bankTransfer }

class PaymentMethod {
  final String id;
  final PaymentMethodType type;
  final String? cardNumber;
  final String? cardHolderName;
  final String? expiryDate;
  final String? appName;
  final String? accountNumber;
  final bool isDefault;

  PaymentMethod({
    required this.id,
    required this.type,
    this.cardNumber,
    this.cardHolderName,
    this.expiryDate,
    this.appName,
    this.accountNumber,
    this.isDefault = false,
  });

  PaymentMethod copyWith({
    String? id,
    PaymentMethodType? type,
    String? cardNumber,
    String? cardHolderName,
    String? expiryDate,
    String? appName,
    String? accountNumber,
    bool? isDefault,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      type: type ?? this.type,
      cardNumber: cardNumber ?? this.cardNumber,
      cardHolderName: cardHolderName ?? this.cardHolderName,
      expiryDate: expiryDate ?? this.expiryDate,
      appName: appName ?? this.appName,
      accountNumber: accountNumber ?? this.accountNumber,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] ?? 'creditCard';
    PaymentMethodType paymentType;
    try {
      paymentType = PaymentMethodType.values.byName(typeStr);
    } catch (e) {
      paymentType = PaymentMethodType.creditCard;
    }
    return PaymentMethod(
      id: json['id']?.toString() ?? '',
      type: paymentType,
      cardNumber: json['card_number'] ?? json['cardNumber'],
      cardHolderName: json['card_holder'] ?? json['cardHolderName'],
      expiryDate: json['expiry_date'] ?? json['expiryDate'],
      appName: json['app_name'] ?? json['appName'],
      accountNumber: json['account_number'] ?? json['accountNumber'],
      isDefault: json['is_default'] ?? json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'cardNumber': cardNumber,
      'cardHolderName': cardHolderName,
      'expiryDate': expiryDate,
      'appName': appName,
      'accountNumber': accountNumber,
      'isDefault': isDefault,
    };
  }

  IconData getIcon() {
    switch (type) {
      case PaymentMethodType.creditCard:
        return Icons.credit_card;
      case PaymentMethodType.debitCard:
        return Icons.credit_card;
      case PaymentMethodType.paymentApp:
        return Icons.account_balance_wallet;
      case PaymentMethodType.bankTransfer:
        return Icons.account_balance;
    }
  }

  String getDisplayName() {
    switch (type) {
      case PaymentMethodType.creditCard:
        return 'Tarjeta de Crédito';
      case PaymentMethodType.debitCard:
        return 'Tarjeta de Débito';
      case PaymentMethodType.paymentApp:
        return appName ?? 'App de Pago';
      case PaymentMethodType.bankTransfer:
        return 'Transferencia Bancaria';
    }
  }
}

class UserPreferences {
  final bool pushNotifications;
  final bool emailNotifications;
  final String language;
  final String region;
  final bool isDarkMode;

  UserPreferences({
    this.pushNotifications = true,
    this.emailNotifications = true,
    this.language = 'Español',
    this.region = 'Perú',
    this.isDarkMode = false,
  });

  UserPreferences copyWith({
    bool? pushNotifications,
    bool? emailNotifications,
    String? language,
    String? region,
    bool? isDarkMode,
  }) {
    return UserPreferences(
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      language: language ?? this.language,
      region: region ?? this.region,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      pushNotifications:
          json['push_notifications'] ?? json['pushNotifications'] ?? true,
      emailNotifications:
          json['email_notifications'] ?? json['emailNotifications'] ?? true,
      language: json['language'] ?? 'Español',
      region: json['region'] ?? 'Perú',
      isDarkMode: json['is_dark_mode'] ?? json['isDarkMode'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pushNotifications': pushNotifications,
      'emailNotifications': emailNotifications,
      'language': language,
      'region': region,
      'isDarkMode': isDarkMode,
    };
  }
}

enum ServiceStatus { pending, inProgress, completed, cancelled }

class ServiceHistory {
  final String id;
  final String serviceId;
  final String serviceName;
  final String serviceImageUrl;
  final DateTime date;
  final String time;
  final double amount;
  final String currency;
  final ServiceStatus status;
  final String professionalName;
  final String address;
  final bool isPaid;
  final String invoiceId;

  ServiceHistory({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.serviceImageUrl,
    required this.date,
    required this.time,
    required this.amount,
    required this.currency,
    required this.status,
    required this.professionalName,
    required this.address,
    required this.isPaid,
    required this.invoiceId,
  });

  ServiceHistory copyWith({
    String? id,
    String? serviceId,
    String? serviceName,
    String? serviceImageUrl,
    DateTime? date,
    String? time,
    double? amount,
    String? currency,
    ServiceStatus? status,
    String? professionalName,
    String? address,
    bool? isPaid,
    String? invoiceId,
  }) {
    return ServiceHistory(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      serviceImageUrl: serviceImageUrl ?? this.serviceImageUrl,
      date: date ?? this.date,
      time: time ?? this.time,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      professionalName: professionalName ?? this.professionalName,
      address: address ?? this.address,
      isPaid: isPaid ?? this.isPaid,
      invoiceId: invoiceId ?? this.invoiceId,
    );
  }

  factory ServiceHistory.fromJson(Map<String, dynamic> json) {
    return ServiceHistory(
      id: json['id'],
      serviceId: json['serviceId'],
      serviceName: json['serviceName'],
      serviceImageUrl: json['serviceImageUrl'],
      date: DateTime.parse(json['date']),
      time: json['time'],
      amount: json['amount'].toDouble(),
      currency: json['currency'],
      status: ServiceStatus.values.byName(json['status']),
      professionalName: json['professionalName'],
      address: json['address'],
      isPaid: json['isPaid'],
      invoiceId: json['invoiceId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'serviceImageUrl': serviceImageUrl,
      'date': date.toIso8601String(),
      'time': time,
      'amount': amount,
      'currency': currency,
      'status': status.name,
      'professionalName': professionalName,
      'address': address,
      'isPaid': isPaid,
      'invoiceId': invoiceId,
    };
  }

  Color getStatusColor() {
    switch (status) {
      case ServiceStatus.pending:
        return Colors.orange;
      case ServiceStatus.inProgress:
        return Colors.blue;
      case ServiceStatus.completed:
        return Colors.green;
      case ServiceStatus.cancelled:
        return Colors.red;
    }
  }

  String getStatusDisplayName() {
    switch (status) {
      case ServiceStatus.pending:
        return 'Pendiente';
      case ServiceStatus.inProgress:
        return 'En progreso';
      case ServiceStatus.completed:
        return 'Completado';
      case ServiceStatus.cancelled:
        return 'Cancelado';
    }
  }

  static List<ServiceHistory> generateMockHistory() {
    return [
      ServiceHistory(
        id: '1',
        serviceId: '101',
        serviceName: 'Limpieza del Hogar',
        serviceImageUrl:
            'https://images.unsplash.com/photo-1581578731548-c64695cc6952',
        date: DateTime.now().subtract(const Duration(days: 2)),
        time: '10:00 AM - 12:00 PM',
        amount: 60.0,
        currency: 'S/',
        status: ServiceStatus.completed,
        professionalName: 'Ana García',
        address: 'Av. Javier Prado 1640, Lima',
        isPaid: true,
        invoiceId: 'INV-2023-001',
      ),
      ServiceHistory(
        id: '2',
        serviceId: '102',
        serviceName: 'Remodela Tu Habitacion',
        serviceImageUrl:
            'https://images.unsplash.com/photo-1560440021-33f9b867899d',
        date: DateTime.now(),
        time: '14:00 PM - 18:00 PM',
        amount: 150.0,
        currency: 'S/',
        status: ServiceStatus.inProgress,
        professionalName: 'Carlos Mendez',
        address: 'Av. Javier Prado 1640, Lima',
        isPaid: true,
        invoiceId: 'INV-2023-002',
      ),
      ServiceHistory(
        id: '3',
        serviceId: '103',
        serviceName: 'Jardinería Profesional',
        serviceImageUrl:
            'https://images.unsplash.com/photo-1557429287-b2e26467fc2b',
        date: DateTime.now().add(const Duration(days: 3)),
        time: '09:00 AM - 11:00 AM',
        amount: 80.0,
        currency: 'S/',
        status: ServiceStatus.pending,
        professionalName: 'Roberto Sanchez',
        address: 'Av. Javier Prado 1640, Lima',
        isPaid: false,
        invoiceId: 'INV-2023-003',
      ),
      ServiceHistory(
        id: '4',
        serviceId: '104',
        serviceName: 'Pintura de Interiores',
        serviceImageUrl:
            'https://images.unsplash.com/photo-1562259929-17e9dd874ee3',
        date: DateTime.now().subtract(const Duration(days: 10)),
        time: '10:00 AM - 16:00 PM',
        amount: 200.0,
        currency: 'S/',
        status: ServiceStatus.cancelled,
        professionalName: 'Luisa Morales',
        address: 'Av. Javier Prado 1640, Lima',
        isPaid: false,
        invoiceId: '',
      ),
    ];
  }
}

class FAQ {
  final String id;
  final String question;
  final String answer;
  bool isExpanded;

  FAQ({
    required this.id,
    required this.question,
    required this.answer,
    this.isExpanded = false,
  });

  static List<FAQ> getMockFAQs() {
    return [
      FAQ(
          id: '1',
          question: '¿Cómo puedo cancelar un servicio?',
          answer:
              'Puedes cancelar un servicio programado con al menos 24 horas de anticipación sin cargos.'),
      FAQ(
          id: '2',
          question: '¿Cuáles son los métodos de pago disponibles?',
          answer:
              'Aceptamos tarjetas de crédito y débito, Yape, Plin y transferencias bancarias.'),
      FAQ(
          id: '3',
          question: '¿Cómo puedo solicitar un reembolso?',
          answer:
              'Puedes solicitar un reembolso dentro de las 48 horas posteriores a la finalización del servicio.'),
      FAQ(
          id: '4',
          question: '¿Cómo funciona el programa de referidos?',
          answer:
              'Por cada amigo que refieras recibirán S/25 en créditos ambos.'),
      FAQ(
          id: '5',
          question: '¿Los profesionales están asegurados?',
          answer:
              'Sí, todos nuestros profesionales están verificados y cuentan con seguros.'),
    ];
  }
}

class Reward {
  final String id;
  final String title;
  final String description;
  final int pointsCost;
  final String imageUrl;
  final DateTime expiryDate;
  final bool isRedeemed;

  Reward({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    required this.imageUrl,
    required this.expiryDate,
    this.isRedeemed = false,
  });

  static List<Reward> getMockRewards() {
    return [
      Reward(
          id: '1',
          title: '25% de descuento',
          description: 'Obtén un 25% de descuento en tu próximo servicio',
          pointsCost: 250,
          imageUrl:
              'https://images.unsplash.com/photo-1581578731548-c64695cc6952',
          expiryDate: DateTime.now().add(const Duration(days: 30))),
      Reward(
          id: '2',
          title: 'Hora extra gratis',
          description: 'Añade una hora extra gratis a cualquier servicio',
          pointsCost: 150,
          imageUrl: 'https://images.unsplash.com/photo-1562259929-17e9dd874ee3',
          expiryDate: DateTime.now().add(const Duration(days: 60))),
      Reward(
          id: '3',
          title: 'Servicio prioritario',
          description: 'Salta la cola y obtén un servicio prioritario',
          pointsCost: 100,
          imageUrl: 'https://images.unsplash.com/photo-1556911261-6bd341186b2f',
          expiryDate: DateTime.now().add(const Duration(days: 45)),
          isRedeemed: true),
    ];
  }
}
