import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../models/ocean.dart';
import '../services/data_service.dart';
import '../services/sound_service.dart';
import '../widgets/ocean_details_widgets.dart';
import '../l10n/app_strings.dart';
import 'settings_screen.dart';

class OceanMapScreen extends StatefulWidget {
  const OceanMapScreen({super.key});

  @override
  State<OceanMapScreen> createState() => _OceanMapScreenState();
}

class _OceanMapScreenState extends State<OceanMapScreen> with TickerProviderStateMixin {
  Ocean? _selectedOcean;
  late final AnimationController _pulseController;
  late final AnimationController _scanLineController;
  String? _backgroundImage;
  int _activeTab = 0;

  final List<_MapMonsterShadow> _monsterShadows = const [
    _MapMonsterShadow(
      imageUrl: 'assets/images/creatures/megalodon.png',
      mapX: 0.30,
      mapY: 0.40,
      size: 42.0,
      tintColor: Color(0xFFFF3366),
    ),
    _MapMonsterShadow(
      imageUrl: 'assets/images/creatures/leviathan.png',
      mapX: 0.80,
      mapY: 0.45,
      size: 46.0,
      tintColor: Color(0xFFFF3366),
    ),
    _MapMonsterShadow(
      imageUrl: 'assets/images/creatures/cthulhu.png',
      mapX: 0.70,
      mapY: 0.82,
      size: 48.0,
      tintColor: Color(0xFFFF00FF),
    ),
    _MapMonsterShadow(
      imageUrl: 'assets/images/creatures/kraken.png',
      mapX: 0.55,
      mapY: 0.62,
      size: 40.0,
      tintColor: Color(0xFFFF6622),
    ),
    _MapMonsterShadow(
      imageUrl: 'assets/images/creatures/giant_squid.png',
      mapX: 0.45,
      mapY: 0.18,
      size: 32.0,
      tintColor: Color(0xFF00F0FF),
    ),
  ];

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
    
    // Pulsing animations for hotspots
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Scanning vertical line animation
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  void _selectOcean(Ocean ocean) {
    setState(() {
      _selectedOcean = ocean;
      _activeTab = 0;
    });
    // Play radar sonar echo sound
    Provider.of<SoundService>(context, listen: false).playCreatureSound("sonar_echo.mp3");
  }

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<DataService>(context);
    final size = MediaQuery.of(context).size;
    final strings = AppStrings.listen(context);

