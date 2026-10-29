import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sailor_story.dart';
import '../services/data_service.dart';
import '../services/locale_service.dart';
import '../services/sound_service.dart';
import '../widgets/cached_video_player.dart';
import 'story_reader_screen.dart';
import 'video_screen.dart';

class StoryListScreen extends StatefulWidget {
  const StoryListScreen({super.key});

  @override
  State<StoryListScreen> createState() => _StoryListScreenState();
}

class _StoryListScreenState extends State<StoryListScreen> {
  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<DataService>(context);
    final localeService = Provider.of<LocaleService>(context);
    final isVi = localeService.isVietnamese;
    final lang = localeService.languageCode;
    final stories = dataService.stories;
    final hasPremium = dataService.hasAnyPremium;

    return Scaffold(
      backgroundColor: const Color(0xFF0C0805),
      body: Stack(
        children: [
          // ========================================================
          // NỀN BÀN GỖ GỤ CỔ ĐIỂN THƯ PHÒNG THUYỀN TRƯỞNG (ANTIQUE OAK DESK)
          // ========================================================
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.5),
                  radius: 1.2,
                  colors: [
                    Color(0xFF1E140C), // Vùng sáng đèn dầu ở giữa
                    Color(0xFF120C07),
                    Color(0xFF080503), // Tối dần về các góc
                  ],
                ),
              ),
            ),
          ),

          // Vệt sáng đèn dầu vàng ấm áp rọi từ trên trần cabin
          Positioned(
            top: -60,
            left: 0,
            right: 0,
            height: 280,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 0.9,
                    colors: [
                      const Color(0xFFFFD54F).withValues(alpha: 0.16),
                      const Color(0xFFB8860B).withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Hoa văn mờ hải đồ la bàn cổ (Antique Sea Chart Compass Watermark)
          Positioned(
            right: -80,
            top: 140,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.035,
                child: Icon(
                  Icons.explore_rounded,
                  size: 320,
                  color: const Color(0xFFFFD54F),
                ),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                // ========================================================
                // THANH TIÊU ĐỀ PHONG CÁCH BẢNG ĐỒNG CỔ (ANTIQUE BRASS APP BAR)
                // ========================================================
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Nút Back huy hiệu đồng cổ
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3E2812), Color(0xFF221609)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFD4AF37).withValues(alpha: 0.7),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Color(0xFFFFD54F),
                            size: 17,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Tiêu đề Thư Viện Cổ Thư Hải Trình
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Image.asset(
                                  'assets/images/icon/pirate-hat.png',
                                  width: 22,
                                  height: 22,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isVi
                                        ? 'CỔ THƯ HẢI TRÌNH'
                                        : 'MARITIME ARCHIVES',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFFFFF8E1),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                      fontFamily: 'serif',
                                      shadows: [
                                        Shadow(
                                          color: Color(0xFFD4AF37),
                                          blurRadius: 10,
                                        ),
                                        Shadow(
                                          color: Colors.black,
                                          blurRadius: 4,
                                          offset: Offset(1, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isVi
                                  ? 'Nhật ký & Bản thảo biển sâu thế kỷ XVIII'
                                  : '18th Century Logs & Abyssal Tomes',
                              style: TextStyle(
                                color: const Color(0xFFD7CCC8).withValues(alpha: 0.7),
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                fontFamily: 'serif',
                              ),
                            ),
                          ],
                        ),
                      ),

                    ],
                  ),
                ),

                // ========================================================
                // DANH SÁCH CUỐN SÁCH CỔ TRÊN KỆ GỖ (THE ANTIQUE BOOKSHELF)
                // ========================================================
                Expanded(
                  child: RefreshIndicator(
                    color: const Color(0xFFFFD54F),
                    backgroundColor: const Color(0xFF1E140C),
                    onRefresh: () async {
                      await dataService.loadData();
                    },
                    child: stories.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFFFFD54F)),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  isVi
                                      ? 'Đang mở khóa thư phòng hải trình...'
                                      : 'Retrieving ancient nautical logs...',
                                  style: const TextStyle(
                                    color: Color(0xFFD7CCC8),
                                    fontFamily: 'serif',
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 36),
                            itemCount: stories.length,
                            itemBuilder: (context, index) {
                              final story = stories[index];
                              return RealisticWesternBookCard(
                                story: story,
                                isVi: isVi,
                                lang: lang,
                                hasPremium: hasPremium,
                              );
                            },
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
/// =========================================================================
/// CÁC LOẠI HIỆU ỨNG PHONG HÓA BÌA CỔ (1 CARD 1 KIỂU HIỆU ỨNG ĐỘC BẢN)
/// =========================================================================
enum BookDistressType {
  /// 1. Davy Jones: Vết xước vôi san hô sắc nhọn & váng muối biển cổ đóng dạt mép
  saltScratches,

  /// 2. Black Pearl: Vết chém gươm hải tặc bạo liệt & nứt nẻ thớ gỗ chiến thuyền
  woodBattleSlash,

  /// 3. Bermuda Triangle: Quầng ố ngấm nước biển & vết sờn rách mép da lộ sợi vải lót
  waterStainsTears,

  /// 4. Cthulhu Abyss: Ba vết cào móng vuốt thực thể sâu thẳm & góc bìa cháy sém than đen
  scorchedClawMarks,

  /// 5. Mariana Trench: Vùng mài mòn bạc da lâu năm & mạng rạn nứt chân chim craquelure
  expeditionScuffs,
}

/// =========================================================================
/// THEME 5 DẠNG BÌA DA THUỘC CỔ ĐIỂN PHƯƠNG TÂY (WESTERN LEATHER BINDING THEMES)
/// =========================================================================
class WesternBookTheme {
  final List<Color> leatherGradient;
  final Color leatherPatina; // Vệt sẫm mép da lâu năm
  final Color spineBase;
  final Color goldFoil; // Vàng lá dập nóng 24k
  final Color goldHighlight;
  final Color claspBrass;
  final String bookCategory;
  final bool isWood;
  final BookDistressType distressType; // Kiểu hiệu ứng cũ / xước / rách độc bản

  const WesternBookTheme({
    required this.leatherGradient,
    required this.leatherPatina,
    required this.spineBase,
    required this.goldFoil,
    required this.goldHighlight,
    required this.claspBrass,
    required this.bookCategory,
    this.isWood = false,
    required this.distressType,
  });

