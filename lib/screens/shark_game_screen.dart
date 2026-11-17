import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_strings.dart';
import '../services/sound_service.dart';

/// Màn hình Mini-Game "Cá Lớn Nuốt Cá Bé - Sát Thủ Đại Dương" (Shark Apex Hunt)
/// Nâng cấp toàn diện:
/// - 2 Màn chơi riêng biệt (Map 1: Vịnh San Hô & Mặt Biển | Map 2: Rãnh Mariana Núi Lửa Dung Nham)
/// - Mặt biển có Thuyền đánh cá, Bè gỗ, Thợ săn bắn lao (Harpoon) & Người bơi biết chạy lên thuyền!
/// - Cơ chế Nhảy Vượt Sóng (Airborne Breach) húc vỡ thuyền ăn thịt người từ LV.3+
/// - Hiệu ứng tâm lý kích thích: Screen Shake, Low-HP Blood Vignette, Gold Rush Frenzy!
class SharkGameScreen extends StatefulWidget {
  const SharkGameScreen({super.key});

  @override
  State<SharkGameScreen> createState() => _SharkGameScreenState();
}

enum _GameStageMap { coralBay, volcanicAbyss }

/// Dữ liệu Sprite đã nạp kèm ImageShader trên GPU để uốn lưới xương sống 60-120 FPS
class _LoadedSpriteMesh {
  final ui.Image image;
  final Paint normalShaderPaint;
  final Paint hitFlashShaderPaint;
  final Paint stunShaderPaint;
  final Paint frenzyShaderPaint;
  final Paint goldRushShaderPaint;

  _LoadedSpriteMesh({required this.image})
      : normalShaderPaint = Paint()
          ..shader = ui.ImageShader(
            image,
            TileMode.clamp,
            TileMode.clamp,
            Float64List.fromList(Matrix4.identity().storage),
          )
          ..filterQuality = FilterQuality.medium,
        hitFlashShaderPaint = Paint()
          ..shader = ui.ImageShader(
            image,
            TileMode.clamp,
            TileMode.clamp,
            Float64List.fromList(Matrix4.identity().storage),
          )
          ..filterQuality = FilterQuality.medium
          ..colorFilter = const ColorFilter.mode(
            Color(0x99FF1744),
            BlendMode.srcATop,
          ),
        stunShaderPaint = Paint()
          ..shader = ui.ImageShader(
            image,
            TileMode.clamp,
            TileMode.clamp,
            Float64List.fromList(Matrix4.identity().storage),
          )
          ..filterQuality = FilterQuality.medium
          ..colorFilter = const ColorFilter.mode(
            Color(0x8800E5FF),
            BlendMode.srcATop,
          ),
        frenzyShaderPaint = Paint()
          ..shader = ui.ImageShader(
            image,
            TileMode.clamp,
            TileMode.clamp,
            Float64List.fromList(Matrix4.identity().storage),
          )
          ..filterQuality = FilterQuality.medium
          ..colorFilter = const ColorFilter.mode(
            Color(0x44FF1744),
            BlendMode.srcATop,
          ),
        goldRushShaderPaint = Paint()
          ..shader = ui.ImageShader(
            image,
            TileMode.clamp,
            TileMode.clamp,
            Float64List.fromList(Matrix4.identity().storage),
          )
          ..filterQuality = FilterQuality.medium
          ..colorFilter = const ColorFilter.mode(
            Color(0x77FFD740),
            BlendMode.srcATop,
          );
}

class _SharkEvolutionStage {
  final int level;
  final String nameVi;
  final String nameEn;
  final String assetPath;
  final Rect uvBounds;
  final double aspectRatio;
  final double baseRadius;
  final double lengthMeters;
  final int expRequired;
  final double maxHp;
  final double biteDamage;
  final Color auraColor;

  const _SharkEvolutionStage({
    required this.level,
    required this.nameVi,
    required this.nameEn,
    required this.assetPath,
    required this.uvBounds,
    required this.aspectRatio,
    required this.baseRadius,
    required this.lengthMeters,
    required this.expRequired,
    required this.maxHp,
    required this.biteDamage,
    required this.auraColor,
  });
}

class _CreatureTemplate {
  final String id;
  final String nameVi;
  final String nameEn;
  final int tier;
  final String assetPath;
  final bool assetFacesRight;
  final Rect uvBounds;
  final double aspectRatio;
  final double radius;
  final double speed;
  final double waveAmplitude;
  final double waveFrequency;
  final double maxHp;
  final double damage;
  final int expReward;
  final int scoreReward;
  final double minDepthRatio;
  final double maxDepthRatio;
  final bool isAggressive;
  final bool isHuman;
  final bool isHarpoonHunter;
  final int schoolSize;
  final Color primaryColor;

  const _CreatureTemplate({
    required this.id,
    required this.nameVi,
    required this.nameEn,
    required this.tier,
    required this.assetPath,
    this.assetFacesRight = false,
    this.uvBounds = const Rect.fromLTRB(0.0, 0.0, 1.0, 1.0),
    this.aspectRatio = 2.2,
    required this.radius,
    required this.speed,
    this.waveAmplitude = 0.16,
    this.waveFrequency = 5.8,
    required this.maxHp,
    required this.damage,
    required this.expReward,
    required this.scoreReward,
    required this.minDepthRatio,
    required this.maxDepthRatio,
    this.isAggressive = false,
    this.isHuman = false,
    this.isHarpoonHunter = false,
    this.schoolSize = 1,
    required this.primaryColor,
  });
}

class _SeaEntity {
  static const int kSpineJoints = 16;

  final _CreatureTemplate template;
  final int schoolGroupId;
  double x;
  double y;
  double vx;
  double vy;
  double hp;
  double maxHp;
  double swimPhase;
  double stunTimer = 0.0;
  double hitFlashTimer = 0.0;
  double aiChangeTimer = 0.0;
  double biteCooldown = 0.0;
  double shootCooldown = 1.6;
  bool isPanicking = false; // Người bơi hoảng loạn bơi về phía thuyền

  bool facingRight;
  double dorsalFlip;
  bool isBeingSwallowed = false;
  double swallowProgress = 0.0;

  final List<Offset> spineNodes = List<Offset>.filled(kSpineJoints, Offset.zero);

  _SeaEntity({
    required this.template,
    required this.schoolGroupId,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.swimPhase,
  })  : hp = template.maxHp,
        maxHp = template.maxHp,
        facingRight = vx >= 0,
        dorsalFlip = vx >= 0 ? 1.0 : -1.0 {
    _initSpine();
  }

  void _initSpine() {
    final double bodyLength = template.radius * 2.55;
    final double segLen = bodyLength / (kSpineJoints - 1);
    final double dir = facingRight ? 1.0 : -1.0;
    final Offset headPos = Offset(x + dir * bodyLength * 0.45, y);
    for (int i = 0; i < kSpineJoints; i++) {
      spineNodes[i] = Offset(headPos.dx - dir * i * segLen, headPos.dy);
    }
  }
}

/// Thuyền đánh cá & Bè gỗ trên mặt biển (Có thể bắn lao vào cá mập yếu, và bị cá mập LV.3+ húc vỡ!)
class _SurfaceVessel {
  final bool isFishingBoat; // true: Thuyền đánh cá, false: Bè gỗ
  double x;
  double vx;
  double width;
  double height;
  double hp;
  double maxHp;
  int passengersCount;
  double shootCooldown;
  double bobPhase;
  double hitFlashTimer = 0.0;
  double respawnTimer = 0.0;
  bool isDestroyed = false;

  _SurfaceVessel({
    required this.isFishingBoat,
    required this.x,
    required this.vx,
    required this.width,
    required this.height,
    required this.maxHp,
    required this.passengersCount,
    required this.bobPhase,
  })  : hp = maxHp,
        shootCooldown = 1.8;
}

/// Mũi lao (Harpoon) bắn ra từ thuyền hoặc thợ săn dưới nước
class _HarpoonProjectile {
  double x;
  double y;
  double vx;
  double vy;
  double damage;
  double lifeTimer = 3.2;

  _HarpoonProjectile({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.damage,
  });
}

enum _PickupType { meatChunk, healingPearl, goldenStar, navalMine }

class _OceanPickup {
  final _PickupType type;
  double x;
  double y;
  double vx;
  double vy;
  double radius;
  double lifeTimer;
  double pulsePhase;

  _OceanPickup({
    required this.type,
    required this.x,
    required this.y,
    this.vx = 0.0,
    this.vy = 0.0,
    required this.radius,
    this.lifeTimer = 25.0,
    this.pulsePhase = 0.0,
  });
}

class _GameParticle {
  double x;
  double y;
  double vx;
  double vy;
  double radius;
  double alpha;
  double decay;
  Color color;

  _GameParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.alpha,
    required this.decay,
    required this.color,
  });
}

class _FloatingTextPopup {
  String text;
  double x;
  double y;
  double vy = -44.0;
  double alpha = 1.0;
  Color color;
  double fontSize;

  _FloatingTextPopup({
    required this.text,
    required this.x,
    required this.y,
    required this.color,
    this.fontSize = 14.0,
  });
}

class _ShockwaveRing {
  double x;
  double y;
  double radius;
  double maxRadius;
  double alpha = 1.0;
  Color color;

  _ShockwaveRing({
    required this.x,
    required this.y,
    this.radius = 10.0,
    required this.maxRadius,
    required this.color,
  });
}