    return Scaffold(
      backgroundColor: const Color(0xFF010409),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1F3D).withValues(alpha: 0.5),
        elevation: 0,
        title: Text(
          strings.oceanMapTitle,
          style: const TextStyle(
            color: Color(0xFF00F0FF),
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            fontFamily: 'monospace',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00F0FF)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00F0FF)),
            onPressed: () {
              setState(() {
                _selectedOcean = null;
              });
            },
          ),
          buildVolumeButton(context),
          buildSettingsButton(context),
        ],
      ),
      body: Stack(
        children: [
          // 1. Background image (Alternating when no selection, or selected ocean's image when selected!)
          Positioned.fill(
            child: Opacity(
              opacity: _selectedOcean != null ? 0.9 : 0.65,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                child: _selectedOcean != null
                    ? Image.asset(
                        _selectedOcean!.imageUrl,
                        key: ValueKey(_selectedOcean!.imageUrl),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      )
                    : (_backgroundImage != null
                        ? Image.asset(
                            _backgroundImage!,
                            key: ValueKey(_backgroundImage!),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          )
                        : const SizedBox.shrink()),
              ),
            ),
          ),
          // 2. Abyssal dark overlay
          Positioned.fill(
            child: Container(
              color: const Color(0xFF010409).withValues(alpha: 0.75),
            ),
          ),
          // 3. Main Content
          SafeArea(
            child: dataService.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00F0FF)),
                    ),
                  )
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        // Instruction Banner
                        _buildStatusBanner(),
                        
                        const SizedBox(height: 16),
                        
                        // Interactive Map Area
                        _buildInteractiveMap(size),
                        
                        const SizedBox(height: 20),
                        
                        // Ocean Details Panel
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _selectedOcean != null
                              ? _buildOceanDetailsCard(_selectedOcean!)
                              : _buildEmptyStateCard(),
                        ),
                        
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    final strings = AppStrings.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF00F0FF),
              shape: BoxShape.circle,
            ),
          ).animateBlinkingLED(),
          const SizedBox(width: 8),
          Text(
            strings.radarActive,
            style: const TextStyle(
              color: Color(0xFF00F0FF),
              fontSize: 9.0,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveMap(Size screenSize) {
    final dataService = Provider.of<DataService>(context, listen: false);
    final strings = AppStrings.of(context);
    final mapHeight = screenSize.width * 0.95; // Ensure square-ish or proportional height

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      height: mapHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: const Color(0xFF00F0FF).withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.5),
        child: Stack(
          children: [
            // 1. World Ocean Map Background
            Positioned.fill(
              child: Image.asset(
                'assets/images/creatures/world_ocean_map.png',
                fit: BoxFit.cover,
              ),
            ),

            // 2. High-Tech Grid Overlays
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _RadarGridPainter(),
                ),
              ),
            ),

            // 3. Scanline Sweep Animation
            AnimatedBuilder(
              animation: _scanLineController,
              builder: (context, child) {
                return Positioned(
                  top: _scanLineController.value * mapHeight,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 2.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F0FF).withValues(alpha: 0.6),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00F0FF).withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // 3.5 Monster shadows active on the map
            ..._monsterShadows.map((shadow) {
              final double posX = shadow.mapX * (screenSize.width - 32.0);
              final double posY = shadow.mapY * mapHeight;

              return Positioned(
                left: posX - shadow.size / 2,
                top: posY - shadow.size / 2,
                child: Opacity(
                  opacity: 0.16,
                  child: Image.asset(
                    shadow.imageUrl,
                    width: shadow.size,
                    height: shadow.size,
                    fit: BoxFit.contain,
                    color: shadow.tintColor,
                    colorBlendMode: BlendMode.srcATop,
                    errorBuilder: (context, err, stack) => const SizedBox.shrink(),
                  ),
                ),
              );
            }),

            // 4. Hotspots (Tapped coordinates)
            ...dataService.oceans.map((ocean) {
              final double posX = ocean.mapX * (screenSize.width - 32.0);
              final double posY = ocean.mapY * mapHeight;
              final bool isSelected = _selectedOcean?.id == ocean.id;

              return Positioned(
                left: posX - 25,
                top: posY - 25,
                child: GestureDetector(
                  onTap: () => _selectOcean(ocean),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer Pulsing Radar Ring
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              width: 12 + (_pulseController.value * 28),
                              height: 12 + (_pulseController.value * 28),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: (isSelected ? const Color(0xFFFF3366) : const Color(0xFF00F0FF))
                                      .withValues(alpha: 1.0 - _pulseController.value),
                                  width: 1.5,
                                ),
                              ),
                            );
                          },
                        ),
                        // Inner pulsing solid ring
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              width: 8 + (_pulseController.value * 12),
                              height: 8 + (_pulseController.value * 12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (isSelected ? const Color(0xFFFF3366) : const Color(0xFF00F0FF))
                                    .withValues(alpha: 0.25 * (1.0 - _pulseController.value)),
                              ),
                            );
                          },
                        ),
                        // Center Core Hotspot
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? const Color(0xFFFF3366) : const Color(0xFF00F0FF),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected ? const Color(0xFFFF3366) : const Color(0xFF00F0FF),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        // Label name above hotspot
                        Positioned(
                          top: 4,
                          child: Text(
                            ocean.getName(strings.languageCode),
                            style: TextStyle(
                              color: isSelected ? const Color(0xFFFF3366) : Colors.white70,
                              fontSize: 8.0,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              backgroundColor: Colors.black.withValues(alpha: 0.75),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard() {
    final strings = AppStrings.of(context);
    return Container(
      key: const ValueKey("empty_state"),
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF020813),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00F0FF).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.radar_outlined,
            color: Color(0xFF00F0FF),
            size: 44,
          ).animateRadarPulse(),
          const SizedBox(height: 16),
          Text(
            strings.radarScan,
            style: const TextStyle(
              color: Color(0xFF00F0FF),
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              strings.radarInstruction,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11.5,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOceanDetailsCard(Ocean ocean) {
    final strings = AppStrings.of(context);
    return Container(
      key: ValueKey("ocean_${ocean.id}"),
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF020A18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00F0FF).withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00F0FF).withValues(alpha: 0.06),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ═══════════════════════════════════════════════════════
          // HERO HEADER — Ocean name + coordinates + CTA BUTTON
          // ═══════════════════════════════════════════════════════
          Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0D2340).withValues(alpha: 0.95),
                  const Color(0xFF040F1E).withValues(alpha: 0.95),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(19),
                topRight: Radius.circular(19),
              ),
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFF00F0FF).withValues(alpha: 0.35),
                  width: 1.0,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location coordinates badge
                Row(
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00F0FF),
                        shape: BoxShape.circle,
                      ),
                    ).animateBlinkingLED(),
                    const SizedBox(width: 6),
                    Text(
                      ocean.coordinates,
                      style: const TextStyle(
                        color: Color(0xFF00F0FF),
                        fontSize: 9.5,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: const Color(0xFF00F0FF).withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Text(
                        "SIGNAL LOCKED",
                        style: TextStyle(
                          color: Color(0xFF00F0FF),
                          fontSize: 7.5,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Ocean name
                Text(
                  ocean.getName(strings.languageCode).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24.0,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  (strings.languageCode == 'en' ? ocean.name : ocean.englishName).toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF00F0FF),
                    fontSize: 11.0,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.5,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 18),

                // ╔══════════════════════════════════════════╗
                // ║  CHIÊM NGƯỠNG LÒNG VỰC SÂU — HERO CTA  ║
                // ╚══════════════════════════════════════════╝
                GestureDetector(
                  onTap: () => _showFullOceanFloor(ocean),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF003D4D), Color(0xFF00F0FF), Color(0xFF003D4D)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00F0FF).withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 1,
                        ),
                        BoxShadow(
                          color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                          blurRadius: 40,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background scan lines
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CustomPaint(
                              painter: _ButtonScanlinePainter(),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.remove_red_eye_outlined,
                              color: Colors.black,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              strings.languageCode == 'en' ? "DEEP ABYSS SPECTACLE" : "CHIÊM NGƯỠNG LÒNG VỰC SÂU",
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14.0,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Futuristic Tab Bar ──────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF030D1C),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  _buildTabItem(0, strings.languageCode == 'en' ? 'TELEMETRY' : 'TRẠM DÒ', Icons.radar),
                  _buildTabItem(1, strings.languageCode == 'en' ? 'GEOLOGY' : 'ĐỊA CHẤT', Icons.terrain),
                  _buildTabItem(2, strings.languageCode == 'en' ? 'WARNING' : 'CẢNH BÁO', Icons.warning_amber_rounded),
                ],
              ),
            ),
          ),

          // ── Animated Content Switcher ──────────────────
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AnimatedSwitcher( 
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.05),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _buildActiveTabContent(ocean),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String label, IconData icon) {
    final bool isActive = _activeTab == index;
    final Color activeColor = index == 2 && isActive
        ? const Color(0xFFFF3366)
        : const Color(0xFF00F0FF);
        
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeTab = index;
          });
          Provider.of<SoundService>(context, listen: false).playCreatureSound("sonar_echo.mp3");
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            color: isActive 
                ? activeColor.withValues(alpha: 0.12)
                : Colors.transparent,
            border: isActive
                ? Border.all(color: activeColor.withValues(alpha: 0.4), width: 1)
                : Border.all(color: Colors.transparent, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isActive ? activeColor : Colors.white38,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white30,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(Ocean ocean) {
    final strings = AppStrings.of(context);
    switch (_activeTab) {
      case 0:
        return Column(
          key: const ValueKey(0),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── DEPTH VISUALIZER BAR ──────────────────────────
            Container(
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: const Color(0xFF0A1B2E).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFFF3366).withValues(alpha: 0.3),
                  width: 1.0,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.arrow_downward, color: Color(0xFFFF3366), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        strings.languageCode == 'en' ? "DEEPEST POINT OF SYSTEM" : "ĐIỂM SÂU NHẤT HỆ THỐNG",
                        style: const TextStyle(
                          color: Color(0xFFFF3366),
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3366).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color(0xFFFF3366).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          ocean.deepestPointDepth,
                          style: const TextStyle(
                            color: Color(0xFFFF3366),
                            fontSize: 13.0,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      ocean.getDeepestPointName(strings.languageCode),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: 6,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF00F0FF),
                            Color(0xFF0044FF),
                            Color(0xFF220055),
                            Color(0xFF110022),
                            Colors.black,
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("0m", style: TextStyle(color: Colors.white30, fontSize: 8, fontFamily: 'monospace')),
                      Text(
                        ocean.deepestPointDepth,
                        style: const TextStyle(color: Color(0xFFFF3366), fontSize: 8, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // ── AREA + AVG DEPTH TILES ──────────────────────────
            Row(
              children: [
                Expanded(
                  child: _buildParameterTile(
                    strings.languageCode == 'en' ? "SURFACE AREA" : "DIỆN TÍCH",
                    ocean.area,
                    Icons.aspect_ratio,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildParameterTile(
                    strings.languageCode == 'en' ? "AVERAGE DEPTH" : "ĐỘ SÂU TRUNG BÌNH",
                    ocean.avgDepth,
                    Icons.compress,
                  ),
                ),
              ],
            ),
          ],
        );
      case 1:
        return Column(
          key: const ValueKey(1),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 3, height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00F0FF),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.6),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  strings.languageCode == 'en' ? "GEOLOGICAL SURVEY PROFILE" : "HỒ SƠ KHẢO SÁT ĐỊA CHẤT",
                  style: const TextStyle(
                    color: Color(0xFF00F0FF),
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            OceanDescriptionWidget(
              description: ocean.getDescription(strings.languageCode),
              themeColor: const Color(0xFF00F0FF),
            ),
          ],
        );
      case 2:
        return Column(
          key: const ValueKey(2),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ThalassophobiaWarningWidget(
              warningText: ocean.getThalassophobiaWarning(strings.languageCode),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildParameterTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00F0FF), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white30,
                    fontSize: 8.0,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullOceanFloor(Ocean ocean) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Ocean Floor View",
      barrierColor: Colors.black.withValues(alpha: 0.95),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return _FullOceanFloorViewer(ocean: ocean);
      },
    );
  }
}