  static WesternBookTheme getForStory(String storyId, bool isVi) {
    switch (storyId) {
      case 'davy_jones':
        return WesternBookTheme(
          leatherGradient: const [
            Color(0xFF133658), // Da thuộc xanh hải quân Bắc Đại Tây Dương
            Color(0xFF205284),
            Color(0xFF18416B),
          ],
          leatherPatina: const Color(0xFF0A1C30),
          spineBase: const Color(0xFF0E253E),
          goldFoil: const Color(0xFFFFD54F),
          goldHighlight: const Color(0xFFFFF9C4),
          claspBrass: const Color(0xFFE5C158),
          bookCategory: isVi
              ? '✦ HẢI KÝ BẮC HẢI • DA XANH NAVY ✦'
              : '✦ NORTH ATLANTIC • NAVY LEATHER ✦',
          isWood: false,
          distressType: BookDistressType.saltScratches,
        );

      case 'black_pearl':
        return WesternBookTheme(
          leatherGradient: const [
            Color(0xFF632814), // Bìa gỗ gụ đỏ tàu chiến cướp biển đánh vecni
            Color(0xFF883C21),
            Color(0xFF5A2311),
          ],
          leatherPatina: const Color(0xFF2C0F06),
          spineBase: const Color(0xFF3B1508),
          goldFoil: const Color(0xFFFFE082),
          goldHighlight: const Color(0xFFFFF8E1),
          claspBrass: const Color(0xFFD4AF37),
          bookCategory: isVi
              ? '✦ BẢN KÝ SỰ TÀU MA • BÌA GỖ GỤ ✦'
              : '✦ GHOST SHIP • MAHOGANY WOOD ✦',
          isWood: true,
          distressType: BookDistressType.woodBattleSlash,
        );

      case 'bermuda_triangle':
        return WesternBookTheme(
          leatherGradient: const [
            Color(0xFF17594B), // Da thuộc xanh ngọc lục bảo đại dương cổ
            Color(0xFF247A68),
            Color(0xFF1B6354),
          ],
          leatherPatina: const Color(0xFF092922),
          spineBase: const Color(0xFF0F3A31),
          goldFoil: const Color(0xFFE5CF7B),
          goldHighlight: const Color(0xFFFFF8D6),
          claspBrass: const Color(0xFFC7B061),
          bookCategory: isVi
              ? '✦ MẬT TẬP VÙNG CHẾT • DA LỤC BẢO ✦'
              : '✦ BERMUDA • EMERALD LEATHER ✦',
          isWood: false,
          distressType: BookDistressType.waterStainsTears,
        );

      case 'cthulhu_abyss':
        return WesternBookTheme(
          leatherGradient: const [
            Color(0xFF751C26), // Da thuộc đỏ mận rượu vang Cordovan
            Color(0xFF9E2A37),
            Color(0xFF691721),
          ],
          leatherPatina: const Color(0xFF38090F),
          spineBase: const Color(0xFF480D14),
          goldFoil: const Color(0xFFFFD54F),
          goldHighlight: const Color(0xFFFFF9C4),
          claspBrass: const Color(0xFFE5B842),
          bookCategory: isVi
              ? '✦ CỔ THƯ R\'LYEH • DA ĐỎ RƯỢU ✦'
              : '✦ R\'LYEH CODEX • OXBLOOD LEATHER ✦',
          isWood: false,
          distressType: BookDistressType.scorchedClawMarks,
        );

      case 'mariana_trench':
      default:
        // Đảm bảo các truyện khác nhau nếu có id mới vẫn có hiệu ứng độc bản phân bổ đều
        final fallbackType = BookDistressType.values[
            storyId.hashCode.abs() % BookDistressType.values.length];

        return WesternBookTheme(
          leatherGradient: const [
            Color(0xFF7A4A1E), // Da bò mộc nâu vàng hổ phách Saddle Tan
            Color(0xFF9E632D),
            Color(0xFF6E4018),
          ],
          leatherPatina: const Color(0xFF3B200A),
          spineBase: const Color(0xFF4A2A0F),
          goldFoil: const Color(0xFFFFEA8A),
          goldHighlight: const Color(0xFFFFFDF0),
          claspBrass: const Color(0xFFE6C158),
          bookCategory: isVi
              ? '✦ NHẬT KÝ 11.000M • DA NÂU HỔ PHÁCH ✦'
              : '✦ HADAL LOG • SADDLE TAN LEATHER ✦',
          isWood: false,
          distressType: storyId == 'mariana_trench'
              ? BookDistressType.expeditionScuffs
              : fallbackType,
        );
    }
  }
}

/// =========================================================================
/// WIDGET CARD CUỐN SÁCH CỔ PHƯƠNG TÂY (AUTHENTIC WESTERN TOME CARD)
/// =========================================================================
class RealisticWesternBookCard extends StatefulWidget {
  final SailorStory story;
  final bool isVi;
  final String lang;
  final bool hasPremium;

  const RealisticWesternBookCard({
    super.key,
    required this.story,
    required this.isVi,
    required this.lang,
    required this.hasPremium,
  });

  @override
  State<RealisticWesternBookCard> createState() =>
      _RealisticWesternBookCardState();
}

