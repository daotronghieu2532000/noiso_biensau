import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../services/ad_service.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  String _selectedBanner = 'assets/images/creatures/banner1.jpg'; // default
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  double _progressValue = 0.0;
  String _loadingText = 'CONNECTING TO DEEP-SEA TELEMETRY HUD...';
  Timer? _progressTimer;
  Timer? _textTimer;

  @override
  void initState() {
    super.initState();
    _initPreferencesAndBanner();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();
    _initTrackingAndStartLoading();
  }

  Future<void> _initTrackingAndStartLoading() async {
    await Future.delayed(const Duration(milliseconds: 1000));

    if (mounted) {
      try {
        final adService = Provider.of<AdService>(context, listen: false);
        await adService.initAdService();
      } catch (e) {
        debugPrint('Error initializing AdService: $e');
      }
    }

    _startSimulatedLoading();
  }

  Future<void> _initPreferencesAndBanner() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final launchCount = prefs.getInt('launch_count') ?? 0;
      
      // Alternate banners based on launch count
      setState(() {
        if (launchCount % 2 == 0) {
          _selectedBanner = 'assets/images/creatures/banner1.jpg';
        } else {
          _selectedBanner = 'assets/images/creatures/banner2.jpeg';
        }
      });

      // Increment launch count for next launch
      await prefs.setInt('launch_count', launchCount + 1);
    } catch (e) {
      debugPrint('Error loading preferences: $e');
    }
  }

  void _startSimulatedLoading() {
    const totalDuration = Duration(milliseconds: 3000);
    const stepDuration = Duration(milliseconds: 30);
    int elapsed = 0;

    _progressTimer = Timer.periodic(stepDuration, (timer) {
      elapsed += stepDuration.inMilliseconds;
      setState(() {
        _progressValue = (elapsed / totalDuration.inMilliseconds).clamp(0.0, 1.0);
      });

      if (elapsed >= totalDuration.inMilliseconds) {
        timer.cancel();
        _navigateToHomeScreen();
      }
    });

    _textTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      setState(() {
        if (timer.tick == 1) {
          _loadingText = 'LOADING MARIANA BASIN TELEMETRY...';
        } else if (timer.tick == 2) {
          _loadingText = 'ESTABLISHING SECURE SUBMERSIBLE LINK...';
        }
      });
    });
  }

  void _navigateToHomeScreen() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressTimer?.cancel();
    _textTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020813),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image with Fade-In and Dark Blue Overlay
          FadeTransition(
            opacity: _fadeAnimation,
            child: Image.asset(
              _selectedBanner,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback in case of asset errors
                return Container(
                  color: const Color(0xFF020813),
                  child: const Center(
                    child: Icon(
                      Icons.waves,
                      color: Color(0xFF00F0FF),
                      size: 64,
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Dark HUD gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF020813).withValues(alpha: 0.3),
                  const Color(0xFF020813).withValues(alpha: 0.7),
                  const Color(0xFF020813),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // HUD Border overlay
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Title
                  Column(
                    children: [
                      const SizedBox(height: 40),
                      Text(
                        'DEEPSEA',
                        style: TextStyle(
                          color: const Color(0xFF00F0FF),
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 8,
                          shadows: [
                            Shadow(
                              color: const Color(0xFF00F0FF).withValues(alpha: 0.5),
                              blurRadius: 15,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3366).withValues(alpha: 0.2),
                          border: Border.all(
                            color: const Color(0xFFFF3366).withValues(alpha: 0.5),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'THÁM HIỂM',
                          style: TextStyle(
                            color: Color(0xFFFF3366),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Bottom loading HUD
                  Column(
                    children: [
                      // Loading percentage and text
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _loadingText,
                              style: TextStyle(
                                color: const Color(0xFF00F0FF).withValues(alpha: 0.7),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${(_progressValue * 100).toInt()}%',
                            style: const TextStyle(
                              color: Color(0xFF00F0FF),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      
                      // Progress Bar
                      Container(
                        height: 6,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1F3D),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _progressValue,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF00F0FF),
                                  Color(0xFFFF3366),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(3),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00F0FF).withValues(alpha: 0.5),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // HUD Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'SYS.STATUS: ACTIVE',
                            style: TextStyle(
                              color: const Color(0xFF00F0FF).withValues(alpha: 0.4),
                              fontSize: 8,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            'REF.SYS: MARIANA_GRID_v4.2',
                            style: TextStyle(
                              color: const Color(0xFF00F0FF).withValues(alpha: 0.4),
                              fontSize: 8,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
