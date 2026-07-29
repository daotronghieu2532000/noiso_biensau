import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_service.dart';
import '../services/sound_service.dart';
import '../services/ad_service.dart';
import '../l10n/app_strings.dart';
import 'ocean_map_screen.dart';
import 'sonar_screen.dart';
import 'simulator_screen.dart';
import 'logbook_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _RadarBlip {
  final String imageUrl;
  final double distance;
  final double angle;
  final double size;

  _RadarBlip({
    required this.imageUrl,
    required this.distance,
    required this.angle,
    required this.size,
  });
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _hudController;
  late SoundService _soundService;
  final List<_RadarBlip> _blips = [];
  double _lastControllerValue = 0.0;

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
    _hudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    
    // Play sonar_echo.mp3 when entering dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _soundService.playAmbient("sonar_echo.mp3");
      _regenerateBlips();
    });

    _hudController.addListener(() {
      if (_hudController.value < _lastControllerValue) {
        // Wrapped around! Regenerate random blips
        _regenerateBlips();
      }
      _lastControllerValue = _hudController.value;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cache SoundService here — safe to use in dispose()
    _soundService = Provider.of<SoundService>(context, listen: false);
  }

  void _generateRandomBlips(List<dynamic> creatures) {
    if (creatures.isEmpty) return;
    _blips.clear();
    final random = math.Random();
    
    // Select 3 random creatures
    final List<dynamic> shuffled = List.from(creatures)..shuffle(random);
    final count = math.min(3, shuffled.length);
    
    for (int i = 0; i < count; i++) {
      final creature = shuffled[i];
      // Random angle (0 to 2*pi)
      final angle = random.nextDouble() * 2 * math.pi;
      // Random distance from center (30 to 72 to fit inside 190x190 circular viewport)
      final distance = 30.0 + random.nextDouble() * 42.0;
      // Size of the creature image on radar (e.g. 26 to 38 pixels)
      final size = 26.0 + random.nextDouble() * 12.0;
      
      _blips.add(_RadarBlip(
        imageUrl: creature.imageUrl,
        distance: distance,
        angle: angle,
        size: size,
      ));
    }
  }

  void _regenerateBlips() {
    if (!mounted) return;
    final dataService = Provider.of<DataService>(context, listen: false);
    if (dataService.creatures.isNotEmpty) {
      setState(() {
        _generateRandomBlips(dataService.creatures);
      });
    }
  }

  @override
  void dispose() {
    _hudController.dispose();
    // Use the cached reference — NOT Provider.of (unsafe in dispose)
    _soundService.stopAmbient();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<DataService>(context);
    final totalCreatures = dataService.creatures.length;
    final unlockedCreatures = dataService.creatures.where((c) => !c.isLocked).length;
    final bestDepth = dataService.highScoreDepth;
    final strings = AppStrings.listen(context);

    return Scaffold(
      backgroundColor: const Color(0xFF010610),
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

          // 2. Abyssal dark gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF010610).withValues(alpha: 0.25),
                    const Color(0xFF010610).withValues(alpha: 0.8),
                    const Color(0xFF010610),
                  ],
                ),
              ),
            ),
          ),

          // 3. Submarine cockpit overlay grid lines
          Positioned.fill(
            child: CustomPaint(
              painter: CockpitGridPainter(),
            ),
          ),

          // 4. Main Control Console Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top HUD Header
                  _buildHUDHeader(context),
                  const SizedBox(height: 16),

                  // Circular Radar Telemetry Instrument Cluster
                  _buildDashboardTelemetry(context, unlockedCreatures, totalCreatures, bestDepth),
                  const SizedBox(height: 24),

                  // Console Modules Section Header
                  Text(
                    strings.commandModules,
                    style: TextStyle(
                      color: const Color(0xFF00F0FF).withValues(alpha: 0.35),
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Asymmetric Staggered Grid of Rich Image Cards
                  _buildStaggeredGrid(context, unlockedCreatures, totalCreatures, bestDepth),
                  const SizedBox(height: 24),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHUDHeader(BuildContext context) {
    final strings = AppStrings.listen(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Digital tech ticker header
        // Digital tech ticker header with Back button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Wrap(
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 4,
                children: [
                  Text(
                    'LAT: 11.3733° N | LON: 142.1167° E (MARIANA ABYSS)',
                    style: TextStyle(
                      color: const Color(0xFF00F0FF).withValues(alpha: 0.4),
                      fontSize: 7.5,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'PRES: 108.6 MPa | TEMP: 1.8°C',
                    style: TextStyle(
                      color: const Color(0xFF00F0FF).withValues(alpha: 0.4),
                      fontSize: 7.5,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00F0FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.3), width: 0.8),
                ),
                child: const Icon(
                  Icons.close,
                  color: Color(0xFF00F0FF),
                  size: 14,
                ),
              ),
            ),
          ],
        ),
        const Divider(color: Color(0xFF00F0FF), height: 10, thickness: 0.3),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.cockpitTitle,
                    style: const TextStyle(
                      color: Color(0xFF00F0FF),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      shadows: [
                        Shadow(color: Color(0xFF00F0FF), blurRadius: 8),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      // Pulsing LED dot
                      AnimatedBuilder(
                        animation: _hudController,
                        builder: (context, child) {
                          return Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00FF66).withValues(
                                alpha: 0.3 + math.sin(_hudController.value * math.pi * 4).abs() * 0.7,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00FF66).withValues(alpha: 0.4),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          strings.systemActive,
                          style: TextStyle(
                            color: const Color(0xFF00F0FF).withValues(alpha: 0.6),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: const Color(0xFF00F0FF).withValues(alpha: 0.5),
                  size: 22,
                ),
                const SizedBox(width: 8),
                buildVolumeButton(context),
                const SizedBox(width: 4),
                buildSettingsButton(context),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDashboardTelemetry(BuildContext context, int unlocked, int total, int bestDepth) {
    final strings = AppStrings.listen(context);
    return Row(
      children: [
        // Left side: circular radar (enlarged to 190x190)
        _buildCentralRadar(context, unlocked, total, bestDepth),
        
        // Right side: 4 telemetry stats stacked vertically
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTelemetryStat(strings.recordDepth, '${bestDepth}m', Colors.amber),
                const SizedBox(height: 12),
                _buildTelemetryStat(strings.creatureDecoded, '$unlocked/$total', Colors.greenAccent),
                const SizedBox(height: 12),
                _buildTelemetryStat(strings.hullPressure, strings.safe, const Color(0xFF00F0FF)),
                const SizedBox(height: 12),
                _buildTelemetryStat(strings.transmissionFreq, 'VLF 18.2kHz', const Color(0xFFFF3366)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCentralRadar(BuildContext context, int unlocked, int total, int bestDepth) {
    const double radarSize = 190.0;
    return Container(
      width: radarSize,
      height: radarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF08152D).withValues(alpha: 0.25),
        border: Border.all(
          color: const Color(0xFF00F0FF).withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00F0FF).withValues(alpha: 0.08),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipOval(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Rotating radar grid
            AnimatedBuilder(
              animation: _hudController,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(radarSize, radarSize),
                  painter: TelemetryCirclePainter(sweepProgress: _hudController.value),
                );
              },
            ),

            // Pulsing radar echo rings
            AnimatedBuilder(
              animation: _hudController,
              builder: (context, child) {
                double pulse = (_hudController.value * 2) % 1.0;
                double opacity = (1.0 - pulse).clamp(0.0, 1.0);
                return Container(
                  width: radarSize * pulse,
                  height: radarSize * pulse,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00F0FF).withValues(alpha: opacity * 0.25),
                      width: 1.5,
                    ),
                  ),
                );
              },
            ),

            // Animated simulated monster blips (display actual monster silhouettes)
            ..._blips.map((blip) {
              return AnimatedBuilder(
                animation: _hudController,
                builder: (context, child) {
                  final double sweepAngle = _hudController.value * 2 * math.pi;
                  double diff = (sweepAngle - blip.angle) % (2 * math.pi);
                  
                  // Calculate opacity based on distance from sweep line (phosphor trail)
                  double opacity = (1.0 - diff / (0.85 * math.pi)).clamp(0.0, 1.0);
                  opacity = math.max(0.05, opacity); // faint background visibility

                  final double centerX = radarSize / 2;
                  final double centerY = radarSize / 2;
                  final double x = centerX + math.cos(blip.angle) * blip.distance;
                  final double y = centerY + math.sin(blip.angle) * blip.distance;

                  return Positioned(
                    left: x - blip.size / 2,
                    top: y - blip.size / 2,
                    child: Opacity(
                      opacity: opacity,
                      child: Container(
                        width: blip.size,
                        height: blip.size,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.15),
                          border: Border.all(
                            color: const Color(0xFF00F0FF).withValues(alpha: opacity * 0.25),
                            width: 0.5,
                          ),
                        ),
                          child: ClipOval(
                            child: blip.imageUrl.startsWith('http')
                                ? Image.network(
                                    blip.imageUrl,
                                    fit: BoxFit.contain,
                                    color: const Color(0xFF00F0FF).withValues(alpha: 0.85), // Sonar cyan tint
                                    colorBlendMode: BlendMode.srcATop,
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.waves, size: 8),
                                  )
                                : Image.asset(
                                    blip.imageUrl,
                                    fit: BoxFit.contain,
                                    color: const Color(0xFF00F0FF).withValues(alpha: 0.85), // Sonar cyan tint
                                    colorBlendMode: BlendMode.srcATop,
                                  ),
                          ),
                      ),
                    ),
                  );
                },
              );
            }),

            // Blinking sub icon in center
            AnimatedBuilder(
              animation: _hudController,
              builder: (context, child) {
                double opacity = 0.4 + math.sin(_hudController.value * math.pi * 4).abs() * 0.6;
                return Opacity(
                  opacity: opacity,
                  child: Image.asset(
                    'assets/images/icon/cruise.png',
                    width: 64,
                    height: 64,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 8,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildStaggeredGrid(BuildContext context, int unlocked, int total, int bestDepth) {
    final strings = AppStrings.listen(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column (Map & Simulator)
        Expanded(
          child: Column(
            children: [
              _buildImageConsoleCard(
                context: context,
                height: 140,
                iconWidget: Image.asset(
                  'assets/images/icon/map.png',
                  width: 46,
                  height: 46,
                ),
                title: strings.moduleMapTitle,
                subtitle: 'OCEAN GEOMAP',
                status: 'GEOLINK ONLINE',
                color: const Color(0xFF00F0FF),
                details: strings.moduleMapDesc,
                imageAsset: 'assets/images/creatures/world_ocean_map.png',
                onTap: () {
                  Provider.of<AdService>(context, listen: false).showInterstitialAd();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const OceanMapScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildImageConsoleCard(
                context: context,
                height: 190,
                iconWidget: Image.asset(
                  'assets/images/icon/oxygen-mask.png',
                  width: 46,
                  height: 46,
                ),
                title: strings.moduleSimulatorTitle,
                subtitle: 'DESCENT SIMULATOR',
                status: bestDepth > 0 ? 'RECORD: ${bestDepth}m' : 'READY TO LAUNCH',
                color: const Color(0xFFFFCC00),
                details: strings.moduleSimulatorDesc,
                imageAsset: 'assets/images/creatures/mariana_trench.png',
                onTap: () {
                  Provider.of<AdService>(context, listen: false).showInterstitialAd();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SimulatorScreen()),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Right Column (Sonar & Logbook)
        Expanded(
          child: Column(
            children: [
              _buildImageConsoleCard(
                context: context,
                height: 190,
                iconWidget: Image.asset(
                  'assets/images/icon/dra00.png',
                  width: 72,
                  height: 72,
                ),
                title: strings.moduleSonarTitle,
                subtitle: 'BIOMASS SCANNER',
                status: 'ACTIVE ',
                color: const Color(0xFFFF3366),
                details: strings.moduleSonarDesc,
                imageAsset: 'assets/images/creatures/the_bloop.png',
                onTap: () {
                  Provider.of<AdService>(context, listen: false).showInterstitialAd();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SonarScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildImageConsoleCard(
                context: context,
                height: 140,
                iconWidget: Image.asset(
                  'assets/images/icon/pirate-hat.png',
                  width: 46,
                  height: 46,
                ),
                title: strings.moduleLogbookTitle,
                subtitle: 'CAPTAIN LOGBOOK',
                status: 'DECODED $unlocked/$total',
                color: const Color(0xFF00FF66),
                details: strings.moduleLogbookDesc,
                imageAsset: 'assets/images/creatures/diver_transparent.png',
                onTap: () {
                  Provider.of<AdService>(context, listen: false).showInterstitialAd();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LogbookScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageConsoleCard({
    required BuildContext context,
    required double height,
    required Widget iconWidget,
    required String title,
    required String subtitle,
    required String status,
    required Color color,
    required String details,
    required String imageAsset,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF071224).withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: color.withValues(alpha: 0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.05),
                  blurRadius: 12,
                  spreadRadius: 1,
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  // 1. Module-themed Background Image (cropped & overlaid for maximum depth)
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.35,
                      child: Image.asset(
                        imageAsset,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // 2. Abyssal dark color overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF010610).withValues(alpha: 0.45),
                            const Color(0xFF010610).withValues(alpha: 0.85),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 3. Grid line pattern overlay inside the box
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.12,
                      child: CustomPaint(
                        painter: MiniGridPainter(),
                      ),
                    ),
                  ),

                  // 4. Corner bracket details for sci-fi look
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: color, width: 2),
                          left: BorderSide(color: color, width: 2),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: color, width: 2),
                          right: BorderSide(color: color, width: 2),
                        ),
                      ),
                    ),
                  ),

                  // 5. Card Contents
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Header: Icon and status dot
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            iconWidget,
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedBuilder(
                                  animation: _hudController,
                                  builder: (context, child) {
                                    return Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: color.withValues(
                                          alpha: 0.3 + math.sin(_hudController.value * math.pi * 4).abs() * 0.7,
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: color.withValues(alpha: 0.5),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  status,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        
                        // Info: Title, Subtitle, Divider, Details
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: const Color(0xFF00F0FF).withValues(alpha: 0.5),
                                fontSize: 7.5,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Divider(color: const Color(0xFF00F0FF).withValues(alpha: 0.1), height: 1),
                            const SizedBox(height: 4),
                            Text(
                              details,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 8.5,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Custom Painter for Cockpit overlay grid lines
class CockpitGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw horizontal lines
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // Draw vertical lines
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CockpitGridPainter oldDelegate) => false;
}

// Custom Painter for circular concentric telemetry grid with sweeping line
class TelemetryCirclePainter extends CustomPainter {
  final double sweepProgress;

  TelemetryCirclePainter({required this.sweepProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw concentric circles (scaled to size)
    canvas.drawCircle(center, size.width * 0.18, paint);
    canvas.drawCircle(center, size.width * 0.36, paint);
    canvas.drawCircle(center, size.width * 0.54, paint);

    // Crosshairs
    canvas.drawLine(Offset(center.dx - size.width * 0.54, center.dy), Offset(center.dx + size.width * 0.54, center.dy), paint);
    canvas.drawLine(Offset(center.dx, center.dy - size.height * 0.54), Offset(center.dx, center.dy + size.height * 0.54), paint);

    // Rotating sweeping sonar radar line
    final double angle = sweepProgress * 2 * math.pi;
    final sweepPaint = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.18)
      ..strokeWidth = 1.25;

    final dx = center.dx + math.cos(angle) * (size.width * 0.54);
    final dy = center.dy + math.sin(angle) * (size.height * 0.54);
    canvas.drawLine(center, Offset(dx, dy), sweepPaint);
  }

  @override
  bool shouldRepaint(covariant TelemetryCirclePainter oldDelegate) {
    return oldDelegate.sweepProgress != sweepProgress;
  }
}

// Custom Painter for fine cyber meshes inside cards
class MiniGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (double i = 0; i < size.height; i += 12) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
    for (double i = 0; i < size.width; i += 12) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant MiniGridPainter oldDelegate) => false;
}