class _RealisticWesternBookCardState extends State<RealisticWesternBookCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _openController;
  late final Animation<double> _openAnimation;
  late final Animation<double> _lightAnimation;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _openController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _openAnimation = CurvedAnimation(
      parent: _openController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _lightAnimation = CurvedAnimation(
      parent: _openController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _openController.dispose();
    super.dispose();
  }

  void _triggerBookOpen() async {
    if (_isNavigating) return;

    final isLocked = widget.story.isVip && !widget.hasPremium;
    if (isLocked) {
      showVipUnlockBottomSheet(
        context,
        onPurchaseSuccess: () {
          if (mounted) {
            _executeBookOpenTransition();
          }
        },
      );
      return;
    }

    _executeBookOpenTransition();
  }

  void _executeBookOpenTransition() async {
    setState(() {
      _isNavigating = true;
    });

    try {
      Provider.of<SoundService>(context, listen: false).playPageFlipSound();
    } catch (_) {}

    // 1. Chạy animation mở bìa sách 3D vật lý
    await _openController.forward();

    if (!mounted) return;

    // 2. Chuyển cảnh CapCut Cinematic: Camera Zoom-In lao thẳng vào bên trong trang sách
    await Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 650),
        reverseTransitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (context, animation, secondaryAnimation) =>
            StoryReaderScreen(story: widget.story),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final zoomCurve = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubicEmphasized,
          );
          final fadeCurve = CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.75, curve: Curves.easeIn),
          );

          return AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              final scale = 0.82 + (zoomCurve.value * 0.18);
              final dynamicRotate = (1.0 - zoomCurve.value) * 0.035;

              return Transform.scale(
                scale: scale,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateZ(dynamicRotate),
                  child: Opacity(
                    opacity: fadeCurve.value,
                    child: Stack(
                      children: [
                        child,
                        // Ánh hào quang nến vàng lóe lên chuyển cảnh
                        if (animation.value < 0.75)
                          IgnorePointer(
                            child: Opacity(
                              opacity: ((1.0 - (animation.value / 0.75)) * 0.6)
                                  .clamp(0.0, 1.0),
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: RadialGradient(
                                    colors: [
                                      Color(0xFFFFECB3),
                                      Color(0xFFFFD54F),
                                      Colors.transparent,
                                    ],
                                    radius: 0.9,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );

    // 3. Khi bấm quay lại, bìa sách khép lại nhẹ nhàng trên kệ
    if (mounted) {
      await _openController.reverse();
      setState(() {
        _isNavigating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.story;
    final theme = WesternBookTheme.getForStory(story.storyId, widget.isVi);
    final isLocked = story.isVip && !widget.hasPremium;

    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: GestureDetector(
        onTap: _triggerBookOpen,
        child: SizedBox(
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ========================================================
              // LỚP 1: BÓNG ĐỔ VẬT LÝ DÀY ĐẶC CỦA CUỐN SÁCH NẶNG (3D TOME SHADOW)
              // ========================================================
              Positioned(
                top: 18,
                left: 12,
                right: 2,
                bottom: -10,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.85),
                        blurRadius: 28,
                        offset: const Offset(8, 16),
                        spreadRadius: 4,
                      ),
                      BoxShadow(
                        color: const Color(0xFF100802).withValues(alpha: 0.9),
                        blurRadius: 10,
                        offset: const Offset(2, 6),
                      ),
                    ],
                  ),
                ),
              ),

              // ========================================================
              // LỚP 2: MÉP GIẤY DÀY ĐẶC Ố VÀNG CỔ ĐIỂN (FORE-EDGE STACKED PAGES)
              // Bìa cứng nhô ra ngoài mép giấy 4px ở 3 cạnh trên, phải, dưới
              // ========================================================
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 36,
                    top: 5,
                    right: 4,
                    bottom: 5,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBE0CD),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                      border: Border.all(
                        color: const Color(0xFFB5A48B),
                        width: 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Họa tiết vệt giấy ố thời gian xếp tầng (Deckle edge & aging)
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          width: 18,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFFC7B79E),
                                  Color(0xFFEFE8DA),
                                  Color(0xFFD9CCB6),
                                  Color(0xFFB5A489),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                          ),
                        ),
                        // Bóng đổ từ mép bìa cứng đè lên xấp giấy
                        Positioned(
                          top: 0,
                          bottom: 0,
                          right: 0,
                          width: 6,
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ========================================================
              // LỚP 3: TRANG GIẤY CẨM THẠCH VÀ BẢN ĐỒ CỔ TRONG LÒNG SÁCH
              // (MARBLED ENDPAPER & ENGRAVED TITLE PAGE)
              // ========================================================
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 38,
                    top: 7,
                    right: 14,
                    bottom: 7,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5EEDB),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(3, 3),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Hoa văn la bàn cổ chìm bằng mực nâu sepia
                        Center(
                          child: Opacity(
                            opacity: 0.14,
                            child: Icon(
                              Icons.explore_rounded,
                              size: 150,
                              color: const Color(0xFF5D4037),
                            ),
                          ),
                        ),
                        // Dòng chữ mực tàu cổ chép tay
                        Padding(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "CHAPTER I • EX LIBRIS",
                                style: TextStyle(
                                  color: const Color(0xFF8D6E63).withValues(alpha: 0.8),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2.2,
                                  fontFamily: 'serif',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 140,
                                height: 1.5,
                                color: const Color(0xFFA1887F),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                story.getTitle(widget.lang),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF3E2723),
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'serif',
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Ánh hào quang nến ấm bừng sáng khi lật mở bìa
                        AnimatedBuilder(
                          animation: _lightAnimation,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _lightAnimation.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    colors: [
                                      theme.goldHighlight.withValues(alpha: 0.85),
                                      theme.goldFoil.withValues(alpha: 0.35),
                                      Colors.transparent,
                                    ],
                                    radius: 0.9,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ========================================================
              // LỚP 4: BÌA CỨNG DA THUỘC PHƯƠNG TÂY MỞ XOAY 3D VẬT LÝ
              // (HARDCOVER BOARD WITH 3D PERSPECTIVE ROTATION)
              // ========================================================
              AnimatedBuilder(
                animation: _openAnimation,
                builder: (context, child) {
                  final angle = -_openAnimation.value * 1.32;

                  return Transform(
                    alignment: Alignment.centerLeft,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0016)
                      ..rotateY(angle),
                    child: _buildAuthenticWesternCover(story, theme, isLocked),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Xây dựng bìa da thuộc phương Tây chuẩn mực thế kỷ XVIII
  Widget _buildAuthenticWesternCover(
    SailorStory story,
    WesternBookTheme theme,
    bool isLocked,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 6), // Để lộ mép giấy 6px bên phải
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: theme.leatherGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(5),
          bottomLeft: Radius.circular(5),
          topRight: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
        border: Border.all(
          color: theme.goldFoil.withValues(alpha: 0.45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.75),
            blurRadius: 18,
            offset: const Offset(4, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(5),
          bottomLeft: Radius.circular(5),
          topRight: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ----------------------------------------------------
              // A. GÁY SÁCH HÌNH TRỤ 3D VỚI 5 GÂN DẬP NỔI (SPINE WITH 5 RIBS)
              // ----------------------------------------------------
              _buildAuthenticSpine(theme),

              // ----------------------------------------------------
              // B. BỀ MẶT BÌA DA CHÍNH DẬP VÀNG LÁ (LEATHER COVER FACE)
              // ----------------------------------------------------
              Expanded(
                child: Stack(
                  children: [
                    // Hiệu ứng da mòn sẫm mép sách theo năm tháng (Leather Vignette)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 1.0,
                            colors: [
                              Colors.transparent,
                              theme.leatherPatina.withValues(alpha: 0.4),
                              theme.leatherPatina.withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Vân gỗ gụ tự nhiên nếu là sách bìa gỗ
                    if (theme.isWood)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: MahoganyWoodGrainPainter(),
                        ),
                      ),

                    // Đường rãnh dập nhiệt chìm đôi (Blind Debossed Double Fillet)
                    Positioned.fill(
                      child: Container(
                        margin: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.45),
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        margin: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: theme.goldFoil.withValues(alpha: 0.4),
                            width: 0.8,
                          ),
                        ),
                      ),
                    ),

                    // Hiệu ứng phong hóa, vết xước, rách mép, cháy xém, hoen ố độc bản (1 card 1 kiểu)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: AntiqueDistressPainter(
                          type: theme.distressType,
                          leatherColor: theme.leatherGradient.first,
                          patinaColor: theme.leatherPatina,
                          goldFoil: theme.goldFoil,
                          goldHighlight: theme.goldHighlight,
                        ),
                      ),
                    ),

                    // 4 Miếng ốp đồng đúc Baroque góc sách (Cast-Brass Corner Guards)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: AntiqueCornerPainter(
                          color: theme.goldFoil,
                          shadowColor: theme.goldHighlight,
                        ),
                      ),
                    ),

                    // Nội dung trang trí bìa sách
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 1. Nhãn dập chìm danh mục hải ký thế kỷ 18
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.4),
                                border: Border.all(
                                  color: theme.goldFoil.withValues(alpha: 0.5),
                                  width: 0.9,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                theme.bookCategory,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: theme.goldHighlight,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.4,
                                  fontFamily: 'serif',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 2. Khung tranh sơn dầu mạ vàng lồng ảnh hoặc video bìa
                          _buildOilPaintingCameo(story, theme),
                          const SizedBox(height: 14),

                          // 3. Tiêu đề tác phẩm dập chữ vàng kim (Hot-Stamped Gold Title)
                          Text(
                            story.getTitle(widget.lang),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: theme.goldHighlight,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.6,
                              fontFamily: 'serif',
                              height: 1.25,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.95),
                                  blurRadius: 5,
                                  offset: const Offset(1, 2),
                                ),
                                Shadow(
                                  color: theme.goldFoil.withValues(alpha: 0.5),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),

                          // 4. Lời tựa chép tay cổ thư
                          if (story.getSubtitle(widget.lang).isNotEmpty)
                            Text(
                              story.getSubtitle(widget.lang),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFFD7CCC8).withValues(alpha: 0.78),
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                height: 1.35,
                                fontFamily: 'serif',
                              ),
                            ),
                          const SizedBox(height: 10),

                          // 5. Thuyền trưởng / Học giả ghi chép
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history_edu_rounded,
                                color: theme.goldFoil.withValues(alpha: 0.8),
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  story.getAuthor(widget.lang),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: theme.goldFoil,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'serif',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 6. KHÓA CÀI SÁCH ĐỒNG CỔ VẬT LÝ (ANTIQUE BRASS CLASP)
                          _buildAntiqueBrassClasp(theme, isLocked),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Gáy sách 3D hình trụ có 5 gân da dập nổi và đường rãnh bản lề chìm
  Widget _buildAuthenticSpine(WesternBookTheme theme) {
    return Container(
      width: 36,
      decoration: BoxDecoration(
        color: theme.spineBase,
        // Rãnh bản lề sâu (French Hinge Groove) ngăn cách gáy và bìa trước
        border: Border(
          right: BorderSide(
            color: Colors.black.withValues(alpha: 0.9),
            width: 3.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 6,
            offset: const Offset(3, 0),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Độ cong hình trụ gáy sách (sống gáy sáng ở giữa, tối ở 2 bên mép)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.white.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.5),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),

          // 5 gân da dập nổi ngang (5 Raised Bands)
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildRaisedSpineBand(theme),
              Icon(
                Icons.anchor_rounded,
                color: theme.goldFoil.withValues(alpha: 0.65),
                size: 15,
              ),
              _buildRaisedSpineBand(theme),
              _buildRaisedSpineBand(theme),
              RotatedBox(
                quarterTurns: 3,
                child: Text(
                  "VOL. MDCCXLII",
                  style: TextStyle(
                    color: theme.goldFoil.withValues(alpha: 0.4),
                    fontSize: 7.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontFamily: 'serif',
                  ),
                ),
              ),
              _buildRaisedSpineBand(theme),
              _buildRaisedSpineBand(theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRaisedSpineBand(WesternBookTheme theme) {
    return Container(
      height: 5,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.6),
            theme.goldFoil,
            theme.goldHighlight,
            theme.goldFoil,
            Colors.black.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          // Vệt sáng highlight bên trên gân
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.2),
            offset: const Offset(0, -1),
            blurRadius: 1,
          ),
          // Vệt bóng đổ bên dưới gân
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            offset: const Offset(0, 2),
            blurRadius: 2,
          ),
        ],
      ),
    );
  }

  /// Khung tranh sơn dầu mạ vàng lồng ảnh hoặc video bìa
  Widget _buildOilPaintingCameo(SailorStory story, WesternBookTheme theme) {
    final useVideo = story.isCoverVideo && story.effectiveCoverVideo.isNotEmpty;

    return Container(
      height: 165,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: theme.goldFoil,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.85),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: theme.goldFoil.withValues(alpha: 0.25),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (useVideo)
            CachedCreatureVideoPlayer(
              key: ValueKey('cover_vid_${story.storyId}_${story.effectiveCoverVideo}'),
              videoUrl: story.effectiveCoverVideo,
              placeholder: _buildCoverImage(story.coverImage),
              disableMask: true,
              fit: BoxFit.cover,
            )
          else
            _buildCoverImage(story.coverImage),
          // Lớp dầu bóng cổ kính phủ trên mặt tranh sơn dầu (Oil Varnish Glaze)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.16),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.55),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Viền khắc chìm bên trong khung tranh
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Khóa cài sách bằng đồng cổ vật lý (Antique Brass Clasp)
  Widget _buildAntiqueBrassClasp(WesternBookTheme theme, bool isLocked) {
    final isVi = widget.isVi;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLocked
              ? const [
                  Color(0xFF8D6E2F),
                  Color(0xFFB8860B),
                  Color(0xFF6B4C12),
                ]
              : [
                  Color(0xFF9E782F),
                  Color(0xFFD4AF37),
                  theme.goldHighlight,
                  Color(0xFFD4AF37),
                  Color(0xFF7A5718),
                ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFFFFF9C4),
          width: 1.0,
        ),
        boxShadow: [
          // Đổ bóng nổi khối kim loại 3D thực tế
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.75),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: theme.goldFoil.withValues(alpha: 0.3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Đinh tán đồng ở 2 mép khóa sách
          Positioned(
            left: 8,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3E280C),
                border: Border.all(
                  color: const Color(0xFFFFF9C4),
                  width: 0.8,
                ),
              ),
            ),
          ),
          Positioned(
            right: 8,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3E280C),
                border: Border.all(
                  color: const Color(0xFFFFF9C4),
                  width: 0.8,
                ),
              ),
            ),
          ),

          // Nội dung chạm khắc trên mặt khóa đồng
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isLocked ? Icons.lock_outline_rounded : Icons.menu_book_rounded,
                color: const Color(0xFF1E1002),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                isLocked
                    ? (isVi ? 'BẢN PHONG ẤN VIP • MỞ KHÓA' : 'SEALED VIP TOME • UNLOCK')
                    : (isVi ? 'LẬT MỞ TRANG SÁCH' : 'OPEN ANCIENT TOME'),
                style: const TextStyle(
                  color: Color(0xFF1E1002),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  fontFamily: 'serif',
                  shadows: [
                    Shadow(
                      color: Color(0xFFFFECB3),
                      offset: Offset(0, 1),
                      blurRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Color(0xFF1E1002),
                size: 14,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImage(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFF160E08),
          child: const Center(
            child: Icon(Icons.broken_image_rounded,
                color: Colors.white38, size: 36),
          ),
        ),
      );
    } else {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFF160E08),
          child: const Center(
            child: Icon(Icons.broken_image_rounded,
                color: Colors.white38, size: 36),
          ),
        ),
      );
    }
  }
}

