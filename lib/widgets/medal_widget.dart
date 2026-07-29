import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';

enum MedalType {
  twilightScout,
  midnightExplorer,
  abyssalPioneer,
  marianaConqueror,
  cryptographer,
  deepseaLegend,
}

class MedalWidget extends StatefulWidget {
  final MedalType type;
  final String title;
  final String description;
  final String progressText;
  final bool isUnlocked;
  final bool alreadyAnimated;
  final VoidCallback onUnlockAnimationComplete;

  const MedalWidget({
    super.key,
    required this.type,
    required this.title,
    required this.description,
    required this.progressText,
    required this.isUnlocked,
    required this.alreadyAnimated,
    required this.onUnlockAnimationComplete,
  });

  @override
  State<MedalWidget> createState() => _MedalWidgetState();
}

class _MedalWidgetState extends State<MedalWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _shatterAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  final List<_DebrisParticle> _particles = [];
  final math.Random _random = math.Random();
  bool _particlesSpawned = false;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // 0.0 - 0.35: Shaking of chains
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 6.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -6.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 5.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 5.0, end: -5.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -5.0, end: 4.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: -4.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 2.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 2.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.35, curve: Curves.linear),
    ));

    // 0.35 - 1.0: Shattering & flying away of chains
    _shatterAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
    );

    // 0.35 - 0.7: Scale pop (medal emerges)
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.15), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.35, 0.7, curve: Curves.easeInOut),
    ));

    // 0.35 - 0.6: Exposure neon glow flash
    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.35, 0.6, curve: Curves.easeIn),
    ));

    _animController.addListener(() {
      // Spawn particles exactly at shatter time
      if (_animController.value >= 0.35 && !_particlesSpawned) {
        _spawnParticles();
      }
      
      // Update particles
      if (_particlesSpawned) {
        _updateParticles();
      }
    });

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onUnlockAnimationComplete();
      }
    });

    // If unlocked and hasn't played animation, trigger it
    if (widget.isUnlocked && !widget.alreadyAnimated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animController.forward();
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _spawnParticles() {
    _particlesSpawned = true;
    _particles.clear();
    
    // Spawn 25-30 metal shard & spark particles at center
    for (int i = 0; i < 28; i++) {
      final double angle = _random.nextDouble() * 2 * math.pi;
      final double speed = 4.0 + _random.nextDouble() * 12.0;
      final bool isSpark = _random.nextBool();
      
      _particles.add(
        _DebrisParticle(
          x: 0, // relative to center
          y: 0,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed - 2.0, // slight upward bias
          size: isSpark ? 1.5 + _random.nextDouble() * 2.0 : 4.0 + _random.nextDouble() * 6.0,
          color: isSpark 
              ? const Color(0xFFFFCC00) // spark gold
              : Colors.grey.shade400, // metal debris
          rotation: _random.nextDouble() * 2 * math.pi,
          rotationSpeed: (_random.nextDouble() - 0.5) * 0.4,
          isSpark: isSpark,
          life: 1.0,
          decay: 0.03 + _random.nextDouble() * 0.04,
        ),
      );
    }
  }

  void _updateParticles() {
    setState(() {
      for (var p in _particles) {
        p.x += p.vx;
        p.y += p.vy;
        
        // Gravity
        p.vy += 0.4;
        
        // Drag
        p.vx *= 0.98;
        p.vy *= 0.98;
        
        // Spin
        p.rotation += p.rotationSpeed;
        
        // Decay life
        p.life -= p.decay;
      }
      _particles.removeWhere((p) => p.life <= 0);
    });
  }

  Color _getMedalThemeColor() {
    switch (widget.type) {
      case MedalType.twilightScout:
        return const Color(0xFF00F0FF); // Cyan
      case MedalType.midnightExplorer:
        return const Color(0xFFFF9900); // Orange
      case MedalType.abyssalPioneer:
        return const Color(0xFFFF3366); // Crimson
      case MedalType.marianaConqueror:
        return const Color(0xFFFFD700); // Gold
      case MedalType.cryptographer:
        return const Color(0xFF00FF66); // Emerald Green
      case MedalType.deepseaLegend:
        return const Color(0xFFA020F0); // Mythic Purple
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color themeColor = _getMedalThemeColor();
    final bool showLockedChains = !widget.isUnlocked || (widget.isUnlocked && !widget.alreadyAnimated);

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        // Compute transforms based on animation state
        double shakeX = 0.0;
        double shakeY = 0.0;
        double medalScale = 1.0;
        double glowOpacity = 0.0;

        if (widget.isUnlocked && !widget.alreadyAnimated) {
          if (_animController.value < 0.35) {
            shakeX = _shakeAnimation.value * (1.0 - 2.0 * _random.nextDouble());
            shakeY = _shakeAnimation.value * (1.0 - 2.0 * _random.nextDouble());
          } else {
            medalScale = _scaleAnimation.value;
            glowOpacity = _glowAnimation.value;
          }
        } else if (!widget.isUnlocked) {
          // Locked
          medalScale = 0.9;
        }

        return Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF030A18).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isUnlocked 
                  ? themeColor.withValues(alpha: 0.3) 
                  : Colors.white10,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isUnlocked 
                    ? themeColor.withValues(alpha: 0.05) 
                    : Colors.transparent,
                blurRadius: 15,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 16),
              
              // 1. Majestic Badge Drawing Container
              SizedBox(
                height: 130,
                width: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Holographic Telemetry Rings (for unlocked medals)
                    if (widget.isUnlocked)
                      Positioned.fill(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 2 * math.pi),
                          duration: const Duration(seconds: 15),
                          builder: (context, val, child) {
                            return Transform.rotate(
                              angle: val,
                              child: CustomPaint(
                                painter: _TelemetryRingsPainter(color: themeColor),
                              ),
                            );
                          },
                        ),
                      ),
                      
                    // The main custom-painted medal badge
                    Transform.scale(
                      scale: medalScale,
                      child: Opacity(
                        opacity: widget.isUnlocked ? 1.0 : 0.45,
                        child: CustomPaint(
                          size: const Size(100, 100),
                          painter: MedalPainter(
                            type: widget.type,
                            color: themeColor,
                            isUnlocked: widget.isUnlocked,
                          ),
                        ),
                      ),
                    ),

                    // Locking chains and lock overlay (if locked or animating)
                    if (showLockedChains)
                      Positioned.fill(
                        child: Transform.translate(
                          offset: Offset(shakeX, shakeY),
                          child: CustomPaint(
                            painter: ChainShatterPainter(
                              animProgress: widget.alreadyAnimated ? 0.0 : _animController.value,
                              shatterProgress: _shatterAnimation.value,
                            ),
                          ),
                        ),
                      ),

                    // Particle system overlay (sparks and debris)
                    if (_particlesSpawned && _particles.isNotEmpty)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: ParticlePainter(particles: _particles),
                        ),
                      ),

                    // Neon exposure glow flash overlay (during shatter)
                    if (glowOpacity > 0)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.7 * glowOpacity),
                                  themeColor.withValues(alpha: 0.4 * glowOpacity),
                                  Colors.transparent,
                                ],
                                radius: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // 2. Info text layout
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    Text(
                      widget.title.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: widget.isUnlocked ? Colors.white : Colors.white30,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: widget.isUnlocked ? Colors.white54 : Colors.white12,
                        fontSize: 9.5,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    // Status tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: widget.isUnlocked
                            ? themeColor.withValues(alpha: 0.1)
                            : Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: widget.isUnlocked
                              ? themeColor.withValues(alpha: 0.25)
                              : Colors.white10,
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        widget.isUnlocked
                            ? (AppStrings.of(context).languageCode == 'en' ? 'ACHIEVED' : 'ĐÃ ĐẠT ĐƯỢC')
                            : widget.progressText,
                        style: TextStyle(
                          color: widget.isUnlocked ? themeColor : Colors.white24,
                          fontSize: 8.5,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _DebrisParticle {
  double x, y;
  double vx, vy;
  double size;
  Color color;
  double rotation;
  double rotationSpeed;
  bool isSpark;
  double life;
  double decay;

  _DebrisParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
    required this.isSpark,
    required this.life,
    required this.decay,
  });
}