class _SharkGameScreenState extends State<SharkGameScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const double worldWidth = 4200.0;
  static const double worldHeight = 2600.0;
  static const double seaSurfaceY = 230.0; // Vùng Y < 230 là Bầu Trời để Cá Mập nhảy vượt sóng!
  static const int kPlayerSpineJoints = 16;
  static const String _highScoreKey = 'shark_game_high_score_v1';

  // Danh sách 6 cấp tiến hóa của Cá Mập Người Chơi (Đã cân bằng độ khó thử thách)
  static const List<_SharkEvolutionStage> _evolutionStages = [
    _SharkEvolutionStage(
      level: 1,
      nameVi: 'Cá Mập Đầu Búa Rạn San Hô',
      nameEn: 'Reef Hammerhead Shark',
      assetPath: 'assets/images/creatures/game_hammerhead_shark.png',
      uvBounds: Rect.fromLTRB(0.0, 0.0, 1.0, 1.0),
      aspectRatio: 2.58,
      baseRadius: 36.0,
      lengthMeters: 1.8,
      expRequired: 160,
      maxHp: 100.0,
      biteDamage: 32.0,
      auraColor: Color(0xFF00E5FF),
    ),
    _SharkEvolutionStage(
      level: 2,
      nameVi: 'Cá Mập Trắng Sát Thủ',
      nameEn: 'Great White Apex',
      assetPath: 'assets/images/creatures/great_white_shark.png',
      uvBounds: Rect.fromLTRB(0.105, 0.365, 0.958, 0.690),
      aspectRatio: 2.63,
      baseRadius: 46.0,
      lengthMeters: 4.2,
      expRequired: 400,
      maxHp: 145.0,
      biteDamage: 56.0,
      auraColor: Color(0xFF00FF88),
    ),
    _SharkEvolutionStage(
      level: 3,
      nameVi: 'Cá Mập Bắc Cực Cổ Đại',
      nameEn: 'Greenland Abyssal Shark',
      assetPath: 'assets/images/creatures/greenland_shark.png',
      uvBounds: Rect.fromLTRB(0.128, 0.342, 0.928, 0.603),
      aspectRatio: 2.95,
      baseRadius: 56.0,
      lengthMeters: 6.8,
      expRequired: 780,
      maxHp: 210.0,
      biteDamage: 92.0,
      auraColor: Color(0xFF64FFDA),
    ),
    _SharkEvolutionStage(
      level: 4,
      nameVi: 'Hổ Kình Đại Dương (Orca)',
      nameEn: 'Killer Whale Titan',
      assetPath: 'assets/images/creatures/orca.png',
      uvBounds: Rect.fromLTRB(0.089, 0.243, 0.744, 0.663),
      aspectRatio: 2.15,
      baseRadius: 68.0,
      lengthMeters: 10.5,
      expRequired: 1350,
      maxHp: 310.0,
      biteDamage: 145.0,
      auraColor: Color(0xFFFFD740),
    ),
    _SharkEvolutionStage(
      level: 5,
      nameVi: 'Siêu Cá Mập Megalodon',
      nameEn: 'Ancient Megalodon',
      assetPath: 'assets/images/creatures/megalodon.png',
      uvBounds: Rect.fromLTRB(0.033, 0.258, 0.985, 0.713),
      aspectRatio: 2.15,
      baseRadius: 82.0,
      lengthMeters: 20.0,
      expRequired: 2300,
      maxHp: 450.0,
      biteDamage: 225.0,
      auraColor: Color(0xFFFF5252),
    ),
    _SharkEvolutionStage(
      level: 6,
      nameVi: 'Chúa Tể Vực Thẳm Leviathan',
      nameEn: 'Abyssal Emperor Leviathan',
      assetPath: 'assets/images/creatures/reaper_leviathan.png',
      uvBounds: Rect.fromLTRB(0.057, 0.345, 0.960, 0.682),
      aspectRatio: 2.68,
      baseRadius: 94.0,
      lengthMeters: 36.0,
      expRequired: 3200,
      maxHp: 640.0,
      biteDamage: 340.0,
      auraColor: Color(0xFFE040FB),
    ),
    _SharkEvolutionStage(
      level: 7,
      nameVi: 'Thủy Quái Bóng Ma Ghost Leviathan',
      nameEn: 'Phantom Ghost Leviathan',
      assetPath: 'assets/images/creatures/ghost_leviathan.png',
      uvBounds: Rect.fromLTRB(0.070, 0.076, 1.000, 1.000),
      aspectRatio: 2.15,
      baseRadius: 102.0,
      lengthMeters: 44.0,
      expRequired: 4600,
      maxHp: 780.0,
      biteDamage: 430.0,
      auraColor: Color(0xFF00E5FF),
    ),
    _SharkEvolutionStage(
      level: 8,
      nameVi: 'Rắn Biển Thần Thoại Jormungandr',
      nameEn: 'World Serpent Jormungandr',
      assetPath: 'assets/images/creatures/jormungandr.png',
      uvBounds: Rect.fromLTRB(0.025, 0.145, 0.980, 0.875),
      aspectRatio: 1.55,
      baseRadius: 112.0,
      lengthMeters: 56.0,
      expRequired: 6400,
      maxHp: 960.0,
      biteDamage: 540.0,
      auraColor: Color(0xFF00E676),
    ),
    _SharkEvolutionStage(
      level: 9,
      nameVi: 'Khủng Long Biển Mosasaurus',
      nameEn: 'Prehistoric Mosasaurus',
      assetPath: 'assets/images/creatures/game_mosasaurus.png',
      uvBounds: Rect.fromLTRB(0.0, 0.0, 1.0, 1.0),
      aspectRatio: 3.40,
      baseRadius: 122.0,
      lengthMeters: 68.0,
      expRequired: 8800,
      maxHp: 1220.0,
      biteDamage: 720.0,
      auraColor: Color(0xFF40C4FF),
    ),
    _SharkEvolutionStage(
      level: 10,
      nameVi: 'Hải Quái Nguyên Tử Godzilla',
      nameEn: 'Atomic Kaiju Godzilla',
      assetPath: 'assets/images/creatures/game_godzilla_swim.png',
      uvBounds: Rect.fromLTRB(0.0, 0.0, 1.0, 1.0),
      aspectRatio: 2.90,
      baseRadius: 132.0,
      lengthMeters: 95.0,
      expRequired: 12000,
      maxHp: 1580.0,
      biteDamage: 960.0,
      auraColor: Color(0xFF2979FF),
    ),
    _SharkEvolutionStage(
      level: 11,
      nameVi: 'Hoàng Đế Vực Thẳm Void Leviathan',
      nameEn: 'Abyssal Void Emperor',
      assetPath: 'assets/images/creatures/game_void_cthulhu.png',
      uvBounds: Rect.fromLTRB(0.0, 0.0, 1.0, 1.0),
      aspectRatio: 3.40,
      baseRadius: 144.0,
      lengthMeters: 135.0,
      expRequired: 999999,
      maxHp: 2100.0,
      biteDamage: 1350.0,
      auraColor: Color(0xFF00F0FF),
    ),
  ];

  // Danh mục hơn 22 loài sinh vật & con người
  static const List<_CreatureTemplate> _speciesCatalog = [
    // ── TIER 1: ĐÀN CÁ CON MỒI ──
    _CreatureTemplate(
      id: 'clownfish',
      nameVi: 'Cá Hề Rạn San Hô',
      nameEn: 'Coral Clownfish',
      tier: 1,
      assetPath: 'assets/images/creatures/game_clownfish_solo.png',
      assetFacesRight: false,
      aspectRatio: 1.83,
      radius: 17.0,
      speed: 94.0,
      waveAmplitude: 0.19,
      waveFrequency: 7.4,
      maxHp: 15.0,
      damage: 0.0,
      expReward: 11,
      scoreReward: 50,
      minDepthRatio: 0.12,
      maxDepthRatio: 0.45,
      schoolSize: 5,
      primaryColor: Color(0xFFFF6D00),
    ),
    _CreatureTemplate(
      id: 'reef_tang',
      nameVi: 'Cá Đuôi Gai Xanh',
      nameEn: 'Regal Blue Tang',
      tier: 1,
      assetPath: 'assets/images/creatures/game_reef_tang.png',
      assetFacesRight: false,
      aspectRatio: 2.00,
      radius: 19.0,
      speed: 102.0,
      waveAmplitude: 0.18,
      waveFrequency: 7.0,
      maxHp: 18.0,
      damage: 0.0,
      expReward: 13,
      scoreReward: 60,
      minDepthRatio: 0.13,
      maxDepthRatio: 0.50,
      schoolSize: 5,
      primaryColor: Color(0xFF00B0FF),
    ),
    _CreatureTemplate(
      id: 'yellowfin_tuna',
      nameVi: 'Cá Ngừ Đại Dương Vây Vàng',
      nameEn: 'Yellowfin Tuna',
      tier: 1,
      assetPath: 'assets/images/creatures/game_yellowfin_tuna.png',
      assetFacesRight: false,
      aspectRatio: 2.32,
      radius: 23.0,
      speed: 132.0,
      waveAmplitude: 0.16,
      waveFrequency: 7.8,
      maxHp: 22.0,
      damage: 0.0,
      expReward: 17,
      scoreReward: 85,
      minDepthRatio: 0.15,
      maxDepthRatio: 0.65,
      schoolSize: 4,
      primaryColor: Color(0xFFFFD54F),
    ),
    _CreatureTemplate(
      id: 'giant_isopod',
      nameVi: 'Bọ Biển Khổng Lồ',
      nameEn: 'Giant Isopod',
      tier: 1,
      assetPath: 'assets/images/creatures/giant_isopod.png',
      assetFacesRight: true,
      uvBounds: Rect.fromLTRB(0.117, 0.342, 0.892, 0.697),
      aspectRatio: 2.18,
      radius: 24.0,
      speed: 72.0,
      waveAmplitude: 0.11,
      waveFrequency: 5.2,
      maxHp: 24.0,
      damage: 5.0,
      expReward: 20,
      scoreReward: 95,
      minDepthRatio: 0.44,
      maxDepthRatio: 0.95,
      schoolSize: 2,
      primaryColor: Color(0xFFB0BEC5),
    ),
    // NGƯỜI BƠI TRÊN MẶT BIỂN (Ăn ngay từ LV.1, hồi nhiều máu & EXP, thấy cá mập sẽ bơi chạy lên thuyền!)
    _CreatureTemplate(
      id: 'surface_swimmer',
      nameVi: 'Người Bơi Mặt Biển',
      nameEn: 'Ocean Swimmer',
      tier: 1,
      assetPath: 'assets/images/creatures/game_swimmer.png',
      assetFacesRight: false,
      aspectRatio: 3.6,
      radius: 26.0,
      speed: 88.0,
      waveAmplitude: 0.09,
      waveFrequency: 6.4,
      maxHp: 22.0,
      damage: 0.0,
      expReward: 34,
      scoreReward: 180,
      minDepthRatio: 0.095,
      maxDepthRatio: 0.125,
      isHuman: true,
      primaryColor: Color(0xFFFF6D00),
    ),

    // ── TIER 2: SINH VẬT TẦNG TRUNG & THỢ SĂN BẮN LAO ──
    _CreatureTemplate(
      id: 'sea_turtle',
      nameVi: 'Rùa Biển Cổ Đại',
      nameEn: 'Green Sea Turtle',
      tier: 2,
      assetPath: 'assets/images/creatures/game_sea_turtle.png',
      assetFacesRight: false,
      aspectRatio: 2.07,
      radius: 32.0,
      speed: 86.0,
      waveAmplitude: 0.12,
      waveFrequency: 4.5,
      maxHp: 58.0,
      damage: 8.0,
      expReward: 36,
      scoreReward: 155,
      minDepthRatio: 0.14,
      maxDepthRatio: 0.55,
      primaryColor: Color(0xFF00E676),
    ),
    _CreatureTemplate(
      id: 'manta_ray',
      nameVi: 'Cá Đuối Ó Đại Dương',
      nameEn: 'Giant Manta Ray',
      tier: 2,
      assetPath: 'assets/images/creatures/game_manta_ray.png',
      assetFacesRight: false,
      aspectRatio: 3.10,
      radius: 38.0,
      speed: 102.0,
      waveAmplitude: 0.20,
      waveFrequency: 4.8,
      maxHp: 64.0,
      damage: 10.0,
      expReward: 42,
      scoreReward: 185,
      minDepthRatio: 0.16,
      maxDepthRatio: 0.68,
      primaryColor: Color(0xFF40C4FF),
    ),
    _CreatureTemplate(
      id: 'harpoon_hunter',
      nameVi: 'Thợ Săn Bắn Lao',
      nameEn: 'Harpoon Diver Hunter',
      tier: 2,
      assetPath: 'assets/images/creatures/game_harpoon_hunter.png',
      assetFacesRight: false,
      aspectRatio: 1.65,
      radius: 32.0,
      speed: 82.0,
      waveAmplitude: 0.10,
      waveFrequency: 4.4,
      maxHp: 68.0,
      damage: 20.0,
      expReward: 62,
      scoreReward: 320,
      minDepthRatio: 0.15,
      maxDepthRatio: 0.72,
      isHuman: true,
      isHarpoonHunter: true,
      primaryColor: Color(0xFFFF1744),
    ),
    _CreatureTemplate(
      id: 'red_octopus',
      nameVi: 'Bạch Tuộc Đỏ Thái Bình Dương',
      nameEn: 'Pacific Red Octopus',
      tier: 2,
      assetPath: 'assets/images/creatures/game_red_octopus.png',
      assetFacesRight: true,
      aspectRatio: 2.85,
      radius: 35.0,
      speed: 98.0,
      waveAmplitude: 0.22,
      waveFrequency: 5.6,
      maxHp: 66.0,
      damage: 14.0,
      expReward: 45,
      scoreReward: 205,
      minDepthRatio: 0.22,
      maxDepthRatio: 0.82,
      primaryColor: Color(0xFFFF5252),
    ),
    _CreatureTemplate(
      id: 'anglerfish',
      nameVi: 'Cá Lồng Đèn Vực Sâu',
      nameEn: 'Abyssal Anglerfish',
      tier: 2,
      assetPath: 'assets/images/creatures/anglerfish.png',
      assetFacesRight: false,
      uvBounds: Rect.fromLTRB(0.213, 0.088, 0.923, 0.830),
      aspectRatio: 1.25,
      radius: 32.0,
      speed: 95.0,
      waveAmplitude: 0.14,
      waveFrequency: 6.0,
      maxHp: 68.0,
      damage: 18.0,
      expReward: 48,
      scoreReward: 220,
      minDepthRatio: 0.32,
      maxDepthRatio: 0.86,
      isAggressive: true,
      primaryColor: Color(0xFF00E5FF),
    ),
    _CreatureTemplate(
      id: 'black_dragonfish',
      nameVi: 'Cá Rồng Đen Phát Quang',
      nameEn: 'Black Dragonfish',
      tier: 2,
      assetPath: 'assets/images/creatures/black_dragonfish.png',
      assetFacesRight: true,
      uvBounds: Rect.fromLTRB(0.085, 0.173, 0.868, 0.822),
      aspectRatio: 1.55,
      radius: 34.0,
      speed: 106.0,
      waveAmplitude: 0.21,
      waveFrequency: 6.4,
      maxHp: 72.0,
      damage: 19.0,
      expReward: 50,
      scoreReward: 235,
      minDepthRatio: 0.36,
      maxDepthRatio: 0.90,
      isAggressive: true,
      primaryColor: Color(0xFFFF4081),
    ),
    _CreatureTemplate(
      id: 'vampire_squid',
      nameVi: 'Mực Ma Cà Rồng',
      nameEn: 'Vampire Squid',
      tier: 2,
      assetPath: 'assets/images/creatures/vampire_squid.png',
      assetFacesRight: false,
      uvBounds: Rect.fromLTRB(0.123, 0.248, 0.938, 0.817),
      aspectRatio: 1.55,
      radius: 34.0,
      speed: 100.0,
      waveAmplitude: 0.18,
      waveFrequency: 5.5,
      maxHp: 70.0,
      damage: 17.0,
      expReward: 48,
      scoreReward: 225,
      minDepthRatio: 0.34,
      maxDepthRatio: 0.88,
      primaryColor: Color(0xFFFF1744),
    ),

    // ── TIER 3: THỢ SĂN TỐC ĐỘ ──
    _CreatureTemplate(
      id: 'swordfish',
      nameVi: 'Cá Kiếm Đại Dương',
      nameEn: 'Blue Marlin Swordfish',
      tier: 3,
      assetPath: 'assets/images/creatures/game_swordfish.png',
      assetFacesRight: false,
      aspectRatio: 2.85,
      radius: 44.0,
      speed: 138.0,
      waveAmplitude: 0.17,
      waveFrequency: 7.4,
      maxHp: 120.0,
      damage: 28.0,
      expReward: 84,
      scoreReward: 400,
      minDepthRatio: 0.16,
      maxDepthRatio: 0.70,
      isAggressive: true,
      primaryColor: Color(0xFF448AFF),
    ),
    _CreatureTemplate(
      id: 'hammerhead_hunter',
      nameVi: 'Cá Mập Đầu Búa Săn Mồi',
      nameEn: 'Great Hammerhead Shark',
      tier: 3,
      assetPath: 'assets/images/creatures/game_hammerhead_shark.png',
      assetFacesRight: false,
      aspectRatio: 2.59,
      radius: 46.0,
      speed: 124.0,
      waveAmplitude: 0.17,
      waveFrequency: 6.5,
      maxHp: 130.0,
      damage: 30.0,
      expReward: 90,
      scoreReward: 440,
      minDepthRatio: 0.18,
      maxDepthRatio: 0.75,
      isAggressive: true,
      primaryColor: Color(0xFF26A69A),
    ),
    _CreatureTemplate(
      id: 'oarfish',
      nameVi: 'Cá Mái Chèo Khổng Lồ',
      nameEn: 'Giant Oarfish',
      tier: 3,
      assetPath: 'assets/images/creatures/oarfish.png',
      assetFacesRight: true,
      uvBounds: Rect.fromLTRB(0.037, 0.307, 0.885, 0.692),
      aspectRatio: 2.40,
      radius: 46.0,
      speed: 102.0,
      waveAmplitude: 0.25,
      waveFrequency: 6.2,
      maxHp: 125.0,
      damage: 25.0,
      expReward: 86,
      scoreReward: 420,
      minDepthRatio: 0.28,
      maxDepthRatio: 0.84,
      primaryColor: Color(0xFF80D8FF),
    ),
    _CreatureTemplate(
      id: 'giant_squid',
      nameVi: 'Mực Khổng Lồ Architeuthis',
      nameEn: 'Architeuthis Giant Squid',
      tier: 3,
      assetPath: 'assets/images/creatures/giant_squid.png',
      assetFacesRight: true,
      uvBounds: Rect.fromLTRB(0.067, 0.228, 0.943, 0.965),
      aspectRatio: 1.65,
      radius: 48.0,
      speed: 116.0,
      waveAmplitude: 0.20,
      waveFrequency: 5.8,
      maxHp: 145.0,
      damage: 32.0,
      expReward: 102,
      scoreReward: 500,
      minDepthRatio: 0.32,
      maxDepthRatio: 0.90,
      isAggressive: true,
      primaryColor: Color(0xFFFF9100),
    ),

    // ── TIER 4: SÁT THỦ ĐẠI DƯƠNG ──
    _CreatureTemplate(
      id: 'greenland_enemy',
      nameVi: 'Cá Mập Bắc Cực',
      nameEn: 'Greenland Sleeper Shark',
      tier: 4,
      assetPath: 'assets/images/creatures/greenland_shark.png',
      assetFacesRight: false,
      uvBounds: Rect.fromLTRB(0.128, 0.342, 0.928, 0.603),
      aspectRatio: 2.95,
      radius: 56.0,
      speed: 106.0,
      waveAmplitude: 0.16,
      waveFrequency: 5.4,
      maxHp: 220.0,
      damage: 42.0,
      expReward: 155,
      scoreReward: 760,
      minDepthRatio: 0.36,
      maxDepthRatio: 0.92,
      isAggressive: true,
      primaryColor: Color(0xFF26A69A),
    ),
    _CreatureTemplate(
      id: 'humpback_whale',
      nameVi: 'Cá Voi Lưng Gù',
      nameEn: 'Humpback Whale',
      tier: 4,
      assetPath: 'assets/images/creatures/humpback_whale.png',
      assetFacesRight: false,
      uvBounds: Rect.fromLTRB(0.155, 0.368, 0.924, 0.788),
      aspectRatio: 2.45,
      radius: 64.0,
      speed: 90.0,
      waveAmplitude: 0.14,
      waveFrequency: 4.5,
      maxHp: 260.0,
      damage: 38.0,
      expReward: 180,
      scoreReward: 880,
      minDepthRatio: 0.18,
      maxDepthRatio: 0.74,
      primaryColor: Color(0xFF4FC3F7),
    ),
    _CreatureTemplate(
      id: 'orca_hunter',
      nameVi: 'Cá Voi Sát Thủ Orca',
      nameEn: 'Apex Killer Whale',
      tier: 4,
      assetPath: 'assets/images/creatures/orca.png',
      assetFacesRight: false,
      uvBounds: Rect.fromLTRB(0.089, 0.243, 0.744, 0.663),
      aspectRatio: 2.15,
      radius: 62.0,
      speed: 126.0,
      waveAmplitude: 0.16,
      waveFrequency: 5.8,
      maxHp: 250.0,
      damage: 46.0,
      expReward: 190,
      scoreReward: 950,
      minDepthRatio: 0.18,
      maxDepthRatio: 0.78,
      isAggressive: true,
      primaryColor: Color(0xFFFFD740),
    ),

    // ── TIER 5: QUÁI VẬT CỔ ĐẠI ──
    _CreatureTemplate(
      id: 'the_bloop_boss',
      nameVi: 'Quái Vật Sóng Âm The Bloop',
      nameEn: 'The Bloop Behemoth',
      tier: 5,
      assetPath: 'assets/images/creatures/the_bloop.png',
      assetFacesRight: false,
      uvBounds: Rect.fromLTRB(0.142, 0.003, 0.958, 0.865),
      aspectRatio: 1.55,
      radius: 72.0,
      speed: 104.0,
      waveAmplitude: 0.15,
      waveFrequency: 5.0,
      maxHp: 370.0,
      damage: 58.0,
      expReward: 280,
      scoreReward: 1450,
      minDepthRatio: 0.45,
      maxDepthRatio: 0.95,
      isAggressive: true,
      primaryColor: Color(0xFF7E57C2),
    ),
    _CreatureTemplate(
      id: 'megalodon_boss',
      nameVi: 'Chúa Tể Megalodon',
      nameEn: 'Apex Megalodon',
      tier: 5,
      assetPath: 'assets/images/creatures/megalodon.png',
      assetFacesRight: false,
      uvBounds: Rect.fromLTRB(0.033, 0.258, 0.985, 0.713),
      aspectRatio: 2.15,
      radius: 76.0,
      speed: 124.0,
      waveAmplitude: 0.17,
      waveFrequency: 5.6,
      maxHp: 410.0,
      damage: 65.0,
      expReward: 320,
      scoreReward: 1700,
      minDepthRatio: 0.45,
      maxDepthRatio: 0.96,
      isAggressive: true,
      primaryColor: Color(0xFFFF5252),
    ),
    _CreatureTemplate(
      id: 'kraken_boss',
      nameVi: 'Quái Vật Bạch Tuộc Kraken',
      nameEn: 'Abyssal Kraken',
      tier: 5,
      assetPath: 'assets/images/creatures/kraken.png',
      assetFacesRight: false,
      uvBounds: Rect.fromLTRB(0.040, 0.054, 1.000, 1.000),
      aspectRatio: 1.45,
      radius: 75.0,
      speed: 102.0,
      waveAmplitude: 0.18,
      waveFrequency: 5.2,
      maxHp: 400.0,
      damage: 62.0,
      expReward: 310,
      scoreReward: 1650,
      minDepthRatio: 0.55,
      maxDepthRatio: 0.98,
      isAggressive: true,
      primaryColor: Color(0xFFFF1744),
    ),

    // ── TIER 6: THẦN THOẠI ĐÁY VỰC ──
    _CreatureTemplate(
      id: 'reaper_boss',
      nameVi: 'Reaper Leviathan',
      nameEn: 'Reaper Leviathan',
      tier: 6,
      assetPath: 'assets/images/creatures/reaper_leviathan.png',
      assetFacesRight: false,
      uvBounds: Rect.fromLTRB(0.057, 0.345, 0.960, 0.682),
      aspectRatio: 2.68,
      radius: 90.0,
      speed: 132.0,
      waveAmplitude: 0.22,
      waveFrequency: 6.2,
      maxHp: 560.0,
      damage: 80.0,
      expReward: 490,
      scoreReward: 2900,
      minDepthRatio: 0.62,
      maxDepthRatio: 0.98,
      isAggressive: true,
      primaryColor: Color(0xFFD50000),
    ),
    _CreatureTemplate(
      id: 'lagiacrus_boss',
      nameVi: 'Hải Long Điện Lagiacrus',
      nameEn: 'Thunder Leviathan Lagiacrus',
      tier: 6,
      assetPath: 'assets/images/creatures/lagiacrus.png',
      assetFacesRight: false,
      uvBounds: Rect.fromLTRB(0.033, 0.293, 0.972, 0.762),
      aspectRatio: 2.15,
      radius: 88.0,
      speed: 128.0,
      waveAmplitude: 0.21,
      waveFrequency: 6.0,
      maxHp: 540.0,
      damage: 76.0,
      expReward: 470,
      scoreReward: 2700,
      minDepthRatio: 0.60,
      maxDepthRatio: 0.98,
      isAggressive: true,
      primaryColor: Color(0xFF00E5FF),
    ),
    _CreatureTemplate(
      id: 'ancient_leviathan',
      nameVi: 'Thủy Tổ Hải Vương Leviathan',
      nameEn: 'Primordial Sea Dragon Leviathan',
      tier: 6,
      assetPath: 'assets/images/creatures/leviathan.png',
      assetFacesRight: false,
      uvBounds: Rect.fromLTRB(0.042, 0.158, 0.972, 0.805),
      aspectRatio: 1.65,
      radius: 86.0,
      speed: 126.0,
      waveAmplitude: 0.20,
      waveFrequency: 5.8,
      maxHp: 550.0,
      damage: 78.0,
      expReward: 480,
      scoreReward: 2800,
      minDepthRatio: 0.62,
      maxDepthRatio: 0.98,
      isAggressive: true,
      primaryColor: Color(0xFF00E676),
    ),

    // ── TIER 7-11: BOSS TỐI THƯỢNG VỰC SÂU (Ghost Leviathan, Jormungandr, Mosasaurus, Godzilla, Void Emperor) ──
    _CreatureTemplate(
      id: 'ghost_leviathan_boss',
      nameVi: 'Thủy Quái Bóng Ma Ghost Leviathan',
      nameEn: 'Phantom Ghost Leviathan',
      tier: 7,
      assetPath: 'assets/images/creatures/ghost_leviathan.png',
      assetFacesRight: false,
      uvBounds: Rect.fromLTRB(0.070, 0.076, 1.000, 1.000),
      aspectRatio: 2.15,
      radius: 94.0,
      speed: 136.0,
      waveAmplitude: 0.22,
      waveFrequency: 6.2,
      maxHp: 720.0,
      damage: 94.0,
      expReward: 620,
      scoreReward: 3900,
      minDepthRatio: 0.52,
      maxDepthRatio: 0.96,
      isAggressive: true,
      primaryColor: Color(0xFF00E5FF),
    ),
    _CreatureTemplate(
      id: 'jormungandr_boss',
      nameVi: 'Rắn Biển Thần Thoại Jormungandr',
      nameEn: 'World Serpent Jormungandr',
      tier: 8,
      assetPath: 'assets/images/creatures/jormungandr.png',
      assetFacesRight: false,
      uvBounds: Rect.fromLTRB(0.025, 0.145, 0.980, 0.875),
      aspectRatio: 1.55,
      radius: 104.0,
      speed: 132.0,
      waveAmplitude: 0.21,
      waveFrequency: 5.8,
      maxHp: 940.0,
      damage: 112.0,
      expReward: 820,
      scoreReward: 5200,
      minDepthRatio: 0.58,
      maxDepthRatio: 0.97,
      isAggressive: true,
      primaryColor: Color(0xFF00E676),
    ),
    _CreatureTemplate(
      id: 'mosasaurus_titan',
      nameVi: 'Khủng Long Biển Mosasaurus',
      nameEn: 'Prehistoric Mosasaurus',
      tier: 9,
      assetPath: 'assets/images/creatures/game_mosasaurus.png',
      assetFacesRight: false,
      aspectRatio: 3.40,
      radius: 110.0,
      speed: 140.0,
      waveAmplitude: 0.21,
      waveFrequency: 6.0,
      maxHp: 1120.0,
      damage: 128.0,
      expReward: 1020,
      scoreReward: 6800,
      minDepthRatio: 0.62,
      maxDepthRatio: 0.98,
      isAggressive: true,
      primaryColor: Color(0xFF40C4FF),
    ),
    _CreatureTemplate(
      id: 'godzilla_kaiju',
      nameVi: 'Hải Quái Nguyên Tử Godzilla',
      nameEn: 'Atomic Kaiju Godzilla',
      tier: 10,
      assetPath: 'assets/images/creatures/game_godzilla_swim.png',
      assetFacesRight: false,
      aspectRatio: 2.90,
      radius: 122.0,
      speed: 134.0,
      waveAmplitude: 0.19,
      waveFrequency: 5.4,
      maxHp: 1450.0,
      damage: 155.0,
      expReward: 1350,
      scoreReward: 8900,
      minDepthRatio: 0.68,
      maxDepthRatio: 0.98,
      isAggressive: true,
      primaryColor: Color(0xFF2979FF),
    ),
    _CreatureTemplate(
      id: 'void_cthulhu_god',
      nameVi: 'Hoàng Đế Vực Thẳm Void Leviathan',
      nameEn: 'Abyssal Void Emperor',
      tier: 11,
      assetPath: 'assets/images/creatures/game_void_cthulhu.png',
      assetFacesRight: false,
      aspectRatio: 3.40,
      radius: 134.0,
      speed: 142.0,
      waveAmplitude: 0.22,
      waveFrequency: 5.6,
      maxHp: 1920.0,
      damage: 185.0,
      expReward: 1850,
      scoreReward: 12500,
      minDepthRatio: 0.72,
      maxDepthRatio: 0.98,
      isAggressive: true,
      primaryColor: Color(0xFF00F0FF),
    ),
  ];

  late final Ticker _gameTicker;
  final ValueNotifier<int> _frameNotifier = ValueNotifier<int>(0);
  final math.Random _rng = math.Random();
  final Map<String, _LoadedSpriteMesh> _loadedMeshes = {};

  Duration _lastElapsed = Duration.zero;
  bool _isPaused = false;
  bool _isGameOver = false;
  bool _showHelpOverlay = false;

  // Màn chơi hiện tại (Map 1: Vịnh San Hô | Map 2: Rãnh Mariana Dung Nham)
  _GameStageMap _currentMap = _GameStageMap.coralBay;
  bool _map2UnlockedBannerShown = false;

  // Trạng thái & Chuỗi Xương Sống 16 Đốt của Cá Mập Người Chơi
  int _stageIndex = 0;
  double _playerX = worldWidth * 0.5;
  double _playerY = 460.0;
  double _playerVx = 120.0;
  double _playerVy = 0.0;
  double _playerHeadingAngle = 0.0;
  bool _playerFacingRight = true;
  double _playerDorsalFlip = 1.0;
  double _playerSwimPhase = 0.0;
  bool _wasAirborne = false;
  final List<Offset> _playerSpine =
      List<Offset>.filled(kPlayerSpineJoints, Offset.zero);

  double _hp = 100.0;
  double _stamina = 100.0;
  int _exp = 0;
  int _score = 0;
  int _highScore = 0;
  int _fishEatenCount = 0;
  int _nextSchoolGroupId = 1;

  // Combo, Gold Rush & Fury (Cuồng Nộ)
  int _comboCount = 0;
  double _comboTimer = 0.0;
  double _furyCharge = 0.0;
  double _frenzyTimer = 0.0;
  bool get _isGoldRushActive => _comboCount >= 6 || _frenzyTimer > 0;

  // Hiệu ứng kích thích tâm lý người chơi (Screen Shake & Low-HP Pulse)
  double _screenShakeTimer = 0.0;
  double _screenShakeIntensity = 0.0;
  double _lowHpPulsePhase = 0.0;

  // Kỹ năng chủ động (Cân bằng Cooldown khó hơn)
  bool _isBoosting = false;
  double _biteAnimTimer = 0.0;
  double _biteCooldown = 0.0;
  double _vortexTimer = 0.0;
  double _vortexCooldown = 0.0;
  double _roarCooldown = 0.0;
  double _invulnerableTimer = 0.0;
  String? _bannerAnnouncement;
  double _bannerTimer = 0.0;

  // Điều khiển Joystick bên trái
  Offset _joystickDelta = Offset.zero;
  Offset? _joystickOrigin;
  Offset? _joystickCurrent;

  // Danh sách thực thể, Thuyền/Bè mặt biển, Mũi lao (Harpoon) & Vật phẩm
  final List<_SeaEntity> _entities = [];
  final List<_SurfaceVessel> _vessels = [];
  final List<_HarpoonProjectile> _harpoons = [];
  final List<_OceanPickup> _pickups = [];
  final List<_GameParticle> _particles = [];
  final List<_FloatingTextPopup> _popups = [];
  final List<_ShockwaveRing> _shockwaves = [];

  _SharkEvolutionStage get _currentStage => _evolutionStages[_stageIndex];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lockLandscapeMode();
    _loadHighScore();
    _preloadSprites();
    _initOceanWorld(map: _GameStageMap.coralBay);

    _gameTicker = createTicker(_onTick)..start();
  }

  Future<void> _lockLandscapeMode() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _restorePortraitMode() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  Future<void> _loadHighScore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _highScore = prefs.getInt(_highScoreKey) ?? 0;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveHighScoreIfNeeded() async {
    if (_score > _highScore) {
      _highScore = _score;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_highScoreKey, _highScore);
      } catch (_) {}
    }
  }

  Future<void> _preloadSprites() async {
    final Set<String> paths = {
      for (final s in _evolutionStages) s.assetPath,
      for (final c in _speciesCatalog) c.assetPath,
      'assets/images/creatures/game_fishing_boat.png',
      'assets/images/creatures/game_wooden_raft.png',
    };

    for (final path in paths) {
      try {
        final ByteData data = await rootBundle.load(path);
        final ui.Codec codec = await ui.instantiateImageCodec(
          data.buffer.asUint8List(),
          targetWidth: 440,
        );
        final ui.FrameInfo frame = await codec.getNextFrame();
        _loadedMeshes[path] = _LoadedSpriteMesh(image: frame.image);
      } catch (_) {}
    }
  }

  void _initPlayerSpine() {
    final double bodyLen = _currentStage.baseRadius * 2.75;
    final double segLen = bodyLen / (kPlayerSpineJoints - 1);
    final double dir = _playerFacingRight ? 1.0 : -1.0;
    final Offset head = Offset(_playerX + dir * bodyLen * 0.44, _playerY);
    for (int i = 0; i < kPlayerSpineJoints; i++) {
      _playerSpine[i] = Offset(head.dx - dir * i * segLen, head.dy);
    }
  }

  void _initOceanWorld({required _GameStageMap map, bool preserveProgress = false}) {
    _currentMap = map;
    if (!preserveProgress) {
      _stageIndex = 0;
      _exp = 0;
      _score = 0;
      _fishEatenCount = 0;
      _comboCount = 0;
      _comboTimer = 0.0;
      _furyCharge = 25.0;
      _frenzyTimer = 0.0;
      _map2UnlockedBannerShown = false;
    }

    _playerX = worldWidth * 0.5;
    _playerY = seaSurfaceY + 210.0;
    _playerVx = 95.0;
    _playerVy = 0.0;
    _playerHeadingAngle = 0.0;
    _playerFacingRight = true;
    _playerDorsalFlip = 1.0;
    _wasAirborne = false;
    _initPlayerSpine();

    _hp = _currentStage.maxHp;
    _stamina = 100.0;
    _biteAnimTimer = 0.0;
    _biteCooldown = 0.0;
    _vortexTimer = 0.0;
    _vortexCooldown = 0.0;
    _roarCooldown = 0.0;
    _invulnerableTimer = 2.0;
    _isGameOver = false;
    _isPaused = false;

    _entities.clear();
    _vessels.clear();
    _harpoons.clear();
    _pickups.clear();
    _particles.clear();
    _popups.clear();
    _shockwaves.clear();

    // Khởi tạo Thuyền đánh cá & Bè gỗ trên mặt biển (Màn 1 nhiều thuyền bè & người bơi hơn)
    final int vesselCount = map == _GameStageMap.coralBay ? 7 : 4;
    for (int i = 0; i < vesselCount; i++) {
      final bool isBoat = i % 2 == 0;
      final double vx = (i % 2 == 0 ? 1.0 : -1.0) * (isBoat ? 42.0 : 28.0);
      _vessels.add(
        _SurfaceVessel(
          isFishingBoat: isBoat,
          x: 320.0 + i * ((worldWidth - 640.0) / vesselCount),
          vx: vx,
          width: isBoat ? 220.0 : 165.0,
          height: isBoat ? 150.0 : 100.0,
          maxHp: isBoat ? 260.0 : 145.0, // Thuyền trâu lì hơn, cần lao đớp nhiều phát!
          passengersCount: isBoat ? 3 : 2,
          bobPhase: _rng.nextDouble() * math.pi * 2,
        ),
      );
    }

    // Khởi tạo quần thể sinh vật (Màn 2 nhiều Thợ săn & Quái vật lớn hơn!)
    final int targetEntities = map == _GameStageMap.coralBay ? 66 : 74;
    while (_entities.length < targetEntities) {
      _spawnRandomEntityOrSchool(avoidPlayer: true);
    }

    // Khởi tạo vật phẩm & Thủy lôi (Màn 2 nhiều thủy lôi hơn)
    final int pickupCount = map == _GameStageMap.coralBay ? 15 : 22;
    for (int i = 0; i < pickupCount; i++) {
      _spawnRandomPickup();
    }
  }

  void _switchGameMap(_GameStageMap targetMap) {
    if (_currentMap == targetMap) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _initOceanWorld(map: targetMap, preserveProgress: true);
      final bool isVi = AppStrings.of(context).languageCode == 'vi';
      _bannerAnnouncement = targetMap == _GameStageMap.volcanicAbyss
          ? (isVi
              ? 'MÀN 2: RÃNH MARIANA & HỎA NGỤC DUNG NHAM (x1.6 ĐIỂM!)'
              : 'STAGE 2: MARIANA VOLCANIC ABYSS (x1.6 SCORE!)')
          : (isVi
              ? 'MÀN 1: VỊNH SAN HÔ & THUYỀN ĐÁNH CÁ MẶT BIỂN'
              : 'STAGE 1: CORAL BAY & FISHING BOATS');
      _bannerTimer = 3.2;
    });
  }

  void _spawnRandomEntityOrSchool({bool avoidPlayer = false}) {
    final bool isMap2 = _currentMap == _GameStageMap.volcanicAbyss;
    final double roll = _rng.nextDouble();
    int targetTier;

    if (isMap2) {
      // Màn 2 khó hơn: xuất hiện đầy đủ từ Tier 1 đến Siêu Boss Tier 7-11
      if (roll < 0.22) {
        targetTier = 1;
      } else if (roll < 0.42) {
        targetTier = 2;
      } else if (roll < 0.58) {
        targetTier = 3;
      } else if (roll < 0.71) {
        targetTier = 4;
      } else if (roll < 0.81) {
        targetTier = 5;
      } else if (roll < 0.88) {
        targetTier = 6;
      } else if (roll < 0.93) {
        targetTier = 7;
      } else if (roll < 0.96) {
        targetTier = 8;
      } else if (roll < 0.982) {
        targetTier = 9;
      } else if (roll < 0.994) {
        targetTier = 10;
      } else {
        targetTier = 11;
      }
    } else {
      if (roll < 0.40) {
        targetTier = 1;
      } else if (roll < 0.65) {
        targetTier = 2;
      } else if (roll < 0.79) {
        targetTier = 3;
      } else if (roll < 0.89) {
        targetTier = 4;
      } else if (roll < 0.95) {
        targetTier = 5;
      } else if (roll < 0.98) {
        targetTier = 6;
      } else {
        targetTier = 7;
      }
    }

    final candidates =
        _speciesCatalog.where((c) => c.tier == targetTier).toList();
    final template = candidates[_rng.nextInt(candidates.length)];

    double baseX = 120.0 + _rng.nextDouble() * (worldWidth - 240.0);
    double minY = math.max(
        seaSurfaceY + 18.0, template.minDepthRatio * worldHeight);
    double maxY =
        math.min(worldHeight - 85.0, template.maxDepthRatio * worldHeight);
    if (maxY <= minY) maxY = minY + 40.0;
    double baseY = minY + _rng.nextDouble() * (maxY - minY);

    if (avoidPlayer) {
      final double dx = baseX - _playerX;
      final double dy = baseY - _playerY;
      if (dx * dx + dy * dy < 420.0 * 420.0 &&
          template.tier > _currentStage.level) {
        baseX = (_playerX + 700.0) % (worldWidth - 240.0) + 120.0;
      }
    }

    final double dir = _rng.nextBool() ? 1.0 : -1.0;
    final double mapSpeedMult = isMap2 ? 1.15 : 1.0;
    final double baseVx =
        dir * template.speed * mapSpeedMult * (0.8 + _rng.nextDouble() * 0.35);
    final double baseVy = (_rng.nextDouble() - 0.5) * template.speed * 0.25;
    final int groupId = _nextSchoolGroupId++;
    final int count = template.schoolSize > 1
        ? (2 + _rng.nextInt(template.schoolSize))
        : 1;

    for (int k = 0; k < count; k++) {
      final double ox = (k == 0) ? 0.0 : (_rng.nextDouble() - 0.5) * 95.0;
      final double oy = (k == 0) ? 0.0 : (_rng.nextDouble() - 0.5) * 65.0;
      _entities.add(
        _SeaEntity(
          template: template,
          schoolGroupId: groupId,
          x: (baseX + ox).clamp(80.0, worldWidth - 80.0),
          y: (baseY + oy).clamp(seaSurfaceY + 12.0, worldHeight - 85.0),
          vx: baseVx * (0.92 + _rng.nextDouble() * 0.16),
          vy: baseVy,
          swimPhase: _rng.nextDouble() * math.pi * 2,
        ),
      );
    }
  }

  void _spawnRandomPickup() {
    final bool isMap2 = _currentMap == _GameStageMap.volcanicAbyss;
    final double r = _rng.nextDouble();
    final _PickupType type;
    double minY = seaSurfaceY + 60.0;
    double maxY = worldHeight - 120.0;
    double radius = 16.0;

    // Giảm tỷ lệ ngọc hồi máu, tăng tỷ lệ thủy lôi để game thử thách hơn!
    if (r < (isMap2 ? 0.22 : 0.30)) {
      type = _PickupType.healingPearl;
      radius = 15.0;
    } else if (r < 0.52) {
      type = _PickupType.goldenStar;
      radius = 16.0;
    } else {
      type = _PickupType.navalMine;
      minY = seaSurfaceY + 180.0;
      radius = 25.0;
    }

    _pickups.add(
      _OceanPickup(
        type: type,
        x: 140.0 + _rng.nextDouble() * (worldWidth - 280.0),
        y: minY + _rng.nextDouble() * (maxY - minY),
        radius: radius,
        lifeTimer: 999.0,
        pulsePhase: _rng.nextDouble() * math.pi * 2,
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (!_isGameOver && !_isPaused) {
        setState(() {
          _isPaused = true;
        });
      }
    }
  }

  void _onTick(Duration elapsed) {
    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }
    double dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;
    if (dt <= 0.0 || dt > 0.1) dt = 0.016;

    if (!_isPaused && !_isGameOver && !_showHelpOverlay) {
      _updateGameWorld(dt);
      _frameNotifier.value++;
    }
  }

  void _triggerScreenShake(double intensity, double duration) {
    // Giới hạn rung màn hình êm dịu (tối đa 4.5px và 0.16s) để không gây mỏi mắt hay khó chịu
    _screenShakeIntensity = math.max(_screenShakeIntensity, math.min(intensity, 4.5));
    _screenShakeTimer = math.max(_screenShakeTimer, math.min(duration, 0.16));
  }

  void _updateSpineChain({
    required List<Offset> spine,
    required double centerX,
    required double centerY,
    required double headingAngle,
    required double bodyLength,
    required double dt,
  }) {
    final int n = spine.length;
    final double segLen = bodyLength / (n - 1);
    final double cosH = math.cos(headingAngle);
    final double sinH = math.sin(headingAngle);

    final Offset targetHead = Offset(
      centerX + cosH * (bodyLength * 0.44),
      centerY + sinH * (bodyLength * 0.44),
    );
    spine[0] = targetHead;

    final double idealBackAngle = headingAngle + math.pi;
    double prevSegAngle = idealBackAngle;
    for (int i = 1; i < n; i++) {
      final Offset prev = spine[i - 1];
      final Offset curr = spine[i];
      final double dx = curr.dx - prev.dx;
      final double dy = curr.dy - prev.dy;

      double segAngle = (dx.abs() < 0.001 && dy.abs() < 0.001)
          ? prevSegAngle
          : math.atan2(dy, dx);

      final double diffToIdeal = _normalizeAngle(idealBackAngle - segAngle);
      segAngle +=
          diffToIdeal * (dt * (4.2 + (1.0 - i / n) * 4.5)).clamp(0.0, 0.45);

      final double bendFromPrev = _normalizeAngle(segAngle - prevSegAngle);
      const double maxBendPerJoint = 0.24;
      if (bendFromPrev.abs() > maxBendPerJoint) {
        segAngle = prevSegAngle + maxBendPerJoint * bendFromPrev.sign;
      }

      spine[i] = Offset(
        prev.dx + math.cos(segAngle) * segLen,
        prev.dy + math.sin(segAngle) * segLen,
      );
      prevSegAngle = segAngle;
    }
  }

  static double _normalizeAngle(double a) {
    while (a > math.pi) {
      a -= math.pi * 2;
    }
    while (a < -math.pi) {
      a += math.pi * 2;
    }
    return a;
  }

  void _updateGameWorld(double dt) {
    final stage = _currentStage;
    final bool isMap2 = _currentMap == _GameStageMap.volcanicAbyss;

    // 1. Timers & Screen Shake
    if (_screenShakeTimer > 0) {
      _screenShakeTimer = math.max(0.0, _screenShakeTimer - dt);
      if (_screenShakeTimer <= 0) _screenShakeIntensity = 0.0;
    }
    _lowHpPulsePhase += dt * 7.5;
    if (_biteAnimTimer > 0) _biteAnimTimer = math.max(0.0, _biteAnimTimer - dt);
    if (_biteCooldown > 0) _biteCooldown = math.max(0.0, _biteCooldown - dt);
    if (_vortexTimer > 0) _vortexTimer = math.max(0.0, _vortexTimer - dt);
    if (_vortexCooldown > 0) {
      _vortexCooldown = math.max(0.0, _vortexCooldown - dt);
    }
    if (_roarCooldown > 0) _roarCooldown = math.max(0.0, _roarCooldown - dt);
    if (_invulnerableTimer > 0) {
      _invulnerableTimer = math.max(0.0, _invulnerableTimer - dt);
    }
    if (_frenzyTimer > 0) _frenzyTimer = math.max(0.0, _frenzyTimer - dt);
    if (_bannerTimer > 0) {
      _bannerTimer = math.max(0.0, _bannerTimer - dt);
      if (_bannerTimer <= 0 && mounted) {
        setState(() {
          _bannerAnnouncement = null;
        });
      }
    }
    if (_comboTimer > 0) {
      _comboTimer -= dt;
      if (_comboTimer <= 0) {
        _comboCount = 0;
      }
    }

    // 2. Cân bằng Độ Đói (Hunger Drain) & Thể lực (Stamina) thách thức hơn!
    final bool frenzyActive = _frenzyTimer > 0;
    final bool canBoost = _isBoosting && (_stamina > 2.0 || frenzyActive);
    if (canBoost && !frenzyActive) {
      _stamina = math.max(0.0, _stamina - 36.0 * dt);
      if (_stamina <= 0.5) {
        _isBoosting = false;
      }
    } else {
      _stamina = math.min(100.0, _stamina + 13.5 * dt);
    }

    if (!frenzyActive) {
      final double hungerRate =
          (2.85 + _stageIndex * 0.65) * (isMap2 ? 1.38 : 1.0);
      _hp = math.max(0.0, _hp - hungerRate * dt);
      if (_hp <= 0.0) {
        _triggerGameOver();
        return;
      }
    } else {
      _hp = math.min(stage.maxHp, _hp + 8.0 * dt);
    }

    // 3. Vật lý Cá Mập Người Chơi (Hỗ trợ Nhảy Vượt Mặt Biển - Airborne Breach!)
    final bool isAirborne = _playerY < seaSurfaceY;
    double maxSpeed = 250.0 + _stageIndex * 18.0;
    if (canBoost) maxSpeed *= 1.92;
    if (frenzyActive) maxSpeed *= 1.35;
    if (_biteAnimTimer > 0.12) maxSpeed *= 1.48;

    if (isAirborne) {
      // Trên không trung (nhảy vượt sóng lên húc thuyền!): Trọng lực kéo cá rơi xuống biển
      _playerVy += 580.0 * dt;
      _playerVx += _joystickDelta.dx * 160.0 * dt;
      _playerVx *= math.pow(0.85, dt).toDouble();
    } else {
      final double inputMag = _joystickDelta.distance.clamp(0.0, 1.0);
      if (inputMag > 0.04) {
        final double tailThrust = 1.0 + 0.08 * math.cos(_playerSwimPhase * 2.0);
        final double targetVx = _joystickDelta.dx * maxSpeed * tailThrust;
        final double targetVy = _joystickDelta.dy * maxSpeed * tailThrust;
        _playerVx =
            ui.lerpDouble(_playerVx, targetVx, (dt * 7.5).clamp(0.0, 1.0))!;
        _playerVy =
            ui.lerpDouble(_playerVy, targetVy, (dt * 7.5).clamp(0.0, 1.0))!;
      } else {
        final double waterDrag = math.pow(0.18, dt).toDouble();
        _playerVx *= waterDrag;
        _playerVy *= waterDrag;
      }
    }

    _playerX = (_playerX + _playerVx * dt).clamp(70.0, worldWidth - 70.0);
    _playerY = (_playerY + _playerVy * dt).clamp(35.0, worldHeight - 75.0);

    // Hiệu ứng Bọt Nước Bắn Tung Tóe khi Cá Mập vọt lên mặt biển hoặc rơi xuống nước!
    final bool nowAirborne = _playerY < seaSurfaceY;
    if (nowAirborne != _wasAirborne) {
      _wasAirborne = nowAirborne;
      _spawnBloodAndBubbles(
        _playerX,
        seaSurfaceY,
        const Color(0xFFE0F7FA),
        count: 18,
      );
      HapticFeedback.lightImpact();
    }

    // Màn 2: Mạch nước phun nhiệt núi lửa dưới đáy biển gây bỏng nếu chạm phải!
    if (isMap2 && _playerY > worldHeight - 115.0 && !frenzyActive) {
      for (double vx = 380.0; vx < worldWidth; vx += 650.0) {
        if ((_playerX - vx).abs() < 46.0 && _invulnerableTimer <= 0) {
          _hp = math.max(0.0, _hp - 18.0);
          _invulnerableTimer = 0.7;
          _playerVy = -260.0;
          _triggerScreenShake(7.0, 0.25);
          _popups.add(
            _FloatingTextPopup(
              text: AppStrings.of(context).languageCode == 'vi'
                  ? 'BỎNG DUNG NHAM! -18 HP'
                  : 'LAVA BURN! -18 HP',
              x: _playerX,
              y: _playerY - 40.0,
              color: const Color(0xFFFF3D00),
            ),
          );
          if (_hp <= 0) {
            _triggerGameOver();
            return;
          }
        }
      }
    }

    final double currentSpeed =
        math.sqrt(_playerVx * _playerVx + _playerVy * _playerVy);
    _playerSwimPhase += dt * (5.2 + currentSpeed * 0.036);

    if (_playerVx.abs() > 10.0) {
      _playerFacingRight = _playerVx > 0;
    }

    final double targetDorsal = _playerFacingRight ? 1.0 : -1.0;
    _playerDorsalFlip = ui.lerpDouble(
      _playerDorsalFlip,
      targetDorsal,
      (dt * 9.5).clamp(0.0, 1.0),
    )!;

    double desiredAngle;
    if (currentSpeed > 14.0) {
      desiredAngle = math.atan2(_playerVy, _playerVx);
      if (!isAirborne) {
        if (_playerFacingRight) {
          desiredAngle = desiredAngle.clamp(-0.78, 0.78);
        } else {
          double diff = _normalizeAngle(desiredAngle - math.pi);
          diff = diff.clamp(-0.78, 0.78);
          desiredAngle = _normalizeAngle(math.pi + diff);
        }
      }
    } else {
      desiredAngle = _playerFacingRight ? 0.0 : math.pi;
    }
    final double angleDelta =
        _normalizeAngle(desiredAngle - _playerHeadingAngle);
    _playerHeadingAngle = _normalizeAngle(
        _playerHeadingAngle + angleDelta * (dt * 10.5).clamp(0.0, 1.0));

    final double effectivePlayerRadius =
        stage.baseRadius * (frenzyActive ? 1.25 : 1.0);
    final double playerBodyLen = effectivePlayerRadius * 2.75;

    _updateSpineChain(
      spine: _playerSpine,
      centerX: _playerX,
      centerY: _playerY,
      headingAngle: _playerHeadingAngle,
      bodyLength: playerBodyLen,
      dt: dt,
    );

    if ((canBoost || frenzyActive) && !isAirborne && _rng.nextDouble() < 0.7) {
      final Offset tailTip = _playerSpine.last;
      _particles.add(
        _GameParticle(
          x: tailTip.dx + (_rng.nextDouble() - 0.5) * 12.0,
          y: tailTip.dy + (_rng.nextDouble() - 0.5) * 12.0,
          vx: -_playerVx * 0.25 + (_rng.nextDouble() - 0.5) * 35.0,
          vy: -20.0 + (_rng.nextDouble() - 0.5) * 35.0,
          radius: 2.8 + _rng.nextDouble() * 4.2,
          alpha: 0.85,
          decay: 1.7,
          color: frenzyActive
              ? const Color(0xFFFF1744)
              : const Color(0xFF80D8FF),
        ),
      );
    }

    final Offset playerMouth = Offset(
      (_playerSpine[0].dx + _playerSpine[1].dx) * 0.5,
      (_playerSpine[0].dy + _playerSpine[1].dy) * 0.5,
    );

    // 4. Cập nhật THUYỀN ĐÁNH CÁ & BÈ GỖ TRÊN MẶT BIỂN (Bắn lao & Húc vỡ thuyền!)
    for (final v in _vessels) {
      v.bobPhase += dt * 2.6;
      if (v.hitFlashTimer > 0) v.hitFlashTimer = math.max(0.0, v.hitFlashTimer - dt);

      if (v.isDestroyed) {
        v.respawnTimer -= dt;
        if (v.respawnTimer <= 0) {
          v.isDestroyed = false;
          v.hp = v.maxHp;
          v.passengersCount = v.isFishingBoat ? 3 : 2;
          v.x = (_playerX + 1200.0) % (worldWidth - 400.0) + 200.0;
        }
        continue;
      }

      v.x += v.vx * dt;
      if (v.x < 180.0) {
        v.x = 180.0;
        v.vx = v.vx.abs();
      } else if (v.x > worldWidth - 180.0) {
        v.x = worldWidth - 180.0;
        v.vx = -v.vx.abs();
      }

      final double vesselY = seaSurfaceY - v.height * 0.12 + math.sin(v.bobPhase) * 5.0;
      final double dxV = _playerX - v.x;
      final double dyV = _playerY - vesselY;
      final double distV = math.sqrt(dxV * dxV + dyV * dyV);

      // Thợ săn trên thuyền bắn mũi lao xuống nếu cá mập bơi gần mặt biển!
      v.shootCooldown -= dt;
      if (v.shootCooldown <= 0 && distV < 430.0 && _playerY > seaSurfaceY - 40.0) {
        v.shootCooldown = (v.isFishingBoat ? 2.2 : 3.0) * (isMap2 ? 0.8 : 1.0);
        final double d = math.max(1.0, distV);
        _harpoons.add(
          _HarpoonProjectile(
            x: v.x,
            y: vesselY + 10.0,
            vx: (dxV / d) * 340.0,
            vy: (dyV / d) * 340.0,
            damage: v.isFishingBoat ? 18.0 : 12.0,
          ),
        );
      }

      // Va chạm giữa Cá Mập và Thuyền / Bè (Phi lên thuyền cắn phá!)
      if (dxV.abs() < v.width * 0.45 + effectivePlayerRadius * 0.7 &&
          dyV.abs() < v.height * 0.42 + effectivePlayerRadius * 0.7) {
        final bool canSmashBoat = stage.level >= 3 || frenzyActive;
        if (canSmashBoat) {
          final double hitDmg =
              frenzyActive ? 999.0 : stage.biteDamage * (_biteAnimTimer > 0 ? 1.8 : 1.1);
          v.hp -= hitDmg;
          v.hitFlashTimer = 0.18;
          _triggerScreenShake(3.0, 0.12);
          _spawnBloodAndBubbles(v.x, seaSurfaceY, const Color(0xFFFF9100), count: 7);

          if (v.hp <= 0) {
            // HÚC VỠ THUYỀN & HẤT TUNG NGƯỜI XUỐNG BIỂN ĐỂ ĂN THỊT!
            v.isDestroyed = true;
            v.respawnTimer = 22.0;
            _score += v.isFishingBoat ? 650 : 400;
            _gainExp(v.isFishingBoat ? 95 : 65);
            _triggerScreenShake(4.5, 0.16);
            HapticFeedback.mediumImpact();
            _popups.add(
              _FloatingTextPopup(
                text: v.isFishingBoat
                    ? (AppStrings.of(context).languageCode == 'vi'
                        ? 'ĐÁNH ĐẮM THUYỀN! +650'
                        : 'BOAT SMASHED! +650')
                    : (AppStrings.of(context).languageCode == 'vi'
                        ? 'PHÁ VỠ BÈ GỖ! +400'
                        : 'RAFT DESTROYED! +400'),
                x: v.x,
                y: seaSurfaceY - 60.0,
                color: const Color(0xFFFFEA00),
                fontSize: 15.0,
              ),
            );

            // Rơi người xuống biển làm mồi ngon cho cá mập!
            final swimmerTpl =
                _speciesCatalog.firstWhere((c) => c.id == 'surface_swimmer');
            for (int p = 0; p < v.passengersCount; p++) {
              _entities.add(
                _SeaEntity(
                  template: swimmerTpl,
                  schoolGroupId: _nextSchoolGroupId++,
                  x: (v.x + (p - 1) * 55.0).clamp(80.0, worldWidth - 80.0),
                  y: seaSurfaceY + 26.0,
                  vx: (p - 1) * 75.0,
                  vy: 45.0,
                  swimPhase: _rng.nextDouble() * math.pi,
                ),
              );
            }
          }
        } else if (_invulnerableTimer <= 0) {
          // Cá nhỏ LV.1 - LV.2 húc vào thân thuyền sắt bị dội ngược & mất máu
          _invulnerableTimer = 0.7;
          _hp = math.max(0.0, _hp - 12.0);
          _playerVy = 210.0;
          _triggerScreenShake(5.0, 0.2);
          _popups.add(
            _FloatingTextPopup(
              text: AppStrings.of(context).languageCode == 'vi'
                  ? 'THUYỀN QUÁ CỨNG! CẦN LV.3+'
                  : 'ARMORED HULL! NEED LV.3+',
              x: _playerX,
              y: _playerY - 30.0,
              color: const Color(0xFFFF5252),
              fontSize: 12.5,
            ),
          );
        }
      }
    }

    // 5. Cập nhật MŨI LAO (Harpoons) bắn từ Thuyền & Thợ săn
    for (int i = _harpoons.length - 1; i >= 0; i--) {
      final h = _harpoons[i];
      h.lifeTimer -= dt;
      h.x += h.vx * dt;
      h.y += h.vy * dt;
      if (h.lifeTimer <= 0 ||
          h.x < 0 ||
          h.x > worldWidth ||
          h.y < 0 ||
          h.y > worldHeight) {
        _harpoons.removeAt(i);
        continue;
      }

      final double dx = h.x - _playerX;
      final double dy = h.y - _playerY;
      if (dx * dx + dy * dy <
          (effectivePlayerRadius * 0.75) * (effectivePlayerRadius * 0.75)) {
        if (!frenzyActive && _invulnerableTimer <= 0) {
          _hp = math.max(0.0, _hp - h.damage);
          _invulnerableTimer = 0.55;
          _triggerScreenShake(7.5, 0.22);
          HapticFeedback.heavyImpact();
          _spawnBloodAndBubbles(h.x, h.y, const Color(0xFFFF1744), count: 10);
          _popups.add(
            _FloatingTextPopup(
              text: AppStrings.of(context).languageCode == 'vi'
                  ? 'TRÚNG LAO! -${h.damage.toInt()} HP'
                  : 'HARPOON HIT! -${h.damage.toInt()} HP',
              x: _playerX,
              y: _playerY - 30.0,
              color: const Color(0xFFFF1744),
            ),
          );
          if (_hp <= 0.0) {
            _triggerGameOver();
            return;
          }
        }
        _harpoons.removeAt(i);
      }
    }

    // 6. Cập nhật AI Sinh Vật, Người Bơi chạy lên thuyền & Va chạm
    for (int i = _entities.length - 1; i >= 0; i--) {
      final e = _entities[i];

      if (e.isBeingSwallowed) {
        e.swallowProgress += dt * 6.8;
        e.x = ui.lerpDouble(e.x, playerMouth.dx, (dt * 18.0).clamp(0.0, 1.0))!;
        e.y = ui.lerpDouble(e.y, playerMouth.dy, (dt * 18.0).clamp(0.0, 1.0))!;
        e.swimPhase += dt * 16.0;
        final double shrinkLen = e.template.radius *
            2.55 *
            (1.0 - e.swallowProgress * 0.78).clamp(0.15, 1.0);
        final double swallowAngle =
            math.atan2(playerMouth.dy - e.y, playerMouth.dx - e.x);
        _updateSpineChain(
          spine: e.spineNodes,
          centerX: e.x,
          centerY: e.y,
          headingAngle: swallowAngle,
          bodyLength: shrinkLen,
          dt: dt,
        );
        if (e.swallowProgress >= 1.0) {
          _finalizeConsumePrey(e, index: i);
        }
        continue;
      }

      if (e.hitFlashTimer > 0) {
        e.hitFlashTimer = math.max(0.0, e.hitFlashTimer - dt);
      }
      if (e.biteCooldown > 0) {
        e.biteCooldown = math.max(0.0, e.biteCooldown - dt);
      }

      if (e.stunTimer > 0) {
        e.stunTimer = math.max(0.0, e.stunTimer - dt);
        e.x += e.vx * 0.12 * dt;
        e.y += e.vy * 0.12 * dt;
      } else {
        final double speedMag = math.sqrt(e.vx * e.vx + e.vy * e.vy);
        e.swimPhase += dt * (e.template.waveFrequency + speedMag * 0.025);
        e.aiChangeTimer -= dt;

        final double dxToPlayer = _playerX - e.x;
        final double dyToPlayer = _playerY - e.y;
        final double dist =
            math.sqrt(dxToPlayer * dxToPlayer + dyToPlayer * dyToPlayer);

        final bool canBeSucked =
            e.template.tier <= stage.level || frenzyActive;

        if (_vortexTimer > 0 && canBeSucked && dist < 400.0 && dist > 1.0) {
          final double pullDx = playerMouth.dx - e.x;
          final double pullDy = playerMouth.dy - e.y;
          final double pullDist =
              math.max(1.0, math.sqrt(pullDx * pullDx + pullDy * pullDy));
          e.vx = ui.lerpDouble(
              e.vx, (pullDx / pullDist) * 340.0, (dt * 8.0).clamp(0.0, 1.0))!;
          e.vy = ui.lerpDouble(
              e.vy, (pullDy / pullDist) * 340.0, (dt * 8.0).clamp(0.0, 1.0))!;
        } else if (e.template.id == 'surface_swimmer') {
          // AI NGƯỜI BƠI: Thấy cá mập đến gần -> Hoảng loạn bơi chạy về phía Thuyền/Bè gần nhất để leo lên!
          e.isPanicking = dist < 360.0;
          if (e.isPanicking) {
            _SurfaceVessel? nearestBoat;
            double bestBoatDist = 999999.0;
            for (final v in _vessels) {
              if (v.isDestroyed) continue;
              final double bd = (v.x - e.x).abs();
              if (bd < bestBoatDist) {
                bestBoatDist = bd;
                nearestBoat = v;
              }
            }
            if (nearestBoat != null) {
              final double dirToBoat = nearestBoat.x >= e.x ? 1.0 : -1.0;
              e.vx = ui.lerpDouble(
                  e.vx, dirToBoat * 135.0, (dt * 6.0).clamp(0.0, 1.0))!;
              e.vy = ui.lerpDouble(
                  e.vy,
                  (seaSurfaceY + 18.0 - e.y) * 2.5,
                  (dt * 6.0).clamp(0.0, 1.0))!;
              // Nếu bơi tới sát thuyền -> Leo lên thuyền an toàn!
              if ((nearestBoat.x - e.x).abs() < nearestBoat.width * 0.35 &&
                  (e.y - seaSurfaceY).abs() < 36.0) {
                nearestBoat.passengersCount++;
                _popups.add(
                  _FloatingTextPopup(
                    text: AppStrings.of(context).languageCode == 'vi'
                        ? 'TRỐN LÊN THUYỀN!'
                        : 'ESCAPED TO BOAT!',
                    x: e.x,
                    y: seaSurfaceY - 25.0,
                    color: const Color(0xFFFFD740),
                    fontSize: 11.5,
                  ),
                );
                _entities.removeAt(i);
                continue;
              }
            } else if (dist > 1.0) {
              e.vx = -(dxToPlayer / dist) * 125.0;
            }
          }
        } else if (e.template.isHarpoonHunter && dist < 440.0) {
          // THỢ SĂN DƯỚI NƯỚC: Bắn lao vào cá mập hoặc giữ khoảng cách
          e.shootCooldown -= dt;
          if (e.shootCooldown <= 0 && dist > 90.0) {
            e.shootCooldown = isMap2 ? 2.1 : 2.7;
            _harpoons.add(
              _HarpoonProjectile(
                x: e.x,
                y: e.y,
                vx: (dxToPlayer / dist) * 310.0,
                vy: (dyToPlayer / dist) * 310.0,
                damage: 16.0,
              ),
            );
          }
          if (dist < 220.0 && dist > 1.0) {
            e.vx = -(dxToPlayer / dist) * e.template.speed * 1.2;
            e.vy = -(dyToPlayer / dist) * e.template.speed * 1.1;
          }
        } else if (dist < 350.0) {
          if (e.template.tier < stage.level || frenzyActive) {
            if (dist < 250.0 && dist > 1.0) {
              final double fleeVx =
                  -(dxToPlayer / dist) * e.template.speed * 1.45;
              final double fleeVy =
                  -(dyToPlayer / dist) * e.template.speed * 1.18;
              e.vx = ui.lerpDouble(e.vx, fleeVx, (dt * 5.5).clamp(0.0, 1.0))!;
              e.vy = ui.lerpDouble(e.vy, fleeVy, (dt * 5.5).clamp(0.0, 1.0))!;
            }
          } else if (e.template.tier > stage.level && e.template.isAggressive) {
            if (dist > 1.0) {
              final double chaseVx =
                  (dxToPlayer / dist) * e.template.speed * (isMap2 ? 1.28 : 1.18);
              final double chaseVy =
                  (dyToPlayer / dist) * e.template.speed * (isMap2 ? 1.15 : 1.05);
              e.vx = ui.lerpDouble(e.vx, chaseVx, (dt * 4.5).clamp(0.0, 1.0))!;
              e.vy = ui.lerpDouble(e.vy, chaseVy, (dt * 4.5).clamp(0.0, 1.0))!;
            }
          }
        } else if (e.aiChangeTimer <= 0) {
          e.aiChangeTimer = 2.2 + _rng.nextDouble() * 3.6;
          final double dir = _rng.nextBool() ? 1.0 : -1.0;
          e.vx = dir * e.template.speed * (0.8 + _rng.nextDouble() * 0.4);
          e.vy = (_rng.nextDouble() - 0.5) * e.template.speed * 0.42;
        }

        e.vy += math.cos(e.swimPhase * 0.4) * 14.0 * dt;
        e.x += e.vx * dt;
        e.y += e.vy * dt;

        final double minY = math.max(
            seaSurfaceY + 14.0, e.template.minDepthRatio * worldHeight);
        final double maxY =
            math.min(worldHeight - 80.0, e.template.maxDepthRatio * worldHeight);
        if (e.y < minY) {
          e.y = minY;
          e.vy = e.vy.abs();
        } else if (e.y > maxY) {
          e.y = maxY;
          e.vy = -e.vy.abs();
        }

        if (e.x < 80.0) {
          e.x = 80.0;
          e.vx = e.vx.abs();
        } else if (e.x > worldWidth - 80.0) {
          e.x = worldWidth - 80.0;
          e.vx = -e.vx.abs();
        }

        if (e.vx.abs() > 6.0) {
          e.facingRight = e.vx > 0;
        }
      }

      final double targetEntityDorsal = e.facingRight ? 1.0 : -1.0;
      e.dorsalFlip = ui.lerpDouble(
        e.dorsalFlip,
        targetEntityDorsal,
        (dt * 8.5).clamp(0.0, 1.0),
      )!;

      double entityHeading = math.atan2(e.vy, e.vx);
      if (e.facingRight) {
        entityHeading = entityHeading.clamp(-0.55, 0.55);
      } else {
        final double diff =
            _normalizeAngle(entityHeading - math.pi).clamp(-0.55, 0.55);
        entityHeading = _normalizeAngle(math.pi + diff);
      }

      _updateSpineChain(
        spine: e.spineNodes,
        centerX: e.x,
        centerY: e.y,
        headingAngle: entityHeading,
        bodyLength: e.template.radius * 2.55,
        dt: dt,
      );

      final double dx = e.x - playerMouth.dx;
      final double dy = e.y - playerMouth.dy;
      final double distToMouth = math.sqrt(dx * dx + dy * dy);
      final double dxBody = e.x - _playerX;
      final double dyBody = e.y - _playerY;
      final double distToBody = math.sqrt(dxBody * dxBody + dyBody * dyBody);
      // CHỈ ăn khi đầu/miệng cá mập chạm sát vào con mồi (loại bỏ cảm giác tự hút khi chưa bật kỹ năng Hút Mồi)
      final double eatRadius =
          effectivePlayerRadius * 0.56 + e.template.radius * 0.58;

      if (distToMouth < eatRadius) {
        final bool isEdibleInstant =
            e.template.tier <= stage.level || frenzyActive;

        if (isEdibleInstant) {
          final double damageDealt = frenzyActive
              ? 9999.0
              : stage.biteDamage * (_biteAnimTimer > 0 ? 1.85 : 1.15);
          e.hp -= damageDealt;
          e.hitFlashTimer = 0.2;
          _biteAnimTimer = math.max(_biteAnimTimer, 0.24);

          if (e.hp <= 0) {
            e.isBeingSwallowed = true;
            e.swallowProgress = 0.0;
            continue;
          } else {
            final double pushDir = dxBody >= 0 ? 1.0 : -1.0;
            e.x += pushDir * 34.0;
            _spawnBloodAndBubbles(e.x, e.y, const Color(0xFFFF1744), count: 8);
            _popups.add(
              _FloatingTextPopup(
                text: '-${damageDealt.toInt()} HP',
                x: e.x,
                y: e.y - e.template.radius,
                color: const Color(0xFFFF5252),
              ),
            );
          }
        } else {
          if (_biteAnimTimer > 0 && _isInFrontOfMouth(e.x, e.y)) {
            final double ripDamage = stage.biteDamage * 0.9;
            e.hp -= ripDamage;
            e.hitFlashTimer = 0.25;
            _biteAnimTimer = 0.0;
            _triggerScreenShake(5.5, 0.18);
            _spawnBloodAndBubbles(e.x, e.y, const Color(0xFFFF5252), count: 10);
            _popups.add(
              _FloatingTextPopup(
                text: AppStrings.of(context).languageCode == 'vi'
                    ? 'CẮN XÉ! -${ripDamage.toInt()}'
                    : 'RIP! -${ripDamage.toInt()}',
                x: e.x,
                y: e.y - e.template.radius,
                color: const Color(0xFFFFAB00),
              ),
            );
            _pickups.add(
              _OceanPickup(
                type: _PickupType.meatChunk,
                x: (e.x + playerMouth.dx) * 0.5,
                y: (e.y + playerMouth.dy) * 0.5,
                vx: (_rng.nextDouble() - 0.5) * 80.0,
                vy: -40.0,
                radius: 14.0,
              ),
            );
            if (e.hp <= 0) {
              e.isBeingSwallowed = true;
              e.swallowProgress = 0.0;
              continue;
            }
          } else if (_invulnerableTimer <= 0 && e.biteCooldown <= 0) {
            e.biteCooldown = 1.05;
            _invulnerableTimer = 0.75;
            final double dmg = e.template.damage * (isMap2 ? 1.2 : 1.0);
            _hp = math.max(0.0, _hp - dmg);
            _triggerScreenShake(9.5, 0.28);
            HapticFeedback.heavyImpact();
            _spawnBloodAndBubbles(
                _playerX, _playerY, const Color(0xFFD50000),
                count: 14);
            _popups.add(
              _FloatingTextPopup(
                text: AppStrings.of(context).languageCode == 'vi'
                    ? '-${dmg.toInt()} MÁU (CÁ LỚN!)'
                    : '-${dmg.toInt()} HP (PREDATOR!)',
                x: _playerX,
                y: _playerY - effectivePlayerRadius,
                color: const Color(0xFFFF1744),
                fontSize: 15.0,
              ),
            );
            if (distToBody > 1.0) {
              _playerVx = -(dxBody / distToBody) * 270.0;
              _playerVy = -(dyBody / distToBody) * 270.0;
            }
            if (_hp <= 0.0) {
              _triggerGameOver();
              return;
            }
          }
        }
      }
    }

    final int targetEntities = isMap2 ? 74 : 66;
    while (_entities.length < targetEntities) {
      _spawnRandomEntityOrSchool(avoidPlayer: true);
    }

    // 7. Cập nhật Pickups
    for (int i = _pickups.length - 1; i >= 0; i--) {
      final p = _pickups[i];
      p.pulsePhase += dt * 4.0;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vx *= 0.95;
      p.vy *= 0.95;

      if (p.type == _PickupType.meatChunk) {
        p.lifeTimer -= dt;
        if (p.lifeTimer <= 0) {
          _pickups.removeAt(i);
          continue;
        }
      }

      final double dx = playerMouth.dx - p.x;
      final double dy = playerMouth.dy - p.y;
      final double dist = math.sqrt(dx * dx + dy * dy);

      if (p.type != _PickupType.navalMine &&
          (_vortexTimer > 0 || frenzyActive) &&
          dist < 360.0 &&
          dist > 1.0) {
        p.x += (dx / dist) * 320.0 * dt;
        p.y += (dy / dist) * 320.0 * dt;
      }

      if (dist < effectivePlayerRadius * 0.85 + p.radius) {
        if (p.type == _PickupType.navalMine) {
          _shockwaves.add(
            _ShockwaveRing(
              x: p.x,
              y: p.y,
              maxRadius: 160.0,
              color: const Color(0xFFFF3D00),
            ),
          );
          _spawnBloodAndBubbles(p.x, p.y, const Color(0xFFFF6D00), count: 22);
          _triggerScreenShake(12.0, 0.35);
          HapticFeedback.heavyImpact();

          if (!frenzyActive && _invulnerableTimer <= 0) {
            final double mineDmg = isMap2 ? 75.0 : 58.0; // Bom Thủy Lôi nổ mất máu cực thấm!
            _hp = math.max(0.0, _hp - mineDmg);
            _invulnerableTimer = 0.85;
            _popups.add(
              _FloatingTextPopup(
                text: AppStrings.of(context).languageCode == 'vi'
                    ? 'NỔ THỦY LÔI! -${mineDmg.toInt()} HP'
                    : 'MINE BLAST! -${mineDmg.toInt()} HP',
                x: _playerX,
                y: _playerY - 40.0,
                color: const Color(0xFFFF3D00),
                fontSize: 15.0,
              ),
            );
          } else {
            _score += 150;
            _popups.add(
              _FloatingTextPopup(
                text: AppStrings.of(context).languageCode == 'vi'
                    ? 'PHÁ HỦY THỦY LÔI! +150'
                    : 'MINE DESTROYED! +150',
                x: p.x,
                y: p.y - 30.0,
                color: const Color(0xFFFFD740),
              ),
            );
          }
          _pickups.removeAt(i);
          _spawnRandomPickup();
          if (_hp <= 0.0) {
            _triggerGameOver();
            return;
          }
        } else if (p.type == _PickupType.healingPearl) {
          _hp = math.min(stage.maxHp, _hp + stage.maxHp * 0.28);
          _stamina = math.min(100.0, _stamina + 40.0);
          _score += 120;
          HapticFeedback.lightImpact();
          _spawnBloodAndBubbles(p.x, p.y, const Color(0xFF00E676), count: 10);
          _popups.add(
            _FloatingTextPopup(
              text: AppStrings.of(context).languageCode == 'vi'
                  ? '+28% MÁU & SP'
                  : '+28% HP & SP',
              x: p.x,
              y: p.y - 20.0,
              color: const Color(0xFF00E676),
            ),
          );
          _pickups.removeAt(i);
          _spawnRandomPickup();
        } else if (p.type == _PickupType.goldenStar) {
          _score += 300;
          _furyCharge = math.min(100.0, _furyCharge + 22.0);
          _gainExp(32);
          HapticFeedback.mediumImpact();
          _spawnBloodAndBubbles(p.x, p.y, const Color(0xFFFFD740), count: 12);
          _popups.add(
            _FloatingTextPopup(
              text: AppStrings.of(context).languageCode == 'vi'
                  ? '+300 ĐIỂM | +22% NỘ'
                  : '+300 SCORE | +22% FURY',
              x: p.x,
              y: p.y - 20.0,
              color: const Color(0xFFFFD740),
            ),
          );
          _pickups.removeAt(i);
          _spawnRandomPickup();
        } else if (p.type == _PickupType.meatChunk) {
          _hp = math.min(stage.maxHp, _hp + 14.0);
          _score += 90;
          _gainExp(20);
          HapticFeedback.selectionClick();
          _popups.add(
            _FloatingTextPopup(
              text: AppStrings.of(context).languageCode == 'vi'
                  ? '+20 EXP | +14 MÁU'
                  : '+20 EXP | +14 HP',
              x: p.x,
              y: p.y - 16.0,
              color: const Color(0xFFFF8A80),
            ),
          );
          _pickups.removeAt(i);
        }
      }
    }

    // 8. Cập nhật Particles, Popups & Shockwaves
    for (int i = _particles.length - 1; i >= 0; i--) {
      final pt = _particles[i];
      pt.x += pt.vx * dt;
      pt.y += pt.vy * dt;
      pt.alpha -= pt.decay * dt;
      if (pt.alpha <= 0) {
        _particles.removeAt(i);
      }
    }

    for (int i = _popups.length - 1; i >= 0; i--) {
      final pop = _popups[i];
      pop.y += pop.vy * dt;
      pop.alpha -= 0.85 * dt;
      if (pop.alpha <= 0) {
        _popups.removeAt(i);
      }
    }

    for (int i = _shockwaves.length - 1; i >= 0; i--) {
      final sw = _shockwaves[i];
      sw.radius += (sw.maxRadius * 2.2) * dt;
      sw.alpha = (1.0 - (sw.radius / sw.maxRadius)).clamp(0.0, 1.0);
      if (sw.radius >= sw.maxRadius) {
        _shockwaves.removeAt(i);
      }
    }
  }

  bool _isInFrontOfMouth(double targetX, double targetY) {
    final double dx = targetX - _playerX;
    if (_playerFacingRight && dx < -15.0) return false;
    if (!_playerFacingRight && dx > 15.0) return false;
    return true;
  }

  void _finalizeConsumePrey(_SeaEntity prey, {required int index}) {
    final stage = _currentStage;
    final bool isMap2 = _currentMap == _GameStageMap.volcanicAbyss;
    if (index >= 0 && index < _entities.length) {
      _entities.removeAt(index);
    }
    _fishEatenCount++;

    _comboCount++;
    _comboTimer = 2.8; // Cửa sổ giữ Combo chặt hơn (2.8s)
    final int multiplier = _comboCount >= 8
        ? 4
        : (_comboCount >= 5 ? 3 : (_comboCount >= 3 ? 2 : 1));
    final double mapMult = isMap2 ? 1.6 : 1.0;

    final int gainedScore =
        (prey.template.scoreReward * multiplier * mapMult).round();
    final int gainedExp = (prey.template.expReward * mapMult).round();
    _score += gainedScore;
    _saveHighScoreIfNeeded();

    // Hồi máu khắt khe hơn: ăn cá nhỏ chỉ hồi 4.5 HP, ăn người hồi 18 HP!
    final double healAmount = prey.template.isHuman
        ? 18.0
        : (4.5 + prey.template.tier * 3.8);
    _hp = math.min(stage.maxHp, _hp + healAmount);
    _stamina = math.min(100.0, _stamina + 11.0);
    if (_frenzyTimer <= 0) {
      _furyCharge =
          math.min(100.0, _furyCharge + 5.0 + prey.template.tier * 3.0);
    }

    if (prey.template.tier >= 4) {
      _triggerScreenShake(7.5, 0.24);
    }

    HapticFeedback.lightImpact();
    _spawnBloodAndBubbles(prey.x, prey.y, const Color(0xFFFF1744), count: 10);

    final String comboSuffix = multiplier > 1 ? ' (x$multiplier!)' : '';
    _popups.add(
      _FloatingTextPopup(
        text: '+$gainedExp EXP | +$gainedScore$comboSuffix',
        x: prey.x,
        y: prey.y - 18.0,
        color: _isGoldRushActive
            ? const Color(0xFFFFD740)
            : const Color(0xFF00E676),
        fontSize: multiplier > 1 ? 15.0 : 13.0,
      ),
    );

    _gainExp(gainedExp);
  }

  void _gainExp(int amount) {
    _exp += amount;
    while (_stageIndex < _evolutionStages.length - 1 &&
        _exp >= _currentStage.expRequired) {
      _exp -= _currentStage.expRequired;
      _stageIndex++;
      final newStage = _currentStage;
      _hp = newStage.maxHp;
      _stamina = 100.0;
      _invulnerableTimer = 2.5;
      _triggerScreenShake(10.0, 0.35);

      HapticFeedback.heavyImpact();
      try {
        Provider.of<SoundService>(context, listen: false)
            .playCreatureSound('shark_heartbeat.mp3');
      } catch (_) {}

      _shockwaves.add(
        _ShockwaveRing(
          x: _playerX,
          y: _playerY,
          maxRadius: 290.0,
          color: newStage.auraColor,
        ),
      );
      _spawnBloodAndBubbles(_playerX, _playerY, newStage.auraColor, count: 26);

      final bool isVi = AppStrings.of(context).languageCode == 'vi';
      setState(() {
        if (newStage.level == 3 && !_map2UnlockedBannerShown) {
          _map2UnlockedBannerShown = true;
          _bannerAnnouncement = isVi
              ? 'LV.3 ĐẠT ĐƯỢC: CÓ THỂ HÚC VỠ THUYỀN & CHUYỂN MÀN 2!'
              : 'LV.3 REACHED: SMASH BOATS & STAGE 2 UNLOCKED!';
        } else {
          _bannerAnnouncement = isVi
              ? 'TIẾN HÓA CẤP ${newStage.level}: ${newStage.nameVi.toUpperCase()} (${newStage.lengthMeters}m)!'
              : 'EVOLVED TO LV.${newStage.level}: ${newStage.nameEn.toUpperCase()} (${newStage.lengthMeters}m)!';
        }
        _bannerTimer = 3.5;
      });
    }
  }

  void _spawnBloodAndBubbles(double x, double y, Color color, {int count = 10}) {
    for (int i = 0; i < count; i++) {
      final double angle = _rng.nextDouble() * math.pi * 2;
      final double speed = 35.0 + _rng.nextDouble() * 125.0;
      _particles.add(
        _GameParticle(
          x: x,
          y: y,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed,
          radius: 2.5 + _rng.nextDouble() * 5.0,
          alpha: 0.95,
          decay: 1.4 + _rng.nextDouble() * 0.8,
          color: i % 3 == 0 ? Colors.white.withValues(alpha: 0.85) : color,
        ),
      );
    }
  }

  // ── HÀNH ĐỘNG & KỸ NĂNG BÊN PHẢI MÀN HÌNH ───────────────────────────

  void _triggerBiteAction() {
    if (_biteCooldown > 0 || _isGameOver || _isPaused) return;
    _biteCooldown = 0.42;
    _biteAnimTimer = 0.28;
    HapticFeedback.mediumImpact();

    final stage = _currentStage;
    final double cosH = math.cos(_playerHeadingAngle);
    final double sinH = math.sin(_playerHeadingAngle);

    _playerVx = cosH * (420.0 + _stageIndex * 26.0);
    _playerVy = sinH * (420.0 + _stageIndex * 26.0);

    final Offset mouthPos = _playerSpine[0];
    final double biteRange =
        stage.baseRadius * (_frenzyTimer > 0 ? 2.15 : 1.75);

    _spawnBloodAndBubbles(
        mouthPos.dx, mouthPos.dy, const Color(0xFF00F0FF),
        count: 8);

    for (int i = _entities.length - 1; i >= 0; i--) {
      final e = _entities[i];
      if (e.isBeingSwallowed) continue;
      final double dx = e.x - mouthPos.dx;
      final double dy = e.y - mouthPos.dy;
      final double dist = math.sqrt(dx * dx + dy * dy);

      if (dist <= biteRange + e.template.radius) {
        if (e.template.tier <= stage.level || _frenzyTimer > 0) {
          e.hp -= stage.biteDamage * 1.95;
          e.hitFlashTimer = 0.25;
          if (e.hp <= 0) {
            e.isBeingSwallowed = true;
            e.swallowProgress = 0.0;
          } else {
            _spawnBloodAndBubbles(e.x, e.y, const Color(0xFFFF1744), count: 10);
            _popups.add(
              _FloatingTextPopup(
                text: AppStrings.of(context).languageCode == 'vi'
                    ? 'ĐỚP! -${(stage.biteDamage * 1.95).toInt()}'
                    : 'BITE! -${(stage.biteDamage * 1.95).toInt()}',
                x: e.x,
                y: e.y - e.template.radius,
                color: const Color(0xFFFF5252),
              ),
            );
          }
        } else {
          final double ripDmg = stage.biteDamage * 1.15;
          e.hp -= ripDmg;
          e.hitFlashTimer = 0.25;
          _triggerScreenShake(5.0, 0.16);
          _spawnBloodAndBubbles(e.x, e.y, const Color(0xFFFF5252), count: 12);
          _popups.add(
            _FloatingTextPopup(
              text: AppStrings.of(context).languageCode == 'vi'
                  ? 'CẮN XÉ! -${ripDmg.toInt()}'
                  : 'RIP! -${ripDmg.toInt()}',
              x: e.x,
              y: e.y - e.template.radius,
              color: const Color(0xFFFFAB00),
            ),
          );
          _pickups.add(
            _OceanPickup(
              type: _PickupType.meatChunk,
              x: mouthPos.dx,
              y: mouthPos.dy,
              vx: -cosH * 45.0,
              vy: -35.0,
              radius: 14.0,
            ),
          );
          if (e.hp <= 0) {
            e.isBeingSwallowed = true;
            e.swallowProgress = 0.0;
          }
        }
      }
    }
  }

  void _triggerVortexSkill() {
    if (_vortexCooldown > 0 || _isGameOver || _isPaused) return;
    _vortexTimer = 3.2;
    _vortexCooldown = 11.0; // Cân bằng thời gian hồi chiêu lâu hơn
    HapticFeedback.mediumImpact();

    _shockwaves.add(
      _ShockwaveRing(
        x: _playerX,
        y: _playerY,
        maxRadius: 220.0,
        color: const Color(0xFF00E5FF),
      ),
    );
  }

  void _triggerSonarRoarSkill() {
    if (_roarCooldown > 0 || _isGameOver || _isPaused) return;
    _roarCooldown = 13.0; // Cân bằng thời gian hồi chiêu lâu hơn
    HapticFeedback.heavyImpact();
    _triggerScreenShake(6.5, 0.25);

    try {
      Provider.of<SoundService>(context, listen: false)
          .playCreatureSound('The_BLOOP.mp3');
    } catch (_) {}

    const double roarRadius = 380.0;
    _shockwaves.add(
      _ShockwaveRing(
        x: _playerX,
        y: _playerY,
        maxRadius: roarRadius,
        color: const Color(0xFF00F0FF),
      ),
    );
    _shockwaves.add(
      _ShockwaveRing(
        x: _playerX,
        y: _playerY,
        radius: 35.0,
        maxRadius: roarRadius * 0.75,
        color: const Color(0xFFE040FB),
      ),
    );

    for (int i = _entities.length - 1; i >= 0; i--) {
      final e = _entities[i];
      if (e.isBeingSwallowed) continue;
      final double dx = e.x - _playerX;
      final double dy = e.y - _playerY;
      final double dist = math.sqrt(dx * dx + dy * dy);
      if (dist <= roarRadius) {
        e.stunTimer = 3.2;
        e.hitFlashTimer = 0.35;
        e.hp -= _currentStage.biteDamage * 0.7;
        if (e.hp <= 0) {
          e.isBeingSwallowed = true;
          e.swallowProgress = 0.0;
        } else {
          _popups.add(
            _FloatingTextPopup(
              text: AppStrings.of(context).languageCode == 'vi'
                  ? 'CHOÁNG!'
                  : 'STUNNED!',
              x: e.x,
              y: e.y - e.template.radius,
              color: const Color(0xFF00F0FF),
            ),
          );
        }
      }
    }

    for (int i = _pickups.length - 1; i >= 0; i--) {
      final p = _pickups[i];
      if (p.type == _PickupType.navalMine) {
        final double dx = p.x - _playerX;
        final double dy = p.y - _playerY;
        if (dx * dx + dy * dy <= roarRadius * roarRadius) {
          _shockwaves.add(
            _ShockwaveRing(
              x: p.x,
              y: p.y,
              maxRadius: 120.0,
              color: const Color(0xFFFF6D00),
            ),
          );
          _score += 100;
          _pickups.removeAt(i);
          _spawnRandomPickup();
        }
      }
    }
  }

  void _triggerBloodFrenzy() {
    if (_furyCharge < 100.0 ||
        _frenzyTimer > 0 ||
        _isGameOver ||
        _isPaused) {
      return;
    }
    _furyCharge = 0.0;
    _frenzyTimer = 7.0;
    _invulnerableTimer = 7.0;
    _hp = _currentStage.maxHp;
    _stamina = 100.0;
    _triggerScreenShake(10.0, 0.35);
    HapticFeedback.heavyImpact();

    try {
      Provider.of<SoundService>(context, listen: false)
          .playCreatureSound('kraken_roar.mp3');
    } catch (_) {}

    _shockwaves.add(
      _ShockwaveRing(
        x: _playerX,
        y: _playerY,
        maxRadius: 340.0,
        color: const Color(0xFFFF1744),
      ),
    );

    final bool isVi = AppStrings.of(context).languageCode == 'vi';
    setState(() {
      _bannerAnnouncement = isVi
          ? 'CUỒNG NỘ ĐẠI DƯƠNG: BẤT TỬ & NUỐT CHỬNG VẠN VẬT!'
          : 'APEX BLOOD FRENZY: INVULNERABLE & DEVOUR ALL!';
      _bannerTimer = 3.0;
    });
  }

  void _triggerGameOver() {
    _saveHighScoreIfNeeded();
    HapticFeedback.heavyImpact();
    if (mounted) {
      setState(() {
        _isGameOver = true;
        _isBoosting = false;
      });
    }
  }

  Future<void> _exitGame() async {
    await _saveHighScoreIfNeeded();
    await _restorePortraitMode();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gameTicker.dispose();
    _frameNotifier.dispose();
    _restorePortraitMode();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.listen(context);
    final isVi = strings.languageCode == 'vi';
    final soundService = Provider.of<SoundService>(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _exitGame();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF010814),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final Size viewportSize =
                Size(constraints.maxWidth, constraints.maxHeight);

            return Stack(
              fit: StackFit.expand,
              children: [
                // 1. THẾ GIỚI ĐẠI DƯƠNG + THUYỀN BÈ MẶT BIỂN + LƯỚI XƯƠNG SỐNG 16 ĐỐT
                RepaintBoundary(
                  child: ValueListenableBuilder<int>(
                    valueListenable: _frameNotifier,
                    builder: (context, _, _) {
                      final double shakeX = _screenShakeTimer > 0
                          ? (_rng.nextDouble() - 0.5) * 2.0 * _screenShakeIntensity
                          : 0.0;
                      final double shakeY = _screenShakeTimer > 0
                          ? (_rng.nextDouble() - 0.5) * 2.0 * _screenShakeIntensity
                          : 0.0;
                      return Transform.translate(
                        offset: Offset(shakeX, shakeY),
                        child: CustomPaint(
                          size: viewportSize,
                          painter: _SharkWorldCanvasPainter(
                            currentMap: _currentMap,
                            playerX: _playerX,
                            playerY: _playerY,
                            playerFacingRight: _playerFacingRight,
                            playerDorsalFlip: _playerDorsalFlip,
                            playerSwimPhase: _playerSwimPhase,
                            playerSpine: _playerSpine,
                            stage: _currentStage,
                            frenzyActive: _frenzyTimer > 0,
                            goldRushActive: _isGoldRushActive,
                            isBoosting: _isBoosting && _stamina > 2.0,
                            biteAnimTimer: _biteAnimTimer,
                            vortexTimer: _vortexTimer,
                            invulnerableTimer: _invulnerableTimer,
                            entities: _entities,
                            vessels: _vessels,
                            harpoons: _harpoons,
                            pickups: _pickups,
                            particles: _particles,
                            popups: _popups,
                            shockwaves: _shockwaves,
                            loadedMeshes: _loadedMeshes,
                            isVi: isVi,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 2. HIỆU ỨNG VIỀN ĐỎ CẢNH BÁO MÁU THẤP & CƠN SỐT VÀNG (PSYCHOLOGICAL VIGNETTE)
                IgnorePointer(
                  child: ValueListenableBuilder<int>(
                    valueListenable: _frameNotifier,
                    builder: (context, _, _) {
                      final double hpRatio =
                          (_hp / _currentStage.maxHp).clamp(0.0, 1.0);
                      if (hpRatio >= 0.30 && !_isGoldRushActive) {
                        return const SizedBox.shrink();
                      }
                      final double pulse =
                          0.5 + 0.5 * math.sin(_lowHpPulsePhase);
                      final Color vignetteColor = hpRatio < 0.30
                          ? const Color(0xFFFF1744)
                              .withValues(alpha: 0.08 + 0.12 * pulse)
                          : const Color(0xFFFFD740)
                              .withValues(alpha: 0.05 + 0.04 * pulse);
                      return Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            radius: 0.95,
                            colors: [
                              Colors.transparent,
                              vignetteColor,
                            ],
                            stops: const [0.55, 1.0],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 3. VÙNG CHẠM JOYSTICK BÊN TRÁI MÀN HÌNH
                Positioned(
                  left: 0,
                  top: 90,
                  bottom: 0,
                  width: viewportSize.width * 0.48,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onPanStart: (details) {
                      setState(() {
                        _joystickOrigin = details.localPosition;
                        _joystickCurrent = details.localPosition;
                        _joystickDelta = Offset.zero;
                      });
                    },
                    onPanUpdate: (details) {
                      if (_joystickOrigin == null) return;
                      final Offset raw =
                          details.localPosition - _joystickOrigin!;
                      const double maxRadius = 56.0;
                      final double dist = raw.distance;
                      final Offset clamped =
                          dist > maxRadius ? (raw / dist) * maxRadius : raw;
                      setState(() {
                        _joystickCurrent = _joystickOrigin! + clamped;
                        _joystickDelta = Offset(
                          clamped.dx / maxRadius,
                          clamped.dy / maxRadius,
                        );
                      });
                    },
                    onPanEnd: (_) {
                      setState(() {
                        _joystickOrigin = null;
                        _joystickCurrent = null;
                        _joystickDelta = Offset.zero;
                      });
                    },
                    onPanCancel: () {
                      setState(() {
                        _joystickOrigin = null;
                        _joystickCurrent = null;
                        _joystickDelta = Offset.zero;
                      });
                    },
                    child: CustomPaint(
                      painter: _VirtualJoystickPainter(
                        origin: _joystickOrigin,
                        current: _joystickCurrent,
                        defaultCenter: Offset(
                          92.0,
                          viewportSize.height - 90.0 - 82.0,
                        ),
                      ),
                    ),
                  ),
                ),

                // 4. GÓC TRÊN BÊN TRÁI: AVATAR + VÒNG EXP + THANH HP/SP VÁT CHÉO + CHỌN MÀN 1 / MÀN 2
                Positioned(
                  left: 14,
                  top: 10,
                  child: ValueListenableBuilder<int>(
                    valueListenable: _frameNotifier,
                    builder: (context, _, _) {
                      return _buildTopLeftPlayerHUD(isVi);
                    },
                  ),
                ),

                // 5. GÓC TRÊN BÊN PHẢI: MINI-MAP PHONG CÁCH PUBG (CHẤM ĐỎ VỊ TRÍ CÁ MẬP)
                Positioned(
                  right: 14,
                  top: 10,
                  child: ValueListenableBuilder<int>(
                    valueListenable: _frameNotifier,
                    builder: (context, _, _) {
                      return _buildTopRightPubgMinimapHUD(isVi, soundService);
                    },
                  ),
                ),

                // 6. GÓC DƯỚI BÊN PHẢI: CỤM 5 NÚT HÀNH ĐỘNG
                Positioned(
                  right: 16,
                  bottom: 14,
                  child: ValueListenableBuilder<int>(
                    valueListenable: _frameNotifier,
                    builder: (context, _, _) {
                      return _buildBottomRightActionCluster(isVi);
                    },
                  ),
                ),

                // 7. THÔNG BÁO TIẾN HÓA / CHUYỂN MÀN / GOLD RUSH
                if (_bannerAnnouncement != null)
                  Positioned(
                    top: 14,
                    left: viewportSize.width * 0.28,
                    right: viewportSize.width * 0.28,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFF1744).withValues(alpha: 0.92),
                              const Color(0xFFFF9100).withValues(alpha: 0.92),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFFFEA00),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  const Color(0xFFFF1744).withValues(alpha: 0.5),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: Text(
                          _bannerAnnouncement!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),

                // 8. MODAL TẠM DỪNG / HƯỚNG DẪN / GAME OVER
                if (_isPaused || _showHelpOverlay)
                  _buildPauseOrHelpModal(isVi),
                if (_isGameOver) _buildGameOverModal(isVi),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopLeftPlayerHUD(bool isVi) {
    final stage = _currentStage;
    final double hpRatio = (_hp / stage.maxHp).clamp(0.0, 1.0);
    final double staminaRatio = (_stamina / 100.0).clamp(0.0, 1.0);
    final double expRatio = stage.level >= _evolutionStages.length
        ? 1.0
        : (_exp / stage.expRequired).clamp(0.0, 1.0);
    final bool frenzy = _frenzyTimer > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // HUY CHƯƠNG AVATAR TRÒN + VÒNG CUNG EXP
            SizedBox(
              width: 50,
              height: 50,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          stage.auraColor.withValues(alpha: 0.55),
                          const Color(0xEB041226),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.65),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      stage.assetPath,
                      fit: BoxFit.contain,
                    ),
                  ),
                  CustomPaint(
                    size: const Size(48, 48),
                    painter: _AvatarExpRingPainter(
                      expRatio: expRatio,
                      frenzy: frenzy,
                    ),
                  ),
                  Positioned(
                    bottom: -3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: frenzy
                              ? const [Color(0xFFFF1744), Color(0xFFB71C1C)]
                              : const [Color(0xFFFFEA00), Color(0xFFFF8F00)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black87, width: 1.0),
                      ),
                      child: Text(
                        'LV.${stage.level}',
                        style: TextStyle(
                          color: frenzy ? Colors.white : Colors.black,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),

            // CỤM THANH MÁU & NĂNG LƯỢNG VÁT CHÉO
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xCC030D1C),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFFFD740).withValues(alpha: 0.65),
                          width: 0.9,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.emoji_events_rounded,
                            color: Color(0xFFFFEA00),
                            size: 11,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '$_score',
                            style: const TextStyle(
                              color: Color(0xFFFFEA00),
                              fontSize: 10.0,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '• ${stage.lengthMeters}m',
                            style: TextStyle(
                              color: stage.auraColor,
                              fontSize: 9.0,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    if (_comboCount >= 2)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _isGoldRushActive
                                ? const [Color(0xFFFFEA00), Color(0xFFFF6D00)]
                                : const [Color(0xFFFF1744), Color(0xFFFF6D00)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _isGoldRushActive
                              ? 'GOLD x$_comboCount!'
                              : 'x$_comboCount!',
                          style: TextStyle(
                            color: _isGoldRushActive ? Colors.black : Colors.white,
                            fontSize: 9.0,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      )
                    else
                      Text(
                        '${isVi ? "Mồi" : "Prey"}: $_fishEatenCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 4,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                _buildSkewedGameBar(
                  width: 152,
                  height: 12.5,
                  ratio: hpRatio,
                  gradientColors: hpRatio > 0.35
                      ? const [
                          Color(0xFF00B248),
                          Color(0xFF00E676),
                          Color(0xFF69F0AE),
                        ]
                      : const [
                          Color(0xFFB71C1C),
                          Color(0xFFFF1744),
                          Color(0xFFFF8A80),
                        ],
                  borderColor: hpRatio > 0.35
                      ? const Color(0xFF00E676)
                      : const Color(0xFFFF1744),
                  overlayText: 'HP ${_hp.toInt()}/${stage.maxHp.toInt()}',
                  showSegments: true,
                ),
                const SizedBox(height: 3),
                _buildSkewedGameBar(
                  width: 126,
                  height: 6.5,
                  ratio: staminaRatio,
                  gradientColors: const [
                    Color(0xFF00838F),
                    Color(0xFF00E5FF),
                    Color(0xFF84FFFF),
                  ],
                  borderColor: const Color(0xFF00E5FF),
                  overlayText: null,
                  showSegments: false,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 5),

        // THANH CHUYỂN ĐỔI NHANH MÀN 1 (VỊNH SAN HÔ) <-> MÀN 2 (RÃNH DUNG NHAM MARIANA)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMapPillButton(
              label: isVi ? 'MÀN 1: VỊNH SAN HÔ' : 'MAP 1: CORAL BAY',
              isActive: _currentMap == _GameStageMap.coralBay,
              activeColor: const Color(0xFF00E5FF),
              onTap: () => _switchGameMap(_GameStageMap.coralBay),
            ),
            const SizedBox(width: 5),
            _buildMapPillButton(
              label: isVi ? 'MÀN 2: DUNG NHAM (x1.6)' : 'MAP 2: VOLCANO (x1.6)',
              isActive: _currentMap == _GameStageMap.volcanicAbyss,
              activeColor: const Color(0xFFFF5252),
              onTap: () => _switchGameMap(_GameStageMap.volcanicAbyss),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMapPillButton({
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.25)
              : const Color(0xAA020915),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? activeColor : Colors.white24,
            width: isActive ? 1.1 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? activeColor : Colors.white60,
            fontSize: 8.2,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildSkewedGameBar({
    required double width,
    required double height,
    required double ratio,
    required List<Color> gradientColors,
    required Color borderColor,
    required String? overlayText,
    required bool showSegments,
  }) {
    return Transform(
      transform: Matrix4.skewX(-0.24),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xD9020812),
          borderRadius: BorderRadius.circular(3.5),
          border: Border.all(
            color: borderColor.withValues(alpha: 0.75),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2.5),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: ratio,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradientColors),
                    ),
                  ),
                ),
              ),
              if (showSegments)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    4,
                    (_) => Container(
                      width: 0.8,
                      height: height,
                      color: Colors.black.withValues(alpha: 0.32),
                    ),
                  ),
                ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: height * 0.36,
                child: Container(
                  color: Colors.white.withValues(alpha: 0.25),
                ),
              ),
              if (overlayText != null)
                Transform(
                  transform: Matrix4.skewX(0.24),
                  child: Text(
                    overlayText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8.2,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                      height: 1.0,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 3,
                          offset: Offset(0.8, 0.8),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopRightPubgMinimapHUD(bool isVi, SoundService soundService) {
    final int depthMeters =
        (((_playerY - seaSurfaceY) / (worldHeight - seaSurfaceY)) * 11000)
            .clamp(0.0, 11000.0)
            .round();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSmallTopIconButton(
                  icon: soundService.isMuted
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  color: soundService.isMuted
                      ? const Color(0xFFFF5252)
                      : const Color(0xFF00E5FF),
                  onTap: () => soundService.toggleMute(),
                ),
                const SizedBox(width: 6),
                _buildSmallTopIconButton(
                  icon: Icons.help_outline_rounded,
                  color: const Color(0xFFFFD740),
                  onTap: () {
                    setState(() {
                      _showHelpOverlay = true;
                    });
                  },
                ),
                const SizedBox(width: 6),
                _buildSmallTopIconButton(
                  icon: Icons.pause_rounded,
                  color: const Color(0xFF00E676),
                  onTap: () {
                    setState(() {
                      _isPaused = !_isPaused;
                    });
                  },
                ),
                const SizedBox(width: 6),
                _buildSmallTopIconButton(
                  icon: Icons.close_rounded,
                  color: const Color(0xFFFF1744),
                  onTap: _exitGame,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF030D1E).withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF00F0FF).withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                _playerY < seaSurfaceY
                    ? (isVi ? 'TRÊN KHÔNG!' : 'AIRBORNE!')
                    : '${isVi ? "ĐỘ SÂU" : "DEPTH"}: ${depthMeters}m',
                style: TextStyle(
                  color: _playerY < seaSurfaceY
                      ? const Color(0xFFFFEA00)
                      : const Color(0xFF00F0FF),
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        Container(
          width: 148,
          height: 96,
          decoration: BoxDecoration(
            color: const Color(0xFF020B18).withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF00F0FF).withValues(alpha: 0.65),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00F0FF).withValues(alpha: 0.2),
                blurRadius: 10,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.5),
            child: Stack(
              children: [
                CustomPaint(
                  size: const Size(148, 96),
                  painter: _PubgMinimapPainter(
                    currentMap: _currentMap,
                    playerX: _playerX,
                    playerY: _playerY,
                    headingAngle: _playerHeadingAngle,
                    playerLevel: _currentStage.level,
                    entities: _entities,
                    vessels: _vessels,
                    pickups: _pickups,
                    pulsePhase: _playerSwimPhase,
                  ),
                ),
                Positioned(
                  left: 5,
                  top: 3,
                  child: Text(
                    isVi ? 'RADAR ĐẠI DƯƠNG' : 'OCEAN RADAR',
                    style: TextStyle(
                      color: const Color(0xFF00F0FF).withValues(alpha: 0.8),
                      fontSize: 7.5,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                Positioned(
                  left: 5,
                  bottom: 3,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF1744),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        isVi ? 'Bạn' : 'You',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 7.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00E676),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        isVi ? 'Mồi' : 'Prey',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 7.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFEA00),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        isVi ? 'Thuyền' : 'Boat',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 7.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallTopIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: const Color(0xFF030D1E).withValues(alpha: 0.82),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.65), width: 1.1),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }

  Widget _buildBottomRightActionCluster(bool isVi) {
    final bool furyReady = _furyCharge >= 100.0 && _frenzyTimer <= 0;

    return SizedBox(
      width: 224,
      height: 184,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 6,
            bottom: 6,
            child: GestureDetector(
              onTapDown: (_) => setState(() => _isBoosting = true),
              onTapUp: (_) => setState(() => _isBoosting = false),
              onTapCancel: () => setState(() => _isBoosting = false),
              child: _buildSkillButton(
                size: 58,
                assetPath: 'assets/images/icon/skill_turbo_boost.png',
                label: isVi ? 'TĂNG TỐC' : 'BOOST',
                color: const Color(0xFF00E5FF),
                isActive: _isBoosting,
                cooldownText: null,
              ),
            ),
          ),
          Positioned(
            left: 46,
            bottom: 72,
            child: GestureDetector(
              onTap: _triggerVortexSkill,
              child: _buildSkillButton(
                size: 56,
                assetPath: 'assets/images/icon/skill_vortex_suction.png',
                label: isVi ? 'HÚT MỒI' : 'VORTEX',
                color: const Color(0xFF00E676),
                isActive: _vortexTimer > 0,
                cooldownText: _vortexCooldown > 0
                    ? '${_vortexCooldown.ceil()}s'
                    : null,
              ),
            ),
          ),
          Positioned(
            right: 8,
            top: 4,
            child: GestureDetector(
              onTap: _triggerSonarRoarSkill,
              child: _buildSkillButton(
                size: 56,
                assetPath: 'assets/images/icon/skill_sonar_roar.png',
                label: isVi ? 'SÓNG ÂM' : 'ROAR',
                color: const Color(0xFFE040FB),
                isActive: false,
                cooldownText:
                    _roarCooldown > 0 ? '${_roarCooldown.ceil()}s' : null,
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 6,
            child: GestureDetector(
              onTap: _triggerBloodFrenzy,
              child: _buildSkillButton(
                size: 54,
                assetPath: 'assets/images/icon/skill_blood_frenzy.png',
                label: _frenzyTimer > 0
                    ? '${_frenzyTimer.ceil()}s'
                    : '${_furyCharge.toInt()}%',
                color: furyReady || _frenzyTimer > 0
                    ? const Color(0xFFFF1744)
                    : const Color(0xFFFF9100),
                isActive: furyReady || _frenzyTimer > 0,
                cooldownText: null,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTapDown: (_) => _triggerBiteAction(),
              child: AnimatedScale(
                scale: _biteAnimTimer > 0 ? 0.90 : 1.0,
                duration: const Duration(milliseconds: 90),
                child: SizedBox(
                  width: 90,
                  height: 90,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFFFF1744).withValues(alpha: 0.42),
                              const Color(0xFF041022).withValues(alpha: 0.78),
                            ],
                          ),
                          border: Border.all(
                            color: _biteAnimTimer > 0
                                ? const Color(0xFFFFEA00)
                                : const Color(0xFFFF1744),
                            width: 2.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF1744)
                                  .withValues(alpha: 0.48),
                              blurRadius: 16,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Image.asset(
                          'assets/images/icon/skill_bite_shark.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      Positioned(
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF1744),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.85),
                              width: 0.9,
                            ),
                          ),
                          child: Text(
                            isVi ? 'ĐỚP MỒI' : 'BITE',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.0,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillButton({
    required double size,
    required String assetPath,
    required String label,
    required Color color,
    required bool isActive,
    required String? cooldownText,
  }) {
    final bool onCooldown = cooldownText != null;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? color.withValues(alpha: 0.32)
                  : const Color(0xFF041022).withValues(alpha: 0.68),
              border: Border.all(
                color: onCooldown
                    ? Colors.white24
                    : color.withValues(alpha: isActive ? 1.0 : 0.78),
                width: isActive ? 2.2 : 1.4,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.55),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
            padding: const EdgeInsets.all(5),
            child: Opacity(
              opacity: onCooldown ? 0.38 : 1.0,
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            bottom: -3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF030D1E).withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: onCooldown
                      ? Colors.white24
                      : color.withValues(alpha: 0.75),
                  width: 0.8,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: onCooldown ? Colors.white54 : Colors.white,
                  fontSize: 7.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          if (onCooldown)
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.58),
              ),
              alignment: Alignment.center,
              child: Text(
                cooldownText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPauseOrHelpModal(bool isVi) {
    return Container(
      color: Colors.black.withValues(alpha: 0.72),
      alignment: Alignment.center,
      child: Container(
        width: 460,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF041226),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF00F0FF), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00F0FF).withValues(alpha: 0.25),
              blurRadius: 24,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isVi
                  ? 'SÁT THỦ ĐẠI DƯƠNG - Cẩm Nang Săn Mồi'
                  : 'SHARK APEX HUNT - Tactical Guide',
              style: const TextStyle(
                color: Color(0xFF00F0FF),
                fontSize: 15.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isVi
                  ? '• Mặt Biển & Thuyền Bè: Người bơi trên mặt nước sẽ bỏ chạy lên thuyền khi thấy bạn! Cẩn thận mũi lao bắn từ Thuyền & Thợ Săn. Từ LV.3+, hãy giữ [TĂNG TỐC] phi lên không trung húc vỡ thuyền để ăn thịt thủy thủ!\n'
                    '• Độ Đói Khắt Khe: Máu tụt liên tục, buộc bạn phải săn mồi liên tục để sinh tồn.\n'
                    '• 2 Màn Chơi: Chuyển đổi trực tiếp giữa Màn 1 (Vịnh San Hô) & Màn 2 (Rãnh Dung Nham Mariana - thưởng x1.6 EXP/Điểm!).\n'
                    '• Cơn Sốt Vàng (Combo x6+): Đạt Combo 6 trở lên để kích hoạt Gold Rush bùng nổ điểm số!'
                  : '• Boats & Swimmers: Swimmers flee onto boats when spotted! Watch out for Harpoons. At LV.3+, breach into the air to smash boats and devour crew!\n'
                    '• Survival Hunger: HP drains steadily—keep hunting to stay alive.\n'
                    '• 2 Ocean Maps: Switch between Stage 1 (Coral Bay) & Stage 2 (Mariana Volcano - x1.6 Rewards!).\n'
                    '• Gold Rush (Combo x6+): Chain 6+ eats to trigger Gold Rush bonus!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.2,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E676),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                  onPressed: () {
                    setState(() {
                      _isPaused = false;
                      _showHelpOverlay = false;
                    });
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    isVi ? 'TIẾP TỤC SĂN MỒI' : 'RESUME HUNT',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF5252),
                    side: const BorderSide(color: Color(0xFFFF5252)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                  onPressed: _exitGame,
                  icon: const Icon(Icons.exit_to_app_rounded),
                  label: Text(isVi ? 'THOÁT' : 'EXIT'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOverModal(bool isVi) {
    return Container(
      color: Colors.black.withValues(alpha: 0.56),
      alignment: Alignment.center,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            width: 392,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
            decoration: BoxDecoration(
              color: const Color(0xD4141821),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.48),
                  blurRadius: 36,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF453A).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0xFFFF453A).withValues(alpha: 0.35),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    isVi ? 'KẾT THÚC' : 'GAME OVER',
                    style: const TextStyle(
                      color: Color(0xFFFF6961),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isVi ? 'Chuyến đi săn kết thúc' : 'Hunt Ended',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'LV.${_currentStage.level} · ${isVi ? _currentStage.nameVi : _currentStage.nameEn}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.09),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildGameOverStat(
                          label: isVi ? 'Điểm số' : 'Score',
                          value: '$_score',
                          valueColor: Colors.white,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                      Expanded(
                        child: _buildGameOverStat(
                          label: isVi ? 'Kỷ lục' : 'Best',
                          value: '$_highScore',
                          valueColor: const Color(0xFFFFD60A),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                      Expanded(
                        child: _buildGameOverStat(
                          label: isVi ? 'Đã săn' : 'Devoured',
                          value: '$_fishEatenCount',
                          valueColor: const Color(0xFF64D2FF),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    // Nút Trang Chủ bên TRÁI
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.10),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.12),
                                width: 0.8,
                              ),
                            ),
                          ),
                          onPressed: _exitGame,
                          icon: const Icon(Icons.home_rounded, size: 19),
                          label: Text(
                            isVi ? 'Trang chủ' : 'Home',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Nút Chơi Lại bên PHẢI
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: const Color(0xFF0A84FF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _initOceanWorld(map: _currentMap);
                            });
                          },
                          icon: const Icon(Icons.replay_rounded, size: 19),
                          label: Text(
                            isVi ? 'Chơi lại' : 'Play Again',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverStat({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CUSTOM PAINTER 1: ENGINE BIẾN DẠNG LƯỚI XƯƠNG SỐNG 16 ĐỐT + 2 MÀN CHƠI
// ═══════════════════════════════════════════════════════════════════════════
class _SharkWorldCanvasPainter extends CustomPainter {
  final _GameStageMap currentMap;
  final double playerX;
  final double playerY;
  final bool playerFacingRight;
  final double playerDorsalFlip;
  final double playerSwimPhase;
  final List<Offset> playerSpine;
  final _SharkEvolutionStage stage;
  final bool frenzyActive;
  final bool goldRushActive;
  final bool isBoosting;
  final double biteAnimTimer;
  final double vortexTimer;
  final double invulnerableTimer;
  final List<_SeaEntity> entities;
  final List<_SurfaceVessel> vessels;
  final List<_HarpoonProjectile> harpoons;
  final List<_OceanPickup> pickups;
  final List<_GameParticle> particles;
  final List<_FloatingTextPopup> popups;
  final List<_ShockwaveRing> shockwaves;
  final Map<String, _LoadedSpriteMesh> loadedMeshes;
  final bool isVi;

  _SharkWorldCanvasPainter({
    required this.currentMap,
    required this.playerX,
    required this.playerY,
    required this.playerFacingRight,
    required this.playerDorsalFlip,
    required this.playerSwimPhase,
    required this.playerSpine,
    required this.stage,
    required this.frenzyActive,
    required this.goldRushActive,
    required this.isBoosting,
    required this.biteAnimTimer,
    required this.vortexTimer,
    required this.invulnerableTimer,
    required this.entities,
    required this.vessels,
    required this.harpoons,
    required this.pickups,
    required this.particles,
    required this.popups,
    required this.shockwaves,
    required this.loadedMeshes,
    required this.isVi,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double worldW = _SharkGameScreenState.worldWidth;
    const double worldH = _SharkGameScreenState.worldHeight;
    const double seaY = _SharkGameScreenState.seaSurfaceY;
    final bool isMap2 = currentMap == _GameStageMap.volcanicAbyss;

    final double depthRatio =
        ((playerY - seaY) / (worldH - seaY)).clamp(0.0, 1.0);

    // Màu sắc nước biển khác biệt hoàn toàn giữa Màn 1 (Xanh San Hô) & Màn 2 (Tím Đỏ Dung Nham)
    final Color topWaterColor = isMap2
        ? Color.lerp(
            const Color(0xFF0B2244), const Color(0xFF14051A), depthRatio)!
        : Color.lerp(
            const Color(0xFF0083A8), const Color(0xFF020D20), depthRatio)!;
    final Color bottomWaterColor = isMap2
        ? Color.lerp(
            const Color(0xFF071128), const Color(0xFF1F060A), depthRatio)!
        : Color.lerp(
            const Color(0xFF013A63), const Color(0xFF01040A), depthRatio)!;

    final Rect screenRect = Offset.zero & size;
    final Paint bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [topWaterColor, bottomWaterColor],
      ).createShader(screenRect);
    canvas.drawRect(screenRect, bgPaint);

    final double camX = (playerX - size.width * 0.5)
        .clamp(0.0, math.max(0.0, worldW - size.width));
    final double camY = (playerY - size.height * 0.5)
        .clamp(0.0, math.max(0.0, worldH - size.height));

    canvas.save();
    canvas.translate(-camX, -camY);

    // 1. Vẽ Bầu Trời & Đường Chân Trời khi ở gần mặt biển (Y < seaY)
    if (camY < seaY + 480.0) {
      _paintSkyAndSeaSurface(canvas, worldW, seaY, isMap2);
    }

    // 2. Vẽ Đáy Biển & Rãnh Núi Lửa Dung Nham (Màn 2 rực lửa!)
    _paintSeabedAndHydrothermalVents(
        canvas, camX, camY, size, worldW, worldH, isMap2);

    // 3. Vẽ Thuyền Đánh Cá & Bè Gỗ trên mặt biển
    for (final v in vessels) {
      if (v.isDestroyed) continue;
      if (v.x + v.width < camX || v.x - v.width > camX + size.width) continue;
      if (camY > seaY + 120.0) continue;
      _paintSurfaceVessel(canvas, v, seaY);
    }

    if (vortexTimer > 0) {
      _paintWhirlpoolVortex(canvas);
    }

    for (final p in pickups) {
      if (p.x + 60 < camX ||
          p.x - 60 > camX + size.width ||
          p.y + 60 < camY ||
          p.y - 60 > camY + size.height) {
        continue;
      }
      _paintPickup(canvas, p);
    }

    // 4. Vẽ Mũi Lao (Harpoon) đang bay
    for (final h in harpoons) {
      _paintHarpoon(canvas, h);
    }

    // 5. Vẽ Sinh Vật & Người Bơi bằng Lưới Xương Sống 16 Đốt
    for (final e in entities) {
      final double pad = e.template.radius * 3.0;
      if (e.x + pad < camX ||
          e.x - pad > camX + size.width ||
          e.y + pad < camY ||
          e.y - pad > camY + size.height) {
        continue;
      }
      _paintSeaEntityWithSpineMesh(canvas, e);
    }

    // 6. Vẽ Cá Mập Người Chơi
    _paintPlayerSharkWithSpineMesh(canvas);

    for (final sw in shockwaves) {
      final Paint swPaint = Paint()
        ..color = sw.color.withValues(alpha: sw.alpha * 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0 + (1.0 - sw.alpha) * 6.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.drawCircle(Offset(sw.x, sw.y), sw.radius, swPaint);
    }

    for (final pt in particles) {
      final Paint ptPaint = Paint()
        ..color = pt.color.withValues(alpha: pt.alpha.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(pt.x, pt.y), pt.radius, ptPaint);
    }

    for (final pop in popups) {
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: pop.text,
          style: TextStyle(
            color: pop.color.withValues(alpha: pop.alpha.clamp(0.0, 1.0)),
            fontSize: pop.fontSize,
            fontWeight: FontWeight.w900,
            shadows: const [
              Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(pop.x - tp.width * 0.5, pop.y));
    }

    canvas.restore();
  }

  void _paintSkyAndSeaSurface(
      Canvas canvas, double worldW, double seaY, bool isMap2) {
    // 1. Bầu trời gradient chuyển sắc tự nhiên + mặt trời lấp lánh ở tầng mây
    final Rect skyRect = Rect.fromLTWH(0, 0, worldW, seaY);
    final Paint skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isMap2
            ? const [
                Color(0xFF140724),
                Color(0xFF421044),
                Color(0xFF8C143C),
                Color(0xFFD84315),
              ]
            : const [
                Color(0xFF0288D1),
                Color(0xFF4FC3F7),
                Color(0xFFB3E5FC),
                Color(0xFFE0F7FA),
              ],
        stops: const [0.0, 0.45, 0.82, 1.0],
      ).createShader(skyRect);
    canvas.drawRect(skyRect, skyPaint);

    // 1b. Hiệu ứng bầu trời sinh động cho Màn 2: Vầng Trăng Máu / Nhật Thực Núi Lửa & Tro bụi
    if (isMap2) {
      final Offset moonPos = Offset(worldW * 0.5, seaY - 92);
      canvas.drawCircle(
        moonPos,
        130,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0x99FF5722),
              const Color(0x33D500F9),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: moonPos, radius: 130)),
      );
      canvas.drawCircle(
        moonPos,
        46,
        Paint()..color = const Color(0xCCFF6E40),
      );
      canvas.drawCircle(
        Offset(moonPos.dx - 8, moonPos.dy - 5),
        38,
        Paint()..color = const Color(0xFF1A0726),
      );

      // Tro lửa núi lửa lơ lửng trên bầu trời Màn 2
      final Paint skyEmberPaint = Paint()..style = PaintingStyle.fill;
      for (int i = 0; i < 28; i++) {
        final double ex = (i * 157.0 + playerSwimPhase * 14.0) % worldW;
        final double ey =
            seaY - 12.0 - ((i * 39.0 + playerSwimPhase * 22.0) % (seaY - 24.0));
        skyEmberPaint.color = (i % 2 == 0
                ? const Color(0xFFFFAB40)
                : const Color(0xFFFF5252))
            .withValues(alpha: 0.45 + 0.35 * math.sin(playerSwimPhase + i));
        canvas.drawCircle(Offset(ex, ey), (i % 3) + 1.2, skyEmberPaint);
      }
    }

    // 2. Lớp sóng xa (Background Swell - di chuyển ngược chiều nhẹ)
    final Path backWave = Path()..moveTo(0, seaY + 42);
    for (double x = 0; x <= worldW; x += 32) {
      final double wy = seaY -
          4.0 +
          math.sin(x * 0.018 - playerSwimPhase * 0.55) * 7.5 +
          math.cos(x * 0.042 + playerSwimPhase * 0.35) * 3.0;
      backWave.lineTo(x, wy);
    }
    backWave.lineTo(worldW, seaY + 55);
    backWave.lineTo(0, seaY + 55);
    backWave.close();
    canvas.drawPath(
      backWave,
      Paint()
        ..color = (isMap2 ? const Color(0xFF0D2B52) : const Color(0xFF00698C))
            .withValues(alpha: 0.55),
    );

    // 3. Lớp sóng chính ở đường chân trời mặt biển (Main Rolling Ocean Swell)
    final Path midWave = Path()..moveTo(0, seaY + 55);
    final Path crestLine = Path();
    bool firstCrest = true;
    for (double x = 0; x <= worldW; x += 24) {
      final double wy = seaY +
          math.sin(x * 0.024 + playerSwimPhase * 0.85) * 8.5 +
          math.sin(x * 0.058 - playerSwimPhase * 0.45) * 3.2;
      midWave.lineTo(x, wy);
      if (firstCrest) {
        crestLine.moveTo(x, wy);
        firstCrest = false;
      } else {
        crestLine.lineTo(x, wy);
      }
    }
    midWave.lineTo(worldW, seaY + 75);
    midWave.lineTo(0, seaY + 75);
    midWave.close();

    canvas.drawPath(
      midWave,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isMap2
              ? const [Color(0xAA0E3B66), Color(0x000B2244)]
              : const [Color(0xCC26C6DA), Color(0x000083A8)],
        ).createShader(Rect.fromLTWH(0, seaY - 12, worldW, 88)),
    );

    // 4. Đường viền bọt trắng lấp lánh trên đỉnh sóng (Realistic Sea Foam Crest + Specular Shimmer)
    canvas.drawPath(
      crestLine,
      Paint()
        ..color = Colors.white.withValues(alpha: isMap2 ? 0.42 : 0.72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
    canvas.drawPath(
      crestLine,
      Paint()
        ..color = Colors.white.withValues(alpha: isMap2 ? 0.55 : 0.90)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // 5. Lưới ánh sáng khúc xạ dưới mặt nước (Underwater Caustic Ripples)
    final Paint causticPaint = Paint()
      ..color = (isMap2 ? const Color(0xFF40C4FF) : Colors.white)
          .withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    for (double x = 20; x < worldW; x += 140) {
      final double cx = x + math.sin(playerSwimPhase * 0.6 + x) * 18.0;
      final double cy = seaY + 26.0 + math.cos(playerSwimPhase * 0.7 + x) * 6.0;
      canvas.drawArc(
        Rect.fromCenter(center: Offset(cx, cy), width: 65, height: 14),
        0,
        math.pi,
        false,
        causticPaint,
      );
    }

    // 6. Chùm tia nắng chiếu xuyên mặt nước (Volumetric Sun God-Rays)
    final Paint rayPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          (isMap2 ? const Color(0x28FF7043) : const Color(0x3AE0F7FA)),
          const Color(0x1000E5FF),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, seaY, 200, 620));

    for (double x = 80; x < worldW; x += 260) {
      final double sway = math.sin(playerSwimPhase * 0.2 + x * 0.01) * 28.0;
      final Path rayPath = Path()
        ..moveTo(x, seaY)
        ..lineTo(x + 75, seaY)
        ..lineTo(x + 170 + sway, seaY + 620)
        ..lineTo(x - 40 + sway, seaY + 620)
        ..close();
      canvas.drawPath(rayPath, rayPaint);
    }
  }

  void _paintSurfaceVessel(
      Canvas canvas, _SurfaceVessel v, double seaY) {
    final String path = v.isFishingBoat
        ? 'assets/images/creatures/game_fishing_boat.png'
        : 'assets/images/creatures/game_wooden_raft.png';
    final _LoadedSpriteMesh? mesh = loadedMeshes[path];
    if (mesh == null) return;

    final double bobY = math.sin(v.bobPhase) * 5.0;
    final double tilt = math.cos(v.bobPhase * 0.8) * 0.04;
    final double centerY = seaY - v.height * 0.16 + bobY;

    canvas.save();
    canvas.translate(v.x, centerY);
    canvas.rotate(tilt);
    if (v.vx > 0) {
      canvas.scale(-1.0, 1.0);
    }

    final Rect dst = Rect.fromCenter(
        center: Offset.zero, width: v.width, height: v.height);
    final Rect src = Rect.fromLTWH(
        0, 0, mesh.image.width.toDouble(), mesh.image.height.toDouble());
    final Paint p = Paint()..filterQuality = FilterQuality.medium;
    if (v.hitFlashTimer > 0) {
      p.colorFilter = const ColorFilter.mode(
        Color(0x99FF1744),
        BlendMode.srcATop,
      );
    }
    canvas.drawImageRect(mesh.image, src, dst, p);
    canvas.restore();

    // Thanh máu thuyền nếu đã bị húc hoặc cá mập đủ LV.3+
    if (v.hp < v.maxHp || stage.level >= 3) {
      const double barW = 72.0;
      const double barH = 5.0;
      final Offset barPos = Offset(v.x - barW * 0.5, centerY - v.height * 0.55);
      canvas.drawRRect(
        RRect.fromRectAndRadius(barPos & const Size(barW, barH), const Radius.circular(3)),
        Paint()..color = Colors.black54,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          barPos & Size(barW * (v.hp / v.maxHp).clamp(0.0, 1.0), barH),
          const Radius.circular(3),
        ),
        Paint()
          ..color = stage.level >= 3
              ? const Color(0xFFFFEA00)
              : const Color(0xFFFF1744),
      );
    }
  }

  void _paintHarpoon(Canvas canvas, _HarpoonProjectile h) {
    final double angle = math.atan2(h.vy, h.vx);
    canvas.save();
    canvas.translate(h.x, h.y);
    canvas.rotate(angle);

    // Thân mũi lao thép phát sáng cảnh báo đỏ
    canvas.drawLine(
      const Offset(-18, 0),
      const Offset(14, 0),
      Paint()
        ..color = const Color(0xFFE0E0E0)
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round,
    );
    final Path head = Path()
      ..moveTo(20, 0)
      ..lineTo(9, -5)
      ..lineTo(11, 0)
      ..lineTo(9, 5)
      ..close();
    canvas.drawPath(head, Paint()..color = const Color(0xFFFF1744));
    canvas.restore();
  }

  void _drawDeformedSpineMesh({
    required Canvas canvas,
    required _LoadedSpriteMesh mesh,
    required Paint activePaint,
    required List<Offset> spine,
    required Rect uvBounds,
    required bool assetFacesRight,
    required double bodyLength,
    required double bodyHeight,
    required double dorsalFlip,
    required double swimPhase,
    required double waveAmplitudeRatio,
    double jawOpenProgress = 0.0,
  }) {
    final int n = spine.length;
    final double imgW = mesh.image.width.toDouble();
    final double imgH = mesh.image.height.toDouble();

    final double uHead =
        (assetFacesRight ? uvBounds.right : uvBounds.left) * imgW;
    final double uTail =
        (assetFacesRight ? uvBounds.left : uvBounds.right) * imgW;
    final double vTop = uvBounds.top * imgH;
    final double vBot = uvBounds.bottom * imgH;

    final double signedFlip = dorsalFlip >= 0
        ? math.max(0.32, dorsalFlip)
        : math.min(-0.32, dorsalFlip);

    final double maxWaveAmp = bodyLength * waveAmplitudeRatio;

    final List<Offset> positions = List<Offset>.filled(n * 2, Offset.zero);
    final List<Offset> texCoords = List<Offset>.filled(n * 2, Offset.zero);

    for (int i = 0; i < n; i++) {
      final double u = i / (n - 1);

      Offset tangent;
      if (i == 0) {
        tangent = spine[0] - spine[1];
      } else if (i == n - 1) {
        tangent = spine[n - 2] - spine[n - 1];
      } else {
        tangent = spine[i - 1] - spine[i + 1];
      }
      final double tLen = tangent.distance;
      final Offset unitT =
          tLen > 0.001 ? (tangent / tLen) : const Offset(1.0, 0.0);
      final Offset normal = Offset(-unitT.dy, unitT.dx);

      final double envelope = math.pow(u, 1.72).toDouble();
      final double waveOffset =
          maxWaveAmp * envelope * math.sin(swimPhase - 4.4 * u);
      final Offset displacedCenter = spine[i] + normal * waveOffset;
      final Offset dorsalUp = normal * (-signedFlip);

      double halfH = bodyHeight * 0.5;
      if (jawOpenProgress > 0.01 && i <= 3) {
        final double jawFactor =
            1.0 + 0.38 * (1.0 - i / 4.0) * math.sin(jawOpenProgress * math.pi);
        halfH *= jawFactor;
      }

      positions[i * 2] = displacedCenter + dorsalUp * halfH;
      positions[i * 2 + 1] = displacedCenter - dorsalUp * halfH;

      final double uTex = ui.lerpDouble(uHead, uTail, u)!;
      texCoords[i * 2] = Offset(uTex, vTop);
      texCoords[i * 2 + 1] = Offset(uTex, vBot);
    }

    final ui.Vertices vertices = ui.Vertices(
      ui.VertexMode.triangleStrip,
      positions,
      textureCoordinates: texCoords,
    );

    canvas.drawVertices(vertices, BlendMode.modulate, activePaint);
  }

  void _paintSeaEntityWithSpineMesh(Canvas canvas, _SeaEntity e) {
    final bool isEdible = e.template.tier <= stage.level || frenzyActive;
    final bool isDangerous = e.template.tier > stage.level && !frenzyActive;
    final double scaleFactor = e.isBeingSwallowed
        ? (1.0 - e.swallowProgress * 0.78).clamp(0.15, 1.0)
        : 1.0;
    final double r = e.template.radius * scaleFactor;
    final double bodyLen = r * 2.55;
    final double bodyHeight =
        (bodyLen / e.template.aspectRatio).clamp(r * 0.65, r * 2.1);

    final _LoadedSpriteMesh? mesh = loadedMeshes[e.template.assetPath];
    if (mesh != null) {
      Paint paintToUse = mesh.normalShaderPaint;
      if (e.hitFlashTimer > 0) {
        paintToUse = mesh.hitFlashShaderPaint;
      } else if (e.stunTimer > 0) {
        paintToUse = mesh.stunShaderPaint;
      } else if (goldRushActive && isEdible && !e.template.isHuman) {
        paintToUse = mesh.goldRushShaderPaint;
      }

      _drawDeformedSpineMesh(
        canvas: canvas,
        mesh: mesh,
        activePaint: paintToUse,
        spine: e.spineNodes,
        uvBounds: e.template.uvBounds,
        assetFacesRight: e.template.assetFacesRight,
        bodyLength: bodyLen,
        bodyHeight: bodyHeight,
        dorsalFlip: e.dorsalFlip,
        swimPhase: e.swimPhase,
        waveAmplitudeRatio: e.template.waveAmplitude,
      );
    }

    if (!e.isBeingSwallowed) {
      canvas.save();
      canvas.translate(e.x, e.y);
      _paintEntityOverheadBadge(canvas, e, r, isEdible, isDangerous);
      canvas.restore();
    }
  }

  void _paintPlayerSharkWithSpineMesh(Canvas canvas) {
    final double baseR = stage.baseRadius * (frenzyActive ? 1.25 : 1.0);
    final double bodyLen = baseR * 2.75;
    final double bodyHeight =
        (bodyLen / stage.aspectRatio).clamp(baseR * 0.85, baseR * 1.9);

    final Color ringColor = frenzyActive
        ? const Color(0xFFFF1744)
        : (goldRushActive ? const Color(0xFFFFD740) : stage.auraColor);
    final Paint auraPaint = Paint()
      ..color = ringColor.withValues(alpha: frenzyActive ? 0.35 : 0.14)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18.0);
    canvas.drawCircle(Offset(playerX, playerY), baseR * 1.2, auraPaint);

    final _LoadedSpriteMesh? mesh = loadedMeshes[stage.assetPath];
    if (mesh != null) {
      final Paint activePaint = frenzyActive
          ? mesh.frenzyShaderPaint
          : (goldRushActive
              ? mesh.goldRushShaderPaint
              : mesh.normalShaderPaint);
      final double jawProgress = (biteAnimTimer / 0.28).clamp(0.0, 1.0);

      _drawDeformedSpineMesh(
        canvas: canvas,
        mesh: mesh,
        activePaint: activePaint,
        spine: playerSpine,
        uvBounds: stage.uvBounds,
        assetFacesRight: false,
        bodyLength: bodyLen,
        bodyHeight: bodyHeight,
        dorsalFlip: playerDorsalFlip,
        swimPhase: playerSwimPhase,
        waveAmplitudeRatio: isBoosting ? 0.21 : 0.15,
        jawOpenProgress: jawProgress,
      );
    }

    if (biteAnimTimer > 0) {
      final Offset snout = playerSpine[0];
      final Paint jawWavePaint = Paint()
        ..color = const Color(0xFFFF1744).withValues(alpha: 0.72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: snout, radius: baseR * 0.65),
        playerFacingRight ? -math.pi * 0.42 : math.pi * 0.58,
        math.pi * 0.84,
        false,
        jawWavePaint,
      );
    }
  }

  void _paintEntityOverheadBadge(
    Canvas canvas,
    _SeaEntity e,
    double r,
    bool isEdible,
    bool isDangerous,
  ) {
    if (e.hp < e.maxHp || e.template.tier >= 3) {
      final double barW = math.max(32.0, r * 1.05);
      const double barH = 4.0;
      final Offset barTopLeft = Offset(-barW * 0.5, -r * 0.75 - 10.0);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          barTopLeft & Size(barW, barH),
          const Radius.circular(3),
        ),
        Paint()..color = Colors.black.withValues(alpha: 0.55),
      );

      final double hpRatio = (e.hp / e.maxHp).clamp(0.0, 1.0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          barTopLeft & Size(barW * hpRatio, barH),
          const Radius.circular(3),
        ),
        Paint()
          ..color =
              isEdible ? const Color(0xFF00E676) : const Color(0xFFFF1744),
      );
    }

    if (isDangerous || e.template.isHarpoonHunter) {
      canvas.drawCircle(
        Offset(0, -r * 0.75 - 15.0),
        3.8,
        Paint()..color = const Color(0xFFFF1744),
      );
    }
  }

  void _paintSeabedAndHydrothermalVents(
    Canvas canvas,
    double camX,
    double camY,
    Size size,
    double worldW,
    double worldH,
    bool isMap2,
  ) {
    final Paint snowPaint = Paint()
      ..color = (isMap2 ? const Color(0xFFFF8A65) : Colors.white)
          .withValues(alpha: 0.16);
    final int startCellX = (camX ~/ 180);
    final int endCellX = ((camX + size.width) ~/ 180) + 1;
    final int startCellY = math.max(2, (camY ~/ 180));
    final int endCellY = ((camY + size.height) ~/ 180) + 1;

    for (int gx = startCellX; gx <= endCellX; gx++) {
      for (int gy = startCellY; gy <= endCellY; gy++) {
        final int hash = (gx * 73856093) ^ (gy * 19349663);
        final double px = gx * 180.0 + (hash.abs() % 160);
        final double py = gy * 180.0 + ((hash ~/ 17).abs() % 160);
        if (isMap2) {
          // Màn 2: Tàn lửa dung nham bay lên & hạt phát quang sinh học tím/cyan sống động
          final double driftY =
              (py - playerSwimPhase * (18.0 + (hash.abs() % 14))) % worldH;
          final double emberY = driftY < 260 ? driftY + worldH - 260 : driftY;
          final double pulse =
              0.35 + 0.35 * math.sin(playerSwimPhase * 1.4 + hash * 0.01);
          final bool isEmber = hash.abs() % 3 != 0;
          final Color moteColor = isEmber
              ? const Color(0xFFFF7043)
              : (hash.abs() % 2 == 0
                  ? const Color(0xFFE040FB)
                  : const Color(0xFF18FFFF));
          final double radius = (hash.abs() % 3) + 1.3;
          if (hash.abs() % 4 == 0) {
            canvas.drawCircle(
              Offset(px, emberY),
              radius * 2.8,
              Paint()
                ..color = moteColor.withValues(alpha: pulse * 0.35)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0),
            );
          }
          canvas.drawCircle(
            Offset(px, emberY),
            radius,
            Paint()..color = moteColor.withValues(alpha: pulse),
          );
        } else {
          canvas.drawCircle(Offset(px, py), (hash.abs() % 3) + 1.0, snowPaint);
        }
      }
    }

    if (camY + size.height > worldH - 260.0) {
      // Đáy biển tối giản, thanh thoát: Đồi cát mềm uốn lượn nhẹ & sương mù đáy vực
      // 1. Lớp sương mù đáy vực dịu mắt (Soft Abyssal Floor Mist)
      final Rect mistRect = Rect.fromLTWH(0, worldH - 180, worldW, 180);
      canvas.drawRect(
        mistRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isMap2
                ? [
                    Colors.transparent,
                    const Color(0x553A080C),
                    const Color(0xCC120204),
                  ]
                : [
                    Colors.transparent,
                    const Color(0x44031B33),
                    const Color(0xCC010914),
                  ],
          ).createShader(mistRect),
      );

      // 2. Đường cồn cát đáy biển uốn lượn mềm mại bằng Bezier mượt mà (không gồ ghề rối mắt)
      final Path sandFloor = Path()..moveTo(0, worldH);
      const double step = 220.0;
      double prevX = 0.0;
      double prevY = worldH - 58.0;
      sandFloor.lineTo(prevX, prevY);

      for (double x = step; x <= worldW + step; x += step) {
        final double nextY = worldH - (54.0 + math.sin(x * 0.0045) * 20.0);
        final double midX = (prevX + x) * 0.5;
        final double midY = (prevY + nextY) * 0.5;
        sandFloor.quadraticBezierTo(prevX, prevY, midX, midY);
        prevX = x;
        prevY = nextY;
      }
      sandFloor.lineTo(worldW, worldH);
      sandFloor.close();

      canvas.drawPath(
        sandFloor,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isMap2
                ? const [Color(0xFF26090D), Color(0xFF090203)]
                : const [Color(0xFF0A243D), Color(0xFF020810)],
          ).createShader(Rect.fromLTWH(0, worldH - 95, worldW, 95)),
      );

      // 3. Điểm nhấn ánh sáng tinh tế (Vệt dung nham hắt sáng dịu ở Màn 2 / Điểm phát quang nhẹ ở Màn 1)
      if (isMap2) {
        final Paint gentleGlow = Paint()
          ..color = const Color(0xFFFF3D00).withValues(alpha: 0.38)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26.0);
        for (double vx = 380; vx < worldW; vx += 650) {
          final double pulse =
              0.78 + 0.22 * math.sin(playerSwimPhase * 1.3 + vx * 0.01);
          // Luồng ánh sáng nhiệt thủy hắt dịu lên tầng nước sâu
          final Rect plumeRect = Rect.fromCenter(
            center: Offset(vx, worldH - 120),
            width: 110,
            height: 210,
          );
          canvas.drawOval(
            plumeRect,
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  const Color(0xFFFF5722).withValues(alpha: 0.26 * pulse),
                  const Color(0xFFD500F9).withValues(alpha: 0.08 * pulse),
                  Colors.transparent,
                ],
              ).createShader(plumeRect),
          );
          canvas.drawOval(
            Rect.fromCenter(
                center: Offset(vx, worldH - 34), width: 96, height: 28),
            gentleGlow,
          );
          canvas.drawOval(
            Rect.fromCenter(
                center: Offset(vx, worldH - 34), width: 38, height: 10),
            Paint()..color = const Color(0xCCFF9100),
          );
        }
      }
    }
  }

  void _paintWhirlpoolVortex(Canvas canvas) {
    final Offset vortexCenter = playerSpine[0];
    for (int ring = 1; ring <= 3; ring++) {
      final double r =
          ring * 38.0 + math.sin(playerSwimPhase * 2 + ring) * 6.0;
      final Paint p = Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.55 / ring)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawArc(
        Rect.fromCircle(center: vortexCenter, radius: r),
        playerSwimPhase * 2.5 + ring,
        math.pi * 1.35,
        false,
        p,
      );
    }
  }

  void _paintPickup(Canvas canvas, _OceanPickup p) {
    final double pulse = 1.0 + math.sin(p.pulsePhase) * 0.12;
    final Offset center = Offset(p.x, p.y);

    if (p.type == _PickupType.healingPearl) {
      final Paint glow = Paint()
        ..color = const Color(0xFF00E676).withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(center, p.radius * 1.4 * pulse, glow);

      final Paint core = Paint()
        ..shader = const RadialGradient(
          colors: [Colors.white, Color(0xFF69F0AE), Color(0xFF00C853)],
        ).createShader(Rect.fromCircle(center: center, radius: p.radius));
      canvas.drawCircle(center, p.radius * pulse, core);
    } else if (p.type == _PickupType.goldenStar) {
      final Paint glow = Paint()
        ..color = const Color(0xFFFFD740).withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(center, p.radius * 1.4 * pulse, glow);

      final Paint core = Paint()
        ..shader = const RadialGradient(
          colors: [Colors.white, Color(0xFFFFEA00), Color(0xFFFF6D00)],
        ).createShader(Rect.fromCircle(center: center, radius: p.radius));
      canvas.drawCircle(center, p.radius * pulse, core);
    } else if (p.type == _PickupType.meatChunk) {
      final Paint meatPaint = Paint()..color = const Color(0xFFFF5252);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: center, width: p.radius * 1.8, height: p.radius * 1.3),
          const Radius.circular(8),
        ),
        meatPaint,
      );
      final Paint bonePaint = Paint()..color = Colors.white;
      canvas.drawCircle(center, p.radius * 0.35, bonePaint);
    } else if (p.type == _PickupType.navalMine) {
      final Paint mineBody = Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF546E7A), Color(0xFF263238), Colors.black],
        ).createShader(Rect.fromCircle(center: center, radius: p.radius));
      canvas.drawCircle(center, p.radius, mineBody);

      final Paint spikePaint = Paint()
        ..color = const Color(0xFF37474F)
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;
      for (int i = 0; i < 8; i++) {
        final double a = i * (math.pi / 4) + p.pulsePhase * 0.15;
        canvas.drawLine(
          center + Offset(math.cos(a), math.sin(a)) * (p.radius * 0.7),
          center + Offset(math.cos(a), math.sin(a)) * (p.radius * 1.35),
          spikePaint,
        );
      }

      final Paint blinkPaint = Paint()
        ..color = const Color(0xFFFF1744)
            .withValues(alpha: 0.45 + 0.55 * math.sin(p.pulsePhase * 2).abs());
      canvas.drawCircle(center, p.radius * 0.32, blinkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SharkWorldCanvasPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// CUSTOM PAINTER 2: MINI-MAP RADAR PHONG CÁCH PUBG (THÊM VỊ TRÍ THUYỀN)
// ═══════════════════════════════════════════════════════════════════════════
class _PubgMinimapPainter extends CustomPainter {
  final _GameStageMap currentMap;
  final double playerX;
  final double playerY;
  final double headingAngle;
  final int playerLevel;
  final List<_SeaEntity> entities;
  final List<_SurfaceVessel> vessels;
  final List<_OceanPickup> pickups;
  final double pulsePhase;

  _PubgMinimapPainter({
    required this.currentMap,
    required this.playerX,
    required this.playerY,
    required this.headingAngle,
    required this.playerLevel,
    required this.entities,
    required this.vessels,
    required this.pickups,
    required this.pulsePhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double worldW = _SharkGameScreenState.worldWidth;
    const double worldH = _SharkGameScreenState.worldHeight;
    final bool isMap2 = currentMap == _GameStageMap.volcanicAbyss;

    final Rect fullRect = Offset.zero & size;
    final Paint bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isMap2
            ? const [
                Color(0xFF280B2E),
                Color(0xFF150822),
                Color(0xFF220505),
              ]
            : const [
                Color(0xFF042B44),
                Color(0xFF02182B),
                Color(0xFF010913),
              ],
      ).createShader(fullRect);
    canvas.drawRect(fullRect, bgPaint);

    final Paint gridPaint = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.14)
      ..strokeWidth = 0.7;
    for (int i = 1; i < 4; i++) {
      final double gx = size.width * (i / 4);
      final double gy = size.height * (i / 4);
      canvas.drawLine(Offset(gx, 0), Offset(gx, size.height), gridPaint);
      canvas.drawLine(Offset(0, gy), Offset(size.width, gy), gridPaint);
    }

    // Vẽ Thuyền & Bè trên mặt nước (Chấm vàng)
    for (final v in vessels) {
      if (v.isDestroyed) continue;
      final double vx = (v.x / worldW) * size.width;
      final double vy = (_SharkGameScreenState.seaSurfaceY / worldH) * size.height;
      canvas.drawRect(
        Rect.fromCenter(center: Offset(vx, vy), width: 6.5, height: 3.2),
        Paint()..color = const Color(0xFFFFEA00),
      );
    }

    for (final e in entities) {
      final double mx = (e.x / worldW) * size.width;
      final double my = (e.y / worldH) * size.height;
      final bool edible = e.template.tier <= playerLevel;
      final Color dotColor = edible
          ? const Color(0xFF00E676).withValues(alpha: 0.85)
          : const Color(0xFFFF9100);
      final double dotRadius = e.template.tier >= 5 ? 2.8 : 1.9;
      canvas.drawCircle(Offset(mx, my), dotRadius, Paint()..color = dotColor);
    }

    final double px = (playerX / worldW) * size.width;
    final double py = (playerY / worldH) * size.height;
    final Offset playerMapPos = Offset(px, py);

    canvas.drawRect(
      Rect.fromCenter(center: playerMapPos, width: 32, height: 20),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    final Paint conePaint = Paint()
      ..color = const Color(0xFFFF1744).withValues(alpha: 0.32)
      ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromCircle(center: playerMapPos, radius: 14.0),
      headingAngle - 0.45,
      0.9,
      true,
      conePaint,
    );

    final double pulseR = 4.5 + (pulsePhase % (math.pi * 2)) * 1.4;
    canvas.drawCircle(
      playerMapPos,
      pulseR,
      Paint()
        ..color = const Color(0xFFFF1744).withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    canvas.drawCircle(
      playerMapPos,
      4.2,
      Paint()..color = const Color(0xFFFF1744),
    );
    canvas.drawCircle(
      playerMapPos,
      4.2,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );
  }

  @override
  bool shouldRepaint(covariant _PubgMinimapPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// CUSTOM PAINTER 3: CẦN ĐIỀU KHIỂN ẢO BÊN TRÁI CHUẨN GAME MOBA / PUBG
// ═══════════════════════════════════════════════════════════════════════════
class _VirtualJoystickPainter extends CustomPainter {
  final Offset? origin;
  final Offset? current;
  final Offset defaultCenter;

  _VirtualJoystickPainter({
    required this.origin,
    required this.current,
    required this.defaultCenter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bool isActive = origin != null;
    final Offset baseCenter = origin ?? defaultCenter;
    final Offset knobCenter = current ?? baseCenter;
    const double outerRadius = 56.0;
    const double innerRadius = 21.0;

    final Offset delta = knobCenter - baseCenter;
    final double dist = delta.distance;
    final double dragRatio = (dist / outerRadius).clamp(0.0, 1.0);
    final double dragAngle = dist > 2.0 ? math.atan2(delta.dy, delta.dx) : 0.0;
    final double masterAlpha = isActive ? 0.95 : 0.52;

    final Rect baseRect =
        Rect.fromCircle(center: baseCenter, radius: outerRadius);
    final Paint baseFill = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF020B18).withValues(alpha: 0.15 * masterAlpha),
          const Color(0xFF041830).withValues(alpha: 0.42 * masterAlpha),
          const Color(0xFF00E5FF).withValues(alpha: 0.16 * masterAlpha),
        ],
        stops: const [0.0, 0.72, 1.0],
      ).createShader(baseRect);
    canvas.drawCircle(baseCenter, outerRadius, baseFill);

    canvas.drawCircle(
      baseCenter,
      outerRadius * 0.42,
      Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.18 * masterAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    final Paint segmentPaint = Paint()
      ..color = const Color(0xFF80D8FF).withValues(alpha: 0.48 * masterAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 4; i++) {
      final double startA = i * (math.pi * 0.5) - math.pi * 0.18;
      canvas.drawArc(baseRect, startA, math.pi * 0.36, false, segmentPaint);
    }

    for (int i = 0; i < 4; i++) {
      final double a = i * (math.pi * 0.5);
      final Offset tip =
          baseCenter + Offset(math.cos(a), math.sin(a)) * (outerRadius - 5.5);
      final Offset leftWing = baseCenter +
          Offset(math.cos(a - 0.13), math.sin(a - 0.13)) *
              (outerRadius - 11.5);
      final Offset rightWing = baseCenter +
          Offset(math.cos(a + 0.13), math.sin(a + 0.13)) *
              (outerRadius - 11.5);

      final Path chevron = Path()
        ..moveTo(leftWing.dx, leftWing.dy)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(rightWing.dx, rightWing.dy)
        ..close();

      canvas.drawPath(
        chevron,
        Paint()
          ..color =
              const Color(0xFF00F0FF).withValues(alpha: 0.55 * masterAlpha)
          ..style = PaintingStyle.fill,
      );
    }

    if (isActive && dragRatio > 0.08) {
      final Paint glowArcPaint = Paint()
        ..color = const Color(0xFF00F0FF).withValues(alpha: 0.55 * dragRatio)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.drawArc(
        Rect.fromCircle(center: baseCenter, radius: outerRadius + 1.5),
        dragAngle - 0.52,
        1.04,
        false,
        glowArcPaint,
      );

      final Paint coreArcPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.9 * dragRatio)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: baseCenter, radius: outerRadius + 1.5),
        dragAngle - 0.42,
        0.84,
        false,
        coreArcPaint,
      );

      final Offset pointerTip = baseCenter +
          Offset(math.cos(dragAngle), math.sin(dragAngle)) *
              (outerRadius + 11.0);
      final Offset pLeft = baseCenter +
          Offset(math.cos(dragAngle - 0.14), math.sin(dragAngle - 0.14)) *
              (outerRadius + 4.0);
      final Offset pRight = baseCenter +
          Offset(math.cos(dragAngle + 0.14), math.sin(dragAngle + 0.14)) *
              (outerRadius + 4.0);
      final Path pointerPath = Path()
        ..moveTo(pointerTip.dx, pointerTip.dy)
        ..lineTo(pLeft.dx, pLeft.dy)
        ..lineTo(pRight.dx, pRight.dy)
        ..close();
      canvas.drawPath(
        pointerPath,
        Paint()..color = const Color(0xFF00F0FF).withValues(alpha: dragRatio),
      );

      final Offset perp = Offset(-math.sin(dragAngle), math.cos(dragAngle));
      final Path beamPath = Path()
        ..moveTo(baseCenter.dx + perp.dx * 4.0, baseCenter.dy + perp.dy * 4.0)
        ..lineTo(
            knobCenter.dx + perp.dx * 11.0, knobCenter.dy + perp.dy * 11.0)
        ..lineTo(
            knobCenter.dx - perp.dx * 11.0, knobCenter.dy - perp.dy * 11.0)
        ..lineTo(baseCenter.dx - perp.dx * 4.0, baseCenter.dy - perp.dy * 4.0)
        ..close();
      canvas.drawPath(
        beamPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment(-math.cos(dragAngle), -math.sin(dragAngle)),
            end: Alignment(math.cos(dragAngle), math.sin(dragAngle)),
            colors: const [Color(0x0000E5FF), Color(0x5500E5FF)],
          ).createShader(baseRect),
      );
    }

    canvas.drawCircle(
      knobCenter + const Offset(0, 3),
      innerRadius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.55 * masterAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0),
    );

    final Rect knobRect =
        Rect.fromCircle(center: knobCenter, radius: innerRadius);
    canvas.drawCircle(
      knobCenter,
      innerRadius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.35),
          radius: 0.95,
          colors: [
            const Color(0xFF1A4B7C).withValues(alpha: masterAlpha),
            const Color(0xFF071D38).withValues(alpha: masterAlpha),
            const Color(0xFF020A16).withValues(alpha: masterAlpha),
          ],
        ).createShader(knobRect),
    );

    canvas.drawCircle(
      knobCenter,
      innerRadius,
      Paint()
        ..color = const Color(0xFF00F0FF).withValues(alpha: 0.9 * masterAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    canvas.drawCircle(
      knobCenter,
      innerRadius * 0.48,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: masterAlpha),
            const Color(0xFF00E5FF).withValues(alpha: 0.9 * masterAlpha),
            const Color(0xFF00838F).withValues(alpha: 0.6 * masterAlpha),
          ],
        ).createShader(
          Rect.fromCircle(center: knobCenter, radius: innerRadius * 0.48),
        ),
    );

    canvas.drawArc(
      Rect.fromCircle(center: knobCenter, radius: innerRadius - 3.5),
      -math.pi * 0.8,
      math.pi * 0.6,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.45 * masterAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _VirtualJoystickPainter oldDelegate) {
    return oldDelegate.origin != origin || oldDelegate.current != current;
  }
}

