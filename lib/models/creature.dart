import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class Creature {
  final String id;
  final String name;
  final String nameEn;
  final String scientificName;
  final String type; // 'real' or 'myth'
  final int minDepth;
  final int maxDepth;
  final int dangerLevel; // 1 to 5
  final String sizeHumanRatio;
  final String sizeHumanRatioEn;
  final double humanSizeMeters;
  final double creatureSizeMeters;
  final String imageUrl;
  final String videoUrl;
  final String ambientSound;
  final String description;
  final String descriptionEn;
  bool isLocked;

  Creature({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.scientificName,
    required this.type,
    required this.minDepth,
    required this.maxDepth,
    required this.dangerLevel,
    required this.sizeHumanRatio,
    required this.sizeHumanRatioEn,
    required this.humanSizeMeters,
    required this.creatureSizeMeters,
    required this.imageUrl,
    required this.videoUrl,
    required this.ambientSound,
    required this.description,
    required this.descriptionEn,
    this.isLocked = false,
  });

  Creature copyWith({
    String? id,
    String? name,
    String? nameEn,
    String? scientificName,
    String? type,
    int? minDepth,
    int? maxDepth,
    int? dangerLevel,
    String? sizeHumanRatio,
    String? sizeHumanRatioEn,
    double? humanSizeMeters,
    double? creatureSizeMeters,
    String? imageUrl,
    String? videoUrl,
    String? ambientSound,
    String? description,
    String? descriptionEn,
    bool? isLocked,
  }) {
    return Creature(
      id: id ?? this.id,
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      scientificName: scientificName ?? this.scientificName,
      type: type ?? this.type,
      minDepth: minDepth ?? this.minDepth,
      maxDepth: maxDepth ?? this.maxDepth,
      dangerLevel: dangerLevel ?? this.dangerLevel,
      sizeHumanRatio: sizeHumanRatio ?? this.sizeHumanRatio,
      sizeHumanRatioEn: sizeHumanRatioEn ?? this.sizeHumanRatioEn,
      humanSizeMeters: humanSizeMeters ?? this.humanSizeMeters,
      creatureSizeMeters: creatureSizeMeters ?? this.creatureSizeMeters,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      ambientSound: ambientSound ?? this.ambientSound,
      description: description ?? this.description,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  String getName(String langCode) => langCode == 'en' ? nameEn : name;
  String getSizeHumanRatio(String langCode) => langCode == 'en' ? sizeHumanRatioEn : sizeHumanRatio;
  String getDescription(String langCode) => langCode == 'en' ? descriptionEn : description;

  bool get isReal => type == 'real';
  bool get isMyth => type == 'myth';
  bool get isSubmersible => type == 'submersible';
  bool get isShipwreck => type == 'shipwreck';

  String getCategoryTitle(String langCode) {
    if (isSubmersible) return langCode == 'en' ? 'DEEP SUBMERSIBLE' : 'TÀU LẶN THÁM HIỂM';
    if (isShipwreck) return langCode == 'en' ? 'HISTORIC SHIPWRECK' : 'XÁC TÀU LỊCH SỬ';
    if (isReal) return langCode == 'en' ? 'REAL MARINE LIFE' : 'SINH VẬT THỰC TẾ';
    return langCode == 'en' ? 'MYTH & TITAN' : 'THẦN THOẠI & VIỄN TƯỞNG';
  }

  Color get categoryThemeColor {
    if (isSubmersible) return const Color(0xFFFFB800); // Amber Gold
    if (isShipwreck) return const Color(0xFF90A4AE);   // Steel Slate
    if (isReal) return const Color(0xFF00FFB2);        // Emerald Sea Green
    return const Color(0xFFFF3366);                    // Cyber Red/Magenta
  }

  ImageProvider get imageProvider {
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return CachedNetworkImageProvider(imageUrl);
    } else {
      return AssetImage(imageUrl);
    }
  }

  Widget buildImage({
    double? width,
    double? height,
    BoxFit? fit,
    Color? color,
    BlendMode? colorBlendMode,
    ImageErrorWidgetBuilder? errorBuilder,
  }) {
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        color: color,
        colorBlendMode: colorBlendMode,
        placeholder: (context, url) => Container(
          color: const Color(0xFF0D1F3D).withValues(alpha: 0.15),
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00F0FF)),
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: const Color(0xFF0D1F3D),
          child: const Icon(Icons.broken_image, color: Colors.white24, size: 40),
        ),
      );
    } else {
      return Image.asset(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        color: color,
        colorBlendMode: colorBlendMode,
        errorBuilder: errorBuilder,
      );
    }
  }

  static String _normalizeAssetPath(String rawUrl) {
    const pngConvertedAssets = {
      'assets/images/creatures/wreck_titanic.jpg': 'assets/images/creatures/wreck_titanic.png',
      'assets/images/creatures/sub_alvin.jpg': 'assets/images/creatures/sub_alvin.png',
      'assets/images/creatures/sub_deepsea_challenger.jpg': 'assets/images/creatures/sub_deepsea_challenger.png',
      'assets/images/creatures/sub_trieste.jpg': 'assets/images/creatures/sub_trieste.png',
    };
    return pngConvertedAssets[rawUrl] ?? rawUrl;
  }

  static String _normalizeVideoUrl(String id, String rawVideoUrl) {
    const defaultSubAndWreckVideos = {
      'wreck_titanic': 'https://codego.io.vn/api/uploads/videos/Titanic_shipwreck.mp4',
      'sub_alvin': 'https://codego.io.vn/api/uploads/videos/Submersible_collecting.mp4',
      'sub_deepsea_challenger': 'https://codego.io.vn/api/uploads/videos/Submersible_descending.mp4',
      'sub_trieste': 'https://codego.io.vn/api/uploads/videos/Bathyscaphe_descending.mp4',
    };
    final trimmed = rawVideoUrl.trim();
    if (defaultSubAndWreckVideos.containsKey(id)) {
      if (trimmed.isEmpty || trimmed.contains('/uploads/creatures/')) {
        return defaultSubAndWreckVideos[id]!;
      }
    }
    return trimmed;
  }

  factory Creature.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final type = json['type'] as String;
    final rawLocked = json['is_locked'] as bool? ?? false;
    // Mở khóa mặc định cho các tàu lặn (submersible) và xác tàu (shipwreck) để hiển thị ảnh & video trực tiếp
    final isSubOrWreck = type == 'submersible' || type == 'shipwreck';

    return Creature(
      id: id,
      name: json['name'] as String,
      nameEn: json['name_en'] as String? ?? json['name'] as String,
      scientificName: json['scientific_name'] as String,
      type: type,
      minDepth: json['min_depth'] as int,
      maxDepth: json['max_depth'] as int,
      dangerLevel: json['danger_level'] as int,
      sizeHumanRatio: json['size_human_ratio'] as String,
      sizeHumanRatioEn: json['size_human_ratio_en'] as String? ?? json['size_human_ratio'] as String,
      humanSizeMeters: (json['human_size_meters'] as num).toDouble(),
      creatureSizeMeters: (json['creature_size_meters'] as num).toDouble(),
      imageUrl: _normalizeAssetPath(json['image_url'] as String),
      videoUrl: _normalizeVideoUrl(id, json['video_url'] as String? ?? ''),
      ambientSound: json['ambient_sound'] as String,
      description: json['description'] as String,
      descriptionEn: json['description_en'] as String? ?? json['description'] as String,
      isLocked: isSubOrWreck ? false : rawLocked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_en': nameEn,
      'scientific_name': scientificName,
      'type': type,
      'min_depth': minDepth,
      'max_depth': maxDepth,
      'danger_level': dangerLevel,
      'size_human_ratio': sizeHumanRatio,
      'size_human_ratio_en': sizeHumanRatioEn,
      'human_size_meters': humanSizeMeters,
      'creature_size_meters': creatureSizeMeters,
      'image_url': imageUrl,
      'video_url': videoUrl,
      'ambient_sound': ambientSound,
      'description': description,
      'description_en': descriptionEn,
      'is_locked': isLocked,
    };
  }
}
