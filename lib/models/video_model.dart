class VideoModel {
  final String id;
  final String title;
  final String thumbnailUrl;
  final String videoUrl;
  final String category;
  final int duration;
  final String description;

  VideoModel({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.videoUrl,
    required this.category,
    required this.duration,
    required this.description,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) => VideoModel(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        thumbnailUrl: json['thumbnailUrl'] ?? '',
        videoUrl: json['videoUrl'] ?? '',
        category: json['category'] ?? '',
        duration: json['duration'] ?? 0,
        description: json['description'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'thumbnailUrl': thumbnailUrl,
        'videoUrl': videoUrl,
        'category': category,
        'duration': duration,
        'description': description,
      };
}