/// Vòng cung tiến trình Kinh Nghiệm (EXP Ring) ôm quanh viền Avatar tròn
class _AvatarExpRingPainter extends CustomPainter {
  final double expRatio;
  final bool frenzy;

  _AvatarExpRingPainter({
    required this.expRatio,
    required this.frenzy,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width * 0.5, size.height * 0.5);
    final double radius = size.width * 0.5 - 2.0;

    final Paint trackPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2;
    canvas.drawCircle(center, radius, trackPaint);

    final Paint innerRim = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius - 1.8, innerRim);

    final double sweep = (expRatio.clamp(0.0, 1.0)) * math.pi * 2;
    if (sweep > 0.01) {
      final Rect rect = Rect.fromCircle(center: center, radius: radius);
      final Paint arcPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          colors: frenzy
              ? const [Color(0xFFFF1744), Color(0xFFFF9100), Color(0xFFFF1744)]
              : const [Color(0xFFFF8F00), Color(0xFFFFEA00), Color(0xFFFFD740)],
        ).createShader(rect);
      canvas.drawArc(rect, -math.pi * 0.5, sweep, false, arcPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AvatarExpRingPainter oldDelegate) {
    return oldDelegate.expRatio != expRatio || oldDelegate.frenzy != frenzy;
  }
}
