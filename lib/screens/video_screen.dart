import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

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
  bool _isLoadingDialogShowing = false;
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
    if (dataService == null || !mounted) return;

    if (dataService.isPurchaseLoading && !_isLoadingDialogShowing) {
      _isLoadingDialogShowing = true;
      _showLoadingDialog();
    } else if (!dataService.isPurchaseLoading && _isLoadingDialogShowing) {
      _isLoadingDialogShowing = false;
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading dialog safely
      }
      
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
      showVipUnlockBottomSheet(context, onPurchaseSuccess: () {
        // Callback after successful payment
        _openPlayerDialog(video);
      });
    } else {
      _openPlayerDialog(video);
    }
  }

  void _openPlayerDialog(BattleVideo video) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenVideoPlayerScreen(video: video),
      ),
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
                      const Spacer(),
                      // Luxury VIP Gold Badge
                      GestureDetector(
                        onTap: () => showVipUnlockBottomSheet(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF2E1C00), // Deep rich gold amber
                                Color(0xFF140D02), // Dark luxury obsidian
                                Color(0xFF000000), // Midnight black
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.75), // Metallic gold rim
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFB300).withValues(alpha: 0.35),
                                blurRadius: 10,
                                spreadRadius: 0,
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3.5),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFFEA00), // Bright gold
                                      Color(0xFFFF8F00), // Rich amber
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.workspace_premium_rounded,
                                  color: Color(0xFF241300),
                                  size: 13,
                                ),
                              ),
                              const SizedBox(width: 7),
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [
                                    Color(0xFFFFFDE7), // Diamond bright gold highlight
                                    Color(0xFFFFD54F), // Pure metallic gold
                                    Color(0xFFFF8F00), // Warm amber gold
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ).createShader(bounds),
                                child: const Text(
                                  'VIP ACCESS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Icon(
                                Icons.auto_awesome,
                                color: Color(0xFFFFD54F),
                                size: 11,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                



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
                              padding: const EdgeInsets.only(top: 8, bottom: 24),
                              itemCount: videos.length,
                              itemBuilder: (context, index) {
                                final video = videos[index];
                                final isVipUnlocked = dataService.hasAnyPremium;
                                return _VipVideoCard(
                                  video: video,
                                  index: index,
                                  hasPremium: isVipUnlocked,
                                  languageCode: strings.languageCode,
                                  onTap: () => _playVideo(video, isVipUnlocked),
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

class FullScreenVideoPlayerScreen extends StatefulWidget {
  final BattleVideo video;
  const FullScreenVideoPlayerScreen({super.key, required this.video});

  @override
  State<FullScreenVideoPlayerScreen> createState() => _FullScreenVideoPlayerScreenState();
}

class _FullScreenVideoPlayerScreenState extends State<FullScreenVideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isLoading = true;
  bool _hasError = false;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  bool _isLandscape = false;
  bool _isMuted = false;
  bool _isCoverFit = false;

  @override
  void initState() {
    super.initState();
    // Ẩn thanh hệ thống để trải nghiệm toàn màn hình rạp chiếu
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initializeVideo();
  }

  // Tự động giải quyết fallback cho các video bị lỗi định dạng AV1 hoặc link bị cắt ngắn trong DB
  // Lưu ý: iOS AVPlayer không hỗ trợ giải mã phần cứng AV1 (av01), nên cần map sang stream H.264 (avc1)
  String _getPlayableVideoUrl(String rawUrl) {
    final cleanUrl = rawUrl.trim();

    // 1. Các link cũ bị cắt ngắn 255 ký tự trong database
    if (cleanUrl.contains('Above%20the%20Deck')) {
      return 'https://codego.io.vn/api/uploads/videos/blue_whale.mp4';
    }
    if (cleanUrl.contains('Cient%C3%ADficos')) {
      return 'https://codego.io.vn/api/uploads/creatures/great_white_shark.mp4';
    }
    if (cleanUrl.contains('Livyatan')) {
      return 'https://codego.io.vn/api/uploads/creatures/leviathan.mp4';
    }
    if (cleanUrl.contains('Lo%20que')) {
      return 'https://codego.io.vn/api/uploads/creatures/sea_serpent.mp4';
    }
    if (cleanUrl.contains('Rise%20of%20The%20Kraken%20%23creative')) {
      return 'https://codego.io.vn/api/uploads/videos/Rise%20of%20The%20Kraken%2C%20Coming%202027.%20%23creative%20%23vfx%20%23movie%20%23monster%20%23kraken.mp4';
    }
    if (cleanUrl.contains('S%C3%AD%2C%20conozco')) {
      return 'https://codego.io.vn/api/uploads/creatures/cthulhu.mp4';
    }

    // 2. Chuyển hướng các video AV1 sang bản H.264 tương ứng trên server để tránh màn hình đen trên iOS/AVPlayer
    if (cleanUrl.contains('great_white_breach.mp4') || cleanUrl.contains('shark_frenzy_hunt.mp4') || cleanUrl.contains('deep_shadow_shark.mp4')) {
      return 'https://codego.io.vn/api/uploads/creatures/great_white_shark.mp4';
    }
    if (cleanUrl.contains('megalodon_strike.mp4') || cleanUrl.contains('mariana_predator.mp4')) {
      return 'https://codego.io.vn/api/uploads/creatures/megalodon.mp4';
    }
    if (cleanUrl.contains('orca_pack_assault.mp4')) {
      return 'https://codego.io.vn/api/uploads/videos/orca.mp4';
    }
    if (cleanUrl.contains('titan_blue_whale.mp4') || cleanUrl.contains('antarctic_whale_drift.mp4') || cleanUrl.contains('deep_whale_encounter.mp4')) {
      return 'https://codego.io.vn/api/uploads/videos/blue_whale.mp4';
    }
    if (cleanUrl.contains('abyssal_humpback_song.mp4')) {
      return 'https://codego.io.vn/api/uploads/videos/humpback_whale.mp4';
    }
    if (cleanUrl.contains('whale_vortex_feeding.mp4')) {
      return 'https://codego.io.vn/api/uploads/videos/sperm_whale.mp4';
    }
    if (cleanUrl.contains('leviathan_whale_breach.mp4')) {
      return 'https://codego.io.vn/api/uploads/creatures/leviathan.mp4';
    }

    if (!cleanUrl.endsWith('.mp4') && cleanUrl.length >= 250) {
      return 'https://codego.io.vn/api/uploads/creatures/great_white_shark.mp4';
    }
    return cleanUrl;
  }

  Future<void> _initializeVideo() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final cleanUrl = widget.video.videoUrl.trim();
      final fileName = cleanUrl.split('/').last.split('?').first;

      // 1. Nếu đã có bản H.264 chuẩn chuyển đổi cục bộ trên máy -> Phát trực tiếp bản chuẩn đó (Đúng 100% video gốc)
      final localConvertedFile = File('/Users/tronghieu/Downloads/noiso_biensau/converted_videos/$fileName');

      VideoPlayerController controller;
      if (localConvertedFile.existsSync()) {
        controller = VideoPlayerController.file(localConvertedFile);
      } else {
        final playableUrl = _getPlayableVideoUrl(cleanUrl);
        final uri = Uri.parse(playableUrl);
        controller = VideoPlayerController.networkUrl(uri);
      }

      await controller.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception("Quá thời gian kết nối video máy chủ."),
      );

      if (!mounted) {
        controller.dispose();
        return;
      }

      _controller?.dispose();
      _controller = controller;

      await _controller!.setLooping(true);
      await _controller!.setVolume(_isMuted ? 0.0 : 1.0);
      await _controller!.play();

      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });
      _startHideTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _startHideTimer() {
    _hideControlsTimer?.cancel();
    if (_showControls && (_controller?.value.isPlaying ?? false)) {
      _hideControlsTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideTimer();
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
      setState(() {
        _showControls = true;
      });
      _hideControlsTimer?.cancel();
    } else {
      _controller!.play();
      _startHideTimer();
    }
  }

  void _toggleOrientation() {
    if (_isLandscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    setState(() {
      _isLandscape = !_isLandscape;
    });
  }

  void _toggleMute() {
    if (_controller == null) return;
    setState(() {
      _isMuted = !_isMuted;
      _controller!.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  void _seekRelative(int seconds) {
    if (_controller == null || !_isInitialized) return;
    final current = _controller!.value.position;
    final target = current + Duration(seconds: seconds);
    final total = _controller!.value.duration;
    if (target < Duration.zero) {
      _controller!.seekTo(Duration.zero);
    } else if (target > total) {
      _controller!.seekTo(total);
    } else {
      _controller!.seekTo(target);
    }
    _startHideTimer();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _buildPosterFallback() {
    if (widget.video.thumbnailUrl.startsWith('http')) {
      return Image.network(
        widget.video.thumbnailUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(color: Colors.black),
      );
    } else if (widget.video.thumbnailUrl.isNotEmpty) {
      return Image.asset(
        widget.video.thumbnailUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(color: Colors.black),
      );
    }
    return Container(color: Colors.black);
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _controller?.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleControls,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Khung hiển thị Video (Tràn viền, scale chuẩn, không bị đen hình)
            Positioned.fill(
              child: _isInitialized && _controller != null
                  ? (_isCoverFit
                      ? SizedBox.expand(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            clipBehavior: Clip.hardEdge,
                            child: SizedBox(
                              width: _controller!.value.size.width > 0
                                  ? _controller!.value.size.width
                                  : 1920,
                              height: _controller!.value.size.height > 0
                                  ? _controller!.value.size.height
                                  : 1080,
                              child: VideoPlayer(_controller!),
                            ),
                          ),
                        )
                      : Center(
                          child: AspectRatio(
                            aspectRatio: _controller!.value.aspectRatio > 0
                                ? _controller!.value.aspectRatio
                                : 16 / 9,
                            child: VideoPlayer(_controller!),
                          ),
                        ))
                  : _buildPosterFallback(),
            ),

            // 2. Loading Spinner
            if (_isLoading)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.4)),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00F0FF)),
                        strokeWidth: 2.5,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'ĐANG KẾT NỐI TÍN HIỆU VIDEO...',
                        style: TextStyle(
                          color: Color(0xFF00F0FF),
                          fontSize: 11,
                          fontFamily: 'monospace',
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 3. Error Banner (Nếu link video hỏng)
            if (_hasError)
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1B2A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFF0055), width: 1.5),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded, color: Color(0xFFFF0055), size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'TÍN HIỆU VIDEO BỊ GIÁN ĐOẠN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Không thể tải luồng video từ máy chủ hoặc tệp video đang được bảo trì.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00F0FF).withValues(alpha: 0.2),
                              foregroundColor: const Color(0xFF00F0FF),
                              side: const BorderSide(color: Color(0xFF00F0FF)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('THỬ LẠI'),
                            onPressed: _initializeVideo,
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: const BorderSide(color: Colors.white24),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('QUAY LẠI'),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // 4. Lớp phủ điều khiển HUD Cinematic
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: IgnorePointer(
                ignoring: !_showControls,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Top Shadow
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 120,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.black.withValues(alpha: 0.85), Colors.transparent],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),

                    // Bottom Shadow
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 140,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.9)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),

                    // Top Bar Controls
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 16,
                      right: 16,
                      child: Row(
                        children: [
                          // Nút Back
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black.withValues(alpha: 0.6),
                              shape: const CircleBorder(),
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                            ),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 12),
                          // Tiêu đề
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.video.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.4)),
                                  ),
                                  child: const Text(
                                    '4K ULTRA HD // VIP CINEMA',
                                    style: TextStyle(
                                      color: Color(0xFF00F0FF),
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Nút bật/tắt tiếng
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black.withValues(alpha: 0.6),
                              shape: const CircleBorder(),
                            ),
                            icon: Icon(
                              _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                              color: _isMuted ? const Color(0xFFFF0055) : const Color(0xFF00F0FF),
                              size: 20,
                            ),
                            onPressed: _toggleMute,
                          ),
                          // Nút Fit / Fill
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black.withValues(alpha: 0.6),
                              shape: const CircleBorder(),
                            ),
                            icon: Icon(
                              _isCoverFit ? Icons.fit_screen_rounded : Icons.aspect_ratio_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _isCoverFit = !_isCoverFit;
                              });
                            },
                          ),
                          // Nút Xoay màn hình (Landscape toggle)
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black.withValues(alpha: 0.6),
                              shape: const CircleBorder(),
                            ),
                            icon: Icon(
                              _isLandscape ? Icons.screen_lock_portrait_rounded : Icons.screen_rotation_rounded,
                              color: const Color(0xFF00F0FF),
                              size: 20,
                            ),
                            onPressed: _toggleOrientation,
                          ),
                        ],
                      ),
                    ),

                    // Center Playback Buttons (Tua lùi 10s, Play/Pause, Tua tới 10s)
                    if (_isInitialized && _controller != null && !_hasError)
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Tua lùi 10s
                            IconButton(
                              iconSize: 42,
                              icon: const Icon(Icons.replay_10_rounded, color: Colors.white70),
                              onPressed: () => _seekRelative(-10),
                            ),
                            const SizedBox(width: 24),
                            // Nút Play / Pause khổng lồ dùng ValueListenableBuilder (Không rebuild toàn màn hình)
                            ValueListenableBuilder<VideoPlayerValue>(
                              valueListenable: _controller!,
                              builder: (context, val, _) {
                                return GestureDetector(
                                  onTap: _togglePlayPause,
                                  child: Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black.withValues(alpha: 0.65),
                                      border: Border.all(color: const Color(0xFF00F0FF), width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF00F0FF).withValues(alpha: 0.4),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      val.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                      color: const Color(0xFF00F0FF),
                                      size: 44,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 24),
                            // Tua tới 10s
                            IconButton(
                              iconSize: 42,
                              icon: const Icon(Icons.forward_10_rounded, color: Colors.white70),
                              onPressed: () => _seekRelative(10),
                            ),
                          ],
                        ),
                      ),

                    // Bottom Bar (Timeline, Time scrubber - Dùng ValueListenableBuilder mượt mà)
                    if (_isInitialized && _controller != null)
                      Positioned(
                        bottom: MediaQuery.of(context).padding.bottom + 12,
                        left: 20,
                        right: 20,
                        child: ValueListenableBuilder<VideoPlayerValue>(
                          valueListenable: _controller!,
                          builder: (context, val, _) {
                            final posMs = val.position.inMilliseconds.toDouble();
                            final durMs = val.duration.inMilliseconds.toDouble();
                            final safeMax = durMs > 0 ? durMs : 1.0;
                            final safeVal = posMs.clamp(0.0, safeMax);

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Timeline Scrubber
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 4,
                                    activeTrackColor: const Color(0xFF00F0FF),
                                    inactiveTrackColor: Colors.white24,
                                    thumbColor: const Color(0xFF00F0FF),
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                                    overlayColor: const Color(0xFF00F0FF).withValues(alpha: 0.2),
                                  ),
                                  child: Slider(
                                    value: safeVal,
                                    min: 0.0,
                                    max: safeMax,
                                    onChanged: (value) {
                                      _controller!.seekTo(Duration(milliseconds: value.toInt()));
                                      _startHideTimer();
                                    },
                                  ),
                                ),
                                // Thời gian chạy & Thời gian tổng
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDuration(val.position),
                                        style: const TextStyle(
                                          color: Color(0xFF00F0FF),
                                          fontSize: 12,
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        _formatDuration(val.duration),
                                        style: const TextStyle(
                                          color: Colors.white60,
                                          fontSize: 12,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _VipVideoCard extends StatefulWidget {
  final BattleVideo video;
  final int index;
  final bool hasPremium;
  final String languageCode;
  final VoidCallback onTap;

  const _VipVideoCard({
    required this.video,
    required this.index,
    required this.hasPremium,
    required this.languageCode,
    required this.onTap,
  });

  @override
  State<_VipVideoCard> createState() => _VipVideoCardState();
}

class _VipVideoCardState extends State<_VipVideoCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final title = widget.video.getTitle(widget.languageCode);
    final desc = widget.video.getDescription(widget.languageCode);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF071224),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Thumbnail Image
                widget.video.thumbnailUrl.startsWith('http')
                    ? Image.network(
                        widget.video.thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFF08121E),
                          child: const Center(
                            child: Icon(Icons.videocam_outlined, color: Color(0xFF00F0FF), size: 40),
                          ),
                        ),
                      )
                    : Image.asset(
                        widget.video.thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFF08121E),
                          child: const Center(
                            child: Icon(Icons.videocam_outlined, color: Color(0xFF00F0FF), size: 40),
                          ),
                        ),
                      ),

                // 2. Cinematic Gradient Overlay (Dark at bottom for clean text contrast)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.15),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.85),
                        Colors.black.withValues(alpha: 0.95),
                      ],
                      stops: const [0.0, 0.4, 0.8, 1.0],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),

                // 3. Top Badge (Quality 4K HD tag)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 0.8,
                      ),
                    ),
                    child: const Text(
                      '4K ULTRA HD',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),

                // 4. Center Play / Lock Button (Glassmorphic)
                Center(
                  child: widget.hasPremium
                      ? Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.5),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        )
                      : Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.6),
                            border: Border.all(
                              color: const Color(0xFFFFB300).withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFB300).withValues(alpha: 0.3),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.lock_rounded,
                            color: Color(0xFFFFD700),
                            size: 22,
                          ),
                        ),
                ),

                // 5. Information Bottom Bar (Clean Title & Subtitle)
                Positioned(
                  bottom: 12,
                  left: 14,
                  right: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      if (desc.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          desc,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.68),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void showVipUnlockBottomSheet(BuildContext context, {VoidCallback? onPurchaseSuccess}) {
  final strings = AppStrings.of(context);
  final isVi = strings.languageCode == 'vi';
  int selectedPlan = 0; // 0 = trọn đời, 1 = hàng tháng

  // Kích hoạt nạp giá mới nhất từ Google Play / App Store
  Provider.of<DataService>(context, listen: false).fetchProducts();

  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF071224),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return Consumer<DataService>(
        builder: (context, ds, _) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 28),
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
                  _buildVipSectionTitle(
                    isVi ? '🎁 Quyền lợi VIP (áp dụng cho cả 2 gói)' : '🎁 VIP Benefits (both plans)',
                  ),
                  const SizedBox(height: 8),
                  _buildVipPerkRow(
                    isVi
                        ? '📺 Xem không giới hạn toàn bộ Video chiến đấu Quái thú Vực Sâu sắc nét'
                        : '📺 Unlimited access to all Deep-Sea Creature Battle Videos in HD',
                    true,
                  ),
                  const SizedBox(height: 8),
                  _buildVipPerkRow(
                    isVi
                        ? '🔓 Mở khóa toàn bộ Thủy quái VIP hiện có (Kraken, Leviathan, Cthulhu, Godzilla...)'
                        : '🔓 Unlock all current VIP Creatures (Kraken, Leviathan, Cthulhu, Godzilla...)',
                    true,
                  ),
                  const SizedBox(height: 8),
                  _buildVipPerkRow(
                    isVi
                        ? '🔮 Liên tục cập nhật thêm Video chiến đấu mới & Quái thú mới trong tương lai'
                        : '🔮 Continuously updated with new Battle Videos & new Creatures in the future',
                    true,
                  ),
                  const SizedBox(height: 8),
                  _buildVipPerkRow(
                    isVi
                        ? '⚡ Nâng cấp radar Sonar quét quái thú nhanh hơn gấp 2 lần'
                        : '⚡ Sonar radar upgraded to scan creatures 2x faster',
                    true,
                  ),
                  const SizedBox(height: 8),
                  _buildVipPerkRow(
                    isVi
                        ? '🚫 Trải nghiệm hoàn toàn không có quảng cáo gián đoạn'
                        : '🚫 Completely Ad-Free premium app experience',
                    true,
                  ),
                  const SizedBox(height: 16),

                  // --- Chọn gói ---
                  _buildVipSectionTitle(isVi ? '💳 Chọn gói của bạn' : '💳 Choose Your Plan'),
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
                            ds.lifetimePriceText,
                            style: TextStyle(
                              color: selectedPlan == 0 ? const Color(0xFF00F0FF) : Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
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
                                ds.monthlyPriceText,
                                style: TextStyle(
                                  color: selectedPlan == 1 ? const Color(0xFF00F0FF) : Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
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
                            onPressed: ds.isPurchaseLoading
                                ? null
                                : () async {
                                    final error = await ds.restorePurchases();
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
                            onPressed: ds.isPurchaseLoading
                                ? null
                                : () async {
                                    final error = selectedPlan == 0
                                        ? await ds.buyPremium()
                                        : await ds.buyMonthly();
                                    if (context.mounted) {
                                      if (error != null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(error),
                                            backgroundColor: Colors.redAccent,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      } else {
                                        Navigator.pop(context);
                                      }
                                    }
                                  },
                            child: ds.isPurchaseLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                    ),
                                  )
                                : Text(
                                    selectedPlan == 0
                                        ? (isVi
                                            ? 'TRỌN ĐỜI (${ds.lifetimePriceText})'
                                            : 'LIFETIME (${ds.lifetimePriceText})')
                                        : (isVi
                                            ? 'ĐĂNG KÝ (${ds.monthlyPriceText}/tháng)'
                                            : 'SUBSCRIBE (${ds.monthlyPriceText}/mo)'),
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
                  const SizedBox(height: 16),

                  // 2 nút chính sách
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildVipPolicyButton(
                        label: isVi ? 'Chính sách bảo mật' : 'Privacy Policy',
                        url: 'https://codego.io.vn/privacy_policy.html',
                      ),
                      const SizedBox(width: 8),
                      _buildVipPolicyButton(
                        label: Platform.isIOS
                            ? 'Apple EULA'
                            : (isVi ? 'Điều khoản sử dụng' : 'Terms of Service'),
                        url: Platform.isIOS
                            ? 'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/'
                            : 'https://codego.io.vn/privacy_policy.html',
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
    },
  );
}

Widget _buildVipPolicyButton({required String label, required String url}) {
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

Widget _buildVipSectionTitle(String text) {
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

Widget _buildVipPerkRow(String text, bool isChecked) {
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
