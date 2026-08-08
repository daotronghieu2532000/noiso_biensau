import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/creature.dart';
import '../services/data_service.dart';
import '../services/sound_service.dart';
import '../l10n/app_strings.dart';
import 'settings_screen.dart';
import '../widgets/cached_video_player.dart';

class SonarScreen extends StatefulWidget {
  const SonarScreen({super.key});

  @override
  State<SonarScreen> createState() => _SonarScreenState();
}

// Monster blip positioned inside the Bermuda Triangle radar
class _MonsterBlip {
  final Creature creature;
  final String imageUrl;
  final double angle; // radians
  final double distanceRatio; // 0.0 – 0.8 relative to triangle inradius
  final double size;
  final bool isDangerous;

  _MonsterBlip({
    required this.creature,
    required this.imageUrl,
    required this.angle,
    required this.distanceRatio,
    required this.size,
    required this.isDangerous,
  });
}

class _SonarScreenState extends State<SonarScreen>
    with TickerProviderStateMixin {
  late AnimationController _radarController;
  late AnimationController _pulseController;
  late AnimationController _glitchController;

  final List<_MonsterBlip> _monsterBlips = [];
  final math.Random _random = math.Random();

  _MonsterBlip? _lockedBlip;
  bool _isScanning = false;
  double _scanProgress = 0.0;
  Timer? _scanTimer;
  Timer? _blipRegenerateTimer;
  Creature? _scannedCreature;
  late SoundService _soundService;

  String? _backgroundImage;

  final List<String> _bgImages = const [
    'assets/images/creatures/banner2.jpeg',
    'assets/images/creatures/banner1.jpg',
    'assets/images/creatures/ocean_atlantic.png',
    'assets/images/creatures/ocean_indian.png',
    'assets/images/creatures/ocean_pacific.png',
    'assets/images/creatures/ocean_southern.png',
    'assets/images/creatures/ocean_arctic.png',
    'assets/images/creatures/bg_bermuda.jpeg',
    'assets/images/creatures/bg_dark_abyss.jpeg',
    'assets/images/creatures/bg_deep_ocean.jpeg',
    'assets/images/creatures/bg_ghost_ship.jpeg',
    'assets/images/creatures/bg_giant_squid.jpeg',
    'assets/images/creatures/bg_kraken.jpeg',
    'assets/images/creatures/bg_research_sub.jpeg',
    'assets/images/creatures/bg_shark.jpeg',
  ];

  @override
  void initState() {
    super.initState();
    _backgroundImage = _bgImages[math.Random().nextInt(_bgImages.length)];
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glitchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );

    // Periodic glitch flicker effect
    _blipRegenerateTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _regenerateMonsterBlips();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _soundService.playAmbient("sonar_echo.mp3");
      _soundService.stopSecondaryAmbient();
      _regenerateMonsterBlips();
    });

    // Regenerate monster blips each radar sweep
    _radarController.addListener(() {
      if (_radarController.value < 0.02 && mounted) {
        _regenerateMonsterBlips();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _soundService = Provider.of<SoundService>(context, listen: false);
  }

  void _regenerateMonsterBlips() {
    if (!mounted || _isScanning || _scannedCreature != null) return;
    final dataService = Provider.of<DataService>(context, listen: false);
    final creatures = dataService.creatures;
    if (creatures.isEmpty) return;

    final shuffled = List.from(creatures)..shuffle(_random);
    final count = math.min(3, shuffled.length);

    setState(() {
      _monsterBlips.clear();
      for (int i = 0; i < count; i++) {
        final creature = shuffled[i];
        final angle = _random.nextDouble() * 2 * math.pi;
        // Keep blips inside the triangle – use modest distance ratios
        final distanceRatio = 0.15 + _random.nextDouble() * 0.55;
        final size = 28.0 + _random.nextDouble() * 18.0;
        final isDangerous = creature.dangerLevel >= 3;
        _monsterBlips.add(_MonsterBlip(
          creature: creature,
          imageUrl: creature.imageUrl,
          angle: angle,
          distanceRatio: distanceRatio,
          size: size,
          isDangerous: isDangerous,
        ));
      }
    });
  }

  void _onTapMonsterBlip(_MonsterBlip blip, double opacity) {
    if (_isScanning) return;
    
    // "rada đang quét" check: opacity must be high enough (e.g. > 0.25)
    // This means the monster blip is currently illuminated by the sweep line.
    final bool isVisibleOnRadar = opacity > 0.25;
    
    if (isVisibleOnRadar) {
      _captureMonster(blip);
    } else {
      // Missed! Play sound / feedback
      _soundService.playCreatureSound("sonar_echo.mp3");
      _glitchController.forward(from: 0.0);
    }
  }

  void _captureMonster(_MonsterBlip blip) {
    if (_isScanning) return;
    _soundService.playCreatureSound("sonar_echo.mp3");

    setState(() {
      _lockedBlip = blip;
      _isScanning = true;
      _scanProgress = 0.0;
      _scannedCreature = null;
    });

    // 800ms (or 400ms if premium) rapid capture/lock animation
    final dataService = Provider.of<DataService>(context, listen: false);
    final isPremium = dataService.hasAnyPremium;
    final duration = Duration(milliseconds: isPremium ? 400 : 800);
    const interval = Duration(milliseconds: 40);
    int elapsed = 0;

    _scanTimer = Timer.periodic(interval, (timer) {
      elapsed += interval.inMilliseconds;
      if (mounted) {
        setState(() {
          _scanProgress = (elapsed / duration.inMilliseconds).clamp(0.0, 1.0);
        });
      }

      if (elapsed >= duration.inMilliseconds) {
        timer.cancel();
        _revealMonster(blip);
      }
    });
  }

  void _revealMonster(_MonsterBlip blip) {
    final dataService = Provider.of<DataService>(context, listen: false);
    
    setState(() {
      _isScanning = false;
      _scannedCreature = blip.creature;
      // Unlock the creature in dataService
      dataService.unlockCreature(blip.creature.id);
      _soundService.playCreatureSound("The_BLOOP.mp3");
    });
  }

  @override
  void dispose() {
    _radarController.dispose();
    _pulseController.dispose();
    _glitchController.dispose();
    _scanTimer?.cancel();
    _blipRegenerateTimer?.cancel();
    _soundService.stopAmbient();
    _soundService.stopSecondaryAmbient();
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<DataService>(context);
    final hasLockedCreatures = dataService.creatures.any((c) => c.isLocked);

    return Scaffold(
      backgroundColor: const Color(0xFF020813),
      body: Stack(
        children: [
          // 1. Alternating background image
          if (_backgroundImage != null)
            Positioned.fill(
              child: Opacity(
                opacity: 0.65,
                child: Image.asset(
                  _backgroundImage!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          // 2. Abyssal dark overlay
          Positioned.fill(
            child: Container(
              color: const Color(0xFF020813).withValues(alpha: 0.75),
            ),
          ),
          // Corner telemetry HUD overlay
          _buildCornerTelemetry(),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),
                // Header with horizontal padding
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: _buildHeader(context),
                ),
                const SizedBox(height: 4),

                // ── Bermuda Triangle Radar — full width, no horizontal padding ──
                Expanded(
                  child: Center(
                    child: _buildBermudaRadar(context),
                  ),
                ),

                // ── Scanning HUD / Prompt ────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: _buildScanningHUD(hasLockedCreatures),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Creature discovery overlay
          if (_scannedCreature != null)
            _buildDiscoveryOverlay(_scannedCreature!),
        ],
      ),
    );
  }

  // ─── Bermuda Triangle Radar Widget ────────────────────────────────────────

  Widget _buildBermudaRadar(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      // Use full available width so the triangle fills the screen
      final double side = constraints.maxWidth * 0.98;
      // Equilateral triangle geometry: height = side * sqrt(3)/2
      final double height = side * math.sqrt(3) / 2;
      // Keep within available vertical space
      final double w = side;
      final double h = math.min(height, constraints.maxHeight * 0.96);

      // The 3 vertices of the equilateral triangle (pointing up)
      final apex = Offset(w / 2, 0);
      final baseLeft = Offset(0, h);
      final baseRight = Offset(w, h);
      final centroid = Offset(w / 2, h * 2 / 3);

      // Inradius (circle inscribed in triangle)
      final double inradius = h / 3;

      return SizedBox(
        width: w,
        height: h,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // ── 1. Bermuda Triangle frame painter (background grid + sweep) ──
            AnimatedBuilder(
              animation: _radarController,
              builder: (_, _) => AnimatedBuilder(
                animation: _pulseController,
                builder: (_, _) {
                  return CustomPaint(
                    size: Size(w, h),
                    painter: BermudaTrianglePainter(
                      sweepAngle:
                          _radarController.value * 2 * math.pi,
                      pulseT: _pulseController.value,
                      apex: apex,
                      baseLeft: baseLeft,
                      baseRight: baseRight,
                      centroid: centroid,
                      inradius: inradius,
                    ),
                  );
                },
              ),
            ),

            // ── 2. Monster silhouettes inside the triangle ─────────────────
            ..._monsterBlips.map((blip) {
              return AnimatedBuilder(
                animation: _radarController,
                builder: (_, _) {
                  final double sweepAngle =
                      _radarController.value * 2 * math.pi;
                  double diff =
                      (sweepAngle - blip.angle) % (2 * math.pi);
                  double opacity =
                      (1.0 - diff / (0.9 * math.pi)).clamp(0.0, 1.0);
                  opacity = math.max(0.08, opacity);

                  final double x = centroid.dx +
                      math.cos(blip.angle) * inradius * blip.distanceRatio;
                  final double y = centroid.dy +
                      math.sin(blip.angle) * inradius * blip.distanceRatio;

                  final Color tint = blip.isDangerous
                      ? const Color(0xFFFF2244)
                      : const Color(0xFFFF6622);

                  return Positioned(
                    left: x - blip.size / 2,
                    top: y - blip.size / 2,
                    child: Opacity(
                      opacity: opacity,
                      child: GestureDetector(
                        onTap: () => _onTapMonsterBlip(blip, opacity),
                        child: Container( 
                          width: blip.size,
                          height: blip.size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.transparent,
                            border: Border.all(
                              color: tint.withValues(alpha: 0.3),
                              width: 0.5,
                            ),
                          ),
                          child: ClipOval(
                            child: blip.imageUrl.startsWith('http')
                                ? Image.network(
                                    blip.imageUrl,
                                    fit: BoxFit.contain,
                                    color: tint.withValues(alpha: 0.9),
                                    colorBlendMode: BlendMode.srcATop,
                                    errorBuilder: (context, err, stack) => Icon(
                                      Icons.pest_control_outlined,
                                      color: tint,
                                      size: blip.size * 0.6,
                                    ),
                                  )
                                : Image.asset(
                                    blip.imageUrl,
                                    fit: BoxFit.contain,
                                    color: tint.withValues(alpha: 0.9),
                                    colorBlendMode: BlendMode.srcATop,
                                    errorBuilder: (context, err, stack) => Icon(
                                      Icons.pest_control_outlined,
                                      color: tint,
                                      size: blip.size * 0.6,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),

            // ── 4. Locked-target targeting reticle ────────────────────────
            if (_lockedBlip != null)
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, _) {
                  final blip = _lockedBlip!;
                  final double x = centroid.dx +
                      (inradius * blip.distanceRatio) *
                          math.cos(blip.angle);
                  final double y = centroid.dy +
                      (inradius * blip.distanceRatio) *
                          math.sin(blip.angle);
                  final double reticleSize =
                      20 + _pulseController.value * 8;
                  return Positioned(
                    left: x - reticleSize,
                    top: y - reticleSize,
                    child: CustomPaint(
                      size: Size(reticleSize * 2, reticleSize * 2),
                      painter: TargetReticlePainter(
                          color: const Color(0xFFFF0033)),
                    ),
                  );
                },
              ),
          ],
        ),
      );
    });
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final strings = AppStrings.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00F0FF)),
          onPressed: () => Navigator.pop(context),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                strings.sonarTitle.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF00F0FF),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  shadows: [Shadow(color: Color(0xFF00F0FF), blurRadius: 10)],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                strings.languageCode == 'vi'
                    ? '▲ TAM GIÁC QUỶ BERMUDA · BIOMASS SCANNER ▲'
                    : '▲ BERMUDA TRIANGLE · BIOMASS SCANNER ▲',
                style: TextStyle(
                  color: const Color(0xFFFF3300).withValues(alpha: 0.7),
                  fontSize: 9,
                  letterSpacing: 1,
                  fontFamily: 'monospace',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF00F0FF)),
              onPressed: () {
                if (!_isScanning) {
                  setState(() {
                    _lockedBlip = null;
                    _scannedCreature = null;
                  });
                  _regenerateMonsterBlips();
                }
              },
            ),
            buildVolumeButton(context),
            buildSettingsButton(context),
          ],
        ),
      ],
    );
  }

  // ─── Corner Telemetry ─────────────────────────────────────────────────────

  Widget _buildCornerTelemetry() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFFFF3300).withValues(alpha: 0.08),
              width: 1.5,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                child: Text(
                  'BERMUDA ZONE: 25°N-30°N\nBIOMASS DENSITY: EXTREME',
                  style: TextStyle(
                      color: const Color(0xFFFF3300).withValues(alpha: 0.25),
                      fontSize: 8,
                      fontFamily: 'monospace'),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Text(
                  'ANOMALY FIELD: ACTIVE\nSIGNAL DISTORTION: HIGH',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: const Color(0xFFFF3300).withValues(alpha: 0.25),
                    fontSize: 8,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              // Bottom distress signal text
              Positioned(
                left: 0,
                bottom: 0,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, _) => Text(
                    'WARNING: UNKNOWN ENTITIES DETECTED',
                    style: TextStyle(
                      color: const Color(0xFFFF0000)
                          .withValues(alpha: 0.15 + _pulseController.value * 0.2),
                      fontSize: 8,
                      fontFamily: 'monospace',
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Scanning HUD ─────────────────────────────────────────────────────────

  Widget _buildScanningHUD(bool hasLocked) {
    final strings = AppStrings.of(context);
    if (_isScanning) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1F3D).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: const Color(0xFFFF3366).withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  strings.languageCode == 'en'
                      ? 'CREATURE BIOMETRIC ANALYSIS...'
                      : 'PHÂN TÍCH DI TRUYỀN SINH VẬT...',
                  style: const TextStyle(
                      color: Color(0xFFFF3366),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1),
                ),
                Text(
                  '${(_scanProgress * 100).toInt()}%',
                  style: const TextStyle(
                      color: Color(0xFFFF3366),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _scanProgress,
              backgroundColor: const Color(0xFF020813),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFFF3366)),
              minHeight: 4,
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1F3D).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFFF3300).withValues(alpha: 0.15)),
      ),
      child: Center(
        child: Text(
          hasLocked
              ? (strings.languageCode == 'en'
                  ? '▲  TAP AN ACTIVE CREATURE SCAN TO CAPTURE TARGET  ▲'
                  : '▲  CHẠM VÀO THỦY QUÁI KHI RADAR QUÉT QUA ĐỂ SĂN  ▲')
              : (strings.languageCode == 'en'
                  ? 'ALL ABYSSAL ENTITIES FULLY CATALOGUED'
                  : 'ĐÃ DÒ QUÉT TOÀN BỘ THỰC THỂ VỰC THẲM'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFFFF3300).withValues(alpha: 0.7),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            height: 1.5,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }

  // ─── Discovery overlay ────────────────────────────────────────────────────

  Widget _buildDiscoveryOverlay(Creature creature) {
    final strings = AppStrings.of(context);
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isHighDanger = creature.dangerLevel >= 4;
    final Color themeColor =
        isHighDanger ? const Color(0xFFFF3366) : const Color(0xFF00F0FF);

    return Positioned.fill(
      child: GestureDetector(
        onTap: () {},
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            color: Colors.black.withValues(alpha: 0.9),
            child: Stack(
              children: [
                // 1. Grid telemetry background
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.05,
                    child: GridPaper(
                      color: themeColor,
                      divisions: 1,
                      subdivisions: 1,
                      interval: 40,
                    ),
                  ),
                ),

                // 2. Creature image - Giant Centered Hero
                Positioned(
                  top: screenHeight * 0.14,
                  left: 0,
                  right: 0,
                  height: screenHeight * 0.48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Radial background glow behind the giant creature
                      Container(
                        width: screenWidth * 0.9,
                        height: screenWidth * 0.9,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              themeColor.withValues(alpha: 0.22),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      
                      // Giant creature video/image with scale
                      Transform.scale(
                        scale: 1.25,
                        child: creature.videoUrl.isNotEmpty
                            ? CachedCreatureVideoPlayer(
                                videoUrl: creature.videoUrl,
                                placeholder: creature.buildImage(
                                  width: screenWidth * 0.88,
                                  height: screenHeight * 0.45,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(Icons.waves, color: themeColor, size: 80),
                                ),
                              )
                            : creature.buildImage(
                                width: screenWidth * 0.88,
                                height: screenHeight * 0.45,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(Icons.waves, color: themeColor, size: 80),
                              ),
                      ),

                      // Holographic bracket painter around the giant creature image
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: DiscoveryBracketsPainter(color: themeColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Cybernetic UI overlays
                // Top header
                Positioned(
                  top: 40,
                  left: 24,
                  right: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: themeColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: themeColor,
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isHighDanger
                                    ? (strings.languageCode == 'en' ? 'WARNING: ANCIENT CLASS' : 'CẢNH BÁO: THỰC THỂ CỔ ĐẠI')
                                    : (strings.languageCode == 'en' ? 'BIOMASS IDENTIFIED' : 'ĐÃ XÁC ĐỊNH SINH VẬT'),
                                style: TextStyle(
                                  color: themeColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                  letterSpacing: 2.0,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'DECK_ID // #0${creature.id.hashCode % 1000}',
                            style: TextStyle(
                              color: themeColor.withValues(alpha: 0.4),
                              fontSize: 9,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 1.5,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [themeColor, Colors.transparent],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Overlay panel containing Info & Buttons
                Positioned(
                  bottom: 30,
                  left: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Creature Name
                      Text(
                        creature.getName(strings.languageCode).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        creature.scientificName.toUpperCase(),
                        style: TextStyle(
                          color: themeColor,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          fontFamily: 'monospace',
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Biometric HUD badges in a row
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildHudBadge(
                            strings.languageCode == 'en' ? 'THREAT' : 'ĐE DỌA',
                            isHighDanger ? 'APEX CLASS' : 'NORMAL',
                            isHighDanger ? const Color(0xFFFF3366) : const Color(0xFF00F0FF),
                          ),
                          _buildHudBadge(
                            strings.languageCode == 'en' ? 'DEPTH' : 'ĐỘ SÂU',
                            '${creature.minDepth}m - ${creature.maxDepth}m',
                            themeColor,
                          ),
                          _buildHudBadge(
                            strings.languageCode == 'en' ? 'SIZE' : 'KÍCH THƯỚC',
                            creature.getSizeHumanRatio(strings.languageCode).split(' ')[0],
                            themeColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Faded description (Max 3 lines, highly readable and clean)
                      Container(
                        padding: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(color: themeColor.withValues(alpha: 0.4), width: 2),
                          ),
                        ),
                        child: Text(
                          creature.getDescription(strings.languageCode),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 11.5,
                            height: 1.5,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Giant neon action button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _scannedCreature = null;
                              _lockedBlip = null;
                            });
                            _regenerateMonsterBlips();
                          },
                          icon: const Icon(Icons.verified_user_outlined, color: Colors.black, size: 18),
                          label: Text(
                            strings.languageCode == 'en' ? 'CONFIRM & STORE FILE' : 'XÁC NHẬN & LƯU HỒ SƠ',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              fontFamily: 'monospace',
                              letterSpacing: 1.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 8,
                            shadowColor: themeColor.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHudBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF030D1C).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 9.5, fontFamily: 'monospace'),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(color: Colors.white30, fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: value.toUpperCase(),
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Data Models
// ═══════════════════════════════════════════════════════════════════════════

class RadarBlip {
  final int id;
  final double angle;
  final double distanceRatio;
  double pulseSize;

  RadarBlip({
    required this.id,
    required this.angle,
    required this.distanceRatio,
    this.pulseSize = 6.0,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Bermuda Triangle Radar Painter
// ═══════════════════════════════════════════════════════════════════════════

class BermudaTrianglePainter extends CustomPainter {
  final double sweepAngle;
  final double pulseT; // 0..1
  final Offset apex;
  final Offset baseLeft;
  final Offset baseRight;
  final Offset centroid;
  final double inradius;

  BermudaTrianglePainter({
    required this.sweepAngle,
    required this.pulseT,
    required this.apex,
    required this.baseLeft,
    required this.baseRight,
    required this.centroid,
    required this.inradius,
  });

  // Compute the triangle path
  Path get _trianglePath {
    return Path()
      ..moveTo(apex.dx, apex.dy)
      ..lineTo(baseRight.dx, baseRight.dy)
      ..lineTo(baseLeft.dx, baseLeft.dy)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final triPath = _trianglePath;

    // ── Clip all drawing to the triangle ──────────────────────────────────
    canvas.save();
    canvas.clipPath(triPath);

    // 1. Dark eerie triangle fill
    final paintFill = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          const Color(0xFF0A0310).withValues(alpha: 0.95),
          const Color(0xFF020006).withValues(alpha: 0.98),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(triPath, paintFill);

    // 2. Inner concentric triangles (like sonar rings)
    _drawConcentricTriangles(canvas);

    // 3. Cross-hair lines from centroid
    _drawCrosshairLines(canvas);

    // 4. Sweeping radar wedge inside the triangle
    _drawSweepWedge(canvas, size);

    // 5. Distortion interference lines
    _drawDistortionLines(canvas, size);

    canvas.restore();

    // ── Draw the glowing triangle border (outside clip) ───────────────────
    _drawTriangleBorder(canvas);

    // ── Corner danger symbols at the 3 vertices ───────────────────────────
    _drawVertexWarnings(canvas);
  }

  void _drawConcentricTriangles(Canvas canvas) {
    final paintRing = Paint()
      ..color = const Color(0xFFFF2200).withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (double scale in [0.25, 0.5, 0.75]) {
      final scaledPath = _scaledTrianglePath(scale);
      canvas.drawPath(scaledPath, paintRing);
    }
  }

  /// Builds a smaller triangle around the centroid with given scale (0..1)
  Path _scaledTrianglePath(double scale) {
    final a = Offset(
        centroid.dx + (apex.dx - centroid.dx) * scale,
        centroid.dy + (apex.dy - centroid.dy) * scale);
    final b = Offset(
        centroid.dx + (baseLeft.dx - centroid.dx) * scale,
        centroid.dy + (baseLeft.dy - centroid.dy) * scale);
    final c = Offset(
        centroid.dx + (baseRight.dx - centroid.dx) * scale,
        centroid.dy + (baseRight.dy - centroid.dy) * scale);
    return Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(c.dx, c.dy)
      ..lineTo(b.dx, b.dy)
      ..close();
  }

  void _drawCrosshairLines(Canvas canvas) {
    final paint = Paint()
      ..color = const Color(0xFFFF3300).withValues(alpha: 0.12)
      ..strokeWidth = 0.8;

    // Centroid to each vertex (main axis lines)
    canvas.drawLine(centroid, apex, paint);
    canvas.drawLine(centroid, baseLeft, paint);
    canvas.drawLine(centroid, baseRight, paint);

    // Centroid to midpoints of each side (altitude lines)
    final midTop = Offset(
        (apex.dx + baseRight.dx) / 2, (apex.dy + baseRight.dy) / 2);
    final midLeft = Offset(
        (apex.dx + baseLeft.dx) / 2, (apex.dy + baseLeft.dy) / 2);
    final midBottom = Offset(
        (baseLeft.dx + baseRight.dx) / 2, (baseLeft.dy + baseRight.dy) / 2);

    final paintAlt = Paint()
      ..color = const Color(0xFFFF3300).withValues(alpha: 0.06)
      ..strokeWidth = 0.5;
    canvas.drawLine(centroid, midTop, paintAlt);
    canvas.drawLine(centroid, midLeft, paintAlt);
    canvas.drawLine(centroid, midBottom, paintAlt);
  }

  void _drawSweepWedge(Canvas canvas, Size size) {
    // Compute exact distance from centroid to triangle edge in sweep direction
    final double sweepLen = _rayToTriangleEdge(sweepAngle) * 0.97;

    // Draw the sweep wedge as a proper Path (wedge from centroid)
    final double wedgeHalf = 0.18; // half-angle of the wedge in radians
    final sweepPath = Path();
    sweepPath.moveTo(centroid.dx, centroid.dy);
    // Arc approximation: draw ~10 points along the leading arc
    const int arcSteps = 10;
    final double maxLen = _rayToTriangleEdge(sweepAngle - wedgeHalf * 2) * 0.97;
    for (int i = 0; i <= arcSteps; i++) {
      final double a = (sweepAngle - wedgeHalf * 2) + (wedgeHalf * 2 / arcSteps) * i;
      final double edgeLen = _rayToTriangleEdge(a) * 0.97;
      sweepPath.lineTo(
        centroid.dx + edgeLen * math.cos(a),
        centroid.dy + edgeLen * math.sin(a),
      );
    }
    sweepPath.close();

    final paintSweep = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          (centroid.dx / size.width) * 2 - 1,
          (centroid.dy / size.height) * 2 - 1,
        ),
        colors: [
          const Color(0xFFFF2200).withValues(alpha: 0.0),
          const Color(0xFFFF4400).withValues(alpha: 0.08),
          const Color(0xFFFF6600).withValues(alpha: 0.28),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: centroid, radius: maxLen))
      ..style = PaintingStyle.fill;
    canvas.drawPath(sweepPath, paintSweep);

    // Leading sweep line — goes exactly to the triangle edge
    final paintLine = Paint()
      ..color = const Color(0xFFFF4400).withValues(alpha: 0.85)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      centroid,
      Offset(
        centroid.dx + sweepLen * math.cos(sweepAngle),
        centroid.dy + sweepLen * math.sin(sweepAngle),
      ),
      paintLine,
    );

    // Pulsing echo ring (triangle-shaped via scale)
    for (final scale in [0.3 + pulseT * 0.4, 0.5 + pulseT * 0.4]) {
      final ringPath = _scaledTrianglePath(scale);
      final paintEcho = Paint()
        ..color = const Color(0xFFFF2200)
            .withValues(alpha: (1 - pulseT) * 0.12 * (1 - scale * 0.5))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawPath(ringPath, paintEcho);
    }
  }

  /// Ray from [centroid] in direction [angle] → distance to nearest triangle edge
  double _rayToTriangleEdge(double angle) {
    final double dx = math.cos(angle);
    final double dy = math.sin(angle);
    final edges = [
      [apex, baseRight],
      [baseRight, baseLeft],
      [baseLeft, apex],
    ];
    double minT = inradius * 2.5; // safe fallback
    for (final edge in edges) {
      final Offset p1 = edge[0];
      final Offset p2 = edge[1];
      final double ex = p2.dx - p1.dx;
      final double ey = p2.dy - p1.dy;
      final double denom = dx * ey - dy * ex;
      if (denom.abs() < 1e-9) continue;
      final double t =
          ((p1.dx - centroid.dx) * ey - (p1.dy - centroid.dy) * ex) / denom;
      final double s =
          ((p1.dx - centroid.dx) * dy - (p1.dy - centroid.dy) * dx) / denom;
      if (t > 1e-6 && s >= -1e-6 && s <= 1 + 1e-6) {
        minT = math.min(minT, t);
      }
    }
    return minT;
  }

  void _drawDistortionLines(Canvas canvas, Size size) {
    // Horizontal scanline distortions for eerie "Bermuda interference" effect
    final paintDist = Paint()
      ..color = const Color(0xFFFF1100).withValues(alpha: 0.04)
      ..strokeWidth = 0.5;

    // Draw ~8 thin horizontal lines spaced across the triangle
    final double step = size.height / 10;
    for (int i = 1; i < 10; i++) {
      final double y = i * step;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintDist);
    }
  }

  void _drawTriangleBorder(Canvas canvas) {
    // Outer glowing border
    final paintGlow = Paint()
      ..color = const Color(0xFFFF2200).withValues(alpha: 0.35 + pulseT * 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 6);
    canvas.drawPath(_trianglePath, paintGlow);

    // Crisp inner border line
    final paintBorder = Paint()
      ..color = const Color(0xFFFF4400).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(_trianglePath, paintBorder);

    // Outer secondary glow
    final paintOuterGlow = Paint()
      ..color = const Color(0xFFFF0000).withValues(alpha: 0.12 + pulseT * 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 12);
    canvas.drawPath(_trianglePath, paintOuterGlow);
  }

  void _drawVertexWarnings(Canvas canvas) {
    // Small danger triangles at each corner
    for (final vertex in [apex, baseLeft, baseRight]) {
      _drawSmallDangerMarker(canvas, vertex, pulseT);
    }
  }

  void _drawSmallDangerMarker(Canvas canvas, Offset pos, double pulse) {
    const double markerSize = 8.0;
    final double alpha = 0.5 + pulse * 0.5;
    final paint = Paint()
      ..color = const Color(0xFFFF2200).withValues(alpha: alpha)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(pos.dx, pos.dy - markerSize)
      ..lineTo(pos.dx + markerSize, pos.dy + markerSize * 0.6)
      ..lineTo(pos.dx - markerSize, pos.dy + markerSize * 0.6)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant BermudaTrianglePainter old) =>
      old.sweepAngle != sweepAngle || old.pulseT != pulseT;
}

// ═══════════════════════════════════════════════════════════════════════════
// Danger Triangle Blip Painter (red triangular target indicators)
// ═══════════════════════════════════════════════════════════════════════════

class DangerTrianglePainter extends CustomPainter {
  final Color color;
  final double glowSize;

  DangerTrianglePainter({required this.color, required this.glowSize});

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double s = size.width / 2;

    // Glow halo
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..maskFilter = MaskFilter.blur(BlurStyle.outer, glowSize / 2);
    final glowPath = Path()
      ..moveTo(cx, cy - s)
      ..lineTo(cx + s, cy + s * 0.6)
      ..lineTo(cx - s, cy + s * 0.6)
      ..close();
    canvas.drawPath(glowPath, glowPaint);

    // Filled danger triangle
    final fillPaint = Paint()..color = color.withValues(alpha: 0.85);
    final fillPath = Path()
      ..moveTo(cx, cy - s * 0.85)
      ..lineTo(cx + s * 0.85, cy + s * 0.5)
      ..lineTo(cx - s * 0.85, cy + s * 0.5)
      ..close();
    canvas.drawPath(fillPath, fillPaint);

    // Center exclamation dot
    final dotPaint = Paint()..color = Colors.black;
    canvas.drawCircle(Offset(cx, cy + s * 0.1), s * 0.2, dotPaint);
  }

  @override
  bool shouldRepaint(covariant DangerTrianglePainter old) =>
      old.color != color || old.glowSize != glowSize;
}

// ═══════════════════════════════════════════════════════════════════════════
// Target Reticle Painter (brackets around locked blip)
// ═══════════════════════════════════════════════════════════════════════════

class TargetReticlePainter extends CustomPainter {
  final Color color;
  TargetReticlePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final cx = size.width / 2;
    final cy = size.height / 2;
    const arm = 8.0;

    // Corner bracket reticle
    // TL
    canvas.drawLine(Offset(cx - 12, cy - 12), Offset(cx - 12 + arm, cy - 12), paint);
    canvas.drawLine(Offset(cx - 12, cy - 12), Offset(cx - 12, cy - 12 + arm), paint);
    // TR
    canvas.drawLine(Offset(cx + 12, cy - 12), Offset(cx + 12 - arm, cy - 12), paint);
    canvas.drawLine(Offset(cx + 12, cy - 12), Offset(cx + 12, cy - 12 + arm), paint);
    // BL
    canvas.drawLine(Offset(cx - 12, cy + 12), Offset(cx - 12 + arm, cy + 12), paint);
    canvas.drawLine(Offset(cx - 12, cy + 12), Offset(cx - 12, cy + 12 - arm), paint);
    // BR
    canvas.drawLine(Offset(cx + 12, cy + 12), Offset(cx + 12 - arm, cy + 12), paint);
    canvas.drawLine(Offset(cx + 12, cy + 12), Offset(cx + 12, cy + 12 - arm), paint);

    // Center crosshair
    canvas.drawLine(Offset(cx - 5, cy), Offset(cx - 2, cy), paint);
    canvas.drawLine(Offset(cx + 2, cy), Offset(cx + 5, cy), paint);
    canvas.drawLine(Offset(cx, cy - 5), Offset(cx, cy - 2), paint);
    canvas.drawLine(Offset(cx, cy + 2), Offset(cx, cy + 5), paint);
  }

  @override
  bool shouldRepaint(covariant TargetReticlePainter old) =>
      old.color != color;
}

// ═══════════════════════════════════════════════════════════════════════════
// Discovery Brackets Painter (on creature photo)
// ═══════════════════════════════════════════════════════════════════════════

class DiscoveryBracketsPainter extends CustomPainter {
  final Color color;
  DiscoveryBracketsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final double w = size.width;
    final double h = size.height;
    const double pad = 24.0;

    canvas.drawLine(Offset(pad, pad), Offset(pad + 20, pad), paint);
    canvas.drawLine(Offset(pad, pad), Offset(pad, pad + 20), paint);
    canvas.drawLine(Offset(w - pad, pad), Offset(w - pad - 20, pad), paint);
    canvas.drawLine(Offset(w - pad, pad), Offset(w - pad, pad + 20), paint);
    canvas.drawLine(Offset(pad, h - pad), Offset(pad + 20, h - pad), paint);
    canvas.drawLine(Offset(pad, h - pad), Offset(pad, h - pad - 20), paint);
    canvas.drawLine(Offset(w - pad, h - pad), Offset(w - pad - 20, h - pad), paint);
    canvas.drawLine(Offset(w - pad, h - pad), Offset(w - pad, h - pad - 20), paint);

    final center = Offset(w / 2, h / 2);
    canvas.drawLine(Offset(center.dx - 12, center.dy), Offset(center.dx - 4, center.dy), paint);
    canvas.drawLine(Offset(center.dx + 4, center.dy), Offset(center.dx + 12, center.dy), paint);
    canvas.drawLine(Offset(center.dx, center.dy - 12), Offset(center.dx, center.dy - 4), paint);
    canvas.drawLine(Offset(center.dx, center.dy + 4), Offset(center.dx, center.dy + 12), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