// Full screen viewer for majestic 3D floor photos
class _FullOceanFloorViewer extends StatefulWidget {
  final Ocean ocean;
  const _FullOceanFloorViewer({required this.ocean});

  @override
  State<_FullOceanFloorViewer> createState() => _FullOceanFloorViewerState();
}

class _FullOceanFloorViewerState extends State<_FullOceanFloorViewer> {
  int _currentPage = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Majestic Ocean Floor Image
          Image.asset(
            widget.ocean.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(Icons.broken_image, color: Colors.white24, size: 50),
              );
            },
          ),

          // 2. Telemetry vignette overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.92),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // 3. Sci-fi scanning grid overlay
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _FloorTelemetryPainter(coordinates: widget.ocean.coordinates),
              ),
            ),
          ),

          // 4. Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: ClipOval(
              child: Container(
                color: Colors.black.withValues(alpha: 0.6),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF00F0FF)),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),

          // 5. Bottom sliding carousel information overlay
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 16,
            right: 16,
            child: Container(
              height: 210,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (_currentPage == 2 ? const Color(0xFFFF3366) : const Color(0xFF00F0FF))
                      .withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_currentPage == 2 ? const Color(0xFFFF3366) : const Color(0xFF00F0FF))
                        .withValues(alpha: 0.08),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Page view contents
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      children: [
                        // Card 1: Telemetry Station Info
                        _buildTelemetryCard(strings),
                        // Card 2: Geological Profile
                        _buildGeologyCard(strings),
                        // Card 3: Deep Sea Threat Warnings
                        _buildWarningCard(strings),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Page Indicator Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      final bool isSelected = _currentPage == index;
                      final Color dotColor = _currentPage == 2 
                          ? const Color(0xFFFF3366) 
                          : const Color(0xFF00F0FF);
                          
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isSelected ? 18.0 : 6.0,
                        height: 6.0,
                        decoration: BoxDecoration(
                          color: isSelected ? dotColor : Colors.white24,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryCard(AppStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                strings.languageCode == 'en'
                    ? "TELEMETRY STATION // ${widget.ocean.getName(strings.languageCode).toUpperCase()}"
                    : "TRẠM THU THẬP TÍN HIỆU // ${widget.ocean.getName(strings.languageCode).toUpperCase()}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF00F0FF),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.ocean.coordinates,
              style: const TextStyle(
                color: Color(0xFF00F0FF),
                fontSize: 9.5,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Text(
              strings.languageCode == 'en'
                  ? "Maximum survey point depth reached ${widget.ocean.deepestPointDepth} at '${widget.ocean.getDeepestPointName(strings.languageCode)}'. Sonar visibility is limited. Extreme hydrostatic pressure."
                  : "Độ sâu điểm khảo sát cực đại đạt ${widget.ocean.deepestPointDepth} tại '${widget.ocean.getDeepestPointName(strings.languageCode)}'. Tầm nhìn bằng rađa siêu âm hạn chế. Áp suất tĩnh cực lớn.",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 11.5,
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGeologyCard(AppStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.terrain, color: Color(0xFF00F0FF), size: 14),
            const SizedBox(width: 6),
            Text(
              strings.languageCode == 'en' ? "GEOLOGICAL SURVEY PROFILE" : "HỒ SƠ KHẢO SÁT ĐỊA CHẤT",
              style: const TextStyle(
                color: Color(0xFF00F0FF),
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: OceanDescriptionWidget(
              description: widget.ocean.getDescription(strings.languageCode),
              themeColor: const Color(0xFF00F0FF),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWarningCard(AppStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF3366), size: 14),
            const SizedBox(width: 6),
            Text(
              strings.languageCode == 'en' ? "THALASSOPHOBIA WARNING" : "CẢNH BÁO HỘI CHỨNG BIỂN SÂU",
              style: const TextStyle(
                color: Color(0xFFFF3366),
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ThalassophobiaWarningWidget(
              warningText: widget.ocean.getThalassophobiaWarning(strings.languageCode),
            ),
          ),
        ),
      ],
    );
  }
}

// Custom Painter for Radar Grid layout on Map
// Scanline texture for the CTA button
class _ButtonScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..strokeWidth = 1.0;
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RadarGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.08)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final double midX = size.width / 2;
    final double midY = size.height / 2;

    // Draw concentric circles
    canvas.drawCircle(Offset(midX, midY), size.width * 0.15, linePaint);
    canvas.drawCircle(Offset(midX, midY), size.width * 0.3, linePaint);
    canvas.drawCircle(Offset(midX, midY), size.width * 0.45, linePaint);

    // Draw diagonal cross lines
    canvas.drawLine(Offset(0, 0), Offset(size.width, size.height), linePaint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), linePaint);

    // Draw horizontal & vertical center lines
    canvas.drawLine(Offset(midX, 0), Offset(midX, size.height), linePaint);
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom Painter for Sci-fi screen corners on the full viewer
class _FloorTelemetryPainter extends CustomPainter {
  final String coordinates;
  _FloorTelemetryPainter({required this.coordinates});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final double margin = 24.0;
    final double len = 20.0;

    // Top-Left corner
    canvas.drawPath(
      Path()
        ..moveTo(margin, margin + len)
        ..lineTo(margin, margin)
        ..lineTo(margin + len, margin),
      paint,
    );

    // Top-Right corner
    canvas.drawPath(
      Path()
        ..moveTo(size.width - margin - len, margin)
        ..lineTo(size.width - margin, margin)
        ..lineTo(size.width - margin, margin + len),
      paint,
    );

    // Bottom-Left corner
    canvas.drawPath(
      Path()
        ..moveTo(margin, size.height - margin - len)
        ..lineTo(margin, size.height - margin)
        ..lineTo(margin + len, size.height - margin),
      paint,
    );

    // Bottom-Right corner
    canvas.drawPath(
      Path()
        ..moveTo(size.width - margin - len, size.height - margin)
        ..lineTo(size.width - margin, size.height - margin)
        ..lineTo(size.width - margin, size.height - margin - len),
      paint,
    );

    // Draw a thin crosshair in the center
    final Paint crossPaint = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.18)
      ..strokeWidth = 1.0;
    
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double gap = 10.0;
    final double sizeC = 30.0;

    canvas.drawLine(Offset(cx - sizeC, cy), Offset(cx - gap, cy), crossPaint);
    canvas.drawLine(Offset(cx + gap, cy), Offset(cx + sizeC, cy), crossPaint);
    canvas.drawLine(Offset(cx, cy - sizeC), Offset(cx, cy - gap), crossPaint);
    canvas.drawLine(Offset(cx, cy + gap), Offset(cx, cy + sizeC), crossPaint);
    canvas.drawCircle(Offset(cx, cy), sizeC * 0.5, crossPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Bouncing and pulsing animations wrappers
extension MapAnimation on Widget {
  Widget animateRadarPulse() {
    return _RadarPulseWrapper(child: this);
  }

  Widget animateBlinkingLED() {
    return _BlinkingLEDWrapper(child: this);
  }
}

class _RadarPulseWrapper extends StatefulWidget {
  final Widget child;
  const _RadarPulseWrapper({required this.child});

  @override
  State<_RadarPulseWrapper> createState() => _RadarPulseWrapperState();
}

class _RadarPulseWrapperState extends State<_RadarPulseWrapper> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.92, end: 1.08).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: widget.child,
    );
  }
}

class _BlinkingLEDWrapper extends StatefulWidget {
  final Widget child;
  const _BlinkingLEDWrapper({required this.child});

  @override
  State<_BlinkingLEDWrapper> createState() => _BlinkingLEDWrapperState();
}

class _BlinkingLEDWrapperState extends State<_BlinkingLEDWrapper> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: widget.child,
    );
  }
}

class _MapMonsterShadow {
  final String imageUrl;
  final double mapX;
  final double mapY;
  final double size;
  final Color tintColor;

  const _MapMonsterShadow({
    required this.imageUrl,
    required this.mapX,
    required this.mapY,
    required this.size,
    required this.tintColor,
  });
}
