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

  String getName(String langCode) => langCode == 'en' ? nameEn : name;
  String getSizeHumanRatio(String langCode) => langCode == 'en' ? sizeHumanRatioEn : sizeHumanRatio;
  String getDescription(String langCode) => langCode == 'en' ? descriptionEn : description;

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

  factory Creature.fromJson(Map<String, dynamic> json) {
    return Creature(
      id: json['id'] as String,
      name: json['name'] as String,
      nameEn: json['name_en'] as String? ?? json['name'] as String,
      scientificName: json['scientific_name'] as String,
      type: json['type'] as String,
      minDepth: json['min_depth'] as int,
      maxDepth: json['max_depth'] as int,
      dangerLevel: json['danger_level'] as int,
      sizeHumanRatio: json['size_human_ratio'] as String,
      sizeHumanRatioEn: json['size_human_ratio_en'] as String? ?? json['size_human_ratio'] as String,
      humanSizeMeters: (json['human_size_meters'] as num).toDouble(),
      creatureSizeMeters: (json['creature_size_meters'] as num).toDouble(),
      imageUrl: json['image_url'] as String,
      videoUrl: json['video_url'] as String? ?? '',
      ambientSound: json['ambient_sound'] as String,
      description: json['description'] as String,
      descriptionEn: json['description_en'] as String? ?? json['description'] as String,
      isLocked: json['is_locked'] as bool? ?? false,
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
