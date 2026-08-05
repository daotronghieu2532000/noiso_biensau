import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/locale_service.dart';
import '../services/sound_service.dart';
import '../services/data_service.dart';
import '../l10n/app_strings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.listen(context);
    final locale = Provider.of<LocaleService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF010812),
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
          // 2. Background deep-sea gradient overlay
          Positioned.fill(
            child: Container(
              color: const Color(0xFF010812).withValues(alpha: 0.75),
            ),
          ),
          // Grid overlay
          Positioned.fill(
            child: CustomPaint(painter: _SettingsGridPainter()),
          ),
          SafeArea(
            child: Column(
              children: [
                // ── AppBar row ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF00F0FF)),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        strings.settingsTitle,
                        style: const TextStyle(
                          color: Color(0xFF00F0FF),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const Spacer(),
                      // Version badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00F0FF).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF00F0FF).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          'v1.0.0',
                          style: TextStyle(
                            color: const Color(0xFF00F0FF).withValues(alpha: 0.7),
                            fontSize: 9,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
                const Divider(
                  color: Color(0xFF00F0FF),
                  thickness: 0.3,
                  height: 1,
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        (() {
                          final isVi = strings.languageCode == 'vi';
                          final dataService = Provider.of<DataService>(context);
                          final soundService = Provider.of<SoundService>(context);
                          final isPremium = dataService.hasAnyPremium;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Card 1: Cockpit Control ─────────────────────
                              _buildSectionLabel(isVi ? 'BẢNG ĐIỀU KHIỂN COCKPIT' : 'COCKPIT CONTROL PANEL'),
                              const SizedBox(height: 10),
                              _buildGlassCard(
                                accentColor: const Color(0xFF00F0FF),
                                child: Column(
                                  children: [
                                    // Ambient Audio Switch
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              soundService.isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                                              color: soundService.isMuted ? const Color(0xFFFF3366) : const Color(0xFF00F0FF),
                                              size: 18,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              isVi ? 'ÂM THANH NỀN' : 'AMBIENT AUDIO',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Switch.adaptive(
                                          value: !soundService.isMuted,
                                          activeThumbColor: const Color(0xFF00F0FF),
                                          activeTrackColor: const Color(0xFF00F0FF).withValues(alpha: 0.3),
                                          inactiveThumbColor: Colors.white70,
                                          inactiveTrackColor: Colors.white10,
                                          onChanged: (value) {
                                            soundService.toggleMute();
                                          },
                                        ),
                                      ],
                                    ),
                                    Divider(color: const Color(0xFF00F0FF).withValues(alpha: 0.1), height: 16, thickness: 0.8),
                                    
                                    // Language Selector
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.language_rounded, color: Color(0xFF00F0FF), size: 18),
                                            const SizedBox(width: 10),
                                            Text(
                                              isVi ? 'NGÔN NGỮ HỆ THỐNG' : 'SYSTEM LANGUAGE',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _buildCompactLangButton('VI', locale.languageCode == 'vi', () => locale.setLanguage('vi')),
                                            const SizedBox(width: 6),
                                            _buildCompactLangButton('EN', locale.languageCode == 'en', () => locale.setLanguage('en')),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Divider(color: const Color(0xFF00F0FF).withValues(alpha: 0.1), height: 16, thickness: 0.8),

                                    // System memory reset
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.delete_forever_rounded, color: Color(0xFFFF3366), size: 18),
                                            const SizedBox(width: 10),
                                            Text(
                                              isVi ? 'DỮ LIỆU TÀU LẶN' : 'SUB MEMORY DATA',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        GestureDetector(
                                          onTap: () => _showResetConfirmationDialog(context, isVi, dataService),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFF3366).withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: const Color(0xFFFF3366).withValues(alpha: 0.6),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              isVi ? 'ĐẶT LẠI' : 'RESET',
                                              style: const TextStyle(
                                                color: Color(0xFFFF3366),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // ── Card 2: Ship Registry ────────────────────────
                              _buildSectionLabel(isVi ? 'ĐĂNG KÝ THÔNG TIN TÀU' : 'SUB REGISTRY FILES'),
                              const SizedBox(height: 10),
                              _buildGlassCard(
                                accentColor: isPremium ? const Color(0xFFFFCC00) : const Color(0xFF00F0FF),
                                child: Column(
                                  children: [
                                    // VIP Status Row
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              isPremium ? Icons.workspace_premium_rounded : Icons.lock_outline_rounded,
                                              color: isPremium ? const Color(0xFFFFCC00) : const Color(0xFF00F0FF),
                                              size: 18,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              isVi ? 'THÀNH VIÊN VIP' : 'VIP SUBSCRIPTION',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (isPremium)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFCC00).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: const Color(0xFFFFCC00), width: 1),
                                            ),
                                            child: Text(
                                              isVi ? 'ĐÃ KÍCH HOẠT' : 'ACTIVE',
                                              style: const TextStyle(
                                                color: Color(0xFFFFCC00),
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                          )
                                        else
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              GestureDetector(
                                                onTap: () => dataService.buyPremium(),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF00F0FF),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    isVi ? 'MỞ KHÓA' : 'UNLOCK',
                                                    style: const TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w900,
                                                      fontFamily: 'monospace',
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              GestureDetector(
                                                onTap: () => dataService.restorePurchases(),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.transparent,
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.6), width: 1),
                                                  ),
                                                  child: Text(
                                                    isVi ? 'KHÔI PHỤC' : 'RESTORE',
                                                    style: const TextStyle(
                                                      color: Color(0xFF00F0FF),
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      fontFamily: 'monospace',
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                    Divider(color: const Color(0xFF00F0FF).withValues(alpha: 0.1), height: 16, thickness: 0.8),

                                    // Contact HQ Row
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.alternate_email_rounded, color: Color(0xFF00F0FF), size: 18),
                                            const SizedBox(width: 10),
                                            Text(
                                              isVi ? 'LIÊN HỆ HQ' : 'CONTACT HQ',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Text(
                                          'trongh138@gmail.com',
                                          style: TextStyle(
                                            color: Color(0xFF00F0FF),
                                            fontSize: 11,
                                            fontFamily: 'monospace',
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // ── Footer ────────────────────────────────────────
                              Center(
                                child: Column(
                                  children: [
                                    const Text(
                                      '🌊',
                                      style: TextStyle(fontSize: 24),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Deep Sea Fear — v1.0.0',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.25),
                                        fontSize: 10,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isVi ? 'Được làm với ❤️ cho các nhà thám hiểm đại dương' : 'Made with ❤️ for ocean explorers',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.18),
                                        fontSize: 9,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        })(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  void _showResetConfirmationDialog(BuildContext context, bool isVi, DataService dataService) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF071224),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFFF3366), width: 1),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFFF3366),
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  isVi ? 'XÁC NHẬN XÓA DỮ LIỆU' : 'CONFIRM DATA WIPE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isVi
                      ? 'Bạn có chắc chắn muốn đặt lại toàn bộ hệ thống? Hành động này không thể hoàn tác.'
                      : 'Are you sure you want to perform a full system wipe? This action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: Colors.white30, width: 1.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            isVi ? 'HỦY' : 'CANCEL',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF3366),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () async {
                            Navigator.pop(context); // Close dialog
                            
                            // WIPE data
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.clear();
                            await dataService.loadData(); // reload data service
                            
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFF071224),
                                  content: Text(
                                    isVi ? 'Đã xóa toàn bộ bộ nhớ hệ thống.' : 'System memory wiped successfully.',
                                    style: const TextStyle(color: Color(0xFF00F0FF), fontFamily: 'monospace', fontSize: 12),
                                  ),
                                ),
                              );
                            }
                          },
                          child: Text(
                            isVi ? 'XÓA HẾT' : 'WIPE ALL',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionLabel(String label) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
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
          label.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF00F0FF),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactLangButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00F0FF).withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00F0FF)
                : const Color(0xFF00F0FF).withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? const Color(0xFF00F0FF) : Colors.white60,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child, Color? accentColor}) {
    final color = accentColor ?? const Color(0xFF00F0FF);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF071224).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Sci-fi grid background overlay
            Positioned.fill(
              child: Opacity(
                opacity: 0.08,
                child: CustomPaint(
                  painter: _MiniGridPainter(),
                ),
              ),
            ),
            
            // Neon left accent bar
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: color,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.6),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),

            // Top-right corner bracket
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: color, width: 1.5),
                    right: BorderSide(color: color, width: 1.5),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Background Grid Painter ──────────────────────────────────────────────────

class _SettingsGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.03)
      ..strokeWidth = 0.5;
    const spacing = 36.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MiniGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.1)
      ..strokeWidth = 0.5;
    const spacing = 12.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Global helper to push the SettingsScreen from any context.
void openSettings(BuildContext context) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => const SettingsScreen(),
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
    ),
  );
}

/// Reusable settings icon button for use in any screen header.
Widget buildSettingsButton(BuildContext context) {
  return IconButton(
    icon: const Icon(Icons.settings_outlined, color: Color(0xFF00F0FF), size: 22),
    tooltip: 'Settings',
    onPressed: () => openSettings(context),
  );
}

Widget buildVolumeButton(BuildContext context) {
  return Consumer<SoundService>(
    builder: (context, soundService, child) {
      return IconButton(
        icon: Icon(
          soundService.isMuted ? Icons.volume_off_outlined : Icons.volume_up_outlined,
          color: soundService.isMuted ? const Color(0xFFFF3366) : const Color(0xFF00F0FF),
          size: 22,
        ),
        tooltip: soundService.isMuted ? 'Unmute' : 'Mute',
        onPressed: () => soundService.toggleMute(),
      );
    },
  );
}


