import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
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
  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.listen(context);
    final locale = Provider.of<LocaleService>(context);
    final dataService = Provider.of<DataService>(context);
    final soundService = Provider.of<SoundService>(context);
    
    final isVi = strings.languageCode == 'vi';
    final isPremium = dataService.hasAnyPremium;

    return Scaffold(
      backgroundColor: const Color(0xFF010610),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          isVi ? 'CÀI ĐẶT' : 'SETTINGS',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF00F0FF), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── SECTION 1: COCKPIT CONTROLS ─────────────────────
              _buildSectionHeader(isVi ? 'BẢNG ĐIỀU KHIỂN COCKPIT' : 'COCKPIT CONTROL PANEL'),
              const SizedBox(height: 8),
              _buildAppleGroup([
                // Ambient sound switch
                _buildSettingRow(
                  icon: soundService.isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  iconBgColor: const Color(0xFF007AFF), // Apple Blue
                  title: isVi ? 'Âm thanh nền' : 'Ambient Audio',
                  trailing: Switch.adaptive(
                    value: !soundService.isMuted,
                    activeThumbColor: Colors.white,
                    activeTrackColor: const Color(0xFF30D158), // Apple Green Switch
                    onChanged: (value) => soundService.toggleMute(),
                  ),
                ),
                
                // Language selection (Việt Nam)
                _buildSettingRow(
                  icon: Icons.language_rounded,
                  iconBgColor: const Color(0xFF34C759), // Apple Green
                  title: '🇻🇳  Tiếng Việt',
                  trailing: locale.languageCode == 'vi'
                      ? const Icon(Icons.check, color: Color(0xFF00F0FF), size: 20)
                      : const SizedBox.shrink(),
                  onTap: () => locale.setLanguage('vi'),
                ),
                
                // Language selection (English)
                _buildSettingRow(
                  icon: Icons.language_rounded,
                  iconBgColor: const Color(0xFF34C759), // Apple Green
                  title: '🇺🇸  English',
                  trailing: locale.languageCode == 'en'
                      ? const Icon(Icons.check, color: Color(0xFF00F0FF), size: 20)
                      : const SizedBox.shrink(),
                  onTap: () => locale.setLanguage('en'),
                ),
              ]),

              const SizedBox(height: 24),

              // ── SECTION 2: SYSTEM DATA ──────────────────────────
              _buildSectionHeader(isVi ? 'DỮ LIỆU HỆ THỐNG' : 'SYSTEM DATA FILES'),
              const SizedBox(height: 8),
              _buildAppleGroup([
                // Submarine Memory Data Reset
                _buildSettingRow(
                  icon: Icons.delete_rounded,
                  iconBgColor: const Color(0xFFFF3B30), // Apple Red
                  title: isVi ? 'Đặt lại dữ liệu tàu lặn' : 'Wipe Sub Memory Data',
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24),
                  onTap: () => _showResetConfirmationDialog(context, isVi, dataService),
                ),
              ]),

              const SizedBox(height: 24),

              // ── SECTION 3: SHIP REGISTRY ────────────────────────
              _buildSectionHeader(isVi ? 'ĐĂNG KÝ THÔNG TIN TÀU' : 'SUB REGISTRY FILES'),
              const SizedBox(height: 8),
              _buildAppleGroup([
                // VIP Membership status / unlock
                _buildSettingRow(
                  icon: isPremium ? Icons.workspace_premium_rounded : Icons.lock_outline_rounded,
                  iconBgColor: const Color(0xFFFF9500), // Apple Orange/Gold
                  title: isVi ? 'Thành viên VIP' : 'VIP Subscription',
                  subtitle: isPremium 
                      ? (isVi ? 'Đã kích hoạt' : 'Active') 
                      : (isVi ? 'Chưa mở khóa' : 'Not Unlocked'),
                  trailing: isPremium
                      ? const Icon(Icons.check_circle_rounded, color: Color(0xFFFF9500), size: 22)
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => dataService.buyPremium(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00F0FF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isVi ? 'MỞ KHÓA' : 'UNLOCK',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => dataService.restorePurchases(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.4), width: 1.0),
                                ),
                                child: Text(
                                  isVi ? 'KHÔI PHỤC' : 'RESTORE',
                                  style: const TextStyle(
                                    color: Color(0xFF00F0FF),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                
                // Contact HQ
                _buildSettingRow(
                  icon: Icons.alternate_email_rounded,
                  iconBgColor: const Color(0xFF8E8E93), // Apple Grey
                  title: isVi ? 'Liên hệ HQ' : 'Contact HQ',
                  trailing: const Text(
                    'trongh138@gmail.com',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ]),

              const SizedBox(height: 36),

              // ── FOOTER ──────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    const Text(
                      '🌊',
                      style: TextStyle(fontSize: 22),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Deep See — v1.0.0',
                      style: TextStyle(
                        color: Colors.white24,
                        fontSize: 10,
                        fontFamily: 'monospace',
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isVi ? 'Được làm với ❤️ cho các nhà thám hiểm đại dương' : 'Made with ❤️ for ocean explorers',
                      style: const TextStyle(
                        color: Colors.white12,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Colors.white30,
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildAppleGroup(List<Widget> children) {
    final List<Widget> itemsWithDividers = [];
    for (int i = 0; i < children.length; i++) {
      itemsWithDividers.add(children[i]);
      if (i < children.length - 1) {
        itemsWithDividers.add(
          Container(
            height: 0.5,
            color: Colors.white.withValues(alpha: 0.08),
            margin: const EdgeInsets.only(left: 48.0), // Don't cut through the icon
          ),
        );
      }
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04), // Beautiful iOS Dark Mode glass cell color
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        children: itemsWithDividers,
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required Color iconBgColor,
    required String title,
    String? subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    final rowContent = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      child: Row(
        children: [
          // iOS-style colorful rounded icon container
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 17,
            ),
          ),
          const SizedBox(width: 12),
          
          // Row Titles (Title & Subtitle)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white30,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Trailing widget
          trailing,
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10.0),
          splashColor: Colors.white10,
          highlightColor: Colors.white.withValues(alpha: 0.02),
          child: rowContent,
        ),
      );
    }

    return rowContent;
  }

  void _showResetConfirmationDialog(BuildContext context, bool isVi, DataService dataService) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFFF3B30),
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  isVi ? 'XÁC NHẬN XÓA DỮ LIỆU' : 'CONFIRM DATA WIPE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isVi
                      ? 'Bạn có chắc chắn muốn đặt lại toàn bộ hệ thống? Hành động này không thể hoàn tác.'
                      : 'Are you sure you want to perform a full system wipe? This action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white60, fontSize: 12.0, height: 1.45),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1.0),
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
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF3B30),
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
                            try {
                              await DefaultCacheManager().emptyCache();
                            } catch (_) {}
                            await dataService.loadData(); // reload data service
                            
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFF0F172A),
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
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
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
