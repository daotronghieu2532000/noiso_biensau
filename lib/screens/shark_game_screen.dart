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
/// Sử dụng Engine Lưới Xương Sống 16 Đốt (16-Joint Spine Kinematics + GPU Mesh Skinning drawVertices)
/// kết hợp 100% tài nguyên hình ảnh 3D chân thực tách nền trong suốt.
class SharkGameScreen extends StatefulWidget {
  const SharkGameScreen({super.key});

  @override
  State<SharkGameScreen> createState() => _SharkGameScreenState();
}

/// Dữ liệu Sprite đã nạp kèm ImageShader trên GPU để uốn lưới xương sống 60-120 FPS
class _LoadedSpriteMesh {
  final ui.Image image;
  final Paint normalShaderPaint;
  final Paint hitFlashShaderPaint;
  final Paint stunShaderPaint;
  final Paint frenzyShaderPaint;

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
          );
}

/// Cấu hình các cấp tiến hóa của Cá Mập Người Chơi
class _SharkEvolutionStage {
  final int level;
  final String nameVi;
  final String nameEn;
  final String assetPath;
  final Rect uvBounds; // Khung UV sát mũi -> đuôi cá trong ảnh gốc (0..1)
  final double aspectRatio; // Tỷ lệ Dài / Cao thực tế của cơ thể cá
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

/// Cấu hình loài sinh vật (100% dùng ảnh 3D tách nền chân thực + Lưới Xương Sống 16 Đốt)
class _CreatureTemplate {
  final String id;
  final String nameVi;
  final String nameEn;
  final int tier; // 1 -> 6
  final String assetPath;
  final bool assetFacesRight;
  final Rect uvBounds; // Khung UV sát cơ thể trong ảnh gốc (0..1)
  final double aspectRatio; // Tỷ lệ Dài / Cao thực tế
  final double radius;
  final double speed;
  final double waveAmplitude; // Độ biên độ vẫy đuôi sinh học
  final double waveFrequency; // Tần số vẫy đuôi
  final double maxHp;
  final double damage;
  final int expReward;
  final int scoreReward;
  final double minDepthRatio;
  final double maxDepthRatio;
  final bool isAggressive;
  final int schoolSize; // > 1 thì bơi theo đàn tự nhiên (Boids Schooling)
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
    this.schoolSize = 1,
    required this.primaryColor,
  });
}

/// Thực thể sinh vật đang bơi trong đại dương với Chuỗi Xương Sống 16 Đốt (16-Node Spine Chain)
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

  bool facingRight;
  double dorsalFlip; // Chuyển tiếp mượt từ +1.0 (phải) <-> -1.0 (trái) khi quay đầu 3D

  // Trạng thái bị hút xoắn vào miệng cá mập khi bị ăn (Swallow Animation giống Feeding Frenzy)
  bool isBeingSwallowed = false;
  double swallowProgress = 0.0;

  // Chuỗi 16 đốt xương sống từ Mõm (index 0) đến Chóp Đuôi (index 15)
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

/// Vật phẩm rơi ra hoặc ngọc trai hồi phục / thủy lôi
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

/// Hiệu ứng hạt (Máu, Bọt khí, Tia sáng tiến hóa)
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

/// Chữ nổi trên màn hình (+EXP, +HP, ĐỚP!, TIẾN HÓA!)
class _FloatingTextPopup {
  String text;
  double x;
  double y;
  double vy = -42.0;
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

/// Sóng xung kích (Sonar Roar / Level Up / Mine Explosion)
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
  static const double worldWidth = 4000.0;
  static const double worldHeight = 2500.0;
  static const int kPlayerSpineJoints = 16;
  static const String _highScoreKey = 'shark_game_high_score_v1';

