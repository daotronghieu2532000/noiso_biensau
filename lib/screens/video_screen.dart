import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/data_service.dart';
import '../services/sound_service.dart';
import '../l10n/app_strings.dart';

class BattleVideo {
  final String title;
  final String titleEn;
  final String description;
  final String descriptionEn;
  final String videoUrl;
  final String thumbnailUrl;

  const BattleVideo({
    required this.title,
    required this.titleEn,
    required this.description,
    required this.descriptionEn,
    required this.videoUrl,
    required this.thumbnailUrl,
  });

  String getTitle(String lang) => lang == 'en' ? titleEn : title;
  String getDescription(String lang) => lang == 'en' ? descriptionEn : description;
}

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  final List<BattleVideo> _videos = const [
    BattleVideo(
      title: 'Đại Chiến Thần Thoại: Kraken vs Megalodon',
      titleEn: 'Mythical Clash: Kraken vs Megalodon',
      description: 'Trận chiến kinh thiên động địa giữa vua xúc tu Kraken và siêu cá mập thời tiền sử Megalodon tại độ sâu 2,000m.',
      descriptionEn: 'A titanic battle between the giant Kraken and the prehistoric Megalodon at 2,000m depth.',
      videoUrl: 'https://assets.mixkit.co/videos/preview/mixkit-underwater-light-beams-through-water-surface-41441-large.mp4',
      thumbnailUrl: 'assets/images/creatures/kraken.png',
    ),
    BattleVideo(
      title: 'Tà Thần Thức Tỉnh: Cthulhu vs Leviathan',
      titleEn: 'Awakening of Cthulhu vs Leviathan',
      description: 'Khi thực thể vũ trụ Cthulhu trỗi dậy từ R\'lyeh, đụng độ với vị vua tối cao của Vực thẳm Mariana - Leviathan.',
      descriptionEn: 'As the cosmic Cthulhu rises from R\'lyeh, it clashes with the sovereign of the Mariana Trench - Leviathan.',
      videoUrl: 'https://assets.mixkit.co/videos/preview/mixkit-underwater-swimmer-with-a-flashlight-41434-large.mp4',
      thumbnailUrl: 'assets/images/creatures/Cthulhu.png',
    ),
    BattleVideo(
      title: 'Độ Sâu Cực Hạn: Godzilla vs Jörmungandr',
      titleEn: 'Extreme Depths: Godzilla vs Jörmungandr',
      description: 'Vua quái thú Godzilla giải phóng luồng hơi thở nguyên tử dưới đáy Thái Bình Dương đấu với Mãng Xà Thế Giới.',
      descriptionEn: 'The King of Monsters Godzilla releases atomic breath against the World Serpent Jörmungandr under the Pacific.',
      videoUrl: 'https://assets.mixkit.co/videos/preview/mixkit-waves-crashing-in-the-ocean-1527-large.mp4',
      thumbnailUrl: 'assets/images/creatures/Godzilla_2014.png',
    ),
    BattleVideo(
      title: 'Bí Mật Tăm Tối: Mực Khổng Lồ Săn Mồi',
      titleEn: 'Dark Secrets: Giant Squid Hunting',
      description: 'Đoạn phim chân thực tái hiện khoảnh khắc Mực Khổng Lồ Architeuthis dux rình rập và săn đuổi con mồi cận đáy sâu.',
      descriptionEn: 'Authentic documentary recreation of the Giant Squid Architeuthis dux hunting in the dark ocean.',
      videoUrl: 'https://assets.mixkit.co/videos/preview/mixkit-underwater-scuba-diver-explores-a-cave-41435-large.mp4',
      thumbnailUrl: 'assets/images/creatures/giant_squid.png',
    ),
  ];

  DataService? _dataService;
  bool _wasLoading = false;
  bool _isSuccessDialogShown = false;
  VoidCallback? _onPurchaseSuccessCallback;

  @override
  void initState() {
    super.initState();
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
      
      if (dataService.isPremiumUnlocked && !_isSuccessDialogShown) {
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
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.3), width: 1.5),
                gradient: const LinearGradient(
                  colors: [Color(0xFF071224), Color(0xFF020710)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // VIP App Icon Glow
                  Container(
                    width: 72,
                    height: 72,
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
                  const SizedBox(height: 16),
                  
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
                      shadows: [
                        Shadow(color: Color(0xFF00F0FF), blurRadius: 10),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isVi 
                      ? 'Mở khóa toàn bộ đặc quyền trọn đời chỉ với 1 lần thanh toán' 
                      : 'Unlock all premium lifetime privileges with a single purchase',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const Divider(color: Color(0xFF00F0FF), height: 32, thickness: 0.5),

                  // Perks List
                  _buildPerkRow(
                    isVi ? 'Xem không giới hạn toàn bộ Video Chiến đấu Quái thú Vực sâu' : 'Watch unlimited high-quality Deep-Sea Battle Videos',
                    true,
                  ),
                  const SizedBox(height: 14),
                  _buildPerkRow(
                    isVi ? 'Mở khóa toàn bộ Thủy quái VIP (Kraken, Leviathan, Cthulhu, Godzilla...)' : 'Unlock all VIP creatures (Kraken, Leviathan, Cthulhu, Godzilla...)',
                    true,
                  ),
                  const SizedBox(height: 14),
                  _buildPerkRow(
                    isVi ? 'Nâng cấp radar Sonar quét quái thú nhanh hơn gấp 2 lần' : 'Upgrade Sonar radar performance to scan creatures 2x faster',
                    true,
                  ),
                  const SizedBox(height: 14),
                  _buildPerkRow(
                    isVi ? 'Không bao giờ xuất hiện quảng cáo làm gián đoạn' : 'Completely Ad-Free premium app experience forever',
                    true,
                  ),
                  const SizedBox(height: 32),

                  // Lifetime price
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F0FF).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isVi ? 'Mức giá một lần mua:' : 'One-time Price:',
                          style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          isVi ? '\$1.99 Trọn đời' : '\$1.99 Lifetime',
                          style: const TextStyle(
                            color: Color(0xFF00F0FF),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Purchase and Restore buttons row
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 40,
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
                              Navigator.pop(context); // Close sheet
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 40,
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
                              Navigator.pop(context); // Close sheet
                              Provider.of<DataService>(context, listen: false).buyPremium();
                            },
                            child: Text(
                              isVi ? 'MỞ KHÓA (\$1.99)' : 'UNLOCK (\$1.99)',
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
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Privacy Policy link
                  GestureDetector(
                    onTap: () async {
                      final url = Uri.parse('https://codego.io.vn/privacy_policy.html');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      } 
                    },
                    child: Text(
                      isVi ? 'Chính sách bảo mật' : 'Privacy Policy',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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

    return Scaffold(
      backgroundColor: const Color(0xFF010812),
      body: Stack(
        children: [
          // Cyber gradient background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF010A18), Color(0xFF03142B), Color(0xFF010812)],
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
                      if (dataService.isPremiumUnlocked)
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
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _videos.length,
                    itemBuilder: (context, index) {
                      final video = _videos[index];
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
                                if (!dataService.isPremiumUnlocked)
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
                                  onTap: () => _playVideo(video, dataService.isPremiumUnlocked),
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
                  ),
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
