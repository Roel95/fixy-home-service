class SavedAddress {
  final String id;
  final String userId;
  final String name;
  final String address;
  final String? city;
  final String? reference;
  final String iconType;
  final bool isDefault;
  final DateTime createdAt;

  SavedAddress({
    required this.id,
    required this.userId,
    required this.name,
    required this.address,
    this.city,
    this.reference,
    this.iconType = 'home',
    this.isDefault = false,
    required this.createdAt,
  });

  SavedAddress copyWith({
    String? id,
    String? userId,
    String? name,
    String? address,
    String? city,
    String? reference,
    String? iconType,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return SavedAddress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      reference: reference ?? this.reference,
      iconType: iconType ?? this.iconType,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory SavedAddress.fromJson(Map<String, dynamic> json) {
    return SavedAddress(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString(),
      reference: json['reference']?.toString(),
      iconType: json['icon_type']?.toString() ?? 'home',
      isDefault: json['is_default'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'address': address,
      'city': city,
      'reference': reference,
      'icon_type': iconType,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'name': name,
      'address': address,
      'city': city,
      'reference': reference,
      'icon_type': iconType,
      'is_default': isDefault,
    };
  }

  String get fullAddress {
    final parts = <String>[address];
    if (city != null && city!.isNotEmpty) parts.add(city!);
    return parts.join(', ');
  }

  static List<String> get availableIcons => [
        'home',
        'work',
        'apartment',
        'store',
        'family',
        'other',
      ];
}
