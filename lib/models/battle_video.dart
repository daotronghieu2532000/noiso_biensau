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

  static String _normalizeThumbnailPath(String rawUrl) {
    const pngConvertedAssets = {
      'assets/images/creatures/wreck_titanic.jpg': 'assets/images/creatures/wreck_titanic.png',
      'assets/images/creatures/sub_alvin.jpg': 'assets/images/creatures/sub_alvin.png',
      'assets/images/creatures/sub_deepsea_challenger.jpg': 'assets/images/creatures/sub_deepsea_challenger.png',
      'assets/images/creatures/sub_trieste.jpg': 'assets/images/creatures/sub_trieste.png',
    };
    return pngConvertedAssets[rawUrl] ?? rawUrl;
  }

  factory BattleVideo.fromJson(Map<String, dynamic> json) {
    return BattleVideo(
      title: json['title'] as String? ?? '',
      titleEn: json['title_en'] as String? ?? json['titleEn'] as String? ?? '',
      description: json['description'] as String? ?? '',
      descriptionEn: json['description_en'] as String? ?? json['descriptionEn'] as String? ?? '',
      videoUrl: json['video_url'] as String? ?? json['videoUrl'] as String? ?? '',
      thumbnailUrl: _normalizeThumbnailPath(
        json['thumbnail_url'] as String? ?? json['thumbnailUrl'] as String? ?? '',
      ),
    );
  }
}