// Painter to draw telemetry rotating rings behind the medal
class _TelemetryRingsPainter extends CustomPainter {
  final Color color;
  _TelemetryRingsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.88;

    final paint = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw circular ring
    canvas.drawCircle(center, radius, paint);

    // Draw little dashes on the ring
    final dashPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const int dashCount = 8;
    const double dashArc = 0.15; // arc length in radians

    for (int i = 0; i < dashCount; i++) {
      double startAngle = (i * 2 * math.pi / dashCount);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashArc,
        false,
        dashPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TelemetryRingsPainter oldDelegate) => oldDelegate.color != color;
}

// Custom Painter to draw sparks and metal particles
class ParticlePainter extends CustomPainter {
  final List<_DebrisParticle> particles;
  ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (var p in particles) {
      final paint = Paint()
        ..color = p.color.withValues(alpha: p.life)
        ..style = PaintingStyle.fill;

      canvas.save();
      // Translate to particle coordinates relative to center
      canvas.translate(center.dx + p.x, center.dy + p.y);
      canvas.rotate(p.rotation);

      if (p.isSpark) {
        // Draw star spark
        final path = Path()
          ..moveTo(0, -p.size)
          ..lineTo(p.size * 0.3, -p.size * 0.3)
          ..lineTo(p.size, 0)
          ..lineTo(p.size * 0.3, p.size * 0.3)
          ..lineTo(0, p.size)
          ..lineTo(-p.size * 0.3, p.size * 0.3)
          ..lineTo(-p.size, 0)
          ..lineTo(-p.size * 0.3, -p.size * 0.3)
          ..close();
        canvas.drawPath(path, paint);
      } else {
        // Draw metal shard (trapezoid / triangle)
        final path = Path()
          ..moveTo(-p.size / 2, -p.size / 2)
          ..lineTo(p.size / 2, -p.size / 3)
          ..lineTo(p.size * 0.4, p.size / 2)
          ..lineTo(-p.size * 0.3, p.size / 2)
          ..close();
        canvas.drawPath(path, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}

// Custom Painter to draw metallic medals and emblems
class MedalPainter extends CustomPainter {
  final MedalType type;
  final Color color;
  final bool isUnlocked;

  MedalPainter({
    required this.type,
    required this.color,
    required this.isUnlocked,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2 * 0.95;

    // Use gray theme if locked
    final Color badgeColor = isUnlocked ? color : Colors.grey.shade700;

    // Draw the shield backing frame
    _drawMetallicShieldBacking(canvas, center, radius);

    // Draw outer golden/neon accent borders
    _drawBadgeBorders(canvas, center, radius, badgeColor);

    // Draw specific emblem in center
    _drawEmblemSymbol(canvas, center, radius * 0.5, badgeColor);
  }

  void _drawMetallicShieldBacking(Canvas canvas, Offset center, double radius) {
    final backingPaint = Paint()
      ..shader = RadialGradient(
        colors: isUnlocked
            ? [
                const Color(0xFF1E355A),
                const Color(0xFF07142A),
                const Color(0xFF030D1C),
              ]
            : [
                const Color(0xFF222831),
                const Color(0xFF1A1D24),
                const Color(0xFF0F1115),
              ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    // Draw shadow
    canvas.drawPath(_getShieldPath(center, radius + 2), shadowPaint);
    // Draw metal backing
    canvas.drawPath(_getShieldPath(center, radius), backingPaint);
  }

  void _drawBadgeBorders(Canvas canvas, Offset center, double radius, Color badgeColor) {
    final borderPaint = Paint()
      ..color = badgeColor.withValues(alpha: 0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawPath(_getShieldPath(center, radius - 4), borderPaint);

    // Subtle inner glowing grid overlay inside the shield
    final gridPaint = Paint()
      ..color = badgeColor.withValues(alpha: 0.08)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
      
    canvas.drawPath(_getShieldPath(center, radius - 12), gridPaint);
  }

  Path _getShieldPath(Offset center, double radius) {
    final path = Path();
    switch (type) {
      case MedalType.twilightScout:
        // Circular shield
        path.addOval(Rect.fromCircle(center: center, radius: radius));
        break;
      case MedalType.midnightExplorer:
      case MedalType.cryptographer:
        // Hexagonal badge pointing up/down
        for (int i = 0; i < 6; i++) {
          double angle = i * math.pi / 3 - math.pi / 2;
          double x = center.dx + radius * math.cos(angle);
          double y = center.dy + radius * math.sin(angle);
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        break;
      case MedalType.abyssalPioneer:
        // Octagonal military shield
        for (int i = 0; i < 8; i++) {
          double angle = i * math.pi / 4 - math.pi / 8;
          double x = center.dx + radius * math.cos(angle);
          double y = center.dy + radius * math.sin(angle);
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        break;
      case MedalType.marianaConqueror:
      case MedalType.deepseaLegend:
        // Custom pointed naval crest / diamond shield
        path.moveTo(center.dx, center.dy - radius); // Top point
        path.lineTo(center.dx + radius * 0.9, center.dy - radius * 0.3); // Top right side
        path.lineTo(center.dx + radius * 0.7, center.dy + radius * 0.5); // Bottom right bend
        path.lineTo(center.dx, center.dy + radius); // Bottom center tip
        path.lineTo(center.dx - radius * 0.7, center.dy + radius * 0.5); // Bottom left bend
        path.lineTo(center.dx - radius * 0.9, center.dy - radius * 0.3); // Top left side
        path.close();
        break;
    }
    return path;
  }

  void _drawEmblemSymbol(Canvas canvas, Offset center, double size, Color badgeColor) {
    final symbolPaint = Paint()
      ..color = badgeColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = badgeColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    switch (type) {
      case MedalType.twilightScout:
        // Draw an Anchor
        final path = Path()
          ..moveTo(center.dx, center.dy - size)
          ..lineTo(center.dx, center.dy + size * 0.7) // shaft
          ..moveTo(center.dx - size * 0.4, center.dy - size * 0.5)
          ..lineTo(center.dx + size * 0.4, center.dy - size * 0.5); // crossbar
        
        // Bottom hook arc
        canvas.drawPath(path, symbolPaint);
        canvas.drawArc(
          Rect.fromCircle(center: Offset(center.dx, center.dy + size * 0.1), radius: size * 0.6),
          0.1 * math.pi,
          0.8 * math.pi,
          false,
          symbolPaint,
        );
        // Anchor top loop
        canvas.drawCircle(Offset(center.dx, center.dy - size), 6.0, symbolPaint);
        break;

      case MedalType.midnightExplorer:
        // Draw a retro Diving Helmet
        // Dome
        canvas.drawArc(
          Rect.fromCircle(center: Offset(center.dx, center.dy - size * 0.15), radius: size * 0.65),
          math.pi,
          math.pi,
          false,
          symbolPaint,
        );
        // Base plate
        final base = Path()
          ..moveTo(center.dx - size * 0.85, center.dy + size * 0.6)
          ..quadraticBezierTo(center.dx, center.dy + size * 0.8, center.dx + size * 0.85, center.dy + size * 0.6)
          ..lineTo(center.dx + size * 0.65, center.dy + size * 0.25)
          ..quadraticBezierTo(center.dx, center.dy + size * 0.4, center.dx - size * 0.65, center.dy + size * 0.25)
          ..close();
        canvas.drawPath(base, symbolPaint);
        canvas.drawPath(base, fillPaint);
        
        // Window viewport circle
        canvas.drawCircle(Offset(center.dx, center.dy - size * 0.1), size * 0.35, symbolPaint);
        // Crossbars in window
        canvas.drawLine(Offset(center.dx - size * 0.35, center.dy - size * 0.1), Offset(center.dx + size * 0.35, center.dy - size * 0.1), symbolPaint);
        canvas.drawLine(Offset(center.dx, center.dy - size * 0.45), Offset(center.dx, center.dy + size * 0.25), symbolPaint);
        break;

      case MedalType.abyssalPioneer:
        // Draw a Poseidon Trident
        final trident = Path()
          ..moveTo(center.dx, center.dy + size * 0.8)
          ..lineTo(center.dx, center.dy - size * 0.8) // center fork
          ..moveTo(center.dx - size * 0.45, center.dy - size * 0.25)
          ..quadraticBezierTo(center.dx - size * 0.45, center.dy + size * 0.3, center.dx, center.dy + size * 0.3)
          ..quadraticBezierTo(center.dx + size * 0.45, center.dy + size * 0.3, center.dx + size * 0.45, center.dy - size * 0.25)
          ..moveTo(center.dx - size * 0.45, center.dy - size * 0.25)
          ..lineTo(center.dx - size * 0.45, center.dy - size * 0.5) // left point
          ..moveTo(center.dx + size * 0.45, center.dy - size * 0.25)
          ..lineTo(center.dx + size * 0.45, center.dy - size * 0.5); // right point
          
        canvas.drawPath(trident, symbolPaint);
        break;

      case MedalType.marianaConqueror:
        // Draw a grand King Crown
        final crown = Path()
          ..moveTo(center.dx - size * 0.8, center.dy + size * 0.5)
          ..lineTo(center.dx + size * 0.8, center.dy + size * 0.5) // bottom
          ..lineTo(center.dx + size * 0.8, center.dy + size * 0.35)
          ..lineTo(center.dx + size * 0.65, center.dy - size * 0.4) // right point
          ..lineTo(center.dx + size * 0.25, center.dy + size * 0.1)
          ..lineTo(center.dx, center.dy - size * 0.6) // middle peak
          ..lineTo(center.dx - size * 0.25, center.dy + size * 0.1)
          ..lineTo(center.dx - size * 0.65, center.dy - size * 0.4) // left point
          ..lineTo(center.dx - size * 0.8, center.dy + size * 0.35)
          ..close();

        canvas.drawPath(crown, symbolPaint);
        canvas.drawPath(crown, fillPaint);
        
        // Little circular gems on the peaks
        canvas.drawCircle(Offset(center.dx - size * 0.65, center.dy - size * 0.4), 3.5, symbolPaint);
        canvas.drawCircle(Offset(center.dx, center.dy - size * 0.6), 4.5, symbolPaint);
        canvas.drawCircle(Offset(center.dx + size * 0.65, center.dy - size * 0.4), 3.5, symbolPaint);
        break;

      case MedalType.cryptographer:
        // Sonar Wave lines & grid
        canvas.drawCircle(center, size * 0.25, symbolPaint);
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: size * 0.55),
          -math.pi * 0.85,
          math.pi * 1.7,
          false,
          symbolPaint,
        );
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: size * 0.88),
          -math.pi * 0.7,
          math.pi * 1.4,
          false,
          symbolPaint,
        );
        // Radar sweeps
        canvas.drawLine(center, Offset(center.dx + size * 0.85 * math.cos(-math.pi/5), center.dy + size * 0.85 * math.sin(-math.pi/5)), symbolPaint);
        break;

      case MedalType.deepseaLegend:
        // Sea Monster dragon head / wings symbol
        final dragon = Path()
          ..moveTo(center.dx, center.dy - size * 0.8) // head
          ..lineTo(center.dx + size * 0.25, center.dy - size * 0.2) // right cheek
          ..lineTo(center.dx + size * 0.85, center.dy - size * 0.4) // right wing tip
          ..lineTo(center.dx + size * 0.45, center.dy + size * 0.15) // wing fold
          ..lineTo(center.dx + size * 0.15, center.dy + size * 0.6) // tail bottom right
          ..lineTo(center.dx, center.dy + size * 0.85) // bottom spike
          ..lineTo(center.dx - size * 0.15, center.dy + size * 0.6) // tail bottom left
          ..lineTo(center.dx - size * 0.45, center.dy + size * 0.15) // left wing fold
          ..lineTo(center.dx - size * 0.85, center.dy - size * 0.4) // left wing tip
          ..lineTo(center.dx - size * 0.25, center.dy - size * 0.2) // left cheek
          ..close();

        canvas.drawPath(dragon, symbolPaint);
        canvas.drawPath(dragon, fillPaint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant MedalPainter oldDelegate) {
    return oldDelegate.type != type || oldDelegate.color != color || oldDelegate.isUnlocked != isUnlocked;
  }
}

// Custom Painter to draw shaking/shattering chains & security lock
class ChainShatterPainter extends CustomPainter {
  final double animProgress;
  final double shatterProgress; // 0.0 to 1.0 curve from 0.35 to 1.0 of animation

  ChainShatterPainter({required this.animProgress, required this.shatterProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Check if lock is broken (shatter phase started)
    final bool isBroken = animProgress >= 0.35;
    
    // Calculate split coordinate translations
    double leftXTranslation = 0.0;
    double leftYTranslation = 0.0;
    double leftRotation = 0.0;

    double rightXTranslation = 0.0;
    double rightYTranslation = 0.0;
    double rightRotation = 0.0;

    double lockYTranslation = 0.0;
    double lockAlpha = 1.0;

    if (isBroken) {
      // Chains fly outwards towards top-left / top-right / bottom-left / bottom-right
      final double progress = shatterProgress;
      
      leftXTranslation = -progress * 90.0;
      leftYTranslation = -progress * 15.0;
      leftRotation = -progress * 1.5;

      rightXTranslation = progress * 90.0;
      rightYTranslation = -progress * 15.0;
      rightRotation = progress * 1.5;

      // Lock falls downwards and fades out
      lockYTranslation = progress * 110.0;
      lockAlpha = (1.0 - progress * 1.2).clamp(0.0, 1.0);
    }

    final chainPaint = Paint()
      ..color = Colors.grey.shade500.withValues(alpha: lockAlpha)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    final lockBodyPaint = Paint()
      ..color = (isBroken ? Colors.redAccent.shade700 : const Color(0xFF8B0000)).withValues(alpha: lockAlpha)
      ..style = PaintingStyle.fill;

    final lockBordersPaint = Paint()
      ..color = (isBroken ? Colors.white : Colors.redAccent).withValues(alpha: lockAlpha)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // 1. Draw Chains
    // Left chain set
    canvas.save();
    canvas.translate(leftXTranslation, leftYTranslation);
    canvas.rotate(leftRotation);
    _drawChainSegment(canvas, Offset(20, 20), center, chainPaint);
    _drawChainSegment(canvas, Offset(20, size.height - 20), center, chainPaint);
    canvas.restore();

    // Right chain set
    canvas.save();
    canvas.translate(rightXTranslation, rightYTranslation);
    canvas.rotate(rightRotation);
    _drawChainSegment(canvas, Offset(size.width - 20, 20), center, chainPaint);
    _drawChainSegment(canvas, Offset(size.width - 20, size.height - 20), center, chainPaint);
    canvas.restore();

    // 2. Draw Center Lock
    canvas.save();
    canvas.translate(0, lockYTranslation);
    
    if (isBroken) {
      // Draw split lock falling apart
      // Left Lock Half
      canvas.save();
      canvas.translate(-shatterProgress * 25.0, 0);
      canvas.rotate(-shatterProgress * 0.4);
      _drawHalfLock(canvas, center, true, lockBodyPaint, lockBordersPaint);
      canvas.restore();

      // Right Lock Half
      canvas.save();
      canvas.translate(shatterProgress * 25.0, 0);
      canvas.rotate(shatterProgress * 0.4);
      _drawHalfLock(canvas, center, false, lockBodyPaint, lockBordersPaint);
      canvas.restore();
    } else {
      // Draw intact locked icon
      _drawIntactLock(canvas, center, lockBodyPaint, lockBordersPaint);
    }
    
    canvas.restore();
  }

  // Draw chain links from anchor point to center
  void _drawChainSegment(Canvas canvas, Offset pStart, Offset pEnd, Paint paint) {
    // We draw small overlapping links along the path
    final double dx = pEnd.dx - pStart.dx;
    final double dy = pEnd.dy - pStart.dy;
    final double distance = math.sqrt(dx * dx + dy * dy);
    final int linkCount = (distance / 16.0).floor() - 1;

    for (int i = 0; i <= linkCount; i++) {
      double t = (i / (linkCount + 1)) * 0.85; // end slightly before center to leave space for lock
      double lx = pStart.dx + dx * t;
      double ly = pStart.dy + dy * t;
      
      canvas.save();
      canvas.translate(lx, ly);
      canvas.rotate(math.atan2(dy, dx));
      
      // Draw an oval chain link
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: 14.0, height: 7.0),
          const Radius.circular(3.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  void _drawIntactLock(Canvas canvas, Offset center, Paint bodyPaint, Paint borderPaint) {
    const double lockW = 24.0;
    const double lockH = 20.0;
    
    // Draw Lock Shackle (U-hook)
    final shacklePaint = Paint()
      ..color = borderPaint.color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(center.dx, center.dy - lockH / 2), width: 14.0, height: 16.0),
      math.pi,
      math.pi,
      false,
      shacklePaint,
    );

    // Draw Lock Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: lockW, height: lockH),
        const Radius.circular(4.0),
      ),
      bodyPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: lockW, height: lockH),
        const Radius.circular(4.0),
      ),
      borderPaint,
    );

    // Draw small keyhole circle
    final keyholePaint = Paint()..color = borderPaint.color;
    canvas.drawCircle(Offset(center.dx, center.dy - 1.0), 2.5, keyholePaint);
    final keyholeBody = Paint()
      ..color = borderPaint.color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(center.dx, center.dy + 1.0), Offset(center.dx, center.dy + 5.0), keyholeBody);
  }

  void _drawHalfLock(Canvas canvas, Offset center, bool isLeftHalf, Paint bodyPaint, Paint borderPaint) {
    const double lockW = 24.0;
    const double lockH = 20.0;

    canvas.save();
    // Clip canvas to only paint the left or right half
    canvas.clipRect(
      Rect.fromLTRB(
        isLeftHalf ? center.dx - 40 : center.dx,
        center.dy - 30,
        isLeftHalf ? center.dx : center.dx + 40,
        center.dy + 30,
      ),
    );

    // Draw Shackle
    final shacklePaint = Paint()
      ..color = borderPaint.color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(center.dx, center.dy - lockH / 2), width: 14.0, height: 16.0),
      math.pi,
      math.pi,
      false,
      shacklePaint,
    );

    // Draw Body half
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: lockW, height: lockH),
        const Radius.circular(4.0),
      ),
      bodyPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: lockW, height: lockH),
        const Radius.circular(4.0),
      ),
      borderPaint,
    );

    // Draw keyhole half
    canvas.drawCircle(Offset(center.dx, center.dy - 1.0), 2.5, Paint()..color = borderPaint.color);
    canvas.drawLine(
      Offset(center.dx, center.dy + 1.0),
      Offset(center.dx, center.dy + 5.0),
      Paint()
        ..color = borderPaint.color
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ChainShatterPainter oldDelegate) {
    return oldDelegate.animProgress != animProgress || oldDelegate.shatterProgress != shatterProgress;
  }
}
