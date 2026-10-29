import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/sailor_story.dart';
import '../services/locale_service.dart';
import '../services/sound_service.dart';
import '../widgets/cached_video_player.dart';

/// Hướng lật trang sách
enum FlipDirection { forward, backward }

/// =========================================================================
/// TRANG ĐỌC KÝ SỰ BẢN THẢO GIẤY DA CỔ ĐIỂN (ANTIQUE PARCHMENT MANUSCRIPT READER)
/// Phiên bản 4.0: Động cơ Uốn Lột Góc Giấy Tự Nhiên Chuẩn StPageFlip
/// =========================================================================
class StoryReaderScreen extends StatefulWidget {
  final SailorStory story;

  const StoryReaderScreen({super.key, required this.story});

  @override
  State<StoryReaderScreen> createState() => _StoryReaderScreenState();
}

class _StoryReaderScreenState extends State<StoryReaderScreen> with SingleTickerProviderStateMixin {
  double _fontSize = 16.5;
  bool _isPlayingSound = false;
  AudioPlayer? _audioPlayer;
  final List<AudioPlayer> _pageFlipPool = [];
  int _pageFlipPoolIndex = 0;

  // Bộ điều khiển lật trang StPageFlip cuộn góc giấy chân thực
  late final AnimationController _flipController;
  FlipDirection _flipDirection = FlipDirection.forward;
  bool _isDragging = false;
  double _dragStartX = 0.0;
  double _touchYRatio = 0.85; // Điểm chạm ngón tay theo chiều dọc (0.0: đỉnh, 1.0: góc đáy)

  int _currentPage = 0;
  double _scrollProgress = 0.0;
  late final List<List<StoryBlock>> _storyPages;
  final Map<int, GlobalKey> _pageGlobalKeys = {};

  GlobalKey _getPageKey(int index) {
    return _pageGlobalKeys.putIfAbsent(
        index, () => GlobalKey(debugLabel: 'book_page_$index'));
  }

  @override
  void initState() {
    super.initState();
    _storyPages = _partitionStory(widget.story.content);
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    );

    _initPageFlipAudio();

