import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/creature.dart';
import '../services/sound_service.dart';
import '../widgets/size_comparison_widget.dart';
import '../widgets/structured_description_widget.dart';
import '../l10n/app_strings.dart';
import 'settings_screen.dart';

class DetailScreen extends StatefulWidget {
  final Creature creature;

  const DetailScreen({super.key, required this.creature});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with TickerProviderStateMixin {
  late final AnimationController _waveController;
  late final AnimationController _scanController;
  bool _isPlayingCreatureSound = false;
  late SoundService _soundService;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // Play creature sound automatically on enter
    if (widget.creature.ambientSound.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _soundService.playCreatureSound(widget.creature.ambientSound);
        if (mounted) {
          setState(() {
            _isPlayingCreatureSound = true;
          });
          _waveController.repeat();
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _soundService = Provider.of<SoundService>(context, listen: false);
  }

  @override
  void dispose() {
    // Stop creature sound on exit to restore background ambient
    _soundService.stopCreatureSound();
    _waveController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  void _toggleSound() async {
    if (widget.creature.ambientSound.isEmpty) return;
    if (_isPlayingCreatureSound) {
      await _soundService.stopCreatureSound();
      _waveController.stop();
    } else {
      await _soundService.playCreatureSound(widget.creature.ambientSound);
      _waveController.repeat();
    }
    setState(() {
      _isPlayingCreatureSound = !_isPlayingCreatureSound;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isMyth = widget.creature.type == 'myth';
    final Color themeColor = isMyth
        ? const Color(0xFFFF3366)
        : const Color(0xFF00F0FF);
    final strings = AppStrings.listen(context);

    return Scaffold(
      backgroundColor: const Color(0xFF020813),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Sleek Image Header
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.height * 0.42,
            backgroundColor: Colors.transparent,
            elevation: 0,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.6),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.6),
                  child: buildVolumeButton(context),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.6),
                  child: buildSettingsButton(context),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'creature_${widget.creature.id}',
                    child: Transform.scale(
                      scale:
                          (widget.creature.id == 'godzilla' ||
                              widget.creature.id == 'ghost_leviathan' ||
                              widget.creature.id == 'lagiacrus')
                          ? 1.35
                          : 1.35,
                      child: widget.creature.buildImage(
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFF0D1F3D),
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.white24,
                              size: 60,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Scanning corner brackets overlay
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: ScannerCornersPainter(
                          color: themeColor.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                  ),

                  // Scanning sweep line animation
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _scanController,
                        builder: (context, child) {
                          return Stack(
                            children: [
                              Positioned(
                                top:
                                    _scanController.value *
                                    (MediaQuery.of(context).size.height * 0.42),
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 2.0,
                                  decoration: BoxDecoration(
                                    color: themeColor,
                                    boxShadow: [
                                      BoxShadow(
                                        color: themeColor.withValues(
                                          alpha: 0.5,
                                        ),
                                        blurRadius: 10.0,
                                        spreadRadius: 1.0,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                  // Dark shadow gradient from bottom to top
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF020813), Colors.transparent],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          stops: [0.15, 0.7],
                        ),
                      ),
                    ),
                  ),

                  // Telemetry overlays
                  Positioned(
                    left: 20,
                    bottom: 20,
                    child: _buildDepthGauge(themeColor),
                  ),
                  Positioned(
                    right: 20,
                    bottom: 20,
                    child: _buildDangerHUD(themeColor),
                  ),
                ],
              ),
            ),
          ),

          // 2. Creature details body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type tag (Science vs Myth)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10.0,
                          vertical: 6.0,
                        ),
                        decoration: BoxDecoration(
                          color: themeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20.0),
                          border: Border.all(
                            color: themeColor.withValues(alpha: 0.3),
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          isMyth
                              ? strings.mythCreature
                              : strings.realCreature,
                          style: TextStyle(
                            color: themeColor,
                            fontSize: 10.0,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),

                      // Sound trigger button
                      if (widget.creature.ambientSound.isNotEmpty)
                        GestureDetector(
                          onTap: _toggleSound,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 6.0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(20.0),
                              border: Border.all(
                                color: themeColor.withValues(alpha: 0.3),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildWaveformAnimation(themeColor),
                                const SizedBox(width: 8),
                                Text(
                                  _isPlayingCreatureSound
                                      ? strings.stopSound
                                      : strings.soundLabel,
                                  style: TextStyle(
                                    color: themeColor,
                                    fontSize: 10.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16.0),

                  // Name & Scientific name
                  Text(
                    widget.creature.getName(strings.languageCode),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28.0,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    widget.creature.scientificName,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 14.0,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  // Description/Cốt truyện rùng rợn
                  Text(
                    strings.languageCode == 'en' ? "FIELD EXPLORATION DOSSIER" : "NHẬT KÝ THÁM HIỂM THỰC ĐỊA",
                    style: const TextStyle(
                      color: Colors.white30,
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  StructuredDescriptionWidget(
                    description: widget.creature.getDescription(strings.languageCode),
                    themeColor: themeColor,
                    compact: false,
                  ),
                  const SizedBox(height: 24.0),

                  // Size comparison widget
                  SizeComparisonWidget(
                    humanSize: widget.creature.humanSizeMeters,
                    creatureSize: widget.creature.creatureSizeMeters,
                    creatureName: widget.creature.getName(strings.languageCode).split(
                      ' (',
                    )[0], // Extract main name without notes
                    creatureImageUrl: widget.creature.imageUrl,
                  ),
                  const SizedBox(height: 48.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveformAnimation(Color color) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            double value = 0.0;
            if (_isPlayingCreatureSound) {
              value = math.sin(
                (_waveController.value * 2 * math.pi) + (index * 1.5),
              );
              value = (value.abs() * 12.0) + 2.0; // scales from 2 to 14
            } else {
              value = 3.0; // static flat line
            }
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 2.0,
              height: value,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(1.0),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildDepthGauge(Color themeColor) {
    final strings = AppStrings.of(context);
    final double gaugeHeight = 135.0;
    final int maxOceanDepth = 11000;

    final double relativeTop = (widget.creature.minDepth / maxOceanDepth).clamp(
      0.0,
      1.0,
    );
    final double relativeBottom = (widget.creature.maxDepth / maxOceanDepth)
        .clamp(0.0, 1.0);

    // Total space for the bar indicator inside the gauge
    final double totalBarHeight = 85.0;
    final double barTop = relativeTop * totalBarHeight;
    final double barHeight = math.max(
      6.0,
      (relativeBottom - relativeTop) * totalBarHeight,
    );

    return Container(
      width: 80,
      height: gaugeHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: themeColor.withValues(alpha: 0.2),
          width: 1.0,
        ),
      ),
      child: Column(
        children: [
          Text(
            strings.languageCode == 'en' ? "DEPTH SCAN" : "QUÉT ĐỘ SÂU",
            style: TextStyle(
              color: themeColor.withValues(alpha: 0.8),
              fontSize: 8.0,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                // Gauge vertical bar
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: barTop,
                        height: barHeight,
                        left: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: themeColor,
                            borderRadius: BorderRadius.circular(2.5),
                            boxShadow: [
                              BoxShadow(
                                color: themeColor.withValues(alpha: 0.6),
                                blurRadius: 4,
                                spreadRadius: 0.5,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                // Depth text markers
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${widget.creature.minDepth}m",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 8.0,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${widget.creature.maxDepth}m",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 8.0,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerHUD(Color themeColor) {
    final strings = AppStrings.of(context);
    final danger = widget.creature.dangerLevel;
    final Color dangerColor = _getDangerLevelColor(danger);
    final String dangerLabel = _getDangerLevelLabel(danger, strings);

    return Container(
      width: 125,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: dangerColor.withValues(alpha: 0.2),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            strings.dangerLevel,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 7.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            dangerLabel,
            style: TextStyle(
              color: dangerColor,
              fontSize: 10.0,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          // Danger level indicator segments
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (index) {
              final active = index < danger;
              return Expanded(
                child: Container(
                  height: 4.0,
                  margin: EdgeInsets.only(right: index < 4 ? 3.0 : 0.0),
                  decoration: BoxDecoration(
                    color: active
                        ? dangerColor
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(1),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: dangerColor.withValues(alpha: 0.4),
                              blurRadius: 4,
                              spreadRadius: 0.5,
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Color _getDangerLevelColor(int level) {
    switch (level) {
      case 1:
        return const Color(0xFF00FF66); // Safe Green
      case 2:
        return const Color(0xFF00F0FF); // Info Cyan
      case 3:
        return const Color(0xFFFFB300); // Warning Orange
      case 4:
        return const Color(0xFFFF3366); // Danger Pink/Red
      case 5:
      default:
        return const Color(0xFFFF003C); // Critical Red
    }
  }

  String _getDangerLevelLabel(int level, AppStrings strings) {
    switch (level) {
      case 1:
        return strings.languageCode == 'vi' ? "AN TOÀN" : "SAFE";
      case 2:
        return strings.languageCode == 'vi' ? "CẢNH GIÁC" : "CAUTION";
      case 3:
        return strings.languageCode == 'vi' ? "NGUY HIỂM" : "DANGEROUS";
      case 4:
        return strings.languageCode == 'vi' ? "MỐI ĐE DỌA" : "THREAT";
      case 5:
      default:
        return strings.languageCode == 'vi' ? "THẢM HỌA GIEO RẮC" : "HARBINGER OF DOOM";
    }
  }
}

class ScannerCornersPainter extends CustomPainter {
  final Color color;
  ScannerCornersPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final double length = 16.0;
    final double padding = 16.0;

    // Top-Left Corner
    canvas.drawPath(
      Path()
        ..moveTo(padding, padding + length)
        ..lineTo(padding, padding)
        ..lineTo(padding + length, padding),
      paint,
    );

    // Top-Right Corner
    canvas.drawPath(
      Path()
        ..moveTo(size.width - padding - length, padding)
        ..lineTo(size.width - padding, padding)
        ..lineTo(size.width - padding, padding + length),
      paint,
    );

    // Bottom-Left Corner
    canvas.drawPath(
      Path()
        ..moveTo(padding, size.height - padding - length)
        ..lineTo(padding, size.height - padding)
        ..lineTo(padding + length, size.height - padding),
      paint,
    );

    // Bottom-Right Corner
    canvas.drawPath(
      Path()
        ..moveTo(size.width - padding - length, size.height - padding)
        ..lineTo(size.width - padding, size.height - padding)
        ..lineTo(size.width - padding, size.height - padding - length),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant ScannerCornersPainter oldDelegate) =>
      oldDelegate.color != color;
}
