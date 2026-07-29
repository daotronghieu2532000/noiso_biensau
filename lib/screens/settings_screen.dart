import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/locale_service.dart';
import '../services/sound_service.dart';
import '../l10n/app_strings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.listen(context);
    final locale = Provider.of<LocaleService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF010812),
      body: Stack(
        children: [
          // Background deep-sea gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF010812),
                    Color(0xFF031428),
                    Color(0xFF010812),
                  ],
                ),
              ),
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
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // ── Language Switcher ─────────────────────────────
                        _buildSectionLabel(strings.settingsLanguageTitle),
                        const SizedBox(height: 12),
                        _LanguageSwitcher(locale: locale),
                        const SizedBox(height: 28),

                        // ── Thank You card ────────────────────────────────
                        _buildSectionLabel(strings.settingsThankyouTitle),
                        const SizedBox(height: 12),
                        _buildGlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00F0FF).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text('🌊', style: TextStyle(fontSize: 22)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      strings.appTitle.toUpperCase(),
                                      style: const TextStyle(
                                        color: Color(0xFF00F0FF),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                strings.settingsThankyouBody,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 13,
                                  height: 1.65,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),



                        // ── Contact card ───────────────────────────────────
                        _buildSectionLabel(strings.settingsContactTitle),
                        const SizedBox(height: 12),
                        _buildGlassCard(
                          accentColor: const Color(0xFFFF3366),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strings.settingsContactBody,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 13,
                                  height: 1.55,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF3366).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFFF3366).withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.email_outlined,
                                      color: Color(0xFFFF3366),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'trongh138@gmail.com',
                                      style: TextStyle(
                                        color: Color(0xFFFF3366),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ── Footer ────────────────────────────────────────
                        Center(
                          child: Column(
                            children: [
                              const Text(
                                '🌊',
                                style: TextStyle(fontSize: 28),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Deep Sea Fear — v1.0.0',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Made with ❤️ for ocean explorers',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  fontSize: 10,
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
            ),
          ),
        ],
      ),
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

  Widget _buildGlassCard({required Widget child, Color? accentColor}) {
    final color = accentColor ?? const Color(0xFF00F0FF);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
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
      child: Stack(
        children: [
          // Neon left accent bar
          Positioned(
            left: -18,
            top: 12,
            bottom: 12,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(2),
                  bottomRight: Radius.circular(2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

// ── Language Switcher Widget ─────────────────────────────────────────────────

class _LanguageSwitcher extends StatelessWidget {
  final LocaleService locale;
  const _LanguageSwitcher({required this.locale});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _LangButton(
            flag: '🇻🇳',
            label: 'Tiếng Việt',
            code: 'vi',
            isSelected: locale.languageCode == 'vi',
            onTap: () => locale.setLanguage('vi'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _LangButton(
            flag: '🇬🇧',
            label: 'English',
            code: 'en',
            isSelected: locale.languageCode == 'en',
            onTap: () => locale.setLanguage('en'),
          ),
        ),
      ],
    );
  }
}

class _LangButton extends StatelessWidget {
  final String flag;
  final String label;
  final String code;
  final bool isSelected;
  final VoidCallback onTap;

  const _LangButton({
    required this.flag,
    required this.label,
    required this.code,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00F0FF).withValues(alpha: 0.12)
              : const Color(0xFF0D1F3D).withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00F0FF)
                : const Color(0xFF00F0FF).withValues(alpha: 0.1),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF00F0FF).withValues(alpha: 0.1),
                    blurRadius: 8,
                    spreadRadius: 0.5,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF00F0FF)
                    : Colors.white70,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                letterSpacing: 0.5,
                fontFamily: 'monospace',
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check_circle_outline,
                color: Color(0xFF00F0FF),
                size: 18,
              )
            else
              Icon(
                Icons.circle_outlined,
                color: const Color(0xFF00F0FF).withValues(alpha: 0.3),
                size: 18,
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