    if (widget.story.ambientSound.isNotEmpty) {
      _initAudio();
    }
  }

  void _turnForward() {
    if (_currentPage >= _storyPages.length - 1 || _flipController.isAnimating) return;
    _playPageFlipSound();
    setState(() {
      _flipDirection = FlipDirection.forward;
      _touchYRatio = 0.85; // Điểm lột góc dưới kinh điển
    });
    _flipController.animateTo(
      1.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    ).then((_) {
      if (mounted) {
        setState(() {
          _currentPage = (_currentPage + 1).clamp(0, _storyPages.length - 1);
          _flipController.value = 0.0;
          _scrollProgress = (_storyPages.length > 1)
              ? (_currentPage / (_storyPages.length - 1)).clamp(0.0, 1.0)
              : 0.0;
        });
        HapticFeedback.lightImpact();
      }
    });
  }

  void _turnBackward() {
    if (_currentPage <= 0 || _flipController.isAnimating) return;
    _playPageFlipSound();
    setState(() {
      _flipDirection = FlipDirection.backward;
      _touchYRatio = 0.85;
    });
    _flipController.animateTo(
      1.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    ).then((_) {
      if (mounted) {
        setState(() {
          _currentPage = (_currentPage - 1).clamp(0, _storyPages.length - 1);
          _flipController.value = 0.0;
          _scrollProgress = (_storyPages.length > 1)
              ? (_currentPage / (_storyPages.length - 1)).clamp(0.0, 1.0)
              : 0.0;
        });
        HapticFeedback.lightImpact();
      }
    });
  }

  void _goToPage(int targetPage) {
    if (targetPage == _currentPage || _flipController.isAnimating) return;
    if (targetPage > _currentPage) {
      _turnForward();
    } else {
      _turnBackward();
    }
  }

  void _restartStory() {
    if (_flipController.isAnimating) return;
    _playPageFlipSound();
    setState(() {
      _currentPage = 0;
      _flipController.value = 0.0;
      _scrollProgress = 0.0;
    });
    HapticFeedback.mediumImpact();
  }

  /// Phân chia câu chuyện thành các Hồi sách (Pages) logic và cân đối
  List<List<StoryBlock>> _partitionStory(List<StoryBlock> blocks) {
    if (blocks.length >= 10) {
      return [
        blocks.sublist(0, 2),
        blocks.sublist(2, 5),
        blocks.sublist(5, 8),
        blocks.sublist(8),
      ];
    } else if (blocks.length >= 6) {
      final mid = (blocks.length / 2).round();
      return [
        blocks.sublist(0, 2),
        blocks.sublist(2, mid),
        blocks.sublist(mid),
      ];
    } else {
      return [blocks];
    }
  }

  void _initAudio() {
    _audioPlayer = AudioPlayer();
    _audioPlayer?.setReleaseMode(ReleaseMode.loop);
  }

  void _initPageFlipAudio() {
    for (int i = 0; i < 3; i++) {
      final player = AudioPlayer();
      player.setReleaseMode(ReleaseMode.stop);
      player.setPlayerMode(PlayerMode.lowLatency);
      player.setVolume(0.85);
      _pageFlipPool.add(player);
    }
  }

  void _playPageFlipSound() {
    try {
      final soundService = Provider.of<SoundService>(context, listen: false);
      if (soundService.isMuted) return;
    } catch (_) {}

    if (_pageFlipPool.isEmpty) return;
    try {
      final player = _pageFlipPool[_pageFlipPoolIndex];
      _pageFlipPoolIndex = (_pageFlipPoolIndex + 1) % _pageFlipPool.length;
      player.stop();
      player.play(
        AssetSource('sounds/page_flip.mp3'),
        mode: PlayerMode.lowLatency,
      );
    } catch (_) {}
  }

  void _toggleAudio() async {
    if (_audioPlayer == null) return;
    if (_isPlayingSound) {
      await _audioPlayer?.stop();
      setState(() {
        _isPlayingSound = false;
      });
    } else {
      try {
        final path = widget.story.ambientSound.replaceFirst('assets/', '');
        await _audioPlayer?.play(AssetSource(path));
        setState(() {
          _isPlayingSound = true;
        });
      } catch (_) {
      }
    }
  }

  @override
  void dispose() {
    _pageGlobalKeys.clear();
    _flipController.dispose();
    _audioPlayer?.stop();
    _audioPlayer?.dispose();
    for (final player in _pageFlipPool) {
      player.stop();
      player.dispose();
    }
    _pageFlipPool.clear();
    super.dispose();
  }

  void _changeFontSize(double delta) {
    setState(() {
      _fontSize = (_fontSize + delta).clamp(14.0, 24.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final localeService = Provider.of<LocaleService>(context);
    final isVi = localeService.isVietnamese;
    final lang = localeService.languageCode;
    final story = widget.story;
    final totalPages = _storyPages.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0A06), // Bàn gỗ gụ tối thư phòng thuyền trưởng
      body: Stack(
        children: [
          // ========================================================
          // 1. NỀN BÀN GỖ GỤ VỚI ÁNH ĐÈN DẦU CHAO ĐẢO THEO TIẾN TRÌNH
          // ========================================================
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.0, -0.4),
                  radius: 1.25,
                  colors: [
                    Color.lerp(
                      const Color(0xFF22150B),
                      const Color(0xFF2B0A0D),
                      _scrollProgress * 0.7,
                    )!,
                    const Color(0xFF140C06),
                    const Color(0xFF0A0503),
                  ],
                ),
              ),
            ),
          ),

          // Vệt sáng đèn dầu rọi từ trần cabin
          Positioned(
            top: -60,
            left: 0,
            right: 0,
            height: 260,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 0.9,
                    colors: [
                      Color.lerp(
                        const Color(0xFFFFD54F).withValues(alpha: 0.18),
                        const Color(0xFFFF5722).withValues(alpha: 0.22),
                        _scrollProgress,
                      )!,
                      const Color(0xFFB8860B).withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ========================================================
          // 2. CUỐN SÁCH MỞ / TRANG SÁCH LẬT TRANG CAPCUT MƯỢT MÀ
          // ========================================================
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // A. THANH CÔNG CỤ ĐỒNG CỔ NẸP ĐẦU TRANG
                _buildAntiqueToolbar(context, isVi, localeService),

                // B. TRÌNH LẬT TRANG SÁCH 3D XOAY 180° CHÂN THỰC (REALISTIC 3D BOOK TURN ENGINE)
                Expanded(
                  child: _buildRealisticBookView(
                    context,
                    story,
                    lang,
                    isVi,
                    totalPages,
                  ),
                ),

                // C. BẢNG ĐIỀU HƯỚNG LẬT TRANG CƠ HỌC ĐỒNG CỔ DƯỚI CÙNG
                _buildAntiqueBottomPageTurner(totalPages, isVi),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// =========================================================================
  /// ĐỘNG CƠ LẬT TRANG SÁCH CHUẨN STPAGEFLIP (CORNER PEEL & ROLL ENGINE)
  /// Hiệu ứng uốn lột góc giấy tự nhiên, trang sau hé lộ bên dưới, nếp gập 3D
  /// =========================================================================
  Widget _buildRealisticBookView(
    BuildContext context,
    SailorStory story,
    String lang,
    bool isVi,
    int totalPages,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final pageSize = Size(w, h);

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (details) {
              if (_flipController.isAnimating) return;
              _dragStartX = details.localPosition.dx;
              _touchYRatio = (details.localPosition.dy / h).clamp(0.1, 0.9);
              _isDragging = false;
            },
            onHorizontalDragUpdate: (details) {
              if (_flipController.isAnimating) return;
              final deltaX = details.localPosition.dx - _dragStartX;
              _touchYRatio = (details.localPosition.dy / h).clamp(0.1, 0.9);

              if (!_isDragging) {
                if (deltaX < -10 && _currentPage < totalPages - 1) {
                  _isDragging = true;
                  setState(() {
                    _flipDirection = FlipDirection.forward;
                  });
                } else if (deltaX > 10 && _currentPage > 0) {
                  _isDragging = true;
                  setState(() {
                    _flipDirection = FlipDirection.backward;
                  });
                }
              }

              if (_isDragging) {
                double p = 0.0;
                if (_flipDirection == FlipDirection.forward) {
                  p = (-deltaX / w).clamp(0.0, 1.0);
                } else {
                  p = (deltaX / w).clamp(0.0, 1.0);
                }
                _flipController.value = p;
              }
            },
            onHorizontalDragEnd: (details) {
              if (!_isDragging) return;
              _isDragging = false;
              final velocity = details.primaryVelocity ?? 0.0;
              final progress = _flipController.value;

              bool shouldComplete = false;
              if (_flipDirection == FlipDirection.forward) {
                shouldComplete = (velocity < -250) || (progress > 0.22);
              } else {
                shouldComplete = (velocity > 250) || (progress > 0.22);
              }

              if (shouldComplete) {
                _playPageFlipSound();
                _flipController.animateTo(
                  1.0,
                  duration: const Duration(milliseconds: 480),
                  curve: Curves.easeOutCubic,
                ).then((_) {
                  if (mounted) {
                    setState(() {
                      if (_flipDirection == FlipDirection.forward) {
                        _currentPage = (_currentPage + 1).clamp(0, totalPages - 1);
                      } else {
                        _currentPage = (_currentPage - 1).clamp(0, totalPages - 1);
                      }
                      _flipController.value = 0.0;
                      _scrollProgress = (totalPages > 1)
                          ? (_currentPage / (totalPages - 1)).clamp(0.0, 1.0)
                          : 0.0;
                    });
                    HapticFeedback.lightImpact();
                  }
                });
              } else {
                _flipController.animateTo(
                  0.0,
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                );
              }
            },
            child: AnimatedBuilder(
              animation: _flipController,
              builder: (context, _) {
                final double progress = _flipController.value;
                final bool isFlipping = progress > 0.0001;

                if (!isFlipping) {
                  // Trạng thái tĩnh: Hiển thị phẳng phiu trang hiện tại
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _buildBookPage(
                        _currentPage,
                        _storyPages[_currentPage],
                        totalPages,
                        story,
                        lang,
                        isVi,
                      ),
                      _buildLeftSpineDecoration(),
                      _buildRightPaperStackDecoration(),
                    ],
                  );
                }

                // Chế độ lật uốn góc / cuốn lượn giấy theo thời gian thực (StPageFlip Mode)
                final bool isForward = _flipDirection == FlipDirection.forward;
                final int topIndex = isForward ? _currentPage : (_currentPage - 1).clamp(0, totalPages - 1);
                final int underIndex = isForward ? (_currentPage + 1).clamp(0, totalPages - 1) : _currentPage;

                if (topIndex == underIndex) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _buildBookPage(
                        _currentPage,
                        _storyPages[_currentPage],
                        totalPages,
                        story,
                        lang,
                        isVi,
                      ),
                      _buildLeftSpineDecoration(),
                      _buildRightPaperStackDecoration(),
                    ],
                  );
                }
                final double effectiveProgress = isForward ? progress : (1.0 - progress);

                final CreaseGeometry crease = CreaseGeometry.compute(
                  pageSize,
                  effectiveProgress,
                  _touchYRatio,
                );

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 1. Trang bên dưới lộ diện qua vùng lột góc (Revealed Area)
                    ClipPath(
                      clipper: PageRevealedClipper(crease),
                      child: _buildBookPage(
                        underIndex,
                        _storyPages[underIndex],
                        totalPages,
                        story,
                        lang,
                        isVi,
                      ),
                    ),

                    // 2. Trang hiện tại phần phẳng chưa bị lật (Unfolded Area)
                    ClipPath(
                      clipper: PageUnfoldedClipper(crease),
                      child: _buildBookPage(
                        topIndex,
                        _storyPages[topIndex],
                        totalPages,
                        story,
                        lang,
                        isVi,
                      ),
                    ),

                    // 3. Dải giấy uốn lượn 3D + Vệt sáng phản quang + Đổ bóng nếp gấp StPageFlip
                    CustomPaint(
                      size: pageSize,
                      painter: StPageCurlPainter(
                        crease: crease,
                        progress: effectiveProgress,
                        isForward: isForward,
                      ),
                    ),

                    // 4. Gáy sách da thuộc nẹp kim loại cố định bên trái
                    _buildLeftSpineDecoration(),

                    // 5. Xấp giấy xếp tầng tạo độ dày thực tế bên phải
                    _buildRightPaperStackDecoration(),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeftSpineDecoration() {
    return Positioned(
      left: 0,
      top: 0,
      bottom: 0,
      width: 14,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                const Color(0xFF140D07),
                const Color(0xFF26180E).withValues(alpha: 0.8),
                const Color(0xFF110B06).withValues(alpha: 0.5),
                Colors.transparent,
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRightPaperStackDecoration() {
    return Positioned(
      right: 0,
      top: 4,
      bottom: 4,
      width: 5,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
            gradient: LinearGradient(
              colors: [
                const Color(0xFF2B1D12),
                const Color(0xFFD4AF37).withValues(alpha: 0.4),
                const Color(0xFF160E08),
                const Color(0xFFDFBA73).withValues(alpha: 0.25),
                const Color(0xFF0F0A06),
              ],
            ),
          ),
        ),
      ),
    );
  }


  /// =========================================================================
  /// XÂY DỰNG MỘT TRANG SÁCH GIẤY DA CỔ ĐIỂN RIÊNG BIỆT (PARCHMENT BOOK PAGE)
  /// =========================================================================
  Widget _buildBookPage(
    int pageIndex,
    List<StoryBlock> pageBlocks,
    int totalPages,
    SailorStory story,
    String lang,
    bool isVi,
  ) {
    final double pageProgress = (pageIndex / (totalPages > 1 ? totalPages - 1 : 1)).clamp(0.0, 1.0);

    return Container(
      key: _getPageKey(pageIndex),
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        // Nền giấy da cừu ngả vàng hoàng gia
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFAF3E3),
            Color.lerp(
              const Color(0xFFF3E7CD),
              const Color(0xFFEBDBC0),
              pageProgress,
            )!,
            const Color(0xFFEADDBD),
            const Color(0xFFFAF3E3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color.lerp(
            const Color(0xFFC7B696),
            const Color(0xFF8D6E63),
            pageProgress,
          )!,
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 22,
            offset: const Offset(3, 10),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: const Color(0xFF3E2715).withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Họa tiết hoa văn la bàn hải đồ cổ in mờ chìm
            Positioned(
              right: -35,
              top: 180,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.045,
                  child: const Icon(
                    Icons.explore_rounded,
                    size: 240,
                    color: Color(0xFF3E2723),
                  ),
                ),
              ),
            ),

            // Viền chỉ đôi dập nhiệt chìm
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFBCAAA4).withValues(alpha: 0.5),
                      width: 0.9,
                    ),
                  ),
                ),
              ),
            ),

            // 4 Góc trang trí hoa văn cổ điển (Ornamental Brass Corners)
            _buildCornerOrnament(Alignment.topLeft),
            _buildCornerOrnament(Alignment.topRight),
            _buildCornerOrnament(Alignment.bottomLeft),
            _buildCornerOrnament(Alignment.bottomRight),

            // Nội dung chính của trang (Cuộn mượt mà nội bộ nếu màn hình nhỏ)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
              child: SingleChildScrollView(
                key: PageStorageKey('page_scroll_$pageIndex'),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header của trang
                    if (pageIndex == 0)
                      _buildChapterHeader(story, lang, isVi)
                    else
                      _buildPageSubHeader(pageIndex, isVi),

                    const SizedBox(height: 18),

                    // Khối nội dung của trang này
                    ..._buildStoryBlocks(pageBlocks, lang),

                    const SizedBox(height: 20),

                    // Nếu là trang cuối cùng: Thêm con dấu sáp đỏ niêm phong
                    if (pageIndex == totalPages - 1) ...[
                      _buildStoryEpilogue(isVi),
                      const SizedBox(height: 16),
                    ] else ...[
                      // Dòng gợi ý lật trang tiếp theo
                      _buildPageTurnHint(pageIndex, isVi),
                      const SizedBox(height: 12),
                    ],

                    // Chân trang hiển thị số trang La Mã
                    _buildPageFooter(pageIndex, totalPages, isVi),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tiêu đề hồi sách cho các trang tiếp theo
  Widget _buildPageSubHeader(int pageIndex, bool isVi) {
    String roman = '';
    String titleVi = '';
    String titleEn = '';

    switch (pageIndex) {
      case 1:
        roman = 'II';
        titleVi = 'ĐIỀM BÁO VỰC SÂU';
        titleEn = 'ABYSSAL OMENS';
        break;
      case 2:
        roman = 'III';
        titleVi = 'CAO TRÀO ĐẠI CHIẾN';
        titleEn = 'THE CLIMACTIC CLASH';
        break;
      case 3:
        roman = 'IV';
        titleVi = 'TUYỆT MỆNH & NIÊM PHONG';
        titleEn = 'THE FINAL DESCENT';
        break;
      default:
        roman = '$pageIndex';
        titleVi = 'HỒI TIẾP THEO';
        titleEn = 'NEXT ACT';
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 35,
              height: 1,
              color: const Color(0xFF8D6E63).withValues(alpha: 0.6),
            ),
            const SizedBox(width: 8),
            Text(
              "❖  ${isVi ? 'HỒI $roman' : 'ACT $roman'}  ❖",
              style: const TextStyle(
                color: Color(0xFF8B2500),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                fontFamily: 'serif',
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 35,
              height: 1,
              color: const Color(0xFF8D6E63).withValues(alpha: 0.6),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          isVi ? titleVi : titleEn,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF2B190C),
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
            fontFamily: 'serif',
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: 1.5,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, Color(0xFFB8860B), Colors.transparent],
            ),
          ),
        ),
      ],
    );
  }

  /// Gợi ý chạm hoặc vuốt lật trang
  Widget _buildPageTurnHint(int pageIndex, bool isVi) {
    return Center(
      child: InkWell(
        onTap: _turnForward,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFEFE2C8).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFBCAAA4).withValues(alpha: 0.5),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isVi
                    ? 'Vuốt sang trái để mở Hồi tiếp theo'
                    : 'Swipe left to turn the page',
                style: const TextStyle(
                  color: Color(0xFF5D4037),
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  fontFamily: 'serif',
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 13,
                color: Color(0xFF8B2500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Chân trang hiển thị số trang La Mã
  Widget _buildPageFooter(int pageIndex, int totalPages, bool isVi) {
    final romanNums = ['I', 'II', 'III', 'IV', 'V'];
    final roman = pageIndex < romanNums.length ? romanNums[pageIndex] : '${pageIndex + 1}';
    final totalRoman = totalPages <= romanNums.length ? romanNums[totalPages - 1] : '$totalPages';

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          "• ${isVi ? 'Trang' : 'Page'} $roman / $totalRoman •",
          style: TextStyle(
            color: const Color(0xFF8D6E63).withValues(alpha: 0.7),
            fontSize: 11,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
            fontFamily: 'serif',
          ),
        ),
      ),
    );
  }

  /// Góc trang trí hoa văn đồng cổ
  Widget _buildCornerOrnament(Alignment alignment) {
    return Positioned(
      top: alignment.y < 0 ? 12 : null,
      bottom: alignment.y > 0 ? 12 : null,
      left: alignment.x < 0 ? 12 : null,
      right: alignment.x > 0 ? 12 : null,
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.45,
          child: Text(
            alignment.y < 0
                ? (alignment.x < 0 ? '╔' : '╗')
                : (alignment.x < 0 ? '╚' : '╝'),
            style: const TextStyle(
              color: Color(0xFF8B2500),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'serif',
            ),
          ),
        ),
      ),
    );
  }

  /// =========================================================================
  /// BẢNG ĐIỀU HƯỚNG LẬT TRANG CƠ HỌC ĐỒNG CỔ DƯỚI CÙNG (ANTIQUE PAGE TURNER)
  /// =========================================================================
  Widget _buildAntiqueBottomPageTurner(int totalPages, bool isVi) {
    final romanNums = ['I', 'II', 'III', 'IV', 'V'];
    final currentRoman = _currentPage < romanNums.length ? romanNums[_currentPage] : '${_currentPage + 1}';
    final totalRoman = totalPages <= romanNums.length ? romanNums[totalPages - 1] : '$totalPages';

    final actTitlesVi = ['HỒI I: KHỞI HÀNH', 'HỒI II: ĐIỀM BÁO', 'HỒI III: CAO TRÀO', 'HỒI IV: HỒI KẾT'];
    final actTitlesEn = ['ACT I: DEPARTURE', 'ACT II: OMENS', 'ACT III: CLIMAX', 'ACT IV: EPILOGUE'];
    final actTitle = isVi
        ? (_currentPage < actTitlesVi.length ? actTitlesVi[_currentPage] : 'TRANG ${_currentPage + 1}')
        : (_currentPage < actTitlesEn.length ? actTitlesEn[_currentPage] : 'PAGE ${_currentPage + 1}');

    final bool canGoBack = _currentPage > 0;
    final bool canGoNext = _currentPage < totalPages - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF160E08),
        border: const Border(
          top: BorderSide(
            color: Color(0xFFD4AF37),
            width: 1.2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Nút Lật Về Trước
          InkWell(
            onTap: canGoBack ? _turnBackward : null,
            borderRadius: BorderRadius.circular(8),
            child: Opacity(
              opacity: canGoBack ? 1.0 : 0.35,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3E2812), Color(0xFF1E1308)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 13,
                      color: Color(0xFFFFD54F),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isVi ? 'Trang trước' : 'Previous',
                      style: const TextStyle(
                        color: Color(0xFFFFD54F),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'serif',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Trung tâm: Thông tin trang + Chuỗi hạt ngọc chỉ báo
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actTitle,
                  style: const TextStyle(
                    color: Color(0xFFFFD54F),
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    fontFamily: 'serif',
                  ),
                ),
                const SizedBox(height: 6),
                // Chuỗi hạt ngọc đồng
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(totalPages, (i) {
                    final isCurrent = i == _currentPage;
                    return GestureDetector(
                      onTap: () => _goToPage(i),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isCurrent ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: isCurrent
                              ? const Color(0xFFFFD54F)
                              : const Color(0xFF5D4037).withValues(alpha: 0.8),
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFFFD54F).withValues(alpha: 0.6),
                                    blurRadius: 6,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 2),
                Text(
                  '$currentRoman / $totalRoman',
                  style: TextStyle(
                    color: const Color(0xFFD7CCC8).withValues(alpha: 0.7),
                    fontSize: 9.5,
                    fontFamily: 'serif',
                  ),
                ),
              ],
            ),
          ),

          // Nút Lật Sang Sau / Đọc lại
          InkWell(
            onTap: canGoNext ? _turnForward : _restartStory,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: canGoNext
                      ? const [Color(0xFF3E2812), Color(0xFF1E1308)]
                      : const [Color(0xFF8A6517), Color(0xFF4A3408)],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.8),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.25),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    canGoNext
                        ? (isVi ? 'Trang sau' : 'Next')
                        : (isVi ? 'Đọc lại' : 'Replay'),
                    style: const TextStyle(
                      color: Color(0xFFFFD54F),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'serif',
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    canGoNext
                        ? Icons.arrow_forward_ios_rounded
                        : Icons.replay_rounded,
                    size: 13,
                    color: const Color(0xFFFFD54F),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// =========================================================================
  /// THANH CÔNG CỤ BẰNG ĐỒNG CỔ NẸP ĐẦU TRANG (ANTIQUE BRASS TOOLBAR)
  /// =========================================================================
  Widget _buildAntiqueToolbar(
    BuildContext context,
    bool isVi,
    LocaleService localeService,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF180F08).withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
            width: 1.2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Nút Quay lại thư viện: Huy hiệu đồng cổ
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3E2812), Color(0xFF221609)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.7),
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFFFFD54F),
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Tên chương nhỏ trên thanh đồng
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/images/icon/pirate-hat.png',
                      width: 16,
                      height: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isVi ? 'BẢN THẢO HẢI TRÌNH' : 'MARITIME CODEX',
                      style: const TextStyle(
                        color: Color(0xFFFFD54F),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        fontFamily: 'serif',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  widget.story.getAuthor(localeService.languageCode),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFFD7CCC8).withValues(alpha: 0.75),
                    fontSize: 10.5,
                    fontStyle: FontStyle.italic,
                    fontFamily: 'serif',
                  ),
                ),
              ],
            ),
          ),

          // Nút bật/tắt âm thanh sóng biển / bão biển: Chuông đồng cổ
          if (widget.story.ambientSound.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InkWell(
                onTap: _toggleAudio,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isPlayingSound
                          ? const [Color(0xFF8A6517), Color(0xFF5A400C)]
                          : const [Color(0xFF332010), Color(0xFF1E1308)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _isPlayingSound
                          ? const Color(0xFFFFD54F)
                          : const Color(0xFFD4AF37).withValues(alpha: 0.5),
                      width: 1.1,
                    ),
                    boxShadow: _isPlayingSound
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFFD54F).withValues(alpha: 0.45),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    _isPlayingSound
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    color: _isPlayingSound
                        ? const Color(0xFFFFF9C4)
                        : const Color(0xFFBCAAA4),
                    size: 18,
                  ),
                ),
              ),
            ),


          // Nút thu nhỏ chữ (A⁻)
          InkWell(
            onTap: () => _changeFontSize(-1.5),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 32,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF2B1A0D),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                  width: 0.9,
                ),
              ),
              alignment: Alignment.center,
              child: const Text(
                'A⁻',
                style: TextStyle(
                  color: Color(0xFFFFD54F),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'serif',
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Nút phóng to chữ (A⁺)
          InkWell(
            onTap: () => _changeFontSize(1.5),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 32,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF2B1A0D),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                  width: 0.9,
                ),
              ),
              alignment: Alignment.center,
              child: const Text(
                'A⁺',
                style: TextStyle(
                  color: Color(0xFFFFD54F),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'serif',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// =========================================================================
  /// PHẦN MỞ ĐẦU CHƯƠNG & BẢN THẢO SƠN DẦU (CHAPTER HEADER & FRONTISPIECE)
  /// =========================================================================
  Widget _buildChapterHeader(SailorStory story, String lang, bool isVi) {
    return Column(
      children: [
        // 1. Hoa văn Baroque chia chương
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 1.2,
              color: const Color(0xFF8D6E63).withValues(alpha: 0.6),
            ),
            const SizedBox(width: 8),
            const Text(
              "❖  LIBER NAUTICA  ❖",
              style: TextStyle(
                color: Color(0xFF8B2500), // Mực son đỏ cổ
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.2,
                fontFamily: 'serif',
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 40,
              height: 1.2,
              color: const Color(0xFF8D6E63).withValues(alpha: 0.6),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 2. Khung tranh sơn dầu mạ đồng cổ lồng ảnh hoặc video bìa
        _buildAntiqueOilPainting(story),

        const SizedBox(height: 18),

        // 3. Tiêu đề tác phẩm bằng mực nâu sepia đen cổ
        Text(
          story.getTitle(lang),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF2B190C),
            fontSize: 23,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
            height: 1.3,
            fontFamily: 'serif',
            shadows: [
              Shadow(
                color: Color(0xFFD7CCC8),
                offset: Offset(0, 1),
                blurRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 4. Lời tựa chép tay mực nâu óc chó
        if (story.getSubtitle(lang).isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              story.getSubtitle(lang),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF5D4037),
                fontSize: 13.5,
                fontStyle: FontStyle.italic,
                height: 1.45,
                fontFamily: 'serif',
              ),
            ),
          ),
        const SizedBox(height: 14),

        // 5. Thẻ ghi chép tác giả & thời gian đọc
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.history_edu_rounded,
              color: Color(0xFF8B2500),
              size: 15,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                "${isVi ? 'Ghi chép bởi' : 'Logged by'}: ${story.getAuthor(lang)}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF4E342E),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'serif',
                ),
              ),
            ),
            const SizedBox(width: 14),
            const Icon(
              Icons.hourglass_bottom_rounded,
              color: Color(0xFF8B2500),
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              "${story.readTimeMinutes} ${isVi ? 'phút' : 'min'}",
              style: const TextStyle(
                color: Color(0xFF4E342E),
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                fontFamily: 'serif',
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // 6. Dải hoa văn phân cách bằng vàng lá và mực son
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                height: 1.2,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Color(0xFF8D6E63),
                      Color(0xFFB8860B),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Icon(
                Icons.anchor_rounded,
                color: const Color(0xFF8B2500).withValues(alpha: 0.8),
                size: 16,
              ),
            ),
            Expanded(
              child: Container(
                height: 1.2,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFB8860B),
                      Color(0xFF8D6E63),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Khung tranh sơn dầu mạ đồng cổ lồng ảnh hoặc video bìa
  Widget _buildAntiqueOilPainting(SailorStory story) {
    final useVideo = story.isCoverVideo && story.effectiveCoverVideo.isNotEmpty;

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: const Color(0xFFB8860B),
          width: 2.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
            blurRadius: 8,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (useVideo)
            CachedCreatureVideoPlayer(
              key: ValueKey('reader_cover_vid_${story.storyId}_${story.effectiveCoverVideo}'),
              videoUrl: story.effectiveCoverVideo,
              placeholder: _buildImageWidget(story.coverImage, fit: BoxFit.cover),
              disableMask: true,
              fit: BoxFit.cover,
            )
          else
            _buildImageWidget(story.coverImage, fit: BoxFit.cover),
          // Lớp dầu bóng cổ kính
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.15),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.5),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Viền dập chìm bên trong khung tranh
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.45),
                width: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// =========================================================================
  /// NỘI DUNG TỪNG KHỐI TRUYỆN ĐA DẠNG HÓA (PARAGRAPHS, LOGS, WHISPERS, CLIMAX)
  /// =========================================================================
  List<Widget> _buildStoryBlocks(List<StoryBlock> blocks, String lang) {
    List<Widget> widgets = [];
    bool isFirstParagraph = true;

    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      switch (block.type) {
        case 'log_entry':
          widgets.add(_buildLogEntryBlock(block, lang));
          widgets.add(const SizedBox(height: 20));
          break;

        case 'whisper':
          widgets.add(_buildWhisperBlock(block, lang));
          widgets.add(const SizedBox(height: 20));
          break;

        case 'quote':
          widgets.add(_buildQuoteBlock(block, lang));
          widgets.add(const SizedBox(height: 22));
          break;

        case 'climax_quote':
          widgets.add(_buildClimaxQuoteBlock(block, lang));
          widgets.add(const SizedBox(height: 22));
          break;

        case 'epilogue_warning':
          widgets.add(_buildEpilogueWarningBlock(block, lang));
          widgets.add(const SizedBox(height: 22));
          break;

        case 'paragraph':
          widgets.add(
            _buildParagraphBlock(
              block.getText(lang),
              isFirstParagraph: isFirstParagraph,
            ),
          );
          widgets.add(const SizedBox(height: 18));
          isFirstParagraph = false;
          break;

        case 'image':
          widgets.add(_buildImageBlock(block, lang));
          widgets.add(const SizedBox(height: 24));
          break;

        case 'video':
          widgets.add(_buildVideoBlock(block, lang));
          widgets.add(const SizedBox(height: 24));
          break;
      }
    }
    return widgets;
  }

  /// 1. KHỐI NHẬT KÝ HẢI TRÌNH MỐC TỌA ĐỘ (LOG ENTRY BLOCK)
  Widget _buildLogEntryBlock(StoryBlock block, String lang) {
    final header = block.getHeader(lang);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0E5CE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF8B2500).withValues(alpha: 0.6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header.isNotEmpty)
            Row(
              children: [
                const Icon(
                  Icons.explore_rounded,
                  color: Color(0xFF8B2500),
                  size: 15,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    header,
                    style: const TextStyle(
                      color: Color(0xFF8B2500),
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontFamily: 'serif',
                    ),
                  ),
                ),
              ],
            ),
          if (header.isNotEmpty) const SizedBox(height: 8),
          Text(
            block.getText(lang),
            style: TextStyle(
              color: const Color(0xFF2B190C),
              fontSize: _fontSize - 0.5,
              height: 1.6,
              fontFamily: 'serif',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 2. KHỐI LỜI THÌ THÀO RUN RẨY CỦA THỦY THỦ (WHISPER BLOCK)
  Widget _buildWhisperBlock(StoryBlock block, String lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF24160E).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: const Color(0xFF8D6E63).withValues(alpha: 0.8),
            width: 3.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.record_voice_over_rounded,
            color: Color(0xFF8D6E63),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              block.getText(lang),
              style: TextStyle(
                color: const Color(0xFF4A3525),
                fontSize: _fontSize,
                fontStyle: FontStyle.italic,
                height: 1.55,
                fontFamily: 'serif',
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 3. KHỐI LỜI TUYỆT MỆNH TRƯỚC KHI TÀU CHÌM (CLIMAX QUOTE BLOCK)
  Widget _buildClimaxQuoteBlock(StoryBlock block, String lang) {
    final header = block.getHeader(lang);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE8D4BE),
            Color(0xFFDEC3AA),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFB71C1C),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB71C1C).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -14,
            right: 14,
            child: _buildWaxSealBadge(size: 38),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (header.isNotEmpty)
                  Row(
                    children: [
                      const Icon(
                        Icons.warning_rounded,
                        color: Color(0xFFB71C1C),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          header,
                          style: const TextStyle(
                            color: Color(0xFFB71C1C),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            fontFamily: 'serif',
                          ),
                        ),
                      ),
                    ],
                  ),
                if (header.isNotEmpty) const SizedBox(height: 10),
                Text(
                  block.getText(lang),
                  style: TextStyle(
                    color: const Color(0xFF26080A),
                    fontSize: _fontSize + 0.5,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    height: 1.6,
                    fontFamily: 'serif',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 4. KHỐI CẢNH BÁO CHO HẬU THẾ (EPILOGUE WARNING BLOCK)
  Widget _buildEpilogueWarningBlock(StoryBlock block, String lang) {
    final header = block.getHeader(lang);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF24150A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFD4AF37),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header.isNotEmpty)
            Row(
              children: [
                const Icon(
                  Icons.shield_rounded,
                  color: Color(0xFFFFD54F),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    header,
                    style: const TextStyle(
                      color: Color(0xFFFFD54F),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      fontFamily: 'serif',
                    ),
                  ),
                ),
              ],
            ),
          if (header.isNotEmpty) const SizedBox(height: 8),
          Text(
            block.getText(lang),
            style: TextStyle(
              color: const Color(0xFFFFF8E1),
              fontSize: _fontSize - 0.5,
              height: 1.6,
              fontStyle: FontStyle.italic,
              fontFamily: 'serif',
            ),
          ),
        ],
      ),
    );
  }

  /// Đoạn văn bản với chữ khởi đầu chương hoa văn Baroque (Illuminated Drop-Cap)
  Widget _buildParagraphBlock(String text, {bool isFirstParagraph = false}) {
    if (text.isEmpty) return const SizedBox.shrink();

    if (isFirstParagraph && text.isNotEmpty) {
      final firstLetter = text.substring(0, 1);
      final remainingText = text.substring(1);

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Con dấu chữ cái hoa đầu chương Baroque mạ vàng nền đỏ son (Illuminated Initial)
          Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.only(right: 12, top: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF991B1E), Color(0xFF6B1012)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFFD4AF37),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 5,
                  offset: const Offset(1, 2),
                ),
                BoxShadow(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                  blurRadius: 6,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              firstLetter,
              style: const TextStyle(
                color: Color(0xFFFFF9C4),
                fontSize: 27,
                fontWeight: FontWeight.bold,
                fontFamily: 'serif',
                shadows: [
                  Shadow(
                    color: Colors.black,
                    offset: Offset(1, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),

          // Phần chữ tiếp nối
          Expanded(
            child: Text(
              remainingText,
              textAlign: TextAlign.justify,
              style: TextStyle(
                color: const Color(0xFF26190F),
                fontSize: _fontSize,
                height: 1.72,
                letterSpacing: 0.35,
                fontFamily: 'serif',
              ),
            ),
          ),
        ],
      );
    }

    // Các đoạn văn sau có thụt đầu dòng nhẹ
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        textAlign: TextAlign.justify,
        style: TextStyle(
          color: const Color(0xFF26190F),
          fontSize: _fontSize,
          height: 1.72,
          letterSpacing: 0.35,
          fontFamily: 'serif',
        ),
      ),
    );
  }

  /// Khối trích dẫn chép tay phong thư có con dấu sáp đỏ niêm phong (Red Wax Seal Quote)
  Widget _buildQuoteBlock(StoryBlock block, String lang) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFE2C6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFBCAAA4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Con dấu sáp đỏ niêm phong ở góc trên bên trái
          Positioned(
            top: -14,
            left: 14,
            child: _buildWaxSealBadge(size: 36),
          ),

          // Nội dung lời nguyền / trích dẫn nhật ký chép tay
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 38),
                    Expanded(
                      child: Text(
                        "EXTRACTUM NAUTICUM",
                        style: TextStyle(
                          color: const Color(0xFF8B2500).withValues(alpha: 0.85),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          fontFamily: 'serif',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "“${block.getText(lang)}”",
                  style: TextStyle(
                    color: const Color(0xFF3E2723),
                    fontSize: _fontSize + 0.8,
                    fontStyle: FontStyle.italic,
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'serif',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Con dấu sáp đỏ niêm phong vật lý 3D (Red Wax Seal Badge)
  Widget _buildWaxSealBadge({double size = 38}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [
            Color(0xFFC62828),
            Color(0xFF8E1B1B),
            Color(0xFF530B0D),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFFF8A80).withValues(alpha: 0.4),
          width: 0.9,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Vòng ngấn dập nhiệt chìm của con dấu
          Container(
            width: size * 0.72,
            height: size * 0.72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF3E0708),
                width: 1.2,
              ),
            ),
          ),
          // Biểu tượng mỏ neo cổ mạ vàng dập nổi ở giữa con dấu sáp
          Icon(
            Icons.anchor_rounded,
            color: const Color(0xFFFFD54F),
            size: size * 0.52,
            shadows: const [
              Shadow(
                color: Colors.black,
                offset: Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Khung tranh minh họa đồng cổ Baroque dập đinh tán
  Widget _buildImageBlock(StoryBlock block, String lang) {
    final caption = block.getCaption(lang);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A1C12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFB8860B),
          width: 2.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(2, 6),
          ),
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.25),
            blurRadius: 6,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ảnh minh họa chính
          GestureDetector(
            onTap: () => _showFullImage(block.url, caption),
            child: AspectRatio(
              aspectRatio: 16 / 9.5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImageWidget(block.url, fit: BoxFit.cover),
                  // Dầu bóng vecni
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.1),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.4),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Nút kính lúp phóng to tranh
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFD4AF37),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.zoom_in_rounded,
                        color: Color(0xFFFFD54F),
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Dải chú thích ảnh bằng bản đồng cổ
          if (caption.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFF22150C),
                border: Border(
                  top: BorderSide(
                    color: Color(0xFFD4AF37),
                    width: 0.8,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.palette_rounded,
                    color: Color(0xFFFFD54F),
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      caption,
                      style: const TextStyle(
                        color: Color(0xFFE0D5C1),
                        fontSize: 12.5,
                        fontStyle: FontStyle.italic,
                        fontFamily: 'serif',
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

  /// Khung phát video biển sâu trong khung đồng cổ
  Widget _buildVideoBlock(StoryBlock block, String lang) {
    return _StoryAntiqueVideoPlayerWidget(
      key: ValueKey('video_${block.url}'),
      videoUrl: block.url,
      caption: block.getCaption(lang),
      isVi: lang == 'vi',
    );
  }

  void _showFullImage(String url, String caption) {
    showDialog(
      context: context,
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Color(0xFFFFD54F), size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: screenHeight * 0.65,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFD4AF37),
                      width: 2.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.8),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InteractiveViewer(
                    child: _buildImageWidget(url, fit: BoxFit.contain),
                  ),
                ),
              ),
              if (caption.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    caption,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFFFF8E1),
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      fontFamily: 'serif',
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageWidget(String path, {BoxFit fit = BoxFit.cover}) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFF1E130B),
          child: const Center(
            child: Icon(Icons.broken_image_rounded,
                color: Colors.white38, size: 40),
          ),
        ),
      );
    } else {
      return Image.asset(
        path,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFF1E130B),
          child: const Center(
            child: Icon(Icons.broken_image_rounded,
                color: Colors.white38, size: 40),
          ),
        ),
      );
    }
  }

  /// =========================================================================
  /// PHẦN KẾT THÚC CHƯƠNG & ẤN NIÊM PHONG HOÀNG GIA (STORY EPILOGUE)
  /// =========================================================================
  Widget _buildStoryEpilogue(bool isVi) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE0C4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFC2AF8C),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Con dấu sáp đỏ lớn ấn phong Bộ Chỉ Huy Hoàng Gia
          _buildWaxSealBadge(size: 54),

          const SizedBox(height: 14),

          Text(
            isVi ? '— ❖ HẾT HỒI KÝ SỰ ❖ —' : '— ❖ END OF CHRONICLE ❖ —',
            style: const TextStyle(
              color: Color(0xFF8B2500),
              fontWeight: FontWeight.bold,
              fontSize: 15,
              letterSpacing: 2.2,
              fontFamily: 'serif',
            ),
          ),
          const SizedBox(height: 8),

          Text(
            isVi
                ? 'Bạn vừa khám phá trọn vẹn chương ghi chép này của cổ thư hải trình. Bản thảo đã được niêm phong lưu trữ.'
                : 'You have explored this entire chapter of the maritime enigma. The manuscript is sealed.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF4E342E),
              fontSize: 13,
              fontStyle: FontStyle.italic,
              height: 1.45,
              fontFamily: 'serif',
            ),
          ),
          const SizedBox(height: 20),

          // Nút bấm đồng dập nổi "Đọc Ký Sự Khác"
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF8C6420),
                    Color(0xFFD4AF37),
                    Color(0xFFFFF9C4),
                    Color(0xFFD4AF37),
                    Color(0xFF6B4810),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFFF9C4),
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.auto_stories_rounded,
                    color: Color(0xFF1E1002),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isVi ? 'ĐỌC BẢN THẢO KHÁC' : 'EXPLORE OTHER TOMES',
                    style: const TextStyle(
                      color: Color(0xFF1E1002),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      fontFamily: 'serif',
                    ),
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

