class ProviderModel {
  final String id;
  final String userId;
  final String businessName;
  final String description;
  final String? profileImageUrl;
  final String phone;
  final String email;
  final String address;
  final String city;
  final String postalCode;
  final double rating;
  final int totalReviews;
  final int completedJobs;
  final List<String> serviceCategories;
  final List<String> certifications;
  final int yearsOfExperience;
  final ProviderStatus status;
  final ProviderAvailability availability;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isVerified;
  final String? verificationDocumentUrl;

  // Campos financieros
  final double balance;
  final double totalEarned;
  final double pendingWithdrawal;
  final String? bankAccountNumber;
  final String? bankName;
  final String? accountHolderName;

  ProviderModel({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.description,
    this.profileImageUrl,
    required this.phone,
    required this.email,
    required this.address,
    required this.city,
    required this.postalCode,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.completedJobs = 0,
    required this.serviceCategories,
    this.certifications = const [],
    this.yearsOfExperience = 0,
    this.status = ProviderStatus.pending,
    required this.availability,
    required this.createdAt,
    required this.updatedAt,
    this.isVerified = false,
    this.verificationDocumentUrl,
    this.balance = 0.0,
    this.totalEarned = 0.0,
    this.pendingWithdrawal = 0.0,
    this.bankAccountNumber,
    this.bankName,
    this.accountHolderName,
  });

  factory ProviderModel.fromJson(Map<String, dynamic> json) {
    return ProviderModel(
      id: json['id'],
      userId: json['user_id'],
      businessName: json['business_name'],
      description: json['description'],
      profileImageUrl: json['profile_image_url'],
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      city: json['city'],
      postalCode: json['postal_code'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
      completedJobs: json['completed_jobs'] ?? 0,
      serviceCategories: List<String>.from(json['service_categories'] ?? []),
      certifications: List<String>.from(json['certifications'] ?? []),
      yearsOfExperience: json['years_of_experience'] ?? 0,
      status: ProviderStatus.values.byName(json['status'] ?? 'pending'),
      availability: ProviderAvailability.fromJson(json['availability'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isVerified: json['is_verified'] ?? false,
      verificationDocumentUrl: json['verification_document_url'],
      balance: (json['balance'] ?? 0.0).toDouble(),
      totalEarned: (json['total_earned'] ?? 0.0).toDouble(),
      pendingWithdrawal: (json['pending_withdrawal'] ?? 0.0).toDouble(),
      bankAccountNumber: json['bank_account_number'],
      bankName: json['bank_name'],
      accountHolderName: json['account_holder_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'business_name': businessName,
      'description': description,
      'profile_image_url': profileImageUrl,
      'phone': phone,
      'email': email,
      'address': address,
      'city': city,
      'postal_code': postalCode,
      'rating': rating,
      'total_reviews': totalReviews,
      'completed_jobs': completedJobs,
      'service_categories': serviceCategories,
      'certifications': certifications,
      'years_of_experience': yearsOfExperience,
      'status': status.name,
      'availability': availability.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_verified': isVerified,
      'verification_document_url': verificationDocumentUrl,
      'balance': balance,
      'total_earned': totalEarned,
      'pending_withdrawal': pendingWithdrawal,
      'bank_account_number': bankAccountNumber,
      'bank_name': bankName,
      'account_holder_name': accountHolderName,
    };
  }

  ProviderModel copyWith({
    String? id,
    String? userId,
    String? businessName,
    String? description,
    String? profileImageUrl,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? postalCode,
    double? rating,
    int? totalReviews,
    int? completedJobs,
    List<String>? serviceCategories,
    List<String>? certifications,
    int? yearsOfExperience,
    ProviderStatus? status,
    ProviderAvailability? availability,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerified,
    String? verificationDocumentUrl,
    double? balance,
    double? totalEarned,
    double? pendingWithdrawal,
    String? bankAccountNumber,
    String? bankName,
    String? accountHolderName,
  }) {
    return ProviderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessName: businessName ?? this.businessName,
      description: description ?? this.description,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      completedJobs: completedJobs ?? this.completedJobs,
      serviceCategories: serviceCategories ?? this.serviceCategories,
      certifications: certifications ?? this.certifications,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      status: status ?? this.status,
      availability: availability ?? this.availability,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerified: isVerified ?? this.isVerified,
      verificationDocumentUrl:
          verificationDocumentUrl ?? this.verificationDocumentUrl,
      balance: balance ?? this.balance,
      totalEarned: totalEarned ?? this.totalEarned,
      pendingWithdrawal: pendingWithdrawal ?? this.pendingWithdrawal,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankName: bankName ?? this.bankName,
      accountHolderName: accountHolderName ?? this.accountHolderName,
    );
  }
}

enum ProviderStatus {
  pending,
  active,
  inactive,
  suspended,
}

class ProviderAvailability {
  final Map<String, DayAvailability> weekSchedule;
  final List<DateTime> unavailableDates;

  ProviderAvailability({
    required this.weekSchedule,
    this.unavailableDates = const [],
  });

  factory ProviderAvailability.fromJson(Map<String, dynamic> json) {
    final weekSchedule = <String, DayAvailability>{};
    if (json['week_schedule'] != null) {
      (json['week_schedule'] as Map<String, dynamic>).forEach((key, value) {
        weekSchedule[key] = DayAvailability.fromJson(value);
      });
    }

    return ProviderAvailability(
      weekSchedule: weekSchedule,
      unavailableDates: (json['unavailable_dates'] as List<dynamic>?)
              ?.map((e) => DateTime.parse(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    final schedule = <String, dynamic>{};
    weekSchedule.forEach((key, value) {
      schedule[key] = value.toJson();
    });

    return {
      'week_schedule': schedule,
      'unavailable_dates':
          unavailableDates.map((e) => e.toIso8601String()).toList(),
    };
  }

  factory ProviderAvailability.defaultSchedule() {
    return ProviderAvailability(
      weekSchedule: {
        'monday': DayAvailability(
            isAvailable: true, timeFrom: '09:00', timeTo: '18:00'),
        'tuesday': DayAvailability(
            isAvailable: true, timeFrom: '09:00', timeTo: '18:00'),
        'wednesday': DayAvailability(
            isAvailable: true, timeFrom: '09:00', timeTo: '18:00'),
        'thursday': DayAvailability(
            isAvailable: true, timeFrom: '09:00', timeTo: '18:00'),
        'friday': DayAvailability(
            isAvailable: true, timeFrom: '09:00', timeTo: '18:00'),
        'saturday': DayAvailability(
            isAvailable: false, timeFrom: '09:00', timeTo: '18:00'),
        'sunday': DayAvailability(
            isAvailable: false, timeFrom: '09:00', timeTo: '18:00'),
      },
    );
  }
}

class DayAvailability {
  final bool isAvailable;
  final String timeFrom;
  final String timeTo;

  DayAvailability({
    required this.isAvailable,
    required this.timeFrom,
    required this.timeTo,
  });

  factory DayAvailability.fromJson(Map<String, dynamic> json) {
    return DayAvailability(
      isAvailable: json['is_available'] ?? false,
      timeFrom: json['time_from'] ?? '09:00',
      timeTo: json['time_to'] ?? '18:00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_available': isAvailable,
      'time_from': timeFrom,
      'time_to': timeTo,
    };
  }

  DayAvailability copyWith({
    bool? isAvailable,
    String? timeFrom,
    String? timeTo,
  }) {
    return DayAvailability(
      isAvailable: isAvailable ?? this.isAvailable,
      timeFrom: timeFrom ?? this.timeFrom,
      timeTo: timeTo ?? this.timeTo,
    );
  }
}