/// =========================================================================
/// CUSTOM PAINTER: 4 GÓC ĐỒNG ĐÚC BAROQUE PHƯƠNG TÂY (BRASS CORNER GUARDS)
/// =========================================================================
class AntiqueCornerPainter extends CustomPainter {
  final Color color;
  final Color shadowColor;
  final bool showLeftCorners;
  final bool showRightCorners;

  AntiqueCornerPainter({
    required this.color,
    required this.shadowColor,
    this.showLeftCorners = false, // Bỏ 2 góc vàng bên trái trên/dưới theo yêu cầu người dùng
    this.showRightCorners = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const cornerSize = 28.0;

    final brassPaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final filigreePaint = Paint()
      ..color = shadowColor.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final rivetPaint = Paint()
      ..color = shadowColor
      ..style = PaintingStyle.fill;

    final rivetBorder = Paint()
      ..color = Colors.black.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    void drawCornerPiece(double startX, double startY, double dx, double dy) {
      // Khung viền góc tam giác Baroque
      final path = Path()
        ..moveTo(startX + (dx * cornerSize), startY)
        ..lineTo(startX + (dx * 6), startY)
        ..lineTo(startX, startY + (dy * 6))
        ..lineTo(startX, startY + (dy * cornerSize))
        ..quadraticBezierTo(
          startX + (dx * 12),
          startY + (dy * 12),
          startX + (dx * cornerSize),
          startY,
        );
      canvas.drawPath(path, brassPaint);

      // Đường hoa văn chìm bên trong
      final innerArc = Path()
        ..moveTo(startX + (dx * 18), startY + (dy * 3))
        ..quadraticBezierTo(
          startX + (dx * 8),
          startY + (dy * 8),
          startX + (dx * 3),
          startY + (dy * 18),
        );
      canvas.drawPath(innerArc, filigreePaint);

      // 3 đinh tán đồng đúc ở mỗi góc
      final centerRivet = Offset(startX + (dx * 9), startY + (dy * 9));
      canvas.drawCircle(centerRivet, 2.0, rivetPaint);
      canvas.drawCircle(centerRivet, 2.0, rivetBorder);

      final r1 = Offset(startX + (dx * 20), startY + (dy * 4));
      canvas.drawCircle(r1, 1.4, rivetPaint);

      final r2 = Offset(startX + (dx * 4), startY + (dy * 20));
      canvas.drawCircle(r2, 1.4, rivetPaint);
    }

    // 1 & 2. Các góc bên phải
    if (showRightCorners) {
      drawCornerPiece(size.width, 0, -1, 1);
      drawCornerPiece(size.width, size.height, -1, -1);
    }

    // 3 & 4. Các góc bên trái (Đã loại bỏ theo yêu cầu người dùng)
    if (showLeftCorners) {
      drawCornerPiece(0, 0, 1, 1);
      drawCornerPiece(0, size.height, 1, -1);
    }
  }

  @override
  bool shouldRepaint(covariant AntiqueCornerPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.shadowColor != shadowColor ||
        oldDelegate.showLeftCorners != showLeftCorners ||
        oldDelegate.showRightCorners != showRightCorners;
  }
}

/// =========================================================================
/// CUSTOM PAINTER: VÂN GỖ GỤ TỰ NHIÊN ĐÁNH VECNI BÓNG (MAHOGANY WOOD GRAIN)
/// =========================================================================
class MahoganyWoodGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final darkGrainPaint = Paint()
      ..color = const Color(0xFF260A03).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final lightGrainPaint = Paint()
      ..color = const Color(0xFFAA4A28).withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    // Các đường thớ gỗ gụ lượn sóng tự nhiên chạy dọc theo phiến gỗ
    for (double y = 16; y < size.height; y += 24) {
      final path = Path()
        ..moveTo(0, y)
        ..quadraticBezierTo(size.width * 0.32, y - 5, size.width * 0.65, y + 4)
        ..quadraticBezierTo(size.width * 0.86, y + 7, size.width, y + 2);
      canvas.drawPath(path, darkGrainPaint);
    }

