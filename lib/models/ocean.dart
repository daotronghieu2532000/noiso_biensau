class Ocean {
  final String id;
  final String name;
  final String englishName;
  final String coordinates;
  final String area;
  final String avgDepth;
  final String deepestPointName;
  final String englishDeepestPointName;
  final String deepestPointDepth;
  final String description;
  final String englishDescription;
  final String thalassophobiaWarning;
  final String englishThalassophobiaWarning;
  final String imageUrl;
  final double mapX;
  final double mapY;

  Ocean({
    required this.id,
    required this.name,
    required this.englishName,
    required this.coordinates,
    required this.area,
    required this.avgDepth,
    required this.deepestPointName,
    required this.englishDeepestPointName,
    required this.deepestPointDepth,
    required this.description,
    required this.englishDescription,
    required this.thalassophobiaWarning,
    required this.englishThalassophobiaWarning,
    required this.imageUrl,
    required this.mapX,
    required this.mapY,
  });

  String getName(String langCode) => langCode == 'en' ? englishName : name;
  String getDeepestPointName(String langCode) => langCode == 'en' ? englishDeepestPointName : deepestPointName;
  String getDescription(String langCode) => langCode == 'en' ? englishDescription : description;
  String getThalassophobiaWarning(String langCode) => langCode == 'en' ? englishThalassophobiaWarning : thalassophobiaWarning;

  factory Ocean.fromJson(Map<String, dynamic> json) {
    return Ocean(
      id: json['id'] as String,
      name: json['name'] as String,
      englishName: json['englishName'] as String,
      coordinates: json['coordinates'] as String,
      area: json['area'] as String,
      avgDepth: json['avgDepth'] as String,
      deepestPointName: json['deepestPointName'] as String,
      englishDeepestPointName: json['deepestPointName_en'] as String? ?? json['deepestPointName'] as String,
      deepestPointDepth: json['deepestPointDepth'] as String,
      description: json['description'] as String,
      englishDescription: json['description_en'] as String? ?? json['description'] as String,
      thalassophobiaWarning: json['thalassophobiaWarning'] as String,
      englishThalassophobiaWarning: json['thalassophobiaWarning_en'] as String? ?? json['thalassophobiaWarning'] as String,
      imageUrl: json['imageUrl'] as String,
      mapX: (json['mapX'] as num).toDouble(),
      mapY: (json['mapY'] as num).toDouble(),
    );
  }
}
