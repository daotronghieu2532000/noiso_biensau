import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:url_launcher/url_launcher.dart';
import '../services/locale_service.dart';
import '../services/sound_service.dart';
import '../services/data_service.dart';
import '../services/feedback_service.dart';
import '../l10n/app_strings.dart';
import 'video_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _vipIdentifier;

  @override
  void initState() {
    super.initState();
    _loadVipIdentifier();
  }

  Future<void> _loadVipIdentifier() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('vip_user_name') ??
        prefs.getString('vip_user_email') ??
        prefs.getString('user_email') ??
        prefs.getString('user_name');
    if (mounted) {
      setState(() {
        _vipIdentifier = saved;
      });
    }
  }

  Future<void> _saveVipIdentifier(String val) async {
    final trimmed = val.trim();
    if (trimmed.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('vip_user_name', trimmed);
    if (trimmed.contains('@')) {
      await prefs.setString('vip_user_email', trimmed);
    }
    if (mounted) {
      setState(() {
        _vipIdentifier = trimmed;
      });
    }
  }

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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isVi ? 'CÀI ĐẶT' : 'SETTINGS',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            if (isPremium) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFDF00), Color(0xFFFF9500)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.workspace_premium_rounded, color: Colors.black, size: 13),
                    SizedBox(width: 3),
                    Text(
                      'VIP',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF00F0FF), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── VIP HONOR BANNER (Full width dính trái phải & phía trên màn hình) ─────
              if (isPremium) ...[
                _buildVipHonorBanner(context, isVi, dataService),
              ],

              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: isPremium ? 16.0 : 12.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── SECTION 1: COCKPIT CONTROLS ─────────────────────
                    _buildSectionHeader(isVi ? 'BẢNG ĐIỀU KHIỂN COCKPIT' : 'COCKPIT CONTROL PANEL'),
              const SizedBox(height: 8),
              _buildAppleGroup([
                // Đóng góp ý kiến & Đánh giá (Netflix style)
                _buildSettingRow(
                  icon: Icons.rate_review_rounded,
                  iconBgColor: const Color(0xFFE50914), // Netflix Red
                  title: isVi ? 'Đóng góp ý kiến & Đánh giá' : 'Feedback & Perspectives',
                  subtitle: isVi 
                      ? 'Chia sẻ trải nghiệm, cảm nhận của bạn' 
                      : 'Share your thoughts & experiences',
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Color(0xFF808080),
                    size: 13,
                  ),
                  onTap: () => _showFeedbackBottomSheet(context, isVi),
                ),

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
                
                // Language selection (Việt Nam & English on 1 row)
                _buildSettingRow(
                  icon: Icons.language_rounded,
                  iconBgColor: const Color(0xFF34C759), // Apple Green
                  title: isVi ? 'Ngôn ngữ' : 'Language',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLanguageChip(
                        label: '🇻🇳 Tiếng Việt',
                        isSelected: locale.languageCode == 'vi',
                        onTap: () => locale.setLanguage('vi'),
                      ),
                      const SizedBox(width: 6),
                      _buildLanguageChip(
                        label: '🇺🇸 English',
                        isSelected: locale.languageCode == 'en',
                        onTap: () => locale.setLanguage('en'),
                      ),
                    ],
                  ),
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
                  onTap: isPremium ? null : () => showVipUnlockBottomSheet(context),
                  trailing: isPremium
                      ? const Icon(Icons.check_circle_rounded, color: Color(0xFFFF9500), size: 22)
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => showVipUnlockBottomSheet(context),
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
                              onTap: () async {
                                final error = await dataService.restorePurchases();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        error ??
                                            (isVi
                                                ? 'Đã kiểm tra khôi phục giao dịch.'
                                                : 'Purchase restore check completed.'),
                                      ),
                                      backgroundColor: error != null
                                          ? Colors.orangeAccent
                                          : const Color(0xFF00F0FF),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
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
                
                // Contact HQ (Hỗ trợ bấm mở ứng dụng gửi Email)
                _buildSettingRow(
                  icon: Icons.alternate_email_rounded,
                  iconBgColor: const Color(0xFF8E8E93), // Apple Grey
                  title: isVi ? 'Liên hệ HQ' : 'Contact HQ',
                  onTap: () async {
                    final emailUri = Uri.parse('mailto:trongh138@gmail.com');
                    try {
                      if (await canLaunchUrl(emailUri)) {
                        await launchUrl(emailUri);
                      }
                    } catch (_) {}
                  },
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

  Widget _buildLanguageChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00F0FF).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? const Color(0xFF00F0FF) : Colors.white12,
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF00F0FF) : Colors.white60,
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
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

  Widget _buildVipHonorBanner(BuildContext context, bool isVi, DataService dataService) {
    final passName = dataService.isPremiumUnlocked
        ? (isVi ? 'GÓI TRỌN ĐỜI' : 'LIFETIME PASS')
        : (isVi ? 'GÓI HÀNG THÁNG' : 'MONTHLY PASS');
    final displayName = (_vipIdentifier != null && _vipIdentifier!.isNotEmpty)
        ? _vipIdentifier!
        : (isVi ? 'Thuyền Trưởng VIP' : 'Elite Fleet Commander');

    return Container(
      width: double.infinity,
      height: 100.0,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFFFD700).withValues(alpha: 0.85),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: const Color(0xFF00F0FF).withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Ảnh nền banner VIP đại dương siêu ngầu
          Image.asset(
            'assets/images/creatures/vip_banner_bg.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
            errorBuilder: (ctx, err, stack) => Container(
              color: const Color(0xFF021028),
            ),
          ),

          // 2. Lớp phủ gradient tối bên trái để chữ nổi bật 100%
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF010612).withValues(alpha: 0.94),
                  const Color(0xFF030E26).withValues(alpha: 0.85),
                  const Color(0xFF021233).withValues(alpha: 0.45),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.50, 0.80, 1.0],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),

          // 3. Nội dung vinh danh
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
            child: Row(
              children: [
                // Thông tin chi tiết
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Hàng nhãn VIP & Gói
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'VIP MEMBER',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            passName,
                            style: const TextStyle(
                              color: Color(0xFF00F0FF),
                              fontSize: 9.0,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Tên thuyền trưởng hoặc Gmail người mua
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                            Shadow(
                              color: Color(0xFFFFD700),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),

                      // Dòng vinh danh
                      Row(
                        children: [
                          const Icon(Icons.verified_rounded, color: Color(0xFF00F0FF), size: 12),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              isVi
                                  ? 'Đã mở khóa toàn bộ sinh vật & video'
                                  : 'All deep sea creatures & videos unlocked',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 10.0,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Nút chỉnh sửa / khắc tên trên bảng vàng
                GestureDetector(
                  onTap: () => _showEditVipNameDialog(context, isVi),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                        width: 1.0,
                      ),
                    ),
                    child: const Icon(
                      Icons.edit_note_rounded,
                      color: Color(0xFFFFD700),
                      size: 20,
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

  void _showEditVipNameDialog(BuildContext context, bool isVi) {
    final controller = TextEditingController(text: _vipIdentifier ?? '');
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF061325),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD700), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.25),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD700), size: 22),
                    const SizedBox(width: 8),
                    Text(
                      isVi ? 'KHẮC TÊN THUYỀN TRƯỞNG VIP' : 'VIP COMMANDER INSIGNIA',
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  isVi
                      ? 'Nhập họ tên, biệt danh hoặc Gmail của bạn để hiển thị trang trọng trên thẻ VIP:'
                      : 'Enter your name, nickname or Gmail to display on the VIP honor banner:',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: isVi ? 'Ví dụ: captain@gmail.com' : 'e.g. captain@gmail.com',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: const Color(0xFF00F0FF).withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFFFD700)),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        isVi ? 'HỦY' : 'CANCEL',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        _saveVipIdentifier(controller.text);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF061325),
                            content: Text(
                              isVi ? 'Đã khắc tên danh hiệu VIP!' : 'VIP Insignia saved!',
                              style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      },
                      child: Text(
                        isVi ? 'LƯU DANH HIỆU' : 'SAVE',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
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

  void _showFeedbackBottomSheet(BuildContext context, bool isVi) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) {
        return _FeedbackBottomSheetContent(
          isVi: isVi,
          initialName: _vipIdentifier,
        );
      },
    );
  }
}