    for (double y = 28; y < size.height; y += 32) {
      final path = Path()
        ..moveTo(0, y)
        ..quadraticBezierTo(size.width * 0.42, y + 6, size.width * 0.78, y - 4)
        ..lineTo(size.width, y + 1);
      canvas.drawPath(path, lightGrainPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// =========================================================================
/// CUSTOM PAINTER: HIỆU ỨNG BÌA CỔ, VẾT XƯỚC, RÁCH NHỎ & PHONG HÓA ĐỘC BẢN
/// (1 CARD 1 KIỂU HIỆU ỨNG - ĐỘC NHẤT VÔ NHỊ CHO TỪNG CUỐN SÁCH HẢI TRÌNH)
/// =========================================================================
class AntiqueDistressPainter extends CustomPainter {
  final BookDistressType type;
  final Color leatherColor;
  final Color patinaColor;
  final Color goldFoil;
  final Color goldHighlight;

  AntiqueDistressPainter({
    required this.type,
    required this.leatherColor,
    required this.patinaColor,
    required this.goldFoil,
    required this.goldHighlight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (type) {
      case BookDistressType.saltScratches:
        _paintSaltScratches(canvas, size);
        break;
      case BookDistressType.woodBattleSlash:
        _paintWoodBattleSlash(canvas, size);
        break;
      case BookDistressType.waterStainsTears:
        _paintWaterStainsTears(canvas, size);
        break;
      case BookDistressType.scorchedClawMarks:
        _paintScorchedClawMarks(canvas, size);
        break;
      case BookDistressType.expeditionScuffs:
        _paintExpeditionScuffs(canvas, size);
        break;
    }
  }

  /// -----------------------------------------------------------------------
  /// 1. DAVY JONES: VẾT CÀO SAN HÔ SẮC NHỌN, VÁNG MUỐI BIỂN & RÁCH KHÍA MÉP
  /// -----------------------------------------------------------------------
  void _paintSaltScratches(Canvas canvas, Size size) {
    // A. Rãnh xước khoét sâu 3D (Shadow lõm tối màu + Highlight lồi màu muối trắng ngà)
    final shadowScratch = Paint()
      ..color = const Color(0xFF040E1A).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final lightScratch = Paint()
      ..color = const Color(0xFFE2ECF5).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.85
      ..strokeCap = StrokeCap.round;

    void draw3DScratch(Path path, double ox, double oy) {
      canvas.drawPath(path, shadowScratch);
      final offsetPath = path.shift(Offset(ox, oy));
      canvas.drawPath(offsetPath, lightScratch);
    }

    // Vết xước 1: Góc trên bên trái, san hô quẹt rẽ nhánh
    final p1 = Path()
      ..moveTo(size.width * 0.12, 32)
      ..quadraticBezierTo(size.width * 0.24, 40, size.width * 0.42, 58);
    draw3DScratch(p1, 0.8, 0.8);

    final p1b = Path()
      ..moveTo(size.width * 0.26, 44)
      ..lineTo(size.width * 0.32, 68);
    draw3DScratch(p1b, 0.7, 0.7);

    // Vết xước 2: Chạy chéo sắc nhọn ở thân trên bên phải
    final p2 = Path()
      ..moveTo(size.width - 24, 135)
      ..quadraticBezierTo(size.width - 55, 155, size.width - 92, 172);
    draw3DScratch(p2, -0.7, 0.7);

    // Vết xước 3: Cặp vết cào ngắn song song góc dưới
    final p3a = Path()
      ..moveTo(size.width * 0.16, size.height - 68)
      ..lineTo(size.width * 0.44, size.height - 56);
    draw3DScratch(p3a, 0.7, 0.7);

    final p3b = Path()
      ..moveTo(size.width * 0.20, size.height - 76)
      ..lineTo(size.width * 0.38, size.height - 68);
    draw3DScratch(p3b, 0.6, 0.6);

    // B. Vết rách khía nhỏ ở mép bìa (Torn notches with frayed fibers)
    final tearPaint = Paint()
      ..color = const Color(0xFF030A12)
      ..style = PaintingStyle.fill;

    final fiberPaint = Paint()
      ..color = const Color(0xFFE2ECF5).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Vết rách khuyết 1 ở mép phải (y = 108)
    final tear1 = Path()
      ..moveTo(size.width, 103)
      ..lineTo(size.width - 4.5, 108)
      ..lineTo(size.width, 114)
      ..close();
    canvas.drawPath(tear1, tearPaint);
    // Sợi tơ chỉ tưa ra
    canvas.drawLine(
        Offset(size.width - 4, 107), Offset(size.width - 1, 105), fiberPaint);
    canvas.drawLine(
        Offset(size.width - 4, 109), Offset(size.width, 110), fiberPaint);

    // Vết rách khuyết 2 ở mép phải (y = 236)
    final tear2 = Path()
      ..moveTo(size.width, 232)
      ..lineTo(size.width - 3.8, 236)
      ..lineTo(size.width, 241)
      ..close();
    canvas.drawPath(tear2, tearPaint);
    canvas.drawLine(
        Offset(size.width - 3.5, 236), Offset(size.width - 0.5, 234), fiberPaint);

    // C. Váng muối biển khô kết tinh (Salt patina crust clusters)
    final saltPaint = Paint()
      ..style = PaintingStyle.fill;

    final saltDots = [
      Offset(size.width * 0.14, 28),
      Offset(size.width * 0.17, 34),
      Offset(size.width * 0.21, 31),
      Offset(size.width * 0.38, 55),
      Offset(size.width * 0.43, 62),
      Offset(size.width - 18, 126),
      Offset(size.width - 28, 142),
      Offset(size.width - 32, 136),
      Offset(size.width - 85, 175),
      Offset(size.width * 0.15, size.height - 62),
      Offset(size.width * 0.22, size.height - 72),
      Offset(size.width * 0.40, size.height - 52),
    ];

    for (int i = 0; i < saltDots.length; i++) {
      final dot = saltDots[i];
      final radius = 0.8 + ((i % 3) * 0.5);
      final alpha = 0.18 + ((i % 4) * 0.08);
      saltPaint.color = const Color(0xFFE0ECF8).withValues(alpha: alpha);
      canvas.drawCircle(dot, radius, saltPaint);
    }
  }

  /// -----------------------------------------------------------------------
  /// 2. BLACK PEARL: VẾT CHÉM GƯƠM HẢI TẶC, THỚ GỖ NỨT NẺ & SỨT MẺ CẠNH
  /// -----------------------------------------------------------------------
  void _paintWoodBattleSlash(Canvas canvas, Size size) {
    // A. Vết chém gươm hải tặc bạo liệt (Cutlass battle slash)
    // 1. Rãnh chém sâu lõm đen màu gỗ cháy
    final cutShadowPaint = Paint()
      ..color = const Color(0xFF140502)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    // 2. Gờ thớ gỗ tươi bị bóc tước sáng màu vàng cam hổ phách
    final cutWoodHighlight = Paint()
      ..color = const Color(0xFFFFB74D).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    // Vết chém lớn cắt chéo qua góc trên và thân bìa
    final slash1 = Path()
      ..moveTo(size.width * 0.16, 40)
      ..quadraticBezierTo(size.width * 0.28, 76, size.width * 0.46, 134);
    canvas.drawPath(slash1, cutShadowPaint);
    canvas.drawPath(slash1.shift(const Offset(0.9, -0.9)), cutWoodHighlight);

    // Vết chém sượt thứ hai ở vùng dưới
    final slash2 = Path()
      ..moveTo(size.width * 0.54, size.height - 84)
      ..quadraticBezierTo(size.width * 0.70, size.height - 72, size.width * 0.88, size.height - 60);
    canvas.drawPath(slash2, cutShadowPaint..strokeWidth = 1.8);
    canvas.drawPath(slash2.shift(const Offset(0.7, -0.7)), cutWoodHighlight..strokeWidth = 0.8);

    // B. Vết nứt thớ gỗ khô cằn zíc zắc từ mép trên (Wood grain split crack)
    final crackPaint = Paint()
      ..color = const Color(0xFF1E0703)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final crackHighlight = Paint()
      ..color = const Color(0xFFFFCC80).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    final crackPath = Path()
      ..moveTo(size.width * 0.72, 0)
      ..lineTo(size.width * 0.70, 16)
      ..lineTo(size.width * 0.73, 26)
      ..lineTo(size.width * 0.68, 48);
    canvas.drawPath(crackPath, crackPaint);
    canvas.drawPath(crackPath.shift(const Offset(0.7, 0.7)), crackHighlight);

    // Nhánh nứt con tách ra
    final branchPath = Path()
      ..moveTo(size.width * 0.73, 26)
      ..lineTo(size.width * 0.78, 38);
    canvas.drawPath(branchPath, crackPaint);
    canvas.drawPath(branchPath.shift(const Offset(0.6, 0.6)), crackHighlight);

    // C. Vết sứt mẻ gỗ ở mép đáy bìa (Chipped wood gouge)
    final chipPaint = Paint()
      ..color = const Color(0xFF180502)
      ..style = PaintingStyle.fill;

    final chipPath = Path()
      ..moveTo(size.width * 0.34, size.height)
      ..quadraticBezierTo(size.width * 0.37, size.height - 4.2, size.width * 0.40, size.height)
      ..close();
    canvas.drawPath(chipPath, chipPaint);

    // Viền sáng cạnh mẻ
    final chipEdge = Paint()
      ..color = const Color(0xFFFFB74D).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    canvas.drawLine(
        Offset(size.width * 0.34, size.height - 1),
        Offset(size.width * 0.37, size.height - 4.2),
        chipEdge);
  }

  /// -----------------------------------------------------------------------
  /// 3. BERMUDA TRIANGLE: QUẦNG NƯỚC BIỂN KHÔ LOANG & SỜN RÁCH LỘ VẢI LÓT
  /// -----------------------------------------------------------------------
  void _paintWaterStainsTears(Canvas canvas, Size size) {
    // A. Quầng nước biển mặn khô loang (Drying water tide ring / stain contours)
    final tideRingPaint = Paint()
      ..color = const Color(0xFF072018).withValues(alpha: 0.46)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    final tideFillPaint = Paint()
      ..color = const Color(0xFF134538).withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;

    // Quầng loang lớn ở nửa dưới bìa
    final waterStain1 = Path()
      ..moveTo(size.width * 0.22, size.height * 0.56)
      ..cubicTo(
        size.width * 0.35, size.height * 0.52,
        size.width * 0.65, size.height * 0.55,
        size.width * 0.82, size.height * 0.62,
      )
      ..cubicTo(
        size.width * 0.92, size.height * 0.70,
        size.width * 0.75, size.height * 0.86,
        size.width * 0.48, size.height * 0.84,
      )
      ..cubicTo(
        size.width * 0.28, size.height * 0.82,
        size.width * 0.16, size.height * 0.68,
        size.width * 0.22, size.height * 0.56,
      )
      ..close();

    canvas.drawPath(waterStain1, tideFillPaint);
    canvas.drawPath(waterStain1, tideRingPaint);

    // Quầng giọt nước khô nhỏ ở góc trên bên phải
    final waterDrop = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(size.width * 0.80, 52),
        width: 36,
        height: 28,
      ));
    canvas.drawPath(waterDrop, tideFillPaint);
    canvas.drawPath(waterDrop, tideRingPaint..strokeWidth = 1.2);

    // B. Vết sờn rách mép da lộ lớp vải lót canvas (Frayed edge tear)
    // Vùng da rách khuyết ở mép phải (y từ 192 đến 230)
    final tearBg = Paint()
      ..color = const Color(0xFFC8B38E) // Màu vải canvas thô bên dưới
      ..style = PaintingStyle.fill;

    final tearShadow = Paint()
      ..color = const Color(0xFF061812)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final tearHole = Path()
      ..moveTo(size.width, 192)
      ..quadraticBezierTo(size.width - 6.0, 202, size.width - 5.5, 214)
      ..quadraticBezierTo(size.width - 5.0, 224, size.width, 230)
      ..close();

    canvas.drawPath(tearHole, tearBg);
    canvas.drawPath(tearHole, tearShadow);

    // Các sợi chỉ canvas tưa đứt ngang dọc
    final threadPaint = Paint()
      ..color = const Color(0xFFF5E8D2).withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.85;

    // Sợi chỉ ngang
    canvas.drawLine(Offset(size.width - 5, 200), Offset(size.width + 1, 200), threadPaint);
    canvas.drawLine(Offset(size.width - 5.5, 208), Offset(size.width + 2, 208), threadPaint);
    canvas.drawLine(Offset(size.width - 5, 216), Offset(size.width + 1.5, 216), threadPaint);
    canvas.drawLine(Offset(size.width - 4, 224), Offset(size.width, 224), threadPaint);

    // Sợi chỉ dọc
    canvas.drawLine(Offset(size.width - 3.5, 195), Offset(size.width - 3.5, 227), threadPaint..strokeWidth = 0.7);
    canvas.drawLine(Offset(size.width - 1.8, 197), Offset(size.width - 1.8, 225), threadPaint);

    // C. Nếp nhăn co rút da mặn
    final wrinklePaint = Paint()
      ..color = const Color(0xFF08261E).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    final w1 = Path()
      ..moveTo(size.width - 10, 188)
      ..quadraticBezierTo(size.width - 24, 198, size.width - 14, 208);
    canvas.drawPath(w1, wrinklePaint);

    final w2 = Path()
      ..moveTo(size.width - 8, 228)
      ..quadraticBezierTo(size.width - 22, 238, size.width - 12, 246);
    canvas.drawPath(w2, wrinklePaint);
  }

  /// -----------------------------------------------------------------------
  /// 4. CTHULHU ABYSS: BA VẾT CÀO MÓNG VUỐT, MỞ RÁCH DA & MÉP CHÁY SÉM ĐEN
  /// -----------------------------------------------------------------------
  void _paintScorchedClawMarks(Canvas canvas, Size size) {
    // A. Ba vết cào móng vuốt thực thể sâu thẳm (Triple Eldritch Claw Gouges)
    final clawShadowPaint = Paint()
      ..color = const Color(0xFF1D0306) // Đỏ thẫm đen máu khô
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final clawFleshHighlight = Paint()
      ..color = const Color(0xFFFFCCBC).withValues(alpha: 0.75) // Mép da bị lột gờ sáng
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    void drawClaw(double startX, double startY, double endX, double endY, double ctrlX, double ctrlY) {
      final path = Path()
        ..moveTo(startX, startY)
        ..quadraticBezierTo(ctrlX, ctrlY, endX, endY);
      canvas.drawPath(path, clawShadowPaint);
      canvas.drawPath(path.shift(const Offset(1.0, 0.8)), clawFleshHighlight);
    }

    // Vuốt 1 (trái)
    drawClaw(
      size.width * 0.22, 54,
      size.width * 0.48, 140,
      size.width * 0.32, 92,
    );

    // Vuốt 2 (giữa - cào dài và sâu nhất)
    drawClaw(
      size.width * 0.26, 45,
      size.width * 0.54, 132,
      size.width * 0.37, 84,
    );

    // Vuốt 3 (phải)
    drawClaw(
      size.width * 0.30, 36,
      size.width * 0.60, 122,
      size.width * 0.42, 75,
    );

    // B. Mép bìa góc trên bên phải bị cháy sém than đen (Scorched burned rim)
    final burnRect = Rect.fromCircle(
      center: Offset(size.width, 0),
      radius: 52,
    );
    final burnPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF0D0103).withValues(alpha: 0.92),
          const Color(0xFF260408).withValues(alpha: 0.75),
          const Color(0xFF4A0810).withValues(alpha: 0.3),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 0.75, 1.0],
      ).createShader(burnRect);