  // Danh sách 6 cấp tiến hóa của Cá Mập Người Chơi (Kèm khung UV sát cơ thể)
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
      expRequired: 120,
      maxHp: 100.0,
      biteDamage: 38.0,
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
      expRequired: 300,
      maxHp: 155.0,
      biteDamage: 65.0,
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
      expRequired: 600,
      maxHp: 230.0,
      biteDamage: 100.0,
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
      expRequired: 1050,
      maxHp: 340.0,
      biteDamage: 155.0,
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
      expRequired: 1800,
      maxHp: 490.0,
      biteDamage: 240.0,
      auraColor: Color(0xFFFF5252),
    ),
    _SharkEvolutionStage(
      level: 6,
      nameVi: 'Chúa Tể Vực Thẳm Leviathan',
      nameEn: 'Abyssal Emperor Leviathan',
      assetPath: 'assets/images/creatures/reaper_leviathan.png',
      uvBounds: Rect.fromLTRB(0.057, 0.345, 0.960, 0.682),
      aspectRatio: 2.68,
      baseRadius: 96.0,
      lengthMeters: 36.0,
      expRequired: 999999,
      maxHp: 720.0,
      biteDamage: 380.0,
      auraColor: Color(0xFFE040FB),
    ),
  ];

  // Danh mục 20 loài sinh vật biển sử dụng 100% ảnh 3D chân thực tách nền + uốn xương sống
  static const List<_CreatureTemplate> _speciesCatalog = [
    // ── TIER 1: ĐÀN CÁ CON MỒI (Bơi theo đàn Boids, ăn ngay từ Cấp 1) ──
    _CreatureTemplate(
      id: 'clownfish',
      nameVi: 'Cá Hề Rạn San Hô',
      nameEn: 'Coral Clownfish',
      tier: 1,
      assetPath: 'assets/images/creatures/game_clownfish_solo.png',
      assetFacesRight: false,
      aspectRatio: 1.83,
      radius: 17.0,
      speed: 88.0,
      waveAmplitude: 0.19,
      waveFrequency: 7.2,
      maxHp: 15.0,
      damage: 0.0,
      expReward: 13,
      scoreReward: 55,
      minDepthRatio: 0.04,
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
      speed: 96.0,
      waveAmplitude: 0.18,
      waveFrequency: 7.0,
      maxHp: 18.0,
      damage: 0.0,
      expReward: 15,
      scoreReward: 65,
      minDepthRatio: 0.05,
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
      speed: 125.0,
      waveAmplitude: 0.16,
      waveFrequency: 7.8,
      maxHp: 22.0,
      damage: 0.0,
      expReward: 19,
      scoreReward: 90,
      minDepthRatio: 0.07,
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
      speed: 68.0,
      waveAmplitude: 0.11,
      waveFrequency: 5.2,
      maxHp: 24.0,
      damage: 4.0,
      expReward: 22,
      scoreReward: 100,
      minDepthRatio: 0.42,
      maxDepthRatio: 0.95,
      schoolSize: 2,
      primaryColor: Color(0xFFB0BEC5),
    ),

    // ── TIER 2: SINH VẬT TẦNG TRUNG (Rùa biển, Cá đuối, Bạch tuộc, Cá lồng đèn) ──
    _CreatureTemplate(
      id: 'sea_turtle',
      nameVi: 'Rùa Biển Cổ Đại',
      nameEn: 'Green Sea Turtle',
      tier: 2,
      assetPath: 'assets/images/creatures/game_sea_turtle.png',
      assetFacesRight: false,
      aspectRatio: 2.07,
      radius: 32.0,
      speed: 82.0,
      waveAmplitude: 0.12,
      waveFrequency: 4.5,
      maxHp: 55.0,
      damage: 6.0,
      expReward: 38,
      scoreReward: 160,
      minDepthRatio: 0.06,
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
      speed: 98.0,
      waveAmplitude: 0.20,
      waveFrequency: 4.8,
      maxHp: 62.0,
      damage: 8.0,
      expReward: 44,
      scoreReward: 190,
      minDepthRatio: 0.10,
      maxDepthRatio: 0.68,
      primaryColor: Color(0xFF40C4FF),
    ),
    _CreatureTemplate(
      id: 'red_octopus',
      nameVi: 'Bạch Tuộc Đỏ Thái Bình Dương',
      nameEn: 'Pacific Red Octopus',
      tier: 2,
      assetPath: 'assets/images/creatures/game_red_octopus.png',
      assetFacesRight: true, // Đầu bên phải, xúc tu vẫy bên trái
      aspectRatio: 2.85,
      radius: 35.0,
      speed: 94.0,
      waveAmplitude: 0.22,
      waveFrequency: 5.6,
      maxHp: 64.0,
      damage: 12.0,
      expReward: 46,
      scoreReward: 210,
      minDepthRatio: 0.18,
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
      speed: 90.0,
      waveAmplitude: 0.14,
      waveFrequency: 6.0,
      maxHp: 65.0,
      damage: 15.0,
      expReward: 48,
      scoreReward: 220,
      minDepthRatio: 0.30,
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
      speed: 102.0,
      waveAmplitude: 0.21,
      waveFrequency: 6.4,
      maxHp: 70.0,
      damage: 16.0,
      expReward: 52,
      scoreReward: 240,
      minDepthRatio: 0.34,
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
      speed: 96.0,
      waveAmplitude: 0.18,
      waveFrequency: 5.5,
      maxHp: 68.0,
      damage: 14.0,
      expReward: 50,
      scoreReward: 230,
      minDepthRatio: 0.32,
      maxDepthRatio: 0.88,
      primaryColor: Color(0xFFFF1744),
    ),

    // ── TIER 3: THỢ SĂN TỐC ĐỘ (Cá Kiếm, Cá Mập Đầu Búa, Cá Mái Chèo, Mực Khổng Lồ) ──
    _CreatureTemplate(
      id: 'swordfish',
      nameVi: 'Cá Kiếm Đại Dương',
      nameEn: 'Blue Marlin Swordfish',
      tier: 3,
      assetPath: 'assets/images/creatures/game_swordfish.png',
      assetFacesRight: false,
      aspectRatio: 2.85,
      radius: 44.0,
      speed: 132.0,
      waveAmplitude: 0.17,
      waveFrequency: 7.4,
      maxHp: 115.0,
      damage: 22.0,
      expReward: 85,
      scoreReward: 400,
      minDepthRatio: 0.10,
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
      speed: 118.0,
      waveAmplitude: 0.17,
      waveFrequency: 6.5,
      maxHp: 125.0,
      damage: 24.0,
      expReward: 92,
      scoreReward: 440,
      minDepthRatio: 0.12,
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
      speed: 98.0,
      waveAmplitude: 0.25,
      waveFrequency: 6.2,
      maxHp: 120.0,
      damage: 20.0,
      expReward: 88,
      scoreReward: 420,
      minDepthRatio: 0.25,
      maxDepthRatio: 0.84,
      primaryColor: Color(0xFF80D8FF),
    ),
    _CreatureTemplate(
      id: 'giant_squid',
      nameVi: 'Mực Khổng Lồ Architeuthis',
      nameEn: 'Architeuthis Giant Squid',
      tier: 3,
      assetPath: 'assets/images/creatures/giant_squid.png',
      assetFacesRight: true, // Đầu/thân bên phải, xúc tu bên trái
      uvBounds: Rect.fromLTRB(0.067, 0.228, 0.943, 0.965),
      aspectRatio: 1.65,
      radius: 48.0,
      speed: 112.0,
      waveAmplitude: 0.20,
      waveFrequency: 5.8,
      maxHp: 140.0,
      damage: 26.0,
      expReward: 105,
      scoreReward: 500,
      minDepthRatio: 0.30,
      maxDepthRatio: 0.90,
      isAggressive: true,
      primaryColor: Color(0xFFFF9100),
    ),

    // ── TIER 4: SÁT THỦ ĐẠI DƯƠNG (Cá Mập Bắc Cực, Cá Voi Lưng Gù, Hổ Kình Orca) ──
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
      speed: 100.0,
      waveAmplitude: 0.16,
      waveFrequency: 5.4,
      maxHp: 210.0,
      damage: 34.0,
      expReward: 155,
      scoreReward: 760,
      minDepthRatio: 0.35,
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
      speed: 86.0,
      waveAmplitude: 0.14,
      waveFrequency: 4.5,
      maxHp: 250.0,
      damage: 30.0,
      expReward: 180,
      scoreReward: 880,
      minDepthRatio: 0.14,
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
      speed: 120.0,
      waveAmplitude: 0.16,
      waveFrequency: 5.8,
      maxHp: 240.0,
      damage: 38.0,
      expReward: 190,
      scoreReward: 950,
      minDepthRatio: 0.15,
      maxDepthRatio: 0.78,
      isAggressive: true,
      primaryColor: Color(0xFFFFD740),
    ),

    // ── TIER 5: QUÁI VẬT CỔ ĐẠI (Megalodon, Kraken, The Bloop) ──
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
      speed: 98.0,
      waveAmplitude: 0.15,
      waveFrequency: 5.0,
      maxHp: 350.0,
      damage: 48.0,
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
      speed: 116.0,
      waveAmplitude: 0.17,
      waveFrequency: 5.6,
      maxHp: 390.0,
      damage: 55.0,
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
      speed: 96.0,
      waveAmplitude: 0.18,
      waveFrequency: 5.2,
      maxHp: 380.0,
      damage: 52.0,
      expReward: 310,
      scoreReward: 1650,
      minDepthRatio: 0.55,
      maxDepthRatio: 0.98,
      isAggressive: true,
      primaryColor: Color(0xFFFF1744),
    ),

    // ── TIER 6: THẦN THOẠI ĐÁY VỰC (Reaper Leviathan, Lagiacrus, Leviathan) ──
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
      speed: 122.0,
      waveAmplitude: 0.22,
      waveFrequency: 6.2,
      maxHp: 520.0,
      damage: 68.0,
      expReward: 490,
      scoreReward: 2900,
      minDepthRatio: 0.65,
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
      speed: 118.0,
      waveAmplitude: 0.21,
      waveFrequency: 6.0,
      maxHp: 500.0,
      damage: 65.0,
      expReward: 470,
      scoreReward: 2700,
      minDepthRatio: 0.62,
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
      speed: 116.0,
      waveAmplitude: 0.20,
      waveFrequency: 5.8,
      maxHp: 510.0,
      damage: 66.0,
      expReward: 480,
      scoreReward: 2800,
      minDepthRatio: 0.64,
      maxDepthRatio: 0.98,
      isAggressive: true,
      primaryColor: Color(0xFF00E676),
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

  // Trạng thái & Chuỗi Xương Sống 16 Đốt của Cá Mập Người Chơi
  int _stageIndex = 0;
  double _playerX = worldWidth * 0.5;
  double _playerY = 340.0;
  double _playerVx = 120.0;
  double _playerVy = 0.0;
  double _playerHeadingAngle = 0.0;
  bool _playerFacingRight = true;
  double _playerDorsalFlip = 1.0; // +1.0 (phải) <-> -1.0 (trái)
  double _playerSwimPhase = 0.0;
  final List<Offset> _playerSpine =
      List<Offset>.filled(kPlayerSpineJoints, Offset.zero);

  double _hp = 100.0;
  double _stamina = 100.0;
  int _exp = 0;
  int _score = 0;
  int _highScore = 0;
  int _fishEatenCount = 0;
  int _nextSchoolGroupId = 1;

  // Combo & Fury (Cuồng Nộ)
  int _comboCount = 0;
  double _comboTimer = 0.0;
  double _furyCharge = 0.0;
  double _frenzyTimer = 0.0;

  // Kỹ năng chủ động
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

  // Danh sách thực thể trong thế giới
  final List<_SeaEntity> _entities = [];
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
    _initOceanWorld();

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
    };

    for (final path in paths) {
      try {
        final ByteData data = await rootBundle.load(path);
        final ui.Codec codec = await ui.instantiateImageCodec(
          data.buffer.asUint8List(),
          targetWidth: 420,
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

  void _initOceanWorld() {
    _stageIndex = 0;
    _playerX = worldWidth * 0.5;
    _playerY = 340.0;
    _playerVx = 95.0;
    _playerVy = 0.0;
    _playerHeadingAngle = 0.0;
    _playerFacingRight = true;
    _playerDorsalFlip = 1.0;
    _initPlayerSpine();

    _hp = _currentStage.maxHp;
    _stamina = 100.0;
    _exp = 0;
    _score = 0;
    _fishEatenCount = 0;
    _comboCount = 0;
    _comboTimer = 0.0;
    _furyCharge = 35.0;
    _frenzyTimer = 0.0;
    _biteAnimTimer = 0.0;
    _biteCooldown = 0.0;
    _vortexTimer = 0.0;
    _vortexCooldown = 0.0;
    _roarCooldown = 0.0;
    _invulnerableTimer = 2.0;
    _isGameOver = false;
    _isPaused = false;

    _entities.clear();
    _pickups.clear();
    _particles.clear();
    _popups.clear();
    _shockwaves.clear();

    // Khởi tạo các đàn cá & sinh vật đại dương
    while (_entities.length < 68) {
      _spawnRandomEntityOrSchool(avoidPlayer: true);
    }

    for (int i = 0; i < 16; i++) {
      _spawnRandomPickup();
    }
  }

  void _spawnRandomEntityOrSchool({bool avoidPlayer = false}) {
    final double roll = _rng.nextDouble();
    int targetTier;
    if (roll < 0.45) {
      targetTier = 1;
    } else if (roll < 0.72) {
      targetTier = 2;
    } else if (roll < 0.86) {
      targetTier = 3;
    } else if (roll < 0.94) {
      targetTier = 4;
    } else if (roll < 0.985) {
      targetTier = 5;
    } else {
      targetTier = 6;
    }

    final candidates =
        _speciesCatalog.where((c) => c.tier == targetTier).toList();
    final template = candidates[_rng.nextInt(candidates.length)];

    double baseX = 120.0 + _rng.nextDouble() * (worldWidth - 240.0);
    double baseY = (template.minDepthRatio +
            _rng.nextDouble() *
                (template.maxDepthRatio - template.minDepthRatio)) *
        worldHeight;

    if (avoidPlayer) {
      final double dx = baseX - _playerX;
      final double dy = baseY - _playerY;
      if (dx * dx + dy * dy < 420.0 * 420.0 &&
          template.tier > _currentStage.level) {
        baseX = (_playerX + 700.0) % (worldWidth - 240.0) + 120.0;
      }
    }

    final double dir = _rng.nextBool() ? 1.0 : -1.0;
    final double baseVx = dir * template.speed * (0.8 + _rng.nextDouble() * 0.35);
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
          y: (baseY + oy).clamp(75.0, worldHeight - 85.0),
          vx: baseVx * (0.92 + _rng.nextDouble() * 0.16),
          vy: baseVy,
          swimPhase: _rng.nextDouble() * math.pi * 2,
        ),
      );
    }
  }

  void _spawnRandomPickup() {
    final double r = _rng.nextDouble();
    final _PickupType type;
    double minY = 120.0;
    double maxY = worldHeight - 120.0;
    double radius = 16.0;

    if (r < 0.45) {
      type = _PickupType.healingPearl;
      radius = 15.0;
    } else if (r < 0.72) {
      type = _PickupType.goldenStar;
      radius = 16.0;
    } else {
      type = _PickupType.navalMine;
      minY = 380.0;
      radius = 24.0;
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

  /// Cập nhật Động Học Chuỗi Xương Sống 16 Đốt (Follow-the-Leader Spine Kinematics)
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

    // Đốt 0 (Mõm/Đầu) dẫn đường ở phía trước trọng tâm
    final Offset targetHead = Offset(
      centerX + cosH * (bodyLength * 0.44),
      centerY + sinH * (bodyLength * 0.44),
    );
    spine[0] = targetHead;

    // Hướng chuẩn từ đầu về đuôi là (-cosH, -sinH)
    final double idealBackAngle = headingAngle + math.pi;

    // Các đốt 1..15 bám theo đốt phía trước với giới hạn độ uốn cong tự nhiên (max 14 độ/đốt)
    double prevSegAngle = idealBackAngle;
    for (int i = 1; i < n; i++) {
      final Offset prev = spine[i - 1];
      final Offset curr = spine[i];
      final double dx = curr.dx - prev.dx;
      final double dy = curr.dy - prev.dy;

      double segAngle = (dx.abs() < 0.001 && dy.abs() < 0.001)
          ? prevSegAngle
          : math.atan2(dy, dx);

      // Kéo nhẹ góc đốt sống về hướng thân để cá duỗi thẳng mượt sau khi rẽ
      final double diffToIdeal = _normalizeAngle(idealBackAngle - segAngle);
      segAngle += diffToIdeal * (dt * (4.2 + (1.0 - i / n) * 4.5)).clamp(0.0, 0.45);

      // Giới hạn góc gập giữa 2 đốt liên tiếp để cơ thể luôn uốn cong tròn trịa (không gãy khúc)
      final double bendFromPrev = _normalizeAngle(segAngle - prevSegAngle);
      const double maxBendPerJoint = 0.24; // ~13.7 độ
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

    // 1. Giảm dần các bộ đếm
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

    // 2. Xử lý Stamina & HP
    final bool frenzyActive = _frenzyTimer > 0;
    final bool canBoost = _isBoosting && (_stamina > 2.0 || frenzyActive);
    if (canBoost && !frenzyActive) {
      _stamina = math.max(0.0, _stamina - 28.0 * dt);
      if (_stamina <= 0.5) {
        _isBoosting = false;
      }
    } else {
      _stamina = math.min(100.0, _stamina + 16.0 * dt);
    }

    if (!frenzyActive) {
      _hp = math.max(0.0, _hp - (1.05 + _stageIndex * 0.22) * dt);
      if (_hp <= 0.0) {
        _triggerGameOver();
        return;
      }
    } else {
      _hp = math.min(stage.maxHp, _hp + 14.0 * dt);
    }

    // 3. Vật lý bơi có quán tính nước & nhịp đẩy vây đuôi của Cá Mập Người Chơi
    double maxSpeed = 245.0 + _stageIndex * 18.0;
    if (canBoost) maxSpeed *= 1.85;
    if (frenzyActive) maxSpeed *= 1.35;
    if (_biteAnimTimer > 0.12) maxSpeed *= 1.48;

    final double inputMag = _joystickDelta.distance.clamp(0.0, 1.0);
    if (inputMag > 0.04) {
      // Nhịp đẩy cơ học từ cú quẫy đuôi
      final double tailThrust = 1.0 + 0.08 * math.cos(_playerSwimPhase * 2.0);
      final double targetVx = _joystickDelta.dx * maxSpeed * tailThrust;
      final double targetVy = _joystickDelta.dy * maxSpeed * tailThrust;
      _playerVx = ui.lerpDouble(_playerVx, targetVx, (dt * 7.5).clamp(0.0, 1.0))!;
      _playerVy = ui.lerpDouble(_playerVy, targetVy, (dt * 7.5).clamp(0.0, 1.0))!;
    } else {
      // Khi nhả tay khỏi Joystick: Cá mập lướt êm theo quán tính nước (Water Glide)
      final double waterDrag = math.pow(0.18, dt).toDouble();
      _playerVx *= waterDrag;
      _playerVy *= waterDrag;
    }

    _playerX = (_playerX + _playerVx * dt).clamp(70.0, worldWidth - 70.0);
    _playerY = (_playerY + _playerVy * dt).clamp(65.0, worldHeight - 75.0);

    final double currentSpeed =
        math.sqrt(_playerVx * _playerVx + _playerVy * _playerVy);
    _playerSwimPhase += dt * (5.2 + currentSpeed * 0.036);

    if (_playerVx.abs() > 10.0) {
      _playerFacingRight = _playerVx > 0;
    }

    // Chuyển tiếp mượt hướng vây lưng (Smooth 3D Yaw Turn trong ~0.18s)
    final double targetDorsal = _playerFacingRight ? 1.0 : -1.0;
    _playerDorsalFlip = ui.lerpDouble(
      _playerDorsalFlip,
      targetDorsal,
      (dt * 9.5).clamp(0.0, 1.0),
    )!;

    // Tính góc hướng đầu mượt mà
    double desiredAngle;
    if (currentSpeed > 14.0) {
      desiredAngle = math.atan2(_playerVy, _playerVx);
      // Giới hạn độ chúc đầu lên/xuống để cá mập nhìn tự nhiên
      if (_playerFacingRight) {
        desiredAngle = desiredAngle.clamp(-0.68, 0.68);
      } else {
        double diff = _normalizeAngle(desiredAngle - math.pi);
        diff = diff.clamp(-0.68, 0.68);
        desiredAngle = _normalizeAngle(math.pi + diff);
      }
    } else {
      desiredAngle = _playerFacingRight ? 0.0 : math.pi;
    }
    final double angleDelta = _normalizeAngle(desiredAngle - _playerHeadingAngle);
    _playerHeadingAngle =
        _normalizeAngle(_playerHeadingAngle + angleDelta * (dt * 10.5).clamp(0.0, 1.0));

    final double effectivePlayerRadius =
        stage.baseRadius * (frenzyActive ? 1.25 : 1.0);
    final double playerBodyLen = effectivePlayerRadius * 2.75;

    // Cập nhật 16 đốt xương sống của Cá Mập Người Chơi
    _updateSpineChain(
      spine: _playerSpine,
      centerX: _playerX,
      centerY: _playerY,
      headingAngle: _playerHeadingAngle,
      bodyLength: playerBodyLen,
      dt: dt,
    );

    // Tạo bọt khí từ chóp đuôi (_playerSpine.last) khi lướt nhanh
    if ((canBoost || frenzyActive) && _rng.nextDouble() < 0.7) {
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

    // Vị trí Miệng Cá Mập Người Chơi (Giữa đốt 0 và đốt 1)
    final Offset playerMouth = Offset(
      (_playerSpine[0].dx + _playerSpine[1].dx) * 0.5,
      (_playerSpine[0].dy + _playerSpine[1].dy) * 0.5,
    );

    // 4. Cập nhật AI Sinh Vật, Bơi Đàn (Schooling), Uốn Xương Sống 16 Đốt & Hút Mồi Vào Miệng
    for (int i = _entities.length - 1; i >= 0; i--) {
      final e = _entities[i];

      // Nếu con mồi đang trong pha bị Hút Xoắn Vào Miệng Cá Mập (Swallow Animation)
      if (e.isBeingSwallowed) {
        e.swallowProgress += dt * 6.8; // ~0.15 giây
        e.x = ui.lerpDouble(e.x, playerMouth.dx, (dt * 18.0).clamp(0.0, 1.0))!;
        e.y = ui.lerpDouble(e.y, playerMouth.dy, (dt * 18.0).clamp(0.0, 1.0))!;
        e.swimPhase += dt * 16.0;
        final double shrinkLen =
            e.template.radius * 2.55 * (1.0 - e.swallowProgress * 0.78).clamp(0.15, 1.0);
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
        e.swimPhase +=
            dt * (e.template.waveFrequency + speedMag * 0.025);
        e.aiChangeTimer -= dt;

        final double dxToPlayer = _playerX - e.x;
        final double dyToPlayer = _playerY - e.y;
        final double dist = math.sqrt(dxToPlayer * dxToPlayer + dyToPlayer * dyToPlayer);

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
        } else if (dist < 330.0) {
          if (e.template.tier < stage.level || frenzyActive) {
            // Cá nhỏ hơn: Quẫy đuôi chạy trốn mềm mại khi cá mập lao tới!
            if (dist < 245.0 && dist > 1.0) {
              final double fleeVx = -(dxToPlayer / dist) * e.template.speed * 1.42;
              final double fleeVy = -(dyToPlayer / dist) * e.template.speed * 1.15;
              e.vx = ui.lerpDouble(e.vx, fleeVx, (dt * 5.5).clamp(0.0, 1.0))!;
              e.vy = ui.lerpDouble(e.vy, fleeVy, (dt * 5.5).clamp(0.0, 1.0))!;
            }
          } else if (e.template.tier > stage.level && e.template.isAggressive) {
            if (dist > 1.0) {
              final double chaseVx = (dxToPlayer / dist) * e.template.speed * 1.18;
              final double chaseVy = (dyToPlayer / dist) * e.template.speed * 1.05;
              e.vx = ui.lerpDouble(e.vx, chaseVx, (dt * 4.5).clamp(0.0, 1.0))!;
              e.vy = ui.lerpDouble(e.vy, chaseVy, (dt * 4.5).clamp(0.0, 1.0))!;
            }
          }
        } else if (e.aiChangeTimer <= 0) {
          e.aiChangeTimer = 2.2 + _rng.nextDouble() * 3.6;
          final double dir = _rng.nextBool() ? 1.0 : -1.0;
          final double targetVx =
              dir * e.template.speed * (0.8 + _rng.nextDouble() * 0.4);
          final double targetVy =
              (_rng.nextDouble() - 0.5) * e.template.speed * 0.42;
          e.vx = targetVx;
          e.vy = targetVy;
        }

        // Nhịp lượn sin tự nhiên khi bơi tuần tra
        e.vy += math.cos(e.swimPhase * 0.4) * 14.0 * dt;

        e.x += e.vx * dt;
        e.y += e.vy * dt;

        final double minY = e.template.minDepthRatio * worldHeight;
        final double maxY = e.template.maxDepthRatio * worldHeight;
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

      // Cập nhật lật hướng 3D mượt & Chuỗi Xương Sống 16 Đốt cho từng sinh vật
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
        final double diff = _normalizeAngle(entityHeading - math.pi).clamp(-0.55, 0.55);
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

      // Kiểm tra va chạm với Miệng / Thân Cá Mập Người Chơi
      final double dx = e.x - playerMouth.dx;
      final double dy = e.y - playerMouth.dy;
      final double distToMouth = math.sqrt(dx * dx + dy * dy);
      final double dxBody = e.x - _playerX;
      final double dyBody = e.y - _playerY;
      final double distToBody = math.sqrt(dxBody * dxBody + dyBody * dyBody);

      final double eatRadius =
          effectivePlayerRadius * 0.78 + e.template.radius * 0.78;

      if (distToMouth < eatRadius || distToBody < eatRadius * 0.9) {
        final bool isEdibleInstant =
            e.template.tier <= stage.level || frenzyActive;

        if (isEdibleInstant) {
          final double damageDealt = frenzyActive
              ? 9999.0
              : stage.biteDamage * (_biteAnimTimer > 0 ? 1.85 : 1.2);
          e.hp -= damageDealt;
          e.hitFlashTimer = 0.2;
          _biteAnimTimer = math.max(_biteAnimTimer, 0.24);

          if (e.hp <= 0) {
            // Kích hoạt hiệu ứng Hút Xoắn Vào Miệng Cá Mập!
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
          // Sinh vật CẤP CAO HƠN
          if (_biteAnimTimer > 0 && _isInFrontOfMouth(e.x, e.y)) {
            final double ripDamage = stage.biteDamage * 0.95;
            e.hp -= ripDamage;
            e.hitFlashTimer = 0.25;
            _biteAnimTimer = 0.0;
            _spawnBloodAndBubbles(e.x, e.y, const Color(0xFFFF5252), count: 10);
            _popups.add(
              _FloatingTextPopup(
                text: 'CẮN XÉ! -${ripDamage.toInt()}',
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
            e.biteCooldown = 1.1;
            _invulnerableTimer = 0.85;
            _hp = math.max(0.0, _hp - e.template.damage);
            HapticFeedback.heavyImpact();
            _spawnBloodAndBubbles(
                _playerX, _playerY, const Color(0xFFD50000),
                count: 14);
            _popups.add(
              _FloatingTextPopup(
                text: '-${e.template.damage.toInt()} MÁU (CÁ LỚN!)',
                x: _playerX,
                y: _playerY - effectivePlayerRadius,
                color: const Color(0xFFFF1744),
                fontSize: 15.0,
              ),
            );
            if (distToBody > 1.0) {
              _playerVx = -(dxBody / distToBody) * 260.0;
              _playerVy = -(dyBody / distToBody) * 260.0;
            }
            if (_hp <= 0.0) {
              _triggerGameOver();
              return;
            }
          }
        }
      }
    }

    while (_entities.length < 68) {
      _spawnRandomEntityOrSchool(avoidPlayer: true);
    }

    // 5. Cập nhật Vật Phẩm (Pickups)
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
              maxRadius: 150.0,
              color: const Color(0xFFFF3D00),
            ),
          );
          _spawnBloodAndBubbles(p.x, p.y, const Color(0xFFFF6D00), count: 20);
          HapticFeedback.heavyImpact();

          if (!frenzyActive && _invulnerableTimer <= 0) {
            _hp = math.max(0.0, _hp - 35.0);
            _invulnerableTimer = 0.9;
            _popups.add(
              _FloatingTextPopup(
                text: 'NỔ THỦY LÔI! -35 HP',
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
                text: 'PHÁ HỦY THỦY LÔI! +150',
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
          _hp = math.min(stage.maxHp, _hp + stage.maxHp * 0.35);
          _stamina = math.min(100.0, _stamina + 45.0);
          _score += 120;
          HapticFeedback.lightImpact();
          _spawnBloodAndBubbles(p.x, p.y, const Color(0xFF00E676), count: 10);
          _popups.add(
            _FloatingTextPopup(
              text: '+35% MÁU & NĂNG LƯỢNG',
              x: p.x,
              y: p.y - 20.0,
              color: const Color(0xFF00E676),
            ),
          );
          _pickups.removeAt(i);
          _spawnRandomPickup();
        } else if (p.type == _PickupType.goldenStar) {
          _score += 300;
          _furyCharge = math.min(100.0, _furyCharge + 25.0);
          _gainExp(35);
          HapticFeedback.mediumImpact();
          _spawnBloodAndBubbles(p.x, p.y, const Color(0xFFFFD740), count: 12);
          _popups.add(
            _FloatingTextPopup(
              text: '+300 ĐIỂM | +25% NỘ',
              x: p.x,
              y: p.y - 20.0,
              color: const Color(0xFFFFD740),
            ),
          );
          _pickups.removeAt(i);
          _spawnRandomPickup();
        } else if (p.type == _PickupType.meatChunk) {
          _hp = math.min(stage.maxHp, _hp + 18.0);
          _score += 90;
          _gainExp(22);
          HapticFeedback.selectionClick();
          _popups.add(
            _FloatingTextPopup(
              text: '+22 EXP | +MÁU',
              x: p.x,
              y: p.y - 16.0,
              color: const Color(0xFFFF8A80),
            ),
          );
          _pickups.removeAt(i);
        }
      }
    }

    // 6. Cập nhật Particles, Popups & Shockwaves
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
    if (index >= 0 && index < _entities.length) {
      _entities.removeAt(index);
    }
    _fishEatenCount++;

    _comboCount++;
    _comboTimer = 3.2;
    final int multiplier = _comboCount >= 8
        ? 4
        : (_comboCount >= 5 ? 3 : (_comboCount >= 3 ? 2 : 1));

    final int gainedScore = prey.template.scoreReward * multiplier;
    final int gainedExp = prey.template.expReward;
    _score += gainedScore;
    _saveHighScoreIfNeeded();

    _hp = math.min(stage.maxHp, _hp + 10.0 + prey.template.tier * 6.0);
    _stamina = math.min(100.0, _stamina + 14.0);
    if (_frenzyTimer <= 0) {
      _furyCharge =
          math.min(100.0, _furyCharge + 6.0 + prey.template.tier * 3.5);
    }

    HapticFeedback.lightImpact();
    _spawnBloodAndBubbles(prey.x, prey.y, const Color(0xFFFF1744), count: 10);

    final String comboSuffix = multiplier > 1 ? ' (x$multiplier!)' : '';
    _popups.add(
      _FloatingTextPopup(
        text: '+$gainedExp EXP | +$gainedScore$comboSuffix',
        x: prey.x,
        y: prey.y - 18.0,
        color: multiplier > 1
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
        _bannerAnnouncement = isVi
            ? 'TIẾN HÓA CẤP ${newStage.level}: ${newStage.nameVi.toUpperCase()} (${newStage.lengthMeters}m)!'
            : 'EVOLVED TO LV.${newStage.level}: ${newStage.nameEn.toUpperCase()} (${newStage.lengthMeters}m)!';
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
    _biteCooldown = 0.34;
    _biteAnimTimer = 0.28;
    HapticFeedback.mediumImpact();

    final stage = _currentStage;
    final double cosH = math.cos(_playerHeadingAngle);
    final double sinH = math.sin(_playerHeadingAngle);

    // Xung lực vọt đớp mồi theo hướng đầu cá mập
    _playerVx = cosH * (410.0 + _stageIndex * 26.0);
    _playerVy = sinH * (410.0 + _stageIndex * 26.0);

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
                text: 'ĐỚP! -${(stage.biteDamage * 1.95).toInt()}',
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
          _spawnBloodAndBubbles(e.x, e.y, const Color(0xFFFF5252), count: 12);
          _popups.add(
            _FloatingTextPopup(
              text: 'CẮN XÉ! -${ripDmg.toInt()}',
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
    _vortexTimer = 3.6;
    _vortexCooldown = 6.5;
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
    _roarCooldown = 8.0;
    HapticFeedback.heavyImpact();

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
        e.stunTimer = 3.5;
        e.hitFlashTimer = 0.35;
        e.hp -= _currentStage.biteDamage * 0.75;
        if (e.hp <= 0) {
          e.isBeingSwallowed = true;
          e.swallowProgress = 0.0;
        } else {
          _popups.add(
            _FloatingTextPopup(
              text: 'CHOÁNG!',
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
    _frenzyTimer = 7.5;
    _invulnerableTimer = 7.5;
    _hp = _currentStage.maxHp;
    _stamina = 100.0;
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
                // 1. THẾ GIỚI ĐẠI DƯƠNG + LƯỚI XƯƠNG SỐNG 16 ĐỐT (60-120FPS Canvas)
                RepaintBoundary(
                  child: ValueListenableBuilder<int>(
                    valueListenable: _frameNotifier,
                    builder: (context, _, _) {
                      return CustomPaint(
                        size: viewportSize,
                        painter: _SharkWorldCanvasPainter(
                          playerX: _playerX,
                          playerY: _playerY,
                          playerFacingRight: _playerFacingRight,
                          playerDorsalFlip: _playerDorsalFlip,
                          playerSwimPhase: _playerSwimPhase,
                          playerSpine: _playerSpine,
                          stage: _currentStage,
                          frenzyActive: _frenzyTimer > 0,
                          isBoosting: _isBoosting && _stamina > 2.0,
                          biteAnimTimer: _biteAnimTimer,
                          vortexTimer: _vortexTimer,
                          invulnerableTimer: _invulnerableTimer,
                          entities: _entities,
                          pickups: _pickups,
                          particles: _particles,
                          popups: _popups,
                          shockwaves: _shockwaves,
                          loadedMeshes: _loadedMeshes,
                          isVi: isVi,
                        ),
                      );
                    },
                  ),
                ),

                // 2. VÙNG CHẠM JOYSTICK BÊN TRÁI MÀN HÌNH
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

                // 3. GÓC TRÊN BÊN TRÁI: AVATAR CÁ MẬP, THANH MÁU, STAMINA, EXP & ĐIỂM SỐ
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

                // 4. GÓC TRÊN BÊN PHẢI: MINI-MAP PHONG CÁCH PUBG (CHẤM ĐỎ VỊ TRÍ CÁ MẬP)
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

                // 5. GÓC DƯỚI BÊN PHẢI: CỤM NÚT HÀNH ĐỘNG (ĐỚP, LƯỚT, XOÁY HÚT, SÓNG ÂM, CUỒNG NỘ)
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

                // 6. THÔNG BÁO TIẾN HÓA / CUỒNG NỘ Ở GIỮA TRÊN MÀN HÌNH
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
                              const Color(0xFFFF1744).withValues(alpha: 0.9),
                              const Color(0xFFFF9100).withValues(alpha: 0.9),
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
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ),
                  ),

                // 7. MÀN HÌNH TẠM DỪNG / HƯỚNG DẪN / GAME OVER
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF030D1E).withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: frenzy
              ? const Color(0xFFFF1744)
              : stage.auraColor.withValues(alpha: 0.55),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: (frenzy ? const Color(0xFFFF1744) : stage.auraColor)
                .withValues(alpha: 0.22),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: 52,
                height: 52,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      stage.auraColor.withValues(alpha: 0.45),
                      const Color(0xFF04142C),
                    ],
                  ),
                  border: Border.all(
                    color: frenzy ? const Color(0xFFFF1744) : stage.auraColor,
                    width: 2.0,
                  ),
                ),
                child: Image.asset(
                  stage.assetPath,
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                bottom: -4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: frenzy ? const Color(0xFFFF1744) : stage.auraColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'LV.${stage.level}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 175,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isVi ? stage.nameVi : stage.nameEn,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.0,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      '${stage.lengthMeters}m',
                      style: TextStyle(
                        color: stage.auraColor,
                        fontSize: 10.0,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _buildCompactBar(
                  label: 'HP',
                  ratio: hpRatio,
                  color: hpRatio > 0.35
                      ? const Color(0xFF00E676)
                      : const Color(0xFFFF1744),
                  valueText: '${_hp.toInt()}/${stage.maxHp.toInt()}',
                ),
                const SizedBox(height: 3),
                _buildCompactBar(
                  label: 'SP',
                  ratio: staminaRatio,
                  color: const Color(0xFF00E5FF),
                  valueText: '${_stamina.toInt()}%',
                ),
                const SizedBox(height: 3),
                _buildCompactBar(
                  label: 'EXP',
                  ratio: expRatio,
                  color: const Color(0xFFFFD740),
                  valueText: stage.level >= _evolutionStages.length
                      ? 'MAX'
                      : '$_exp/${stage.expRequired}',
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${isVi ? "ĐIỂM" : "SCORE"}: $_score',
                      style: const TextStyle(
                        color: Color(0xFFFFEA00),
                        fontSize: 10.0,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                      ),
                    ),
                    if (_comboCount >= 2)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF1744),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'COMBO x$_comboCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      )
                    else
                      Text(
                        '${isVi ? "MỒI" : "PREY"}: $_fishEatenCount',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 9.5,
                          fontFamily: 'monospace',
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactBar({
    required String label,
    required double ratio,
    required Color color,
    required String valueText,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6.5,
              child: Stack(
                children: [
                  Container(color: Colors.white.withValues(alpha: 0.12)),
                  FractionallySizedBox(
                    widthFactor: ratio,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color.withValues(alpha: 0.75), color],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 5),
        SizedBox(
          width: 44,
          child: Text(
            valueText,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 8.0,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopRightPubgMinimapHUD(bool isVi, SoundService soundService) {
    final int depthMeters = ((_playerY / worldHeight) * 11000).round();

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
                '${isVi ? "ĐỘ SÂU" : "DEPTH"}: ${depthMeters}m',
                style: const TextStyle(
                  color: Color(0xFF00F0FF),
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
                    playerX: _playerX,
                    playerY: _playerY,
                    headingAngle: _playerHeadingAngle,
                    playerLevel: _currentStage.level,
                    entities: _entities,
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
                          color: Color(0xFFFF9100),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Text(
                        'Boss',
                        style: TextStyle(
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
      width: 215,
      height: 175,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 8,
            bottom: 4,
            child: GestureDetector(
              onTapDown: (_) => setState(() => _isBoosting = true),
              onTapUp: (_) => setState(() => _isBoosting = false),
              onTapCancel: () => setState(() => _isBoosting = false),
              child: _buildSkillButton(
                size: 56,
                icon: Icons.bolt_rounded,
                label: isVi ? 'TĂNG TỐC' : 'BOOST',
                color: const Color(0xFF00E5FF),
                isActive: _isBoosting,
                cooldownText: null,
              ),
            ),
          ),
          Positioned(
            left: 44,
            bottom: 68,
            child: GestureDetector(
              onTap: _triggerVortexSkill,
              child: _buildSkillButton(
                size: 52,
                icon: Icons.cyclone_rounded,
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
                size: 52,
                icon: Icons.surround_sound_rounded,
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
                size: 50,
                icon: Icons.local_fire_department_rounded,
                label: _frenzyTimer > 0
                    ? '${_frenzyTimer.ceil()}s'
                    : '${_furyCharge.toInt()}%',
                color: furyReady || _frenzyTimer > 0
                    ? const Color(0xFFFF1744)
                    : Colors.white38,
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
              child: Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFF1744).withValues(alpha: 0.92),
                      const Color(0xFF880E4F).withValues(alpha: 0.95),
                    ],
                  ),
                  border: Border.all(
                    color: _biteAnimTimer > 0
                        ? const Color(0xFFFFEA00)
                        : const Color(0xFFFF8A80),
                    width: 2.6,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF1744).withValues(alpha: 0.55),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.pest_control_rodent_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isVi ? 'ĐỚP MỒI' : 'BITE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
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
    required IconData icon,
    required String label,
    required Color color,
    required bool isActive,
    required String? cooldownText,
  }) {
    final bool onCooldown = cooldownText != null;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive
            ? color.withValues(alpha: 0.38)
            : const Color(0xFF041022).withValues(alpha: 0.82),
        border: Border.all(
          color: onCooldown ? Colors.white24 : color,
          width: isActive ? 2.2 : 1.5,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: onCooldown ? Colors.white30 : color,
                size: size * 0.40,
              ),
              Text(
                label,
                style: TextStyle(
                  color: onCooldown ? Colors.white38 : Colors.white,
                  fontSize: 7.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          if (onCooldown)
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.62),
              ),
              alignment: Alignment.center,
              child: Text(
                cooldownText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
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
        width: 440,
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
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isVi
                  ? '• Bên Trái: Kéo Joystick 360° để uốn lượn điều khiển hướng bơi của cá mập.\n'
                    '• Bên Phải: Bấm [ĐỚP MỒI] để lao tới cắn xé, [TĂNG TỐC] để lướt nhanh, [HÚT MỒI] tạo xoáy nước hút cá vào miệng, [SÓNG ÂM] làm choáng cá lớn.\n'
                    '• Quy tắc Cá Lớn Nuốt Cá Bé: Ăn các loài có chấm XANH để tăng EXP và Tiến Hóa từ Cá Mập Đầu Búa (1.8m) lên Megalodon & Leviathan (36m)!\n'
                    '• Mini-Map Góc Phải: Chấm Đỏ là vị trí của bạn, Chấm Xanh là con mồi, Chấm Cam là Quái vật lớn.'
                  : '• Left Joystick: Drag anywhere on the left side to steer your shark smoothly.\n'
                    '• Right Action Buttons: Use [BITE] to lunge & chomp, [BOOST] to dash, [VORTEX] to suck prey in, and [ROAR] to stun predators.\n'
                    '• Evolution Rule: Eat GREEN-tagged prey to gain EXP and evolve up to Megalodon & Leviathan!\n'
                    '• Top-Right Radar: Red Dot is your position, Green Dots are prey, Orange Dots are giant bosses.',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
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
      color: Colors.black.withValues(alpha: 0.78),
      alignment: Alignment.center,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF061020),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFF1744), width: 2.0),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF1744).withValues(alpha: 0.35),
              blurRadius: 24,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isVi ? 'KẾT THÚC CHUYẾN ĐI SĂN!' : 'HUNT ENDED!',
              style: const TextStyle(
                color: Color(0xFFFF1744),
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${isVi ? "Cấp tiến hóa đạt được" : "Evolution Reached"}: LV.${_currentStage.level} (${isVi ? _currentStage.nameVi : _currentStage.nameEn})',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF00E5FF),
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${isVi ? "Điểm số" : "Score"}: $_score   |   ${isVi ? "Kỷ lục" : "Best"}: $_highScore',
              style: const TextStyle(
                color: Color(0xFFFFEA00),
                fontSize: 15,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${isVi ? "Số sinh vật đã săn" : "Creatures Devoured"}: $_fishEatenCount',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                  onPressed: () {
                    setState(() {
                      _initOceanWorld();
                    });
                  },
                  icon: const Icon(Icons.replay_rounded),
                  label: Text(
                    isVi ? 'CHƠI LẠI NGAY' : 'PLAY AGAIN',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white30),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                  onPressed: _exitGame,
                  icon: const Icon(Icons.home_rounded),
                  label: Text(isVi ? 'TRANG CHỦ' : 'HOME'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CUSTOM PAINTER 1: ENGINE BIẾN DẠNG LƯỚI XƯƠNG SỐNG 16 ĐỐT TRÊN GPU
// (Skeletal Spine Mesh Deformation via canvas.drawVertices + ImageShader)
// ═══════════════════════════════════════════════════════════════════════════
class _SharkWorldCanvasPainter extends CustomPainter {
  final double playerX;
  final double playerY;
  final bool playerFacingRight;
  final double playerDorsalFlip;
  final double playerSwimPhase;
  final List<Offset> playerSpine;
  final _SharkEvolutionStage stage;
  final bool frenzyActive;
  final bool isBoosting;
  final double biteAnimTimer;
  final double vortexTimer;
  final double invulnerableTimer;
  final List<_SeaEntity> entities;
  final List<_OceanPickup> pickups;
  final List<_GameParticle> particles;
  final List<_FloatingTextPopup> popups;
  final List<_ShockwaveRing> shockwaves;
  final Map<String, _LoadedSpriteMesh> loadedMeshes;
  final bool isVi;

  _SharkWorldCanvasPainter({
    required this.playerX,
    required this.playerY,
    required this.playerFacingRight,
    required this.playerDorsalFlip,
    required this.playerSwimPhase,
    required this.playerSpine,
    required this.stage,
    required this.frenzyActive,
    required this.isBoosting,
    required this.biteAnimTimer,
    required this.vortexTimer,
    required this.invulnerableTimer,
    required this.entities,
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

    final double depthRatio = (playerY / worldH).clamp(0.0, 1.0);
    final Color topWaterColor = Color.lerp(
      const Color(0xFF007799),
      const Color(0xFF020B1A),
      depthRatio,
    )!;
    final Color bottomWaterColor = Color.lerp(
      const Color(0xFF013A63),
      const Color(0xFF01040A),
      depthRatio,
    )!;

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

    if (camY < 750.0) {
      _paintSunlitSurfaceAndRays(canvas, worldW);
    }

    _paintSeabedAndHydrothermalVents(canvas, camX, camY, size, worldW, worldH);

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

    // Vẽ toàn bộ Sinh Vật Biển bằng Lưới Xương Sống 16 Đốt (16-Node Spine Mesh)
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

    // Vẽ Cá Mập Người Chơi bằng Lưới Xương Sống 16 Đốt
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

  /// Hàm lõi: Vẽ biến dạng Lưới Xương Sống 16 Đốt (Carangiform S-Curve + Kinematic Turn Mesh)
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

    // Tọa độ UV pixel của Mõm (Head) và Chóp Đuôi (Tail) trong ảnh gốc
    final double uHead =
        (assetFacesRight ? uvBounds.right : uvBounds.left) * imgW;
    final double uTail =
        (assetFacesRight ? uvBounds.left : uvBounds.right) * imgW;
    final double vTop = uvBounds.top * imgH;
    final double vBot = uvBounds.bottom * imgH;

    // Đảm bảo độ dày không bị bẹp về 0 khi đang cuộn người quay đầu 3D
    final double signedFlip = dorsalFlip >= 0
        ? math.max(0.32, dorsalFlip)
        : math.min(-0.32, dorsalFlip);

    final double maxWaveAmp = bodyLength * waveAmplitudeRatio;

    final List<Offset> positions = List<Offset>.filled(n * 2, Offset.zero);
    final List<Offset> texCoords = List<Offset>.filled(n * 2, Offset.zero);

    for (int i = 0; i < n; i++) {
      final double u = i / (n - 1); // 0.0 (Mõm) -> 1.0 (Chóp Đuôi)

      // Vector tiếp tuyến dọc xương sống (hướng từ Đuôi về Đầu)
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

      // Vector pháp tuyến vuông góc với đốt xương sống
      final Offset normal = Offset(-unitT.dy, unitT.dx);

      // Sóng truyền cơ học chữ S (Carangiform Traveling Wave):
      // Đầu ổn định (u^1.75 gần 0), thân lượn nhẹ, cuống đuôi và vây đuôi vẫy mạnh với độ trễ pha -4.4*u
      final double envelope = math.pow(u, 1.72).toDouble();
      final double waveOffset =
          maxWaveAmp * envelope * math.sin(swimPhase - 4.4 * u);

      final Offset displacedCenter = spine[i] + normal * waveOffset;

      // Vector hướng lên vây lưng (Dorsal Up) giữ cho cá không bao giờ bị lật ngửa bụng
      final Offset dorsalUp = normal * (-signedFlip);

      // Hiệu ứng há rộng hàm khi bấm ĐỚP ở 4 đốt đầu tiên (i = 0..3)
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

    // 1. Vòng hào quang mỏng dưới thân cá mập người chơi
    final Color ringColor =
        frenzyActive ? const Color(0xFFFF1744) : stage.auraColor;
    final Paint auraPaint = Paint()
      ..color = ringColor.withValues(alpha: frenzyActive ? 0.35 : 0.14)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18.0);
    canvas.drawCircle(Offset(playerX, playerY), baseR * 1.2, auraPaint);

    // 2. Vẽ Lưới Xương Sống 16 Đốt của Cá Mập Người Chơi
    final _LoadedSpriteMesh? mesh = loadedMeshes[stage.assetPath];
    if (mesh != null) {
      final Paint activePaint =
          frenzyActive ? mesh.frenzyShaderPaint : mesh.normalShaderPaint;
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

    // 3. Hiệu ứng Sóng Nước Cắn Xé trước Mõm khi bấm nút ĐỚP
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

    if (isDangerous) {
      canvas.drawCircle(
        Offset(0, -r * 0.75 - 15.0),
        3.8,
        Paint()..color = const Color(0xFFFF1744),
      );
    }
  }

  void _paintSunlitSurfaceAndRays(Canvas canvas, double worldW) {
    final Paint surfacePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xCC80DEEA),
          Color(0x4400BCD4),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, worldW, 140));
    canvas.drawRect(Rect.fromLTWH(0, 0, worldW, 140), surfacePaint);

    final Paint rayPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x38E0F7FA),
          Color(0x1200E5FF),
          Colors.transparent,
        ],
      ).createShader(const Rect.fromLTWH(0, 0, 200, 620));

    for (double x = 80; x < worldW; x += 260) {
      final double sway = math.sin(playerSwimPhase * 0.2 + x * 0.01) * 28.0;
      final Path rayPath = Path()
        ..moveTo(x, 0)
        ..lineTo(x + 75, 0)
        ..lineTo(x + 170 + sway, 620)
        ..lineTo(x - 40 + sway, 620)
        ..close();
      canvas.drawPath(rayPath, rayPaint);
    }
  }

  void _paintSeabedAndHydrothermalVents(
    Canvas canvas,
    double camX,
    double camY,
    Size size,
    double worldW,
    double worldH,
  ) {
    final Paint snowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.16);
    final int startCellX = (camX ~/ 180);
    final int endCellX = ((camX + size.width) ~/ 180) + 1;
    final int startCellY = (camY ~/ 180);
    final int endCellY = ((camY + size.height) ~/ 180) + 1;

    for (int gx = startCellX; gx <= endCellX; gx++) {
      for (int gy = startCellY; gy <= endCellY; gy++) {
        final int hash = (gx * 73856093) ^ (gy * 19349663);
        final double px = gx * 180.0 + (hash.abs() % 160);
        final double py = gy * 180.0 + ((hash ~/ 17).abs() % 160);
        canvas.drawCircle(Offset(px, py), (hash.abs() % 3) + 1.0, snowPaint);
      }
    }

    if (camY + size.height > worldH - 280.0) {
      final Path seabed = Path()..moveTo(0, worldH);
      for (double x = 0; x <= worldW; x += 160) {
        final double ridgeH =
            55.0 + math.sin(x * 0.008) * 35.0 + math.cos(x * 0.02) * 20.0;
        seabed.lineTo(x, worldH - ridgeH);
      }
      seabed.lineTo(worldW, worldH);
      seabed.close();

      final Paint rockPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0A192F),
            Color(0xFF02060D),
          ],
        ).createShader(Rect.fromLTWH(0, worldH - 140, worldW, 140));
      canvas.drawPath(seabed, rockPaint);

      final Paint lavaGlow = Paint()
        ..color = const Color(0xFFFF3D00).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18.0);
      for (double vx = 350; vx < worldW; vx += 650) {
        canvas.drawCircle(Offset(vx, worldH - 35), 48.0, lavaGlow);
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
// CUSTOM PAINTER 2: MINI-MAP RADAR PHONG CÁCH PUBG (CHẤM ĐỎ VỊ TRÍ CÁ MẬP)
// ═══════════════════════════════════════════════════════════════════════════
class _PubgMinimapPainter extends CustomPainter {
  final double playerX;
  final double playerY;
  final double headingAngle;
  final int playerLevel;
  final List<_SeaEntity> entities;
  final List<_OceanPickup> pickups;
  final double pulsePhase;

  _PubgMinimapPainter({
    required this.playerX,
    required this.playerY,
    required this.headingAngle,
    required this.playerLevel,
    required this.entities,
    required this.pickups,
    required this.pulsePhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double worldW = _SharkGameScreenState.worldWidth;
    const double worldH = _SharkGameScreenState.worldHeight;

    final Rect fullRect = Offset.zero & size;
    final Paint bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
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

    for (final p in pickups) {
      if (p.type == _PickupType.healingPearl ||
          p.type == _PickupType.goldenStar) {
        final double mx = (p.x / worldW) * size.width;
        final double my = (p.y / worldH) * size.height;
        canvas.drawCircle(
          Offset(mx, my),
          1.8,
          Paint()..color = const Color(0xFF00E5FF),
        );
      }
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
// CUSTOM PAINTER 3: CẦN ĐIỀU KHIỂN ẢO BÊN TRÁI (VIRTUAL ANALOG JOYSTICK)
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
    final Offset baseCenter = origin ?? defaultCenter;
    final Offset knobCenter = current ?? baseCenter;
    const double outerRadius = 54.0;
    const double innerRadius = 22.0;

    final Paint baseFill = Paint()
      ..color = const Color(0xFF031024).withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(baseCenter, outerRadius, baseFill);

    final Paint baseBorder = Paint()
      ..color = const Color(0xFF00F0FF)
          .withValues(alpha: origin != null ? 0.75 : 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(baseCenter, outerRadius, baseBorder);

    final Paint tickPaint = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.45)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 4; i++) {
      final double a = i * (math.pi / 2);
      canvas.drawLine(
        baseCenter + Offset(math.cos(a), math.sin(a)) * (outerRadius - 10),
        baseCenter + Offset(math.cos(a), math.sin(a)) * (outerRadius - 4),
        tickPaint,
      );
    }

    if (origin != null) {
      canvas.drawLine(
        baseCenter,
        knobCenter,
        Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: 0.45)
          ..strokeWidth = 3.0,
      );
    }

    final Paint knobPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFF80D8FF),
          Color(0xFF00E5FF),
          Color(0xFF006064),
        ],
      ).createShader(Rect.fromCircle(center: knobCenter, radius: innerRadius));
    canvas.drawCircle(knobCenter, innerRadius, knobPaint);

    canvas.drawCircle(
      knobCenter,
      innerRadius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _VirtualJoystickPainter oldDelegate) {
    return oldDelegate.origin != origin || oldDelegate.current != current;
  }
}