class _FeedbackBottomSheetContent extends StatefulWidget {
  final bool isVi;
  final String? initialName;

  const _FeedbackBottomSheetContent({
    required this.isVi,
    this.initialName,
  });

  @override
  State<_FeedbackBottomSheetContent> createState() => _FeedbackBottomSheetContentState();
}

class _FeedbackBottomSheetContentState extends State<_FeedbackBottomSheetContent> {
  late final TextEditingController _contentController;
  int _rating = 5;
  bool _isSubmitting = false;
  late final stt.SpeechToText _speech;
  bool _speechEnabled = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController();
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _speechEnabled = await _speech.initialize(
        onError: (val) {
          if (mounted) setState(() => _isListening = false);
        },
        onStatus: (val) {
          if (mounted) {
            setState(() {
              _isListening = (val == 'listening');
            });
          }
        },
      );
      if (mounted) setState(() {});
    } catch (_) {
      _speechEnabled = false;
    }
  }

  Future<void> _toggleListening() async {
    if (!_speechEnabled) {
      await _initSpeech();
      if (!_speechEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF260810),
              content: Text(
                widget.isVi
                    ? 'Không thể mở Micro. Vui lòng cấp quyền Microphone trong Cài đặt iPhone/máy.'
                    : 'Microphone not available. Please allow permissions in Settings.',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          );
        }
        return;
      }
    }

    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      HapticFeedback.selectionClick();
    } else {
      HapticFeedback.mediumImpact();
      final localeId = widget.isVi ? 'vi_VN' : 'en_US';
      await _speech.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _contentController.text = result.recognizedWords;
              _contentController.selection = TextSelection.fromPosition(
                TextPosition(offset: _contentController.text.length),
              );
            });
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          cancelOnError: true,
          partialResults: true,
          localeId: localeId,
        ),
      );
      if (mounted) setState(() => _isListening = true);
    }
  }

  @override
  void dispose() {
    if (_isListening) {
      _speech.stop();
    }
    _contentController.dispose();
    super.dispose();
  }

  String _getRatingText(int stars) {
    if (widget.isVi) {
      switch (stars) {
        case 5:
          return 'Tuyệt vời! Rất thích ứng dụng';
        case 4:
          return 'Hài lòng, trải nghiệm tốt';
        case 3:
          return 'Khá ổn, cần thêm nội dung';
        case 2:
          return 'Chưa như mong đợi';
        default:
          return 'Cần cải thiện nhiều';
      }
    } else {
      switch (stars) {
        case 5:
          return 'Exceptional! Absolutely love it';
        case 4:
          return 'Great experience!';
        case 3:
          return 'Decent, needs more content';
        case 2:
          return 'Below expectations';
        default:
          return 'Needs improvement';
      }
    }
  }

  Future<void> _handleSubmit() async {
    final contentText = _contentController.text.trim();
    if (contentText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1E0A10),
          content: Text(
            widget.isVi
                ? 'Vui lòng nhập vài dòng ý kiến hoặc nói qua micro.'
                : 'Please enter feedback or speak through mic.',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      );
      return;
    }

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.lightImpact();

    final result = await FeedbackService.submitFeedback(
      userName: widget.initialName ?? 'Ẩn danh Thủy Thủ',
      rating: _rating,
      feedbackType: 'experience',
      content: contentText,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.isSuccess) {
      HapticFeedback.mediumImpact();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF141414),
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: Color(0xFFE50914), width: 1.0),
          ),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFFE50914), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.isVi
                      ? 'Cảm ơn bạn đã gửi ý kiến đóng góp!'
                      : 'Thank you for your valuable feedback!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF141414),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: Color(0xFFE50914), width: 1.0),
          ),
          content: Text(
            result.message,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isVi = widget.isVi;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF121212), // Netflix Pure Cinematic Black
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          border: Border.all(
            color: const Color(0xFF282828),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.85),
              blurRadius: 28,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thanh kéo drag handle phong cách Netflix tối giản
              Center(
                child: Container(
                  width: 36,
                  height: 3.5,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF333333),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Tiêu đề & nút đóng (Netflix Header)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE50914), // Netflix Red
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.rate_review_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isVi ? 'ĐÓNG GÓP Ý KIẾN' : 'SHARE FEEDBACK',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF808080), size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Đánh giá sao nhanh (Chạm chọn 1 giây)
              Center(
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (index) {
                        final star = index + 1;
                        final isFilled = star <= _rating;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _rating = star);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Icon(
                              isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 34,
                              color: isFilled ? const Color(0xFFFFB800) : const Color(0xFF2E2E2E),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _getRatingText(_rating),
                      style: const TextStyle(
                        color: Color(0xFFE5E5E5),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Hàng nhãn & Nút Micro nói nhanh
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isVi ? 'Ý KIẾN CỦA BẠN' : 'YOUR FEEDBACK',
                    style: const TextStyle(
                      color: Color(0xFF808080),
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  GestureDetector(
                    onTap: _toggleListening,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _isListening
                            ? const Color(0xFFE50914)
                            : const Color(0xFF242424),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _isListening
                              ? const Color(0xFFE50914)
                              : const Color(0xFF383838),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _isListening
                                ? (isVi ? 'Dừng micro' : 'Stop')
                                : (isVi ? 'Nói bằng Micro' : 'Speak with Mic'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Banner thông báo khi đang lắng nghe (Netflix Red)
              if (_isListening) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE50914).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFE50914), width: 1.0),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.graphic_eq_rounded, color: Color(0xFFE50914), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isVi
                              ? 'Đang lắng nghe... Hãy nói ý kiến của bạn'
                              : 'Listening... Please speak your feedback',
                          style: const TextStyle(
                            color: Color(0xFFFF525D),
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 1 Ô NHẬP DUY NHẤT (Netflix Style)
              TextField(
                controller: _contentController,
                minLines: 3,
                maxLines: 5,
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: isVi
                      ? 'Nói qua micro hoặc gõ trải nghiệm, ý kiến của bạn...'
                      : 'Speak via mic or type your feedback here...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF737373),
                    fontSize: 12.5,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  contentPadding: const EdgeInsets.all(12),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: _isListening ? const Color(0xFFE50914) : const Color(0xFF888888),
                      size: 20,
                    ),
                    tooltip: isVi ? 'Bật/Tắt Micro' : 'Toggle Mic',
                    onPressed: _toggleListening,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(
                      color: _isListening
                          ? const Color(0xFFE50914)
                          : const Color(0xFF333333),
                      width: 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(
                      color: Color(0xFFE50914),
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // NÚT GỬI Ý KIẾN (Netflix Signature Red CTA)
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE50914), // Netflix Red
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.send_rounded, size: 15, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              isVi ? 'GỬI Ý KIẾN' : 'SUBMIT',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
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