    canvas.drawCircle(Offset(size.width, 0), 52, burnPaint);

    // Lỗ thủng than rơi nhỏ (cắt thủng da)
    final emberHole = Offset(size.width - 24, 22);
    final holePaint = Paint()
      ..color = const Color(0xFF080102)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(emberHole, 3.2, holePaint);

    // Viền tàn tro than hồng quanh lỗ thủng
    final emberRim = Paint()
      ..color = const Color(0xFFD84315).withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    canvas.drawCircle(emberHole, 3.4, emberRim);

    // Vết rách cào nhỏ ở mép phải (y = 155)
    final clawTear = Path()
      ..moveTo(size.width, 150)
      ..lineTo(size.width - 4.5, 155)
      ..lineTo(size.width, 161)
      ..close();
    canvas.drawPath(clawTear, Paint()..color = const Color(0xFF1D0306));
  }

  /// -----------------------------------------------------------------------
  /// 5. MARIANA TRENCH: MẢNG MÀI MÒN BẠC DA & MẠNG RẠN NỨT CHÂN CHIM CỔ
  /// -----------------------------------------------------------------------
  void _paintExpeditionScuffs(Canvas canvas, Size size) {
    // A. Mảng da bị mài mòn bạc màu diện rộng do cầm nắm nhiều (Heavy rubbed wear patches)
    final scuffPaint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFD7A768).withValues(alpha: 0.26), // Màu thịt da mộc thô lộ ra
          const Color(0xFFC48E4F).withValues(alpha: 0.12),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCenter(
        center: Offset(size.width * 0.72, size.height * 0.70),
        width: 120,
        height: 80,
      ));

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.72, size.height * 0.70),
        width: 120,
        height: 80,
      ),
      scuffPaint1,
    );

    // Mảng mòn phụ ở góc trên bên trái
    final scuffPaint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFD7A768).withValues(alpha: 0.20),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCenter(
        center: Offset(size.width * 0.28, 48),
        width: 75,
        height: 50,
      ));

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.28, 48),
        width: 75,
        height: 50,
      ),
      scuffPaint2,
    );

    // B. Mạng lưới rạn nứt chân chim cổ kính (Leather craquelure micro-cracks)
    final craquelurePaint = Paint()
      ..color = const Color(0xFF281303).withValues(alpha: 0.52)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;

    final craquelureHighlight = Paint()
      ..color = const Color(0xFFFFE0B2).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    void drawCraquelure(List<Offset> points) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, craquelurePaint);
      canvas.drawPath(path.shift(const Offset(0.5, 0.5)), craquelureHighlight);
    }

    // Mạng rạn góc dưới bên trái
    drawCraquelure([
      Offset(size.width * 0.14, size.height - 35),
      Offset(size.width * 0.20, size.height - 48),
      Offset(size.width * 0.26, size.height - 42),
      Offset(size.width * 0.32, size.height - 58),
    ]);
    drawCraquelure([
      Offset(size.width * 0.20, size.height - 48),
      Offset(size.width * 0.18, size.height - 62),
    ]);
    drawCraquelure([
      Offset(size.width * 0.26, size.height - 42),
      Offset(size.width * 0.34, size.height - 38),
    ]);

    // Mạng rạn thân trên
    drawCraquelure([
      Offset(size.width * 0.60, 36),
      Offset(size.width * 0.68, 46),
      Offset(size.width * 0.76, 40),
      Offset(size.width * 0.82, 54),
    ]);
    drawCraquelure([
      Offset(size.width * 0.68, 46),
      Offset(size.width * 0.70, 60),
    ]);

    // C. Vết cứa dao thám hiểm dài & rách mép nhỏ
    final cutPaint = Paint()
      ..color = const Color(0xFF220E02)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    final cutLight = Paint()
      ..color = const Color(0xFFFFD180).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    final cutPath = Path()
      ..moveTo(size.width * 0.56, size.height - 54)
      ..quadraticBezierTo(size.width * 0.66, size.height - 58, size.width * 0.78, size.height - 50);
    canvas.drawPath(cutPath, cutPaint);
    canvas.drawPath(cutPath.shift(const Offset(0.6, 0.6)), cutLight);

    // Vết mẻ khuyết mép phải (y = 282)
    final notch = Path()
      ..moveTo(size.width, 278)
      ..lineTo(size.width - 3.6, 282)
      ..lineTo(size.width, 287)
      ..close();
    canvas.drawPath(notch, Paint()..color = const Color(0xFF281303));
  }

  @override
  bool shouldRepaint(covariant AntiqueDistressPainter oldDelegate) {
    return oldDelegate.type != type ||
        oldDelegate.leatherColor != leatherColor ||
        oldDelegate.patinaColor != patinaColor ||
        oldDelegate.goldFoil != goldFoil ||
        oldDelegate.goldHighlight != goldHighlight;
  }
}


