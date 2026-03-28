enum UserRole {
  customer,
  provider,
  both,
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String avatarUrl;
  final String? address;
  final String? city;
  final String? postalCode;
  final bool hasNotifications;
  final UserRole role;
  final bool isProvider;
  final String? providerProfileId;
  final int rewardPoints;
  final String referralCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.avatarUrl,
    this.address,
    this.city,
    this.postalCode,
    this.hasNotifications = false,
    this.role = UserRole.customer,
    this.isProvider = false,
    this.providerProfileId,
    this.rewardPoints = 0,
    required this.referralCode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      avatarUrl: json['avatar_url'] ?? '',
      address: json['address'],
      city: json['city'],
      postalCode: json['postal_code'],
      hasNotifications: json['has_notifications'] ?? false,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.customer,
      ),
      isProvider: json['is_provider'] ?? false,
      providerProfileId: json['provider_profile_id'],
      rewardPoints: json['reward_points'] ?? 0,
      referralCode: json['referral_code'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar_url': avatarUrl,
      'address': address,
      'city': city,
      'postal_code': postalCode,
      'has_notifications': hasNotifications,
      'role': role.name,
      'is_provider': isProvider,
      'provider_profile_id': providerProfileId,
      'reward_points': rewardPoints,
      'referral_code': referralCode,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    String? address,
    String? city,
    String? postalCode,
    bool? hasNotifications,
    UserRole? role,
    bool? isProvider,
    String? providerProfileId,
    int? rewardPoints,
    String? referralCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      address: address ?? this.address,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      hasNotifications: hasNotifications ?? this.hasNotifications,
      role: role ?? this.role,
      isProvider: isProvider ?? this.isProvider,
      providerProfileId: providerProfileId ?? this.providerProfileId,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      referralCode: referralCode ?? this.referralCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get canAccessProviderDashboard =>
      isProvider || role == UserRole.provider || role == UserRole.both;
}
