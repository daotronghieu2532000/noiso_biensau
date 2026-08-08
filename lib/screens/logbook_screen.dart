import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/creature.dart';
import '../services/data_service.dart';
import '../widgets/structured_description_widget.dart';
import '../widgets/medal_widget.dart';
import '../widgets/cached_video_player.dart';
import '../l10n/app_strings.dart';
import 'settings_screen.dart';

class LogbookScreen extends StatefulWidget {
  const LogbookScreen({super.key});

  @override
  State<LogbookScreen> createState() => _LogbookScreenState();
}

class _LogbookScreenState extends State<LogbookScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, bool> _animatedMedals = {};
  bool _prefsLoaded = false;
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
    _tabController = TabController(length: 2, vsync: this);
    _loadMedalStates();
  }

  Future<void> _loadMedalStates() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _animatedMedals['twilight_scout'] = prefs.getBool('medal_anim_twilight_scout') ?? false;
        _animatedMedals['midnight_explorer'] = prefs.getBool('medal_anim_midnight_explorer') ?? false;
        _animatedMedals['abyssal_pioneer'] = prefs.getBool('medal_anim_abyssal_pioneer') ?? false;
        _animatedMedals['mariana_conqueror'] = prefs.getBool('medal_anim_mariana_conqueror') ?? false;
        _animatedMedals['cryptographer'] = prefs.getBool('medal_anim_cryptographer') ?? false;
        _animatedMedals['deepsea_legend'] = prefs.getBool('medal_anim_deepsea_legend') ?? false;
        _prefsLoaded = true;
      });
    }
  }

  Future<void> _onMedalUnlockAnimated(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('medal_anim_$key', true);
    if (mounted) {
      setState(() {
        _animatedMedals[key] = true;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getCaptainLog(String id, String langCode) {
    final isEn = langCode == 'en';
    switch (id) {
      case 'clownfish':
        return isEn
            ? 'Log Entry #01: Sunlight-filled shallow waters. It is peaceful to observe the small clownfish swimming among the vibrant corals before we sink completely into the dark...'
            : 'Bút ký số 01: Vùng nước nông chan hòa ánh sáng. Thật yên bình khi quan sát đàn cá hề nhỏ bé bơi lội giữa những cụm san hô rực rỡ trước khi chúng tôi chìm hẳn vào bóng tối...';
      case 'great_white_shark':
        return isEn
            ? 'Log Entry #05: We detected a long, slender shadow darting quickly in the twilight zone. Great White Shark, the apex predator of the upper waters. Its deep heartbeat echo through our audio sensors is terrifying.'
            : 'Bút ký số 05: Chúng tôi phát hiện một bóng đen thon dài lao nhanh ở vùng hoàng hôn. Cá mập trắng lớn, kẻ săn mồi tối cao cận mặt nước. Tiếng đập tim của nó dội qua cảm biến thu âm trầm đục đáng sợ.';
      case 'oarfish':
        return isEn
            ? 'Log Entry #11: The oarfish, as long as a legendary sea dragon, hovers vertically in the water column. Sonar records its strange swimming rhythm. A creature bearing unusual portents from the tectonic faults.'
            : 'Bút ký số 11: Loài cá hố dài như một con rồng biển huyền thoại trôi lơ lửng theo chiều thẳng đứng. Sonar ghi nhận nhịp bơi kỳ lạ của nó. Một sinh vật mang điềm báo kỳ lạ từ thềm lục địa.';
      case 'giant_squid':
        return isEn
            ? 'Log Entry #18: A terrifying encounter at 800m depth. A giant squid lashed its tentacles against the submarine\'s viewing glass. Its dinner-plate-sized eyes stared at us in the dark.'
            : 'Bút ký số 18: Cuộc chạm trán kinh hoàng ở độ sâu 800m. Một con mực khổng lồ quất xúc tu vào kính quan sát của tàu ngầm. Đôi mắt to như chiếc đĩa của nó nhìn chằm chằm vào chúng tôi trong bóng đêm.';
      case 'vampire_squid':
        return isEn
            ? 'Log Entry #22: The small vampire squid curls up to camouflage itself as a dark red spiny ball. Its bat-wing-like webbing glows with magical bioluminescent dots.'
            : 'Bút ký số 22: Mực ma cà rồng nhỏ bé co tròn ngụy trang như một quả bóng gai màu đỏ sẫm. Lớp màng đen tựa cánh dơi của nó lấp lánh các điểm phát sáng sinh học cực kỳ huyền ảo.';
      case 'anglerfish':
        return isEn
            ? 'Log Entry #30: Entering the Midnight Zone. We were drawn to a small light source swaying ahead. Luckily, the secondary floodlights managed to expose the wide-open, needle-toothed jaws of the anglerfish in time.'
            : 'Bút ký số 30: Vùng Midnight Zone. Chúng tôi bị thu hút bởi một đốm sáng nhỏ đung đưa phía trước. May mắn thay, đèn pha phụ đã kịp quét ra bộ hàm răng nhọn hoắt của con cá vây chân đang há rộng.';
      case 'giant_isopod':
        return isEn
            ? 'Log Entry #32: Giant isopods crawling around the carcass of a deep-sunk marine creature. Their thick armored shells seem indifferent to the suffocating water pressure.'
            : 'Bọ chân đều khổng lồ bò lúc nhúc bên cạnh xác một sinh vật biển chìm sâu. Lớp vỏ giáp dày cộm của chúng dường như trơ lỳ trước sức ép nước nghẹt thở.';
      case 'black_dragonfish':
        return isEn
            ? 'Log Entry #38: The pitch-black body of the dragonfish absorbs light completely, making it invisible in the dark. Only when it flashes its bioluminescent barbel to lure prey do we identify its terrifyingly long teeth.'
            : 'Bút ký số 38: Cơ thể đen kịt hấp thụ hoàn toàn ánh sáng của cá rồng đen làm cho nó vô hình trong bóng tối. Chỉ khi nó nhấp nháy đèn phát quang dụ mồi, chúng tôi mới nhận diện được bộ răng dài đáng sợ.';
      case 'greenland_shark':
        return isEn
            ? 'Log Entry #42: Under the freezing sub-Arctic waters, a massive Greenland shark moves slowly past our scanners. Its extremely slow heart rate is the key to its centuries-long lifespan.'
            : 'Bút ký số 42: Dưới làn nước lạnh buốt cận Bắc Cực, một con cá mập Greenland khổng lồ di chuyển chậm rãi qua máy quét. Nhịp tim cực chậm của nó là chìa khóa giúp nó sống thọ hàng thế kỷ.';
      case 'kraken':
        return isEn
            ? 'Log Entry #50: The Kraken has appeared! Titanic tentacles are squeezing the hull. Hull pressure is dropping rapidly. We had to activate the maximum electromagnetic shield to escape its crushing wrap.'
            : 'Bút ký số 50: Thủy quái Kraken xuất hiện! Những xúc tu khổng lồ siết chặt vỏ tàu. Áp lực vỏ sụt giảm nghiêm trọng. Chúng tôi đã phải kích hoạt lá chắn điện từ tối đa để thoát khỏi cú quấn của nó.';
      case 'the_bloop':
        return isEn
            ? 'Log Entry #58: Seismographs registered an enormous acoustic wave named "The Bloop". It is not ice cracking, but the sound emitted by a colossal biological entity hundreds of meters long moving below.'
            : 'Bút ký số 58: Thiết bị đo địa chấn ghi nhận sóng âm The Bloop cực lớn. Nó không phải tiếng nứt băng, mà là âm thanh phát ra từ một thực thể sinh học khổng lồ dài hàng trăm mét đang di chuyển phía dưới.';
      case 'leviathan':
        return isEn
            ? 'Log Entry #65: The Great Leviathan! A sea dragon hundreds of meters long glides across the fractured continental shelf. Its boiling hot breath heats the waters around the submarine. A true king.'
            : 'Bút ký số 65: Đại Long Leviathan! Một con rồng biển dài hàng trăm mét lướt qua thềm lục địa nứt gãy. Hơi thở nóng sục sôi của nó làm nước quanh tàu ngầm sôi sùng sục. Một vị vua đích thực.';
      case 'sea_serpent':
        return isEn
            ? 'Log Entry #72: The long sea serpent winds through the deep sea like a moving mountain range. We had to shut down all engines and maintain absolute silence to avoid attracting its attention.'
            : 'Bút ký số 72: Con mãng xà biển dài uốn lượn như một dãy núi di động trong lòng biển sâu. Chúng tôi phải tắt hết động cơ, giữ im lặng tuyệt đối để tránh sự chú ý của thực thể cổ đại này.';
      case 'cthulhu':
        return isEn
            ? 'Log Entry #99: Great Old One Cthulhu awakens in the Mariana Trench depth. Optical feeds are completely corrupted. Sanity of crew is fracturing at the sight of the colossal winged shadow below. Must evacuate immediately!'
            : 'Bút ký số 99: Tà Thần Cthulhu thức tỉnh ở đáy Mariana. Optic quang học bị nhiễu loạn hoàn toàn. Tâm trí các thủy thủ bắt đầu hỗn loạn trước bóng đen khổng lồ sải cánh dưới đáy thẳm. Phải thoát ngay lập tức!';
      case 'megalodon':
        return isEn
            ? 'Log Entry #10: The prehistoric Megalodon, once thought extinct, is hunting a pack of smaller sharks. Its terrifying bite force creates deep underwater currents that violently shake our submarine.'
            : 'Bút ký số 10: Siêu cá mập Megalodon tiền sử tưởng như đã tuyệt chủng đang săn đuổi một đàn cá mập nhỏ. Cú táp lực cắn kinh hoàng của nó tạo nên dòng hải lưu ngầm làm rung lắc tàu ngầm dữ dội.';
      case 'reaper_leviathan':
        return isEn
            ? 'Log Entry #27: The ear-splitting roar of the Reaper Leviathan echoes through the sonar. Its four red horns have locked onto the starboard side of the submarine. Shield alarm is flashing red.'
            : 'Bút ký số 27: Tiếng gầm rú đinh tai nhức óc của Reaper Leviathan vọng qua sonar. Bốn chiếc sừng đỏ của nó đã khóa chặt lấy mạn phải tàu ngầm. Hệ thống lá chắn báo động đỏ rực.';
      case 'jormungandr':
        return isEn
            ? 'Log Entry #88: The World Serpent Jörmungandr lies asleep, coiled around deep volcanic rifts. Nuclear gases emitting from its body are constantly overloading our telemetry sensors.'
            : 'Bút ký số 88: Mãng xà thế giới Jörmungandr đang ngủ say cuộn quanh thềm đá nứt sâu. Khí độc nguyên tử phát ra từ cơ thể nó làm cảm biến đo đạc của chúng tôi quá tải liên tục.';
      case 'lagiacrus':
        return isEn
            ? 'Log Entry #34: The Lord of the Seas gathers brilliant blue lightning arcs around its dorsal spikes. The electric discharge temporarily paralyzes the submarine\'s communications.'
            : 'Bút ký số 34: Lôi hải long tích tụ luồng điện cao thế rực rỡ màu xanh sấm sét quanh các gai lưng. Sức mạnh dòng điện làm tê liệt tạm thời hệ thống liên lạc của tàu ngầm.';
      case 'ghost_leviathan':
        return isEn
            ? 'Log Entry #78: The colossal translucent phantom patrols the boundaries of the void. Its bioluminescent body glides like a giant ribbon of neon through the deep waters.'
            : 'Bút ký số 78: Con quái thú ma quái trong suốt khổng lồ tuần tra ranh giới hư vô. Thân hình phát quang của nó lướt đi như một dải lụa neon khổng lồ phát sáng rực rỡ giữa vùng nước thẳm.';
      case 'godzilla':
        return isEn
            ? 'Log Entry #90: The King of Monsters Godzillaa is slumbering under nuclear radiation recovery at the bottom of the Pacific. Its jagged dorsal fins pulse with a faint, beautiful blue light.'
            : 'Bút ký số 90: Vua quái thú Godzillaa đang ngủ say trong tư thế phục hồi bức xạ dưới đáy Thái Bình Dương. Vây lưng gai của nó phát ánh sáng xanh hạt nhân le lói tuyệt đẹp.';
      default:
        return isEn
            ? 'Captain\'s logbook entry for the deep-sea exploration mission.'
            : 'Nhật ký hành trình thám hiểm biển sâu của thuyền trưởng.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<DataService>(context);
    final strings = AppStrings.listen(context);

    return Scaffold(
      backgroundColor: const Color(0xFF020813),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1F3D).withValues(alpha: 0.8),
        elevation: 0,
        title: Text(
          strings.logbookTitle,
          style: const TextStyle(
            color: Color(0xFF00F0FF),
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
        actions: [
          buildVolumeButton(context),
          buildSettingsButton(context),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00F0FF),
          labelColor: const Color(0xFF00F0FF),
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(text: strings.tabCreatures),
            Tab(text: strings.tabMedals),
          ],
        ),
      ),
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
          // 2. Abyssal dark overlay
          Positioned.fill(
            child: Container(
              color: const Color(0xFF020813).withValues(alpha: 0.75),
            ),
          ),
          // 3. Main content
          SafeArea(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCreatureLog(dataService),
                _buildMissionLog(dataService),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatureLog(DataService dataService) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      itemCount: dataService.creatures.length,
      itemBuilder: (context, index) {
        final creature = dataService.creatures[index];
        return _buildCreatureDossierCard(creature);
      },
    );
  }

  Widget _buildCreatureDossierCard(Creature creature) {
    final strings = AppStrings.of(context);
    final bool isHighDanger = creature.dangerLevel >= 4;
    final Color accentColor = creature.isLocked
        ? Colors.white24
        : (isHighDanger ? const Color(0xFFFF3366) : const Color(0xFF00F0FF));

    return GestureDetector(
      onTap: () {
        if (!creature.isLocked) {
          _showCreatureLogDetail(creature);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF030D1C),
              shape: RoundedRectangleBorder(
                side: BorderSide(color: const Color(0xFFFF3366).withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(8),
              ),
              content: Text(
                strings.languageCode == 'en'
                    ? 'SIGNAL LOCKED. Scan with Sonar at depth ${creature.minDepth}m to decode!'
                    : 'TÍN HIỆU ĐANG KHÓA. Hãy dò quét Sonar ở độ sâu ${creature.minDepth}m để giải mã!',
                style: const TextStyle(color: Color(0xFFFF3366), fontFamily: 'monospace', fontSize: 11),
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        height: 390,
        decoration: BoxDecoration(
          color: const Color(0xFF020917).withValues(alpha: 0.65),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.25),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.03),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Holographic background watermark icon
            Positioned(
              right: 16,
              bottom: 12,
              child: Opacity(
                opacity: 0.05,
                child: Icon(
                  creature.type == 'myth' ? Icons.storm : Icons.waves,
                  color: accentColor,
                  size: 90,
                ),
              ),
            ),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Huge Cinematic Image
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Grid under image
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.08,
                          child: GridPaper(
                            color: accentColor,
                            divisions: 1,
                            subdivisions: 1,
                            interval: 40,
                          ),
                        ),
                      ),
                      
                      // Widescreen image/video
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(15),
                        ),
                        child: creature.isLocked
                            ? creature.buildImage(
                                fit: BoxFit.cover,
                                color: Colors.black.withValues(alpha: 0.95),
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: const Color(0xFF030D1C),
                                  child: Icon(Icons.waves, color: accentColor, size: 48),
                                ),
                              )
                            : (creature.videoUrl.isNotEmpty)
                                ? CachedCreatureVideoPlayer(
                                    videoUrl: creature.videoUrl,
                                    placeholder: creature.buildImage(
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: const Color(0xFF030D1C),
                                        child: Icon(Icons.waves, color: accentColor, size: 48),
                                      ),
                                    ),
                                  )
                                : creature.buildImage(
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: const Color(0xFF030D1C),
                                      child: Icon(Icons.waves, color: accentColor, size: 48),
                                    ),
                                  ),
                      ),
                      
                      // Vignette overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                const Color(0xFF020917).withValues(alpha: 0.4),
                                const Color(0xFF020917),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                      
                      // Cyber target corners painter
                      Positioned.fill(
                        child: CustomPaint(
                          painter: LogbookBracketsPainter(color: accentColor),
                        ),
                      ),
                      
                      // Lock overlay if locked
                      if (creature.isLocked)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(15),
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.lock_outline, color: Colors.white60, size: 36),
                                const SizedBox(height: 8),
                                Text(
                                  strings.languageCode == 'en' ? "SIGNAL LOCKED BY PRESSURE" : "TÍN HIỆU ĐÃ BỊ KHÓA BỞI ÁP SUẤT",
                                  style: const TextStyle(color: Colors.white54, fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold, letterSpacing: 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                      // Neon top-left indicator bar
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 4.0,
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(2),
                              bottomRight: Radius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 2. Info section at bottom
                Container(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title & Scientific Name Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  creature.isLocked
                                      ? (strings.languageCode == 'en' ? 'UNIDENTIFIED CREATURE' : 'THỰC THỂ LẠ (UNIDENTIFIED)')
                                      : creature.getName(strings.languageCode).toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: creature.isLocked ? Colors.white38 : Colors.white,
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  creature.isLocked
                                      ? (strings.languageCode == 'en' ? 'CLASSIFICATION // UNIDENTIFIED' : 'PHÂN KHU // CHƯA XÁC ĐỊNH')
                                      : creature.scientificName.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: creature.isLocked ? Colors.white12 : const Color(0xFF00F0FF).withValues(alpha: 0.6),
                                    fontSize: 9.5,
                                    fontFamily: 'monospace',
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Decoded / Locked Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: creature.isLocked
                                  ? Colors.white10
                                  : (isHighDanger ? const Color(0xFFFF3366).withValues(alpha: 0.1) : const Color(0xFF00F0FF).withValues(alpha: 0.1)),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: creature.isLocked
                                      ? Colors.white12
                                      : (isHighDanger ? const Color(0xFFFF3366).withValues(alpha: 0.3) : const Color(0xFF00F0FF).withValues(alpha: 0.3)),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              creature.isLocked ? 'LOCKED // SECURE' : 'DECODED // ONLINE',
                              style: TextStyle(
                                color: creature.isLocked
                                    ? Colors.white30
                                    : (isHighDanger ? const Color(0xFFFF3366) : const Color(0xFF00F0FF)),
                                fontSize: 7.5,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      const Divider(color: Colors.white10, height: 1, thickness: 1),
                      const SizedBox(height: 8),
                      
                      // Biometrics grid
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Danger / Threat level
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  strings.languageCode == 'en' ? 'DANGER: ' : 'ĐỘ NGUY HIỂM: ',
                                  style: const TextStyle(color: Colors.white24, fontSize: 8.5, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                                ),
                                Expanded(
                                  child: Text(
                                    creature.isLocked ? '?.?/5' : '★' * creature.dangerLevel + '☆' * (5 - creature.dangerLevel),
                                    style: TextStyle(
                                      color: creature.isLocked
                                          ? Colors.white24
                                          : (isHighDanger ? const Color(0xFFFF3366) : const Color(0xFF00F0FF)),
                                      fontSize: 9.5,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Depth parameters
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  strings.languageCode == 'en' ? 'RANGE: ' : 'PHÂN BỐ: ',
                                  style: const TextStyle(color: Colors.white24, fontSize: 8.5, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                                ),
                                Text(
                                  creature.isLocked ? '${creature.minDepth}m' : '${creature.minDepth}m - ${creature.maxDepth}m',
                                  style: TextStyle(
                                    color: creature.isLocked ? Colors.green.withValues(alpha: 0.5) : const Color(0xFF00F0FF),
                                    fontSize: 9.5,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightedCaptainLog(String text) {
    final RegExp highlightRegex = RegExp(
      r"(Bút ký số \d+:|"
      r"đại dương|biển sâu|bóng tối|bóng đêm|hoàng hôn|Midnight Zone|"
      r"kẻ săn mồi|sinh vật|thủy quái|tà thần|"
      r"áp lực vỏ|sụt giảm nghiêm trọng|áp lực nước|sức ép nước|"
      r"hàm răng nhọn hoắt|răng cưa sắc nhọn|đôi mắt to|"
      r"xúc tu khổng lồ|xúc tu|cú quấn|"
      r"Cá mập trắng lớn|Cá hề|Cá hố dài|Mực khổng lồ|Mực ma cà rồng|Cá vây chân|Bọ chân đều khổng lồ|Cá rồng đen|Cá mập Greenland|Kraken|The Bloop|Đại Long Leviathan|Mãng Xà Biển|Tà Thần Cthulhu|Megalodon|Reaper Leviathan|Jörmungandr|Lôi hải long|Lagiacrus|Godzillaa|"
      r"gầm rú|chấn động|sóng âm|lá chắn điện từ|thiết bị đo địa chấn|cảm biến|quá tải|tê liệt|"
      r"Mariana|R'lyeh|Bắc Cực|Thái Bình Dương|"
      r"thoát ngay lập tức|im lặng tuyệt đối|rung lắc dữ dội)",
      caseSensitive: false,
    );

    final List<TextSpan> spans = [];

    text.splitMapJoin(
      highlightRegex,
      onMatch: (Match match) {
        final String matchText = match[0]!;
        spans.add(TextSpan(
          text: matchText,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.amber,
          ),
        ));
        return '';
      },
      onNonMatch: (String nonMatchText) {
        spans.add(TextSpan(
          text: nonMatchText,
          style: const TextStyle(
            color: Colors.amberAccent,
          ),
        ));
        return '';
      },
    );

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 12.5,
          height: 1.6,
          fontFamily: 'monospace',
        ),
        children: spans,
      ),
    );
  }

  void _showCreatureLogDetail(Creature creature) {
    final strings = AppStrings.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1F3D),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white30,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Immersive Creature Image (Full width, height 220, HUD brackets)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: creature.isLocked
                            ? creature.buildImage(
                                width: double.infinity,
                                height: 330,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: double.infinity,
                                  height: 330,
                                  color: const Color(0xFF020813),
                                  child: const Icon(Icons.waves, color: Color(0xFF00F0FF), size: 48),
                                ),
                              )
                            : (creature.videoUrl.isNotEmpty)
                                ? SizedBox(
                                    width: double.infinity,
                                    height: 330,
                                    child: CachedCreatureVideoPlayer(
                                      videoUrl: creature.videoUrl,
                                      placeholder: creature.buildImage(
                                        width: double.infinity,
                                        height: 330,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          width: double.infinity,
                                          height: 330,
                                          color: const Color(0xFF020813),
                                          child: const Icon(Icons.waves, color: Color(0xFF00F0FF), size: 48),
                                        ),
                                      ),
                                    ),
                                  )
                                : creature.buildImage(
                                    width: double.infinity,
                                    height: 330,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: double.infinity,
                                      height: 330,
                                      color: const Color(0xFF020813),
                                      child: const Icon(Icons.waves, color: Color(0xFF00F0FF), size: 48),
                                    ),
                                  ),
                      ),
                      // Vignette overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                const Color(0xFF0D1F3D).withValues(alpha: 0.7),
                                const Color(0xFF0D1F3D),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                      // Target brackets overlay
                      Positioned.fill(
                        child: CustomPaint(
                          painter: LogbookBracketsPainter(
                            color: creature.dangerLevel >= 4
                                ? const Color(0xFFFF3366)
                                : const Color(0xFF00F0FF),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Header details
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              creature.getName(strings.languageCode).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              creature.scientificName,
                              style: const TextStyle(
                                color: Color(0xFF00F0FF),
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Biometrics HUD grid
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHUDText(
                                strings.languageCode == 'en' ? 'THREAT LEVEL' : 'MỨC NGUY HIỂM',
                                '★' * creature.dangerLevel + '☆' * (5 - creature.dangerLevel),
                                creature.dangerLevel >= 4
                                    ? const Color(0xFFFF3366)
                                    : const Color(0xFF00F0FF),
                              ),
                              const SizedBox(height: 6),
                              _buildHUDText(
                                strings.languageCode == 'en' ? 'DEPTH DISTRIBUTION' : 'ĐỘ SÂU PHÂN BỐ',
                                '${creature.minDepth}m - ${creature.maxDepth}m',
                                const Color(0xFF00F0FF),
                              ),
                              const SizedBox(height: 6),
                              _buildHUDText(
                                strings.languageCode == 'en' ? 'SIZE RELATION' : 'TỶ LỆ KÍCH THƯỚC',
                                creature.getSizeHumanRatio(strings.languageCode),
                                const Color(0xFF00F0FF),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Captain Logbook text (retro box)
                  Text(
                    strings.languageCode == 'en' ? 'CAPTAIN\'S VOYAGE LOG' : 'BÚT KÝ HÀNH TRÌNH CỦA THUYỀN TRƯỞNG',
                    style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF010307),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                    ),
                    child: _buildHighlightedCaptainLog(_getCaptainLog(creature.id, strings.languageCode)),
                  ),
                  const SizedBox(height: 24),
                  
                  // Description
                  Text(
                    strings.languageCode == 'en' ? 'FIELD EXPLORATION LOG' : 'NHẬT KÝ THÁM HIỂM THỰC ĐỊA',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  const SizedBox(height: 8),
                  StructuredDescriptionWidget(
                    description: creature.getDescription(strings.languageCode),
                    themeColor: const Color(0xFF00F0FF),
                    compact: false,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHUDText(String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }

  Widget _buildMissionLog(DataService dataService) {
    if (!_prefsLoaded) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00F0FF)),
        ),
      );
    }

    final strings = AppStrings.of(context);
    final isEn = strings.languageCode == 'en';
    final bestDepth = dataService.highScoreDepth;
    final totalCreatures = dataService.creatures.length;
    final unlockedCreatures = dataService.creatures.where((c) => !c.isLocked).length;

    return Container(
      color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
      child: GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.zero,
        crossAxisSpacing: 1.5,
        mainAxisSpacing: 1.5,
        childAspectRatio: 1.02,
        physics: const BouncingScrollPhysics(),
        children: [
        MedalWidget(
          type: MedalType.twilightScout,
          title: isEn ? 'Twilight Scout' : 'Hoàng Hôn Thám Hiểm',
          description: isEn ? 'Descend to at least 1,000m in the simulator.' : 'Lặn sâu đạt tối thiểu 1,000m trong mô phỏng.',
          progressText: '$bestDepth / 1000m',
          isUnlocked: bestDepth >= 1000,
          alreadyAnimated: _animatedMedals['twilight_scout'] ?? false,
          onUnlockAnimationComplete: () => _onMedalUnlockAnimated('twilight_scout'),
        ),
        MedalWidget(
          type: MedalType.midnightExplorer,
          title: isEn ? 'Midnight Explorer' : 'Đột Phá Vùng Tối',
          description: isEn ? 'Descend to at least 4,000m in the simulator.' : 'Lặn sâu đạt tối thiểu 4,000m trong mô phỏng.',
          progressText: '$bestDepth / 4000m',
          isUnlocked: bestDepth >= 4000,
          alreadyAnimated: _animatedMedals['midnight_explorer'] ?? false,
          onUnlockAnimationComplete: () => _onMedalUnlockAnimated('midnight_explorer'),
        ),
        MedalWidget(
          type: MedalType.abyssalPioneer,
          title: isEn ? 'Abyssal Pioneer' : 'Tiên Phong Vực Thẳm',
          description: isEn ? 'Descend to at least 8,000m in the simulator.' : 'Lặn sâu đạt tối thiểu 8,000m trong mô phỏng.',
          progressText: '$bestDepth / 8000m',
          isUnlocked: bestDepth >= 8000,
          alreadyAnimated: _animatedMedals['abyssal_pioneer'] ?? false,
          onUnlockAnimationComplete: () => _onMedalUnlockAnimated('abyssal_pioneer'),
        ),
        MedalWidget(
          type: MedalType.marianaConqueror,
          title: isEn ? 'Mariana Conqueror' : 'Kinh Điển Mariana',
          description: isEn ? 'Descend to the bottom of the Mariana Trench at 11,000m.' : 'Lặn sâu chạm đáy Mariana 11,000m.',
          progressText: '$bestDepth / 11000m',
          isUnlocked: bestDepth >= 11000,
          alreadyAnimated: _animatedMedals['mariana_conqueror'] ?? false,
          onUnlockAnimationComplete: () => _onMedalUnlockAnimated('mariana_conqueror'),
        ),
        MedalWidget(
          type: MedalType.cryptographer,
          title: isEn ? 'Expert Cryptographer' : 'Chuyên Gia Giải Mã',
          description: isEn ? 'Successfully decode 10 ocean creatures via Sonar.' : 'Giải mã thành công 10 sinh vật đại dương qua Sonar.',
          progressText: isEn ? '$unlockedCreatures / 10 creatures' : '$unlockedCreatures / 10 sinh vật',
          isUnlocked: unlockedCreatures >= 10,
          alreadyAnimated: _animatedMedals['cryptographer'] ?? false,
          onUnlockAnimationComplete: () => _onMedalUnlockAnimated('cryptographer'),
        ),
        MedalWidget(
          type: MedalType.deepseaLegend,
          title: isEn ? 'Deep Sea Legend' : 'Huyền Thoại Biển Sâu',
          description: isEn ? 'Successfully decode all 20 creatures.' : 'Giải mã hoàn thành tất cả 20 sinh vật.',
          progressText: isEn ? '$unlockedCreatures / $totalCreatures creatures' : '$unlockedCreatures / $totalCreatures sinh vật',
          isUnlocked: unlockedCreatures == totalCreatures,
          alreadyAnimated: _animatedMedals['deepsea_legend'] ?? false,
          onUnlockAnimationComplete: () => _onMedalUnlockAnimated('deepsea_legend'),
        ),
      ],
    ),
  );
}
}

