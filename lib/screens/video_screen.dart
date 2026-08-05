import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/data_service.dart';
import '../services/sound_service.dart';
import '../l10n/app_strings.dart';
import '../models/battle_video.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
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

  DataService? _dataService;
  bool _wasLoading = false;
  bool _isSuccessDialogShown = false;
  VoidCallback? _onPurchaseSuccessCallback;

  @override
  void initState() {
    super.initState();
    _backgroundImage = _bgImages[math.Random().nextInt(_bgImages.length)];
    // Mute ambient sound when entering video screen to avoid noise clash
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SoundService>(context, listen: false).stopAmbient();
      Provider.of<SoundService>(context, listen: false).stopSecondaryAmbient();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dataService?.removeListener(_onDataServiceChanged);
    _dataService = Provider.of<DataService>(context);
    _dataService?.addListener(_onDataServiceChanged);
  }

  @override
  void dispose() {
    _dataService?.removeListener(_onDataServiceChanged);
    super.dispose();
  }

  void _onDataServiceChanged() {
    final dataService = _dataService;
    if (dataService == null) return;

    if (dataService.isPurchaseLoading && !_wasLoading) {
      _wasLoading = true;
      _showLoadingDialog();
    } else if (!dataService.isPurchaseLoading && _wasLoading) {
      _wasLoading = false;
      Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading dialog
      
      if (dataService.hasAnyPremium && !_isSuccessDialogShown) {
        _isSuccessDialogShown = true;
        _showSuccessDialog();
      }
    }
  }

  void _showLoadingDialog() {
    final isVi = AppStrings.of(context).languageCode == 'vi';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF071224),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00F0FF)),
                ),
                const SizedBox(height: 24),
                Text(
                  isVi ? 'ĐANG KẾT NỐI CỔNG THANH TOÁN...' : 'CONNECTING SECURE GATEWAY...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSuccessDialog() {
    final isVi = AppStrings.of(context).languageCode == 'vi';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF071224),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF00F0FF), width: 1),
          ),
          child: Container(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Color(0xFF00F0FF),
                  size: 64,
                ),
                const SizedBox(height: 18),
                Text(
                  isVi ? 'MỞ KHÓA THÀNH CÔNG!' : 'PURCHASE SUCCESSFUL!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isVi 
                    ? 'Chúc mừng! Bạn đã sở hữu đặc quyền VIP trọn đời.' 
                    : 'Congratulations! You now have permanent VIP status.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00F0FF),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      _isSuccessDialogShown = false;
                      Navigator.pop(context); // Close success dialog
                      if (_onPurchaseSuccessCallback != null) {
                        _onPurchaseSuccessCallback!(); // Play the video
                      }
                    },
                    child: Text(
                      isVi ? 'BẮT ĐẦU XEM VIDEO' : 'START WATCHING',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _playVideo(BattleVideo video, bool isVipUnlocked) {
    if (!isVipUnlocked) {
      _showVipUnlockBottomSheet(context, () {
        // Callback after successful payment
        _openPlayerDialog(video);
      });
    } else {
      _openPlayerDialog(video);
    }
  }

  void _openPlayerDialog(BattleVideo video) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _VideoPlayerDialog(video: video),
    );
  }

  void _showVipUnlockBottomSheet(BuildContext context, VoidCallback onPurchaseSuccess) {
    final strings = AppStrings.of(context);
    final isVi = strings.languageCode == 'vi';
    int selectedPlan = 0; // 0 = trọn đời, 1 = hàng tháng

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF071224),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border.all(
                    color: const Color(0xFF00F0FF).withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF071224), Color(0xFF020710)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // App Icon
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00F0FF).withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                        border: Border.all(color: const Color(0xFF00F0FF), width: 2),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/creatures/icon.jpeg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Title
                    Text(
                      isVi ? 'KÍCH HOẠT THÀNH VIÊN VIP' : 'ACTIVATE VIP MEMBERSHIP',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        shadows: [Shadow(color: Color(0xFF00F0FF), blurRadius: 10)],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isVi
                          ? 'Chọn gói phù hợp để mở toàn bộ đặc quyền VIP'
                          : 'Choose a plan to unlock all premium privileges',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    const Divider(color: Color(0xFF00F0FF), height: 24, thickness: 0.5),

                    // --- Quyền lợi chung cả 2 gói ---
                    _buildSectionTitle(
                      isVi ? '🎁 Quyền lợi VIP (áp dụng cho cả 2 gói)' : '🎁 VIP Benefits (both plans)',
                    ),
                    const SizedBox(height: 8),
                    _buildPerkRow(
                      isVi
                          ? '📺 Xem không giới hạn toàn bộ Video chiến đấu Quái thú Vực Sâu sắc nét'
                          : '📺 Unlimited access to all Deep-Sea Creature Battle Videos in HD',
                      true,
                    ),
                    const SizedBox(height: 8),
                    _buildPerkRow(
                      isVi
                          ? '🔓 Mở khóa toàn bộ Thủy quái VIP hiện có (Kraken, Leviathan, Cthulhu, Godzilla...)'
                          : '🔓 Unlock all current VIP Creatures (Kraken, Leviathan, Cthulhu, Godzilla...)',
                      true,
                    ),
                    const SizedBox(height: 8),
                    _buildPerkRow(
                      isVi
                          ? '🔮 Liên tục cập nhật thêm Video chiến đấu mới & Quái thú mới trong tương lai'
                          : '🔮 Continuously updated with new Battle Videos & new Creatures in the future',
                      true,
                    ),
                    const SizedBox(height: 8),
                    _buildPerkRow(
                      isVi
                          ? '⚡ Nâng cấp radar Sonar quét quái thú nhanh hơn gấp 2 lần'
                          : '⚡ Sonar radar upgraded to scan creatures 2x faster',
                      true,
                    ),
                    const SizedBox(height: 8),
                    _buildPerkRow(
                      isVi
                          ? '🚫 Trải nghiệm hoàn toàn không có quảng cáo gián đoạn'
                          : '🚫 Completely Ad-Free premium app experience',
                      true,
                    ),
                    const SizedBox(height: 16),

                    // --- Chọn gói ---
                    _buildSectionTitle(isVi ? '💳 Chọn gói của bạn' : '💳 Choose Your Plan'),
                    const SizedBox(height: 10),

                    // Gói Trọn đời
                    GestureDetector(
                      onTap: () => setModalState(() => selectedPlan = 0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedPlan == 0
                                ? const Color(0xFF00F0FF)
                                : const Color(0xFF00F0FF).withValues(alpha: 0.2),
                            width: selectedPlan == 0 ? 2 : 1,
                          ),
                          color: selectedPlan == 0
                              ? const Color(0xFF00F0FF).withValues(alpha: 0.08)
                              : Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            // Radio indicator
                            Container(
                              width: 20, height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF00F0FF), width: 2),
                                color: selectedPlan == 0 ? const Color(0xFF00F0FF) : Colors.transparent,
                              ),
                              child: selectedPlan == 0
                                  ? const Icon(Icons.check, size: 12, color: Colors.black)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        isVi ? 'Trọn đời' : 'Lifetime',
                                        style: TextStyle(
                                          color: selectedPlan == 0
                                              ? const Color(0xFF00F0FF)
                                              : Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                                          ),
                                        ),
                                        child: Text(
                                          isVi ? 'GIÁ TỐT NHẤT' : 'BEST VALUE',
                                          style: const TextStyle(
                                            color: Color(0xFFFFD700),
                                            fontSize: 8,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    isVi
                                        ? 'Trả một lần, dùng mãi mãi. Mở khóa vĩnh viễn tất cả nội dung hiện tại & trong tương lai.'
                                        : 'Pay once, keep forever. Permanently unlocks all current & future content.',
                                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              r'$3.99',
                              style: TextStyle(
                                color: selectedPlan == 0 ? const Color(0xFF00F0FF) : Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Gói Hàng tháng
                    GestureDetector(
                      onTap: () => setModalState(() => selectedPlan = 1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedPlan == 1
                                ? const Color(0xFF00F0FF)
                                : const Color(0xFF00F0FF).withValues(alpha: 0.2),
                            width: selectedPlan == 1 ? 2 : 1,
                          ),
                          color: selectedPlan == 1
                              ? const Color(0xFF00F0FF).withValues(alpha: 0.08)
                              : Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 20, height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF00F0FF), width: 2),
                                color: selectedPlan == 1 ? const Color(0xFF00F0FF) : Colors.transparent,
                              ),
                              child: selectedPlan == 1
                                  ? const Icon(Icons.check, size: 12, color: Colors.black)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isVi ? 'Hàng tháng' : 'Monthly',
                                    style: TextStyle(
                                      color: selectedPlan == 1 ? const Color(0xFF00F0FF) : Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    isVi
                                        ? 'Gia hạn tự động mỗi tháng. Huỷ bất cứ lúc nào. Thích hợp trải nghiệm trước khi chọn trọn đời.'
                                        : 'Auto-renews monthly. Cancel anytime. Great for trying before going lifetime.',
                                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  r'$0.99',
                                  style: TextStyle(
                                    color: selectedPlan == 1 ? const Color(0xFF00F0FF) : Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  isVi ? '/tháng' : '/mo',
                                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Nút Mua + Khôi phục
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 42,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF00F0FF),
                                side: const BorderSide(color: Color(0xFF00F0FF), width: 1.2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: () {
                                _onPurchaseSuccessCallback = onPurchaseSuccess;
                                Navigator.pop(context);
                                Provider.of<DataService>(context, listen: false).restorePurchases();
                              },
                              child: Text(
                                isVi ? 'KHÔI PHỤC' : 'RESTORE',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 42,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00F0FF),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 4,
                                shadowColor: const Color(0xFF00F0FF).withValues(alpha: 0.3),
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: () {
                                _onPurchaseSuccessCallback = onPurchaseSuccess;
                                Navigator.pop(context);
                                final ds = Provider.of<DataService>(context, listen: false);
                                if (selectedPlan == 0) {
                                  ds.buyPremium();
                                } else {
                                  ds.buyMonthly();
                                }
                              },
                              child: Text(
                                selectedPlan == 0
                                    ? (isVi ? r'TRỌN ĐỜI (\$3.99)' : 'LIFETIME (\$3.99)')
                                    : (isVi ? r'ĐĂNG KÝ (\$0.99/tháng)' : 'SUBSCRIBE (\$0.99/mo)'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 2 nút chính sách
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildPolicyButton(
                          label: isVi ? 'Chính sách bảo mật' : 'Privacy Policy',
                          url: 'https://codego.io.vn/privacy_policy.html',
                        ),
                        const SizedBox(width: 8),
                        _buildPolicyButton(
                          label: 'Apple EULA',
                          url: 'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPolicyButton({required String label, required String url}) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildPerkRow(String text, bool isChecked) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          'assets/images/icon/shield.png',
          width: 18,
          height: 18,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final isVi = strings.languageCode == 'vi';
    final dataService = Provider.of<DataService>(context);
    final videos = dataService.videos;

    return Scaffold(
      backgroundColor: const Color(0xFF010812),
      body: Stack(
        children: [
          // 1. Random background image
          if (_backgroundImage != null)
            Positioned.fill(
              child: Opacity(
                opacity: 0.25,
                child: Image.asset(
                  _backgroundImage!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          // 2. Abyssal dark overlay / Cyber gradient background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF010A18).withValues(alpha: 0.8),
                    const Color(0xFF03142B).withValues(alpha: 0.85),
                    const Color(0xFF010812).withValues(alpha: 0.9),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          
          // Cyber Grid Overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: GridPaper(
                color: const Color(0xFF00F0FF),
                divisions: 1,
                subdivisions: 1,
                interval: 50,
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom Navigation Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Back Button
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                        ),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 16),
                      // Title
                      Expanded(
                        child: Text(
                          isVi ? 'VIDEO QUÁI THÚ CHIẾN ĐẤU' : 'CREATURE BATTLES',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      
                      // VIP tag if unlocked
                      if (dataService.hasAnyPremium)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                            border: Border.all(color: const Color(0xFF00F0FF), width: 1),
                          ),
                          child: const Text(
                            'VIP MEMBERSHIP',
                            style: TextStyle(
                              color: Color(0xFF00F0FF),
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Header description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(
                    isVi 
                      ? 'Xem cuộc đụng độ khốc liệt của những kẻ thống trị đại dương sâu thẳm.'
                      : 'Witness fierce clashes between the supreme rulers of the dark abyss.',
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 12),

                // Videos List
                Expanded(
                  child: dataService.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00F0FF)),
                          ),
                        )
                      : (videos.isEmpty
                          ? Center(
                              child: Text(
                                isVi 
                                    ? 'Không có kết nối mạng hoặc không có video.' 
                                    : 'No network connection or no videos available.',
                                style: const TextStyle(color: Colors.white54, fontSize: 13),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: videos.length,
                              itemBuilder: (context, index) {
                                final video = videos[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                            width: 1,
                          ),
                          color: const Color(0xFF061121).withValues(alpha: 0.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Video Thumbnail Stack
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                // Thumbnail Image
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                  child: Image.asset(
                                    video.thumbnailUrl,
                                    width: double.infinity,
                                    height: 180,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                // Vignette Gradient
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.black.withValues(alpha: 0.3),
                                          Colors.black.withValues(alpha: 0.7),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                  ),
                                ),
                                
                                // Lock overlay if not VIP
                                if (!dataService.hasAnyPremium)
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.black54,
                                      ),
                                      child: const Icon(
                                        Icons.lock_rounded,
                                        color: Color(0xFF00F0FF),
                                        size: 16,
                                      ),
                                    ),
                                  ),

                                // Play Button Icon Overlay
                                GestureDetector(
                                  onTap: () => _playVideo(video, dataService.hasAnyPremium),
                                  child: Container(
                                    width: 58,
                                    height: 58,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black.withValues(alpha: 0.6),
                                      border: Border.all(
                                        color: const Color(0xFF00F0FF),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF00F0FF).withValues(alpha: 0.3),
                                          blurRadius: 12,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow_rounded,
                                      color: Color(0xFF00F0FF),
                                      size: 38,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Video Info
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    video.getTitle(strings.languageCode),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    video.getDescription(strings.languageCode),
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.6),
                                      fontSize: 11,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoPlayerDialog extends StatefulWidget {
  final BattleVideo video;
  const _VideoPlayerDialog({required this.video});

  @override
  State<_VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<_VideoPlayerDialog> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.video.videoUrl))
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
        _controller.setLooping(true);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: const Color(0xFF040C1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF00F0FF), width: 1),
      ),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          children: [
            // Video Playback
            if (_isInitialized)
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: VideoPlayer(_controller),
              )
            else
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00F0FF)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'ESTABLISHING SONAR LINK...',
                      style: TextStyle(
                        color: Color(0xFF00F0FF),
                        fontSize: 10,
                        fontFamily: 'monospace',
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),

            // Video Controller UI Overlay
            if (_isInitialized)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_controller.value.isPlaying) {
                        _controller.pause();
                      } else {
                        _controller.play();
                      }
                    });
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: Stack(
                      children: [
                        // Play/Pause Overlay indicator when paused
                        if (!_controller.value.isPlaying)
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black45,
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Color(0xFF00F0FF),
                                size: 48,
                              ),
                            ),
                          ),

                        // Top Title & Close Button Bar
                        Positioned(
                          top: 12,
                          left: 16,
                          right: 16,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Title
                              Expanded(
                                child: Text(
                                  widget.video.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                                  ),
                                ),
                              ),
                              // Close Button
                              IconButton(
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black45,
                                  shape: const CircleBorder(),
                                ),
                                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                                onPressed: () {
                                  _controller.pause();
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        ),

                        // Bottom Control Seek bar
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.transparent, Colors.black87],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
                            ),
                            child: Row(
                              children: [
                                // Play / Pause small button
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      if (_controller.value.isPlaying) {
                                        _controller.pause();
                                      } else {
                                        _controller.play();
                                      }
                                    });
                                  },
                                  child: Icon(
                                    _controller.value.isPlaying 
                                      ? Icons.pause_rounded 
                                      : Icons.play_arrow_rounded,
                                    color: const Color(0xFF00F0FF),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                
                                // Video Progress bar
                                Expanded(
                                  child: VideoProgressIndicator(
                                    _controller,
                                    allowScrubbing: true,
                                    colors: const VideoProgressColors(
                                      playedColor: Color(0xFF00F0FF),
                                      bufferedColor: Colors.white24,
                                      backgroundColor: Colors.white10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
