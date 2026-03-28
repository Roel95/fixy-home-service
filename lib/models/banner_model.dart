class BannerModel {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String? discount;
  final String backgroundColor;
  final String textColor;
  final String? route;
  final Map<String, dynamic>? routeParams;
  final bool isActive;

  BannerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.discount,
    required this.backgroundColor,
    required this.textColor,
    this.route,
    this.routeParams,
    this.isActive = true,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      imageUrl: json['image_url'] ?? '',
      discount: json['discount'],
      backgroundColor: json['background_color'] ?? '#E8F3FF',
      textColor: json['text_color'] ?? '#0066FF',
      route: json['route'],
      routeParams: json['route_params'] != null
          ? Map<String, dynamic>.from(json['route_params'])
          : null,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'image_url': imageUrl,
      'discount': discount,
      'background_color': backgroundColor,
      'text_color': textColor,
      'route': route,
      'route_params': routeParams,
      'is_active': isActive,
    };
  }
}