class LogbookBracketsPainter extends CustomPainter {
  final Color color;

  LogbookBracketsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final double w = size.width;
    final double h = size.height;
    final double pad = 12.0;
    
    // Draw corner brackets around the photo frame
    // Top Left
    canvas.drawLine(Offset(pad, pad), Offset(pad + 16, pad), paint);
    canvas.drawLine(Offset(pad, pad), Offset(pad, pad + 16), paint);
    
    // Top Right
    canvas.drawLine(Offset(w - pad, pad), Offset(w - pad - 16, pad), paint);
    canvas.drawLine(Offset(w - pad, pad), Offset(w - pad, pad + 16), paint);

    // Bottom Left
    canvas.drawLine(Offset(pad, h - pad), Offset(pad + 16, h - pad), paint);
    canvas.drawLine(Offset(pad, h - pad), Offset(pad, h - pad - 16), paint);

    // Bottom Right
    canvas.drawLine(Offset(w - pad, h - pad), Offset(w - pad - 16, h - pad), paint);
    canvas.drawLine(Offset(w - pad, h - pad), Offset(w - pad, h - pad - 16), paint);

    // Center crosshair
    final center = Offset(w / 2, h / 2);
    canvas.drawLine(Offset(center.dx - 8, center.dy), Offset(center.dx - 3, center.dy), paint);
    canvas.drawLine(Offset(center.dx + 3, center.dy), Offset(center.dx + 8, center.dy), paint);
    canvas.drawLine(Offset(center.dx, center.dy - 8), Offset(center.dx, center.dy - 3), paint);
    canvas.drawLine(Offset(center.dx, center.dy + 3), Offset(center.dx, center.dy + 8), paint);
  }

  @override
  bool shouldRepaint(covariant LogbookBracketsPainter oldDelegate) => false;
}

class DossierTileBracketsPainter extends CustomPainter {
  final Color color;

  DossierTileBracketsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final double w = size.width;
    final double h = size.height;
    final double pad = 4.0;
    
    // Corner brackets
    canvas.drawLine(Offset(pad, pad), Offset(pad + 8, pad), paint);
    canvas.drawLine(Offset(pad, pad), Offset(pad, pad + 8), paint);
    
    canvas.drawLine(Offset(w - pad, pad), Offset(w - pad - 8, pad), paint);
    canvas.drawLine(Offset(w - pad, pad), Offset(w - pad, pad + 8), paint);

    canvas.drawLine(Offset(pad, h - pad), Offset(pad + 8, h - pad), paint);
    canvas.drawLine(Offset(pad, h - pad), Offset(pad, h - pad - 8), paint);

    canvas.drawLine(Offset(w - pad, h - pad), Offset(w - pad - 8, h - pad), paint);
    canvas.drawLine(Offset(w - pad, h - pad), Offset(w - pad, h - pad - 8), paint);
  }

  @override
  bool shouldRepaint(covariant DossierTileBracketsPainter oldDelegate) => false;
}

