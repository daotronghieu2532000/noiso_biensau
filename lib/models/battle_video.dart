class BattleVideo {
  final String title;
  final String titleEn;
  final String description;
  final String descriptionEn;
  final String videoUrl;
  final String thumbnailUrl;

  const BattleVideo({
    required this.title,
    required this.titleEn,
    required this.description,
    required this.descriptionEn,
    required this.videoUrl,
    required this.thumbnailUrl,
  });

  String getTitle(String lang) => lang == 'en' ? titleEn : title;
  String getDescription(String lang) => lang == 'en' ? descriptionEn : description;

  factory BattleVideo.fromJson(Map<String, dynamic> json) {
    return BattleVideo(
      title: json['title'] as String? ?? '',
      titleEn: json['title_en'] as String? ?? json['titleEn'] as String? ?? '',
      description: json['description'] as String? ?? '',
      descriptionEn: json['description_en'] as String? ?? json['descriptionEn'] as String? ?? '',
      videoUrl: json['video_url'] as String? ?? json['videoUrl'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String? ?? json['thumbnailUrl'] as String? ?? '',
    );
  }
}