/// =========================================================================
/// WIDGET PHÁT VIDEO TRONG KHUNG ĐỒNG CỔ BAROQUE
/// =========================================================================
class _StoryAntiqueVideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final String caption;
  final bool isVi;

  const _StoryAntiqueVideoPlayerWidget({
    super.key,
    required this.videoUrl,
    required this.caption,
    this.isVi = true,
  });

  @override
  State<_StoryAntiqueVideoPlayerWidget> createState() =>
      _StoryAntiqueVideoPlayerWidgetState();
}

class _StoryAntiqueVideoPlayerWidgetState
    extends State<_StoryAntiqueVideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isMuted = true;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  String _resolvePlayableUrl(String url) {
    if (url.contains('Rise%20of%20The%20Kraken') ||
        url.contains('davy_jones')) {
      return 'https://codego.io.vn/api/uploads/videos/Rise%20of%20The%20Kraken%2C%20Coming%202027.%20%23creative%20%23vfx%20%23movie%20%23monster%20%23kraken.mp4';
    }
    if (url.startsWith('https://codego.io.vn/') && !url.contains('?')) {
      return '$url?v=2';
    }
    return url;
  }

  @override
  void didUpdateWidget(covariant _StoryAntiqueVideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _controller?.pause();
      _controller?.dispose();
      _controller = null;
      _isInitialized = false;
      _isLoading = true;
      _hasError = false;
      _initVideo();
    }
  }

  void _initVideo() async {
    final playable = _resolvePlayableUrl(widget.videoUrl);
    if (playable.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
      return;
    }
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(playable));
      await _controller!.initialize();
      _controller!.setLooping(true);
      _controller!.setVolume(0.0);
      _controller!.play();
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.pause();
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    });
  }

  void _toggleMute() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      _isMuted = !_isMuted;
      _controller!.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A1C12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFB8860B),
          width: 2.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 14,
            offset: const Offset(2, 6),
          ),
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.25),
            blurRadius: 6,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9.5,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_isInitialized && _controller != null)
                  GestureDetector(
                    onTap: _togglePlayPause,
                    child: SizedBox.expand(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _controller!.value.size.width,
                          height: _controller!.value.size.height,
                          child: VideoPlayer(_controller!),
                        ),
                      ),
                    ),
                  )
                else if (_isLoading)
                  Container(
                    color: const Color(0xFF1E130B),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFFFFD54F)),
                        strokeWidth: 2.2,
                      ),
                    ),
                  )
                else if (_hasError)
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isLoading = true;
                        _hasError = false;
                      });
                      _initVideo();
                    },
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 0.95,
                          colors: [
                            Color(0xFF2E1C10),
                            Color(0xFF130C07),
                          ],
                        ),
                      ),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF1C1108),
                              border: Border.all(
                                color:
                                    const Color(0xFFD4AF37).withValues(alpha: 0.65),
                                width: 1.4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFD4AF37)
                                      .withValues(alpha: 0.25),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.movie_creation_outlined,
                              color: Color(0xFFFFD54F),
                              size: 26,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.isVi
                                ? 'THƯỚC PHIM HẢI VĂN ĐANG PHỤC CHẾ'
                                : 'NAVAL ARCHIVE FOOTAGE RESTORING',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFFFD54F),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                              fontFamily: 'serif',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.isVi
                                ? 'Tài liệu lưu trữ tại Văn khố Hải quân. Tự động chiếu khi hoàn tất kết nối máy chủ.'
                                : 'Archived in Admiralty Records. Auto-plays once server connection is established.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color:
                                  const Color(0xFFD7CCC8).withValues(alpha: 0.8),
                              fontSize: 10.5,
                              fontStyle: FontStyle.italic,
                              fontFamily: 'serif',
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFD4AF37)
                                    .withValues(alpha: 0.5),
                                width: 0.8,
                              ),
                              color: const Color(0xFF1E130B),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.refresh_rounded,
                                    size: 13, color: Color(0xFFFFD54F)),
                                const SizedBox(width: 4),
                                Text(
                                  widget.isVi
                                      ? 'Chạm để kết nối lại'
                                      : 'Tap to reconnect',
                                  style: const TextStyle(
                                    color: Color(0xFFFFD54F),
                                    fontSize: 10,
                                    fontFamily: 'serif',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(color: const Color(0xFF1E130B)),

                // Bảng điều khiển video cơ khí đồng cổ
                if (_isInitialized && _controller != null)
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Nút Play / Pause đồng tròn
                        InkWell(
                          onTap: _togglePlayPause,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF3E2812), Color(0xFF1C1207)],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFD4AF37),
                                width: 1.1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(
                              _controller!.value.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: const Color(0xFFFFD54F),
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Nút Tắt / Bật tiếng đồng tròn
                        InkWell(
                          onTap: _toggleMute,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF3E2812), Color(0xFF1C1207)],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFD4AF37),
                                width: 1.1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(
                              _isMuted
                                  ? Icons.volume_off_rounded
                                  : Icons.volume_up_rounded,
                              color: _isMuted
                                  ? const Color(0xFFBCAAA4)
                                  : const Color(0xFFFFD54F),
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Dải chú thích video bằng bản đồng
          if (widget.caption.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFF22150C),
                border: Border(
                  top: BorderSide(
                    color: Color(0xFFD4AF37),
                    width: 0.8,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.movie_creation_outlined,
                    color: Color(0xFFFFD54F),
                    size: 15,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.caption,
                      style: const TextStyle(
                        color: Color(0xFFE0D5C1),
                        fontSize: 12.5,
                        fontStyle: FontStyle.italic,
                        fontFamily: 'serif',
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
}

/// =========================================================================
/// MÔ HÌNH HÌNH HỌC NẾP GẤP TRANG SÁCH CHUẨN STPAGEFLIP (CREASE GEOMETRY)
/// Tính toán đường phân giác lột góc chéo, đa giác phẳng và đa giác hé lộ
/// =========================================================================
class CreaseGeometry {
  final Size pageSize;
  final double progress;
  final double touchYRatio;
  final Offset? p1;
  final Offset? p2;
  final bool hasCrease;
  final List<Offset> unfoldedPoly;
  final List<Offset> revealedPoly;

  const CreaseGeometry({
    required this.pageSize,
    required this.progress,
    required this.touchYRatio,
    this.p1,
    this.p2,
    required this.hasCrease,
    required this.unfoldedPoly,
    required this.revealedPoly,
  });

  factory CreaseGeometry.compute(
    Size size,
    double progress,
    double touchYRatio,
  ) {
    if (size.isEmpty || size.width <= 0 || size.height <= 0) {
      return CreaseGeometry(
        pageSize: size,
        progress: progress,
        touchYRatio: touchYRatio,
        hasCrease: false,
        unfoldedPoly: const [],
        revealedPoly: const [],
      );
    }

    final double w = size.width;
    final double h = size.height;
    final List<Offset> rectCorners = [
      Offset.zero,
      Offset(w, 0),
      Offset(w, h),
      Offset(0, h),
    ];

    if (progress <= 0.001) {
      return CreaseGeometry(
        pageSize: size,
        progress: progress,
        touchYRatio: touchYRatio,
        hasCrease: false,
        unfoldedPoly: rectCorners,
        revealedPoly: const [],
      );
    }

    if (progress >= 0.999) {
      return CreaseGeometry(
        pageSize: size,
        progress: progress,
        touchYRatio: touchYRatio,
        hasCrease: false,
        unfoldedPoly: const [],
        revealedPoly: rectCorners,
      );
    }

    // Xác định góc kéo (Góc đáy hay góc trên theo vị trí chạm của ngón tay)
    final bool isBottomCorner = touchYRatio >= 0.5;
    final double yCorner = isBottomCorner ? h : 0.0;
    final Offset oc = Offset(w, yCorner);

    // Điểm góc bị kéo C(xc, yc) theo động học lật sách tự nhiên
    final double xc = w - 2.15 * progress * w;
    final double bendDirection = isBottomCorner ? -1.0 : 1.0;
    final double yc = yCorner + bendDirection * 0.32 * h * math.sin(progress * math.pi);
    final Offset c = Offset(xc, yc);

    // Trung điểm nếp gấp M và Vector hướng kéo V
    final Offset m = Offset((oc.dx + c.dx) / 2, (oc.dy + c.dy) / 2);
    final Offset v = Offset(c.dx - oc.dx, c.dy - oc.dy);
    final double vLen = math.sqrt(v.dx * v.dx + v.dy * v.dy);

    if (vLen < 1e-4) {
      return CreaseGeometry(
        pageSize: size,
        progress: progress,
        touchYRatio: touchYRatio,
        hasCrease: false,
        unfoldedPoly: rectCorners,
        revealedPoly: const [],
      );
    }

    // Vector pháp tuyến nếp gấp hướng về phía trang phẳng chưa lật (sang trái)
    final double nx = v.dx / vLen;
    final double ny = v.dy / vLen;

    // Khoảng cách có dấu đến đường nếp gấp:
    // >= 0: Thuộc nửa mặt phẳng phẳng trên bàn (Unfolded)
    // < 0: Thuộc nửa mặt phẳng đã lột góc hé lộ trang dưới (Revealed)
    double signedDist(Offset p) {
      return (p.dx - m.dx) * nx + (p.dy - m.dy) * ny;
    }

    // Thuật toán cắt đa giác Sutherland-Hodgman chuẩn xác cho GPU Canvas
    List<Offset> clipPolygon(List<Offset> poly, bool Function(double) keepInside) {
      final List<Offset> output = [];
      if (poly.isEmpty) return output;
      for (int i = 0; i < poly.length; i++) {
        final cur = poly[i];
        final next = poly[(i + 1) % poly.length];
        final dCur = signedDist(cur);
        final dNext = signedDist(next);

        final bool curInside = keepInside(dCur);
        final bool nextInside = keepInside(dNext);

        if (curInside) {
          output.add(cur);
          if (!nextInside) {
            final t = (dCur / (dCur - dNext)).clamp(0.0, 1.0);
            output.add(Offset.lerp(cur, next, t)!);
          }
        } else if (nextInside) {
          final t = (dCur / (dCur - dNext)).clamp(0.0, 1.0);
          output.add(Offset.lerp(cur, next, t)!);
        }
      }
      return output;
    }

    final unfolded = clipPolygon(rectCorners, (d) => d >= 0);
    final revealed = clipPolygon(rectCorners, (d) => d < 0);

    // Tìm 2 giao điểm nếp gấp cắt qua các cạnh của khung trang sách
    final List<Offset> intersections = [];
    for (int i = 0; i < rectCorners.length; i++) {
      final a = rectCorners[i];
      final b = rectCorners[(i + 1) % rectCorners.length];
      final da = signedDist(a);
      final db = signedDist(b);
      if ((da > 0 && db < 0) || (da < 0 && db > 0)) {
        final t = (da / (da - db)).clamp(0.0, 1.0);
        intersections.add(Offset.lerp(a, b, t)!);
      } else if (da.abs() < 1e-4) {
        if (!intersections.any((p) => (p - a).distance < 1.0)) {
          intersections.add(a);
        }
      }
    }

    Offset? p1;
    Offset? p2;
    bool hasCrease = false;

    if (intersections.length >= 2) {
      intersections.sort((a, b) => a.dy.compareTo(b.dy));
      p1 = intersections.first;
      p2 = intersections.last;
      if ((p2 - p1).distance > 2.0) {
        hasCrease = true;
      } else {
        p1 = null;
        p2 = null;
      }
    }

    return CreaseGeometry(
      pageSize: size,
      progress: progress,
      touchYRatio: touchYRatio,
      p1: p1,
      p2: p2,
      hasCrease: hasCrease,
      unfoldedPoly: unfolded,
      revealedPoly: revealed,
    );
  }
}

/// =========================================================================
/// CLIPPER TRANG HIỆN TẠI (PHẦN NẰM PHẲNG BÊN TRÁI NẾP GẤP)
/// =========================================================================
class PageUnfoldedClipper extends CustomClipper<Path> {
  final CreaseGeometry crease;

  PageUnfoldedClipper(this.crease);

  @override
  Path getClip(Size size) {
    final Path path = Path();
    if (crease.unfoldedPoly.length >= 3) {
      path.addPolygon(crease.unfoldedPoly, true);
    }
    return path;
  }

  @override
  bool shouldReclip(covariant PageUnfoldedClipper oldClipper) {
    return oldClipper.crease != crease;
  }
}

/// =========================================================================
/// CLIPPER TRANG BÊN DƯỚI (PHẦN HÉ LỘ QUA GÓC LỘT BÊN PHẢI NẾP GẤP)
/// =========================================================================
class PageRevealedClipper extends CustomClipper<Path> {
  final CreaseGeometry crease;

  PageRevealedClipper(this.crease);

  @override
  Path getClip(Size size) {
    final Path path = Path();
    if (crease.revealedPoly.length >= 3) {
      path.addPolygon(crease.revealedPoly, true);
    }
    return path;
  }

  @override
  bool shouldReclip(covariant PageRevealedClipper oldClipper) {
    return oldClipper.crease != crease;
  }
}

/// =========================================================================
/// PAINTER ĐỒ HỌA UỐN CONG 3D CHUẨN STPAGEFLIP (3D CURL, SHADOW & SPECULAR)
/// =========================================================================
class StPageCurlPainter extends CustomPainter {
  final CreaseGeometry crease;
  final double progress;
  final bool isForward;

  StPageCurlPainter({
    required this.crease,
    required this.progress,
    required this.isForward,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!crease.hasCrease || crease.p1 == null || crease.p2 == null) {
      return;
    }

    final Offset p1 = crease.p1!;
    final Offset p2 = crease.p2!;

    final Offset lineVec = p2 - p1;
    final double lineLen = lineVec.distance;
    if (lineLen < 1.0) return;

    // Vector đơn vị chỉ phương dọc nếp gấp
    final Offset dir = lineVec / lineLen;
    // Vector pháp tuyến hướng sang phía hé lộ trang dưới (Revealed side / sang phải)
    final Offset nRevealed = Offset(dir.dy, -dir.dx);
    // Vector pháp tuyến hướng sang phía phẳng của trang sách (Unfolded side / sang trái)
    final Offset nUnfolded = -nRevealed;

    canvas.save();
    canvas.clipRect(Offset.zero & size);

    final double sinP = math.sin(progress.clamp(0.0, 1.0) * math.pi);

    // 1. ĐỔ BÓNG TRANG SÁCH LƠ LỬNG LÊN TRANG DƯỚI (Outer Drop Shadow)
    final double shadowWidth = (28.0 + 44.0 * sinP).clamp(16.0, 75.0);
    final Path shadowPath = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p2.dx + nRevealed.dx * shadowWidth, p2.dy + nRevealed.dy * shadowWidth)
      ..lineTo(p1.dx + nRevealed.dx * shadowWidth, p1.dy + nRevealed.dy * shadowWidth)
      ..close();

    final Paint shadowPaint = Paint()
      ..shader = ui.Gradient.linear(
        p1,
        p1 + nRevealed * shadowWidth,
        [
          Colors.black.withValues(alpha: 0.42 * (0.4 + 0.6 * sinP)),
          Colors.black.withValues(alpha: 0.16 * sinP),
          Colors.transparent,
        ],
        [0.0, 0.45, 1.0],
      );
    canvas.drawPath(shadowPath, shadowPaint);

    // 2. ĐỔ BÓNG LÒNG MÁNG NẾP GẤP (Inner Crease Valley Shadow)
    final double valleyWidth = (16.0 + 16.0 * sinP).clamp(10.0, 32.0);
    final Path valleyPath = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p2.dx + nUnfolded.dx * valleyWidth, p2.dy + nUnfolded.dy * valleyWidth)
      ..lineTo(p1.dx + nUnfolded.dx * valleyWidth, p1.dy + nUnfolded.dy * valleyWidth)
      ..close();

    final Paint valleyPaint = Paint()
      ..shader = ui.Gradient.linear(
        p1,
        p1 + nUnfolded * valleyWidth,
        [
          const Color(0xFF26180E).withValues(alpha: 0.38),
          Colors.transparent,
        ],
        const [0.0, 1.0],
      );
    canvas.drawPath(valleyPath, valleyPaint);

    // 3. ỐNG CUỘN GIẤY 3D UỐN LƯỢN (3D Cylindrical Paper Roll)
    final double curlRadius = (12.0 + 20.0 * sinP).clamp(8.0, 32.0);
    final double curlWidth = curlRadius * 2.0;

    final Offset p1Left = p1 + nUnfolded * (curlWidth * 0.25);
    final Offset p2Left = p2 + nUnfolded * (curlWidth * 0.25);
    final Offset p2Right = p2 + nRevealed * (curlWidth * 0.75);
    final Offset p1Right = p1 + nRevealed * (curlWidth * 0.75);

    final Path curlPath = Path()
      ..moveTo(p1Left.dx, p1Left.dy)
      ..lineTo(p2Left.dx, p2Left.dy)
      ..lineTo(p2Right.dx, p2Right.dy)
      ..lineTo(p1Right.dx, p1Right.dy)
      ..close();

    final Paint curlPaint = Paint()
      ..shader = ui.Gradient.linear(
        p1Left,
        p1Right,
        [
          const Color(0xFFC4B494).withValues(alpha: 0.5), // Lòng nếp gấp
          const Color(0xFFF4EAD2),                         // Thân giấy da
          const Color(0xFFFFFFFD),                         // Đỉnh vòm đón sáng (Specular Ridge)
          const Color(0xFFDFCDA3),                         // Phần giấy cong xuống
          const Color(0xFF8B6B48).withValues(alpha: 0.65), // Mép cuộn khuất sáng
        ],
        const [0.0, 0.28, 0.50, 0.78, 1.0],
      );
    canvas.drawPath(curlPath, curlPaint);

    // 4. ĐƯỜNG GÂN SÁNG PHẢN QUANG DỌC ĐỈNH UỐN (Specular Highlight Crest Line)
    final Offset crest1 = p1 + nRevealed * (curlWidth * 0.18);
    final Offset crest2 = p2 + nRevealed * (curlWidth * 0.18);

    final Paint crestPaint = Paint()
      ..shader = ui.Gradient.linear(
        crest1,
        crest2,
        [
          Colors.white.withValues(alpha: 0.2),
          Colors.white.withValues(alpha: 0.85),
          Colors.white.withValues(alpha: 0.2),
        ],
        const [0.0, 0.5, 1.0],
      )
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    canvas.drawLine(crest1, crest2, crestPaint);

    // 5. VIỀN CHỈ ĐỒNG CỔ MÉP NẾP GẤP (Antique Brass Accent Line)
    final Paint edgeLinePaint = Paint()
      ..color = const Color(0xFFB8860B).withValues(alpha: 0.35)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawLine(p1, p2, edgeLinePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant StPageCurlPainter oldDelegate) {
    return oldDelegate.crease != crease ||
        oldDelegate.progress != progress ||
        oldDelegate.isForward != isForward;
  }
}
