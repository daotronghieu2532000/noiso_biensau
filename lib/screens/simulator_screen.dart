import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../services/data_service.dart';
import '../services/sound_service.dart';
import '../l10n/app_strings.dart';
import '../widgets/cached_video_player.dart';
import 'settings_screen.dart';

class SimulatorScreen extends StatefulWidget {
  const SimulatorScreen({super.key});

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class VesselConfig {
  final String id;
  final String nameVi;
  final String nameEn;
  final IconData iconData;
  final String imageAsset;
  final Color themeColor;
  final String descVi;
  final String descEn;
  final int bonusO2Charges;
  final int bonusHullCharges;
  final double damageReduction;
  final double energyRegenMultiplier;
  final double threatAvoidance;

  const VesselConfig({
    required this.id,
    required this.nameVi,
    required this.nameEn,
    required this.iconData,
    required this.imageAsset,
    required this.themeColor,
    required this.descVi,
    required this.descEn,
    this.bonusO2Charges = 0,
    this.bonusHullCharges = 0,
    this.damageReduction = 0.0,
    this.energyRegenMultiplier = 1.0,
    this.threatAvoidance = 0.0,
  });
}

class TechPerkConfig {
  final String id;
  final String nameVi;
  final String nameEn;
  final IconData icon;
  final String imageAsset;
  final Color color;
  final String descVi;
  final String descEn;

  const TechPerkConfig({
    required this.id,
    required this.nameVi,
    required this.nameEn,
    required this.icon,
    required this.imageAsset,
    required this.color,
    required this.descVi,
    required this.descEn,
  });
}

class _SimulatorScreenState extends State<SimulatorScreen> with SingleTickerProviderStateMixin {
  final math.Random _random = math.Random();
  final ScrollController _logScrollController = ScrollController();
  
  late AnimationController _hudAnimationController;
  late SoundService _soundService;

  bool _gameActive = false;
  bool _gameOver = false;
  int _depth = 0;
  double _oxygen = 1.0; // 0.0 to 1.0
  double _hull = 1.0;   // 0.0 to 1.0
  double _energy = 1.0; // 0.0 to 1.0
  
  int _oxygenCharges = 4;
  int _hullCharges = 4;
  bool _shieldActive = false;
  int _shieldSecondsLeft = 0;
  bool _isLogExpanded = false;

  // Customization State
  int _selectedVesselIndex = 0;
  final Set<int> _selectedPerkIndices = {0, 1};
  bool _autoDroneUsed = false;
  final Set<int> _reachedMilestones = {};

  static const List<VesselConfig> _vessels = [
    VesselConfig(
      id: 'explorer',
      nameVi: 'DSV Explorer (Thám Hiểm)',
      nameEn: 'DSV Explorer',
      iconData: Icons.explore_rounded,
      imageAsset: 'assets/images/creatures/sub_explorer.jpg',
      themeColor: Color(0xFF00F0FF),
      descVi: 'Tàu thám hiểm chuẩn cân bằng. Thưởng +1 lần bơm Oxy & +1 lần Hàn vỏ tàu.',
      descEn: 'Versatile sub. +1 Oxygen & +1 Hull Repair charge.',
      bonusO2Charges: 1,
      bonusHullCharges: 1,
    ),
    VesselConfig(
      id: 'titan',
      nameVi: 'Titan Fortress (Giáp Trụ)',
      nameEn: 'Titan Fortress',
      iconData: Icons.shield_rounded,
      imageAsset: 'assets/images/creatures/sub_titan.jpg',
      themeColor: Color(0xFFFFCC00),
      descVi: 'Pháo đài vỏ thép siêu dày. Giảm 35% sát thương quái vật & +2 lần Hàn vỏ tàu.',
      descEn: 'Titan armor. -35% creature damage & +2 Repair charges.',
      bonusHullCharges: 2,
      damageReduction: 0.35,
    ),
    VesselConfig(
      id: 'phantom',
      nameVi: 'Abyss Phantom (Bóng Ma)',
      nameEn: 'Abyss Phantom',
      iconData: Icons.visibility_off_rounded,
      imageAsset: 'assets/images/creatures/sub_phantom.jpg',
      themeColor: Color(0xFFA855F7),
      descVi: 'Tàng hình tản nhiệt. Giảm 40% đụng độ quái vật biển sâu.',
      descEn: 'Acoustic stealth camouflage. 40% fewer monster attacks.',
      threatAvoidance: 0.40,
    ),
    VesselConfig(
      id: 'hunter',
      nameVi: 'Leviathan Hunter (Săn Thủy Quái)',
      nameEn: 'Leviathan Hunter',
      iconData: Icons.bolt_rounded,
      imageAsset: 'assets/images/creatures/sub_hunter.jpg',
      themeColor: Color(0xFFFF3366),
      descVi: 'Lò phản ứng hạt nhân. Tốc độ sạc Năng lượng pin nhanh gấp 2 lần.',
      descEn: 'Hyper nuclear core. Double battery charge rate.',
      energyRegenMultiplier: 2.0,
    ),
  ];

  static const List<TechPerkConfig> _perks = [
    TechPerkConfig(
      id: 'o2_xl',
      nameVi: 'Bình Oxy XL',
      nameEn: 'O2 Reserve XL',
      icon: Icons.air_rounded,
      imageAsset: 'assets/images/creatures/perk_o2_xl.jpg',
      color: Colors.green,
      descVi: 'Tốc độ tiêu thụ Oxy chậm hơn 30%',
      descEn: 'Oxygen drains 30% slower',
    ),
    TechPerkConfig(
      id: 'capacitor',
      nameVi: 'Siêu Tụ Điện Pin',
      nameEn: 'Super Capacitor',
      icon: Icons.bolt_rounded,
      imageAsset: 'assets/images/creatures/perk_capacitor.jpg',
      color: Color(0xFF00F0FF),
      descVi: 'Tốc độ sạc Năng lượng tăng 50%',
      descEn: 'Energy recharges 50% faster',
    ),
    TechPerkConfig(
      id: 'auto_drone',
      nameVi: 'Drone Tự Sửa Chữa',
      nameEn: 'Auto Repair Drone',
      icon: Icons.precision_manufacturing_rounded,
      imageAsset: 'assets/images/creatures/perk_auto_drone.jpg',
      color: Color(0xFFFFCC00),
      descVi: 'Tự hồi 25% Giáp khi Hull dưới 25%',
      descEn: 'Auto restores 25% Hull when critical',
    ),
    TechPerkConfig(
      id: 'abyss_radar',
      nameVi: 'Radar Viễn Thám',
      nameEn: 'Abyss Radar',
      icon: Icons.radar_rounded,
      imageAsset: 'assets/images/creatures/perk_abyss_radar.jpg',
      color: Color(0xFFA855F7),
      descVi: 'Tốc độ lặn nhanh hơn +30%',
      descEn: 'Descent speed increased by 30%',
    ),
  ];

  final List<String> _logs = [];
  Timer? _gameTimer;
  Timer? _shieldTimer;

  // Visual effects states
  double _shakeX = 0.0;
  double _shakeY = 0.0;
  bool _shieldTriggeredFlash = false;
  String? _activeThreat;
  int _threatTicks = 0;
  bool _oxygenWarningActive = false;

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

  static const List<String> _allSimulatorVideos = [
    'https://codego.io.vn/api/uploads/videos/Above%20the%20Deck...%20Into%20the%20Frozen%20End%20of%20the%20World%20%20Towering%20masts...%20Endless%20ice...%20And%20one%20of%20the%20planet\'s%20most%20remote%20oceans%20stretching%20to%20the%20horizon.%20This%20image%20appears%20to%20show%20the%20--mast%20of%20the%20historic%20tall%20.mp4',
    'https://codego.io.vn/api/uploads/videos/Enjoy%20your%20deepest%20fears%E2%80%A6%20%23ai%20%23deepocean%20%23scifi%23kraken%23films.mp4',
    'https://codego.io.vn/api/uploads/videos/Rise%20of%20The%20Kraken%20%23creative%20%23vfx%20%23movie%20%23kraken%23monster.mp4',
    'https://codego.io.vn/api/uploads/videos/Rise%20of%20The%20Kraken%2C%20Coming%202027.%20%23creative%20%23vfx%20%23movie%20%23monster%20%23kraken.mp4',
    'https://codego.io.vn/api/uploads/videos/V%C3%ADdeo%20Kraken%20100_%20IA%20Workflow%20de%20Nano%20b.mp4',
    'https://codego.io.vn/api/uploads/videos/S%C3%AD%2C%20conozco%20la%20historia%20de%20Cthulhu%2C%20una%20de%20las%20criaturas%20m%C3%A1s%20ic%C3%B3nicas%20creadas%20por%20el%20escritor%20H.%20P.%20Lovecraft.%20Aqu%C3%AD%20te%20la%20cuento%20de%20forma%20clara%20v%C3%A0%20perturbadora%2C%20como%20suele%20gustar%20en%20tus%20contenidos-%20%20Qui%C3%A9n%20es%20Cthulhu.mp4',
    'https://codego.io.vn/api/uploads/videos/Livyatan%20%20The%20Giant%20Killer%20Whale%20of%20the%20Miocene%20%20Livyatan%20melvillei%20was%20a%20massive%20predatory%20whale%20that%20lived%20about%201213%20million%20years%20ago%20in%20the%20Miocene%20seas%20off%20Peru.%20It%20was%20one%20of%20the%20top%20ocean%20predators%20of%20its%20t.mp4',
    'https://codego.io.vn/api/uploads/videos/Lo%20que%20vimos%20desde%20el%20helic%C3%B3ptero%20nos%20dej%C3%B3%20sin%20alienti!%20%20Una%20criatura%20extra%C3%B1a%20tipo%20drag%C3%B3n%20marino%20luchando%20contra%20un%20pulpo%20gigante%20en%20el%20Pac%C3%ADfico.%20Inolvidable!%20%20%23Misterio%20%23Terror%20%23Mar%20%23impactante%20-------------------.mp4',
    'https://codego.io.vn/api/uploads/videos/Cient%C3%ADficos%20quedaron%20impactados%20al%20registrar%20esta%20extra%C3%B1a%20criatura%20en%20las%20profundidades%20del%20oc%C3%A9ano.%20Una%20recente%20expedici%C3%B3n%20cient%C3%ADfica%20realizada%20por%20investigadores%20de%20Australia%20en%20una%20zona%20remota%20del%20Oc%C3%A9ano%20%C3%8Dndico%20.mp4',
  ];

  late String _currentVideoUrl;

  @override
  void initState() {
    super.initState();
    _currentVideoUrl = _allSimulatorVideos[1];
    _backgroundImage = _bgImages[_random.nextInt(_bgImages.length)];
    _hudAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _preloadMonsterVideos();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _soundService = Provider.of<SoundService>(context, listen: false);
  }

  void _startGame() {
    final selectedVessel = _vessels[_selectedVesselIndex];
    setState(() {
      _gameActive = true;
      _gameOver = false;
      _depth = 0;
      _oxygen = 1.0;
      _hull = 1.0;
      _energy = 1.0;
      _oxygenCharges = 4 + selectedVessel.bonusO2Charges;
      _hullCharges = 4 + selectedVessel.bonusHullCharges;
      _shieldActive = false;
      _shieldSecondsLeft = 0;
      _activeThreat = null;
      _threatTicks = 0;
      _shakeX = 0.0;
      _shakeY = 0.0;
      _shieldTriggeredFlash = false;
      _oxygenWarningActive = false;
      _autoDroneUsed = false;
      _reachedMilestones.clear();
      _selectVideoForThreat(null);

      final isEn = AppStrings.of(context).languageCode == 'en';
      _logs.clear();
      _addLog(isEn 
          ? 'SYS: INITIALIZING ${selectedVessel.nameEn.toUpperCase()} SYSTEMS...' 
          : 'SYS: KHỞI ĐỘNG HỆ THỐNG TÀU ${selectedVessel.nameVi.toUpperCase()}...');
      _addLog(isEn ? 'SYS: HUD TELEMETRY LINK: CONNECTED' : 'SYS: LIÊN KẾT LIÊN LẠC HUD: KẾT NỐI');
      _addLog(isEn 
          ? 'SYS: ACTIVE PERKS: ${_getActivePerkNames(true)}'
          : 'SYS: MẠCH NÂNG CẤP: ${_getActivePerkNames(false)}');
      _addLog(isEn ? 'SYS: BEGINNING SUBMERSIBLE DESCENT INTO DEEP BASIN...' : 'SYS: BẮT ĐẦU THẢ TRÔI TÀU NGẦM XUỐNG VỰC SÂU...');
    });

    _ambientSoundForDepth(0);

    // Game loop ticks every 500ms
    _gameTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _tickGame();
    });
  }

  String _getActivePerkNames(bool isEn) {
    if (_selectedPerkIndices.isEmpty) return isEn ? 'None' : 'Không có';
    return _selectedPerkIndices
        .map((i) => isEn ? _perks[i].nameEn : _perks[i].nameVi)
        .join(', ');
  }

  void _addLog(String text) {
    if (!mounted) return;
    setState(() {
      _logs.add('[${_formatTime(DateTime.now())}] $text');
    });
    // Auto-scroll log to bottom
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_logScrollController.hasClients) {
        _logScrollController.animateTo(
          _logScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime dt) {
    return '${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}.${(dt.millisecond ~/ 100)}';
  }

  void _tickGame() {
    if (!mounted || !_gameActive || _gameOver) return;

    final selectedVessel = _vessels[_selectedVesselIndex];
    final hasCapacitor = _selectedPerkIndices.contains(1);
    final hasO2Xl = _selectedPerkIndices.contains(0);
    final hasAutoDrone = _selectedPerkIndices.contains(2);
    final hasAbyssRadar = _selectedPerkIndices.contains(3);

    setState(() {
      // 1. Descend depth (approx 75m per tick, modified by Radar perk)
      double depthStep = (75 + _random.nextInt(35)).toDouble();
      if (hasAbyssRadar) depthStep *= 1.30;
      _depth += depthStep.toInt();

      // Check depth milestone video events
      _checkDepthMilestones();

      // 2. Consume oxygen (0.007 per tick - balanced for deep survival)
      double o2Drain = 0.007;
      if (_depth > 6000) o2Drain = 0.010;
      if (_depth > 10000) o2Drain = 0.014;
      if (hasO2Xl) o2Drain *= 0.70;

      _oxygen = (_oxygen - o2Drain).clamp(0.0, 1.0);
      _updateOxygenWarningSound();

      // 3. Recharge energy
      if (!_shieldActive) {
        double energyRegen = 0.008 * selectedVessel.energyRegenMultiplier;
        if (hasCapacitor) energyRegen *= 1.5;
        _energy = (_energy + energyRegen).clamp(0.0, 1.0);
      }

      // 4. Auto Drone Perk check
      if (hasAutoDrone && !_autoDroneUsed && _hull < 0.25 && _hull > 0.0) {
        _hull = (_hull + 0.25).clamp(0.0, 1.0);
        _autoDroneUsed = true;
        final isEn = AppStrings.of(context).languageCode == 'en';
        _addLog(isEn 
            ? 'ROBOT: AUTO-REPAIR DRONES ACTIVATED! Hull restored +25%!' 
            : 'ROBOT: DRONE TỰ SỬA CHỮA KÍCH HOẠT KhỦNG! Phục hồi +25% giáp!');
        _soundService.playCreatureSound("low_pressure.m4a");
      }

      // 5. Random Events based on depth (pass stealth avoidance)
      _triggerDepthEvents(selectedVessel.threatAvoidance, selectedVessel.damageReduction);

      // Decrement active threat ticks
      if (_activeThreat != null) {
        _threatTicks--;
        if (_threatTicks <= 0) {
          _activeThreat = null;
          _selectVideoForThreat(null);
        }
      }

      // 6. Check Game Over
      final isEn = AppStrings.of(context).languageCode == 'en';
      if (_oxygen <= 0.0) {
        _endGame(isEn ? 'OXYGEN DEPLETED - CREW SUFFOCATED' : 'OXY CẠN KIỆT - THỦY THỦ ĐOÀN NGẠT KHÍ');
      } else if (_hull <= 0.0) {
        _endGame(isEn ? 'CRUSH PRESSURE DESTROYED HULL - IMPLOSION' : 'ÁP SUẤT NGHIỀN NÁT VỎ TÀU NGẦM - NỔ TUNG');
      }
    });
  }

  void _checkDepthMilestones() {
    final milestones = [
      {'depth': 2000, 'vi': 'ĐẠT MỐC 2,000M - VÙNG TRUNG HẢI. Mở khóa Video Sinh vật Biển Sâu!', 'videoIndex': 0},
      {'depth': 5000, 'vi': 'ĐẠT MỐC 5,000M - VÙNG THẢM VỰC. Mở khóa Video Thủy Quái Leviathan!', 'videoIndex': 7},
      {'depth': 8000, 'vi': 'ĐẠT MỐC 8,000M - VỰC HADAL BĂNG GIÁ. Mở khóa Video Kraken Băng!', 'videoIndex': 4},
      {'depth': 12000, 'vi': 'ĐẠT MỐC 12,000M - LÒNG VỰC MARIANA. Mở khóa Video Tà Thần Cthulhu!', 'videoIndex': 5},
      {'depth': 18000, 'vi': 'ĐẠT MỐC 18,000M - BIỂN CỔ ĐẠI THÁI BÌNH DƯƠNG. Mở khóa Video Rồng Biển!', 'videoIndex': 7},
      {'depth': 25000, 'vi': 'ĐẠT MỐC 25,000M - TÂM TRÁI ĐẤT! BẠN LÀ THỦY THỦ HUYỀN THOẠI!', 'videoIndex': 3},
    ];

    for (final m in milestones) {
      final depthReq = m['depth'] as int;
      if (_depth >= depthReq && !_reachedMilestones.contains(depthReq)) {
        _reachedMilestones.add(depthReq);
        final viText = m['vi'] as String;
        final vIndex = m['videoIndex'] as int;
        _addLog('🏆 MILESTONE: $viText');
        _soundService.playCreatureSound("leviathan_groan.mp3");
        if (_activeThreat == null) {
          _currentVideoUrl = _allSimulatorVideos[vIndex % _allSimulatorVideos.length];
        }
      }
    }
  }

  void _preloadMonsterVideos() {
    for (final url in _allSimulatorVideos) {
      final cacheBusterUrl = url.contains('?') ? '$url&cb=1.0.4_v1' : '$url?cb=1.0.4_v1';
      DefaultCacheManager().getSingleFile(cacheBusterUrl).then((_) {}, onError: (e) {});
    }
  }

  void _selectVideoForThreat(String? threat) {
    if (threat == null) {
      _currentVideoUrl = _allSimulatorVideos[_random.nextInt(2)];
      return;
    }
    List<String> pool;
    switch (threat) {
      case 'kraken':
        pool = [_allSimulatorVideos[2], _allSimulatorVideos[3], _allSimulatorVideos[4]];
        break;
      case 'cthulhu':
        pool = [_allSimulatorVideos[5], _allSimulatorVideos[1]];
        break;
      case 'shark':
        pool = [_allSimulatorVideos[6], _allSimulatorVideos[7]];
        break;
      case 'bloop':
        pool = [_allSimulatorVideos[7], _allSimulatorVideos[8]];
        break;
      case 'vent':
        pool = [_allSimulatorVideos[8], _allSimulatorVideos[0]];
        break;
      case 'twilight':
      case 'midnight':
      default:
        pool = [_allSimulatorVideos[1], _allSimulatorVideos[0]];
        break;
    }
    _currentVideoUrl = pool[_random.nextInt(pool.length)];
  }

  void _triggerDepthEvents(double threatAvoidance, double damageReduction) {
    // Occur randomly with adjusted frequency for exciting gameplay
    if (_random.nextDouble() > 0.35) return;
    // Stealth avoidance check
    if (threatAvoidance > 0 && _random.nextDouble() < threatAvoidance) return;

    final isEn = AppStrings.of(context).languageCode == 'en';

    if (_depth > 500 && _depth < 1000 && !_logs.any((l) => l.contains('TWILIGHT') || l.contains('Hoàng Hôn'))) {
      _addLog(isEn ? 'WARNING: Entering Twilight Zone. Sunlight fades away.' : 'CẢNH BÁO: Đi vào vùng Hoàng Hôn (Twilight Zone). Ánh sáng mặt trời tắt dần.');
      _activeThreat = 'twilight';
      _threatTicks = 12;
      _selectVideoForThreat(_activeThreat);
    }
    else if (_depth > 1000 && _depth < 1500 && !_logs.any((l) => l.contains('MIDNIGHT') || l.contains('Nửa Đêm'))) {
      _addLog(isEn ? 'WARNING: Entering Midnight Zone. High-power spotlights engaged.' : 'CẢNH BÁO: Đi vào vùng Nửa Đêm (Midnight Zone). Bật đèn pha công suất cao.');
      _soundService.playCreatureSound("low_pressure.m4a");
      _activeThreat = 'midnight';
      _threatTicks = 14;
      _selectVideoForThreat(_activeThreat);
    }
    else if (_depth > 1500 && _depth < 3000 && _random.nextDouble() < 0.40) {
      _addLog(isEn ? 'HAZARD: Encountered boiling underwater hydrothermal vent plume!' : 'SỰ CỐ: Gặp luồng phun thủy nhiệt ngầm sục sôi!');
      _activeThreat = 'vent';
      _threatTicks = 16;
      _selectVideoForThreat(_activeThreat);
      _soundService.playCreatureSound("shark_heartbeat.mp3");
      if (_shieldActive) {
        _addLog(isEn ? 'SHIELD: Thermal vent impact absorbed by electromagnetic deflector.' : 'KÝ HIỆU: Lá chắn hấp thụ chấn động thủy nhiệt.');
        _triggerShieldFlash();
      } else {
        double rawDmg = 0.15 + _random.nextDouble() * 0.08;
        double dmg = rawDmg * (1.0 - damageReduction);
        _hull = (_hull - dmg).clamp(0.0, 1.0);
        _addLog(isEn ? 'ALERT: Hull heat fractures detected! Armor decreased by ${(dmg * 100).toInt()}%!' : 'BÁO ĐỘNG: Vỏ tàu bị nứt nhiệt! Độ bền giáp giảm ${(dmg * 100).toInt()}%!');
        _triggerShake(intensity: 8.0);
      }
    }
    else if (_depth > 3000 && _depth < 4500 && _random.nextDouble() < 0.40) {
      _addLog(isEn ? 'DETECTION: Hostile pack of prehistoric sharks surrounding the vessel!' : 'PHÁT HIỆN: Đàn cá mập cổ đại hung tợn vây quanh tàu!');
      _activeThreat = 'shark';
      _threatTicks = 18;
      _selectVideoForThreat(_activeThreat);
      _soundService.playCreatureSound("shark_heartbeat.mp3");
      if (_shieldActive) {
        _addLog(isEn ? 'SHIELD: Electromagnetic screen repelled the shark pack.' : 'KÝ HIỆU: Lá chắn điện từ đẩy lùi đàn cá mập.');
        _triggerShieldFlash();
      } else {
        double rawDmg = 0.12;
        double dmg = rawDmg * (1.0 - damageReduction);
        _hull = (_hull - dmg).clamp(0.0, 1.0);
        _addLog(isEn ? 'ALERT: Shark rammed into viewing viewport! Armor decreased by ${(dmg * 100).toInt()}%!' : 'BÁO ĐỘNG: Cá mập tấn công đâm vào kính ngắm! Giáp giảm ${(dmg * 100).toInt()}%!');
        _triggerShake(intensity: 10.0);
      }
    }
    else if (_depth > 4500 && _depth < 7000 && _random.nextDouble() < 0.40) {
      _addLog(isEn ? 'WARNING: Massive biomass tremor signature. Kraken leviathan approaching!' : 'CẢNH BÁO: Phát hiện chấn động biomass lớn. Thủy quái Kraken đang áp sát!');
      _activeThreat = 'kraken';
      _threatTicks = 18;
      _selectVideoForThreat(_activeThreat);
      _soundService.playCreatureSound("leviathan_groan.mp3");
      if (_shieldActive) {
        _addLog(isEn ? 'SHIELD: Electromagnetic shield deflected Kraken constricting wrap.' : 'KÝ HIỆU: Lá chắn chặn đứng cú quấn siết của Kraken.');
        _triggerShieldFlash();
      } else {
        double rawDmg = 0.22;
        double dmg = rawDmg * (1.0 - damageReduction);
        _hull = (_hull - dmg).clamp(0.0, 1.0);
        _addLog(isEn ? 'ALERT: Kraken tentacle slammed the hull! Armor integrity decreased by ${(dmg * 100).toInt()}%!' : 'BÁO ĐỘNG: Xúc tu Kraken quất mạnh vào vỏ tàu! Giáp giảm ${(dmg * 100).toInt()}%!');
        _triggerShake(intensity: 14.0);
      }
    }
    else if (_depth > 7000 && _depth < 9500 && _random.nextDouble() < 0.40) {
      _addLog(isEn ? 'WARNING: Ultra-low frequency infrasound "The Bloop" swept through!' : 'CẢNH BÁO: Sóng siêu âm tần số cực thấp "The Bloop" quét qua!');
      _activeThreat = 'bloop';
      _threatTicks = 18;
      _selectVideoForThreat(_activeThreat);
      _soundService.playCreatureSound("leviathan_groan.mp3");
      _energy = (_energy - 0.20).clamp(0.0, 1.0);
      _addLog(isEn ? 'SYS: Severe electromagnetic interference! Battery cells drained by 20%!' : 'SYS: Nhiễu loạn điện từ cực mạnh! Năng lượng dự trữ giảm 20%!');
      _triggerShake(intensity: 5.0);
    }
    else if (_depth >= 9500 && _random.nextDouble() < 0.45) {
      _addLog(isEn ? 'WARNING: Eerie telepathic feedback from Old God Cthulhu detected!' : 'CẢNH BÁO: Tín hiệu thần giao cách cảm ma quái của Tà Thần Cthulhu!');
      _activeThreat = 'cthulhu';
      _threatTicks = 18;
      _selectVideoForThreat(_activeThreat);
      _soundService.playCreatureSound("leviathan_groan.mp3");
      if (_shieldActive) {
        _addLog(isEn ? 'SHIELD: Psychic ward blocked Cthulhu mental disturbance.' : 'KÝ HIỆU: Hào quang tâm linh chặn đứng tác động từ Cthulhu.');
        _triggerShieldFlash();
      } else {
        _oxygen = (_oxygen - 0.12).clamp(0.0, 1.0);
        _addLog(isEn ? 'ALERT: Respiration rate increased under psychic shock! O2 decreased by 12%!' : 'BÁO ĐỘNG: Thủy thủ đoàn hoảng sợ! Oxy hao hụt 12%!');
        _triggerShake(intensity: 6.0);
      }
    }
  }

  void _triggerShake({double intensity = 8.0}) {
    int ticks = 0;
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (ticks >= 10 || !_gameActive) {
        if (mounted) {
          setState(() {
            _shakeX = 0;
            _shakeY = 0;
          });
        }
        timer.cancel();
        return;
      }
      if (mounted) {
        setState(() {
          _shakeX = (_random.nextDouble() * 2 - 1) * intensity;
          _shakeY = (_random.nextDouble() * 2 - 1) * intensity;
        });
      }
      ticks++;
    });
  }

  void _triggerShieldFlash() {
    if (!mounted) return;
    setState(() {
      _shieldTriggeredFlash = true;
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _shieldTriggeredFlash = false;
        });
      }
    });
  }

  void _ambientSoundForDepth(int depth) {
    if (depth < 4000) {
      _soundService.playAmbient("low_pressure.m4a");
      _soundService.stopSecondaryAmbient();
    } else if (depth >= 4000 && depth < 9000) {
      _soundService.playAmbient("deep_hum.mp3");
      _soundService.stopSecondaryAmbient();
    } else {
      // Depth >= 9000m: Play BOTH deep_hum.mp3 and sonar_echo.mp3
      _soundService.playAmbient("deep_hum.mp3");
      _soundService.playSecondaryAmbient("sonar_echo.mp3");
    }
  }

  void _updateOxygenWarningSound() {
    if (!_gameActive || _gameOver) {
      if (_oxygenWarningActive) {
        _oxygenWarningActive = false;
        _soundService.stopSecondaryAmbient();
      }
      return;
    }

    if (_oxygen <= 0.25) {
      if (!_oxygenWarningActive) {
        _oxygenWarningActive = true;
        _soundService.playSecondaryAmbient("shark_heartbeat.mp3");
        final isEn = AppStrings.of(context).languageCode == 'en';
        _addLog(isEn ? 'WARNING: Oxygen levels critical! O2 < 25%!' : 'CẢNH BÁO: Dưỡng khí nguy kịch! O2 dưới 25%!');
      }
    } else {
      if (_oxygenWarningActive) {
        _oxygenWarningActive = false;
        // Restore normal ambient / secondary ambient for current depth
        if (_depth >= 9000) {
          _soundService.playSecondaryAmbient("sonar_echo.mp3");
        } else {
          _soundService.stopSecondaryAmbient();
        }
      }
    }
  }

  void _refillOxygen() {
    if (!_gameActive || _gameOver || _oxygenCharges <= 0 || _oxygen >= 0.9) return;
    final isEn = AppStrings.of(context).languageCode == 'en';
    setState(() {
      _oxygenCharges--;
      _oxygen = (_oxygen + 0.35).clamp(0.0, 1.0);
      _updateOxygenWarningSound();
      _addLog(isEn 
          ? 'SYS: Auxiliary Oxygen tank refilled. O2 level +35%. Cylinders remaining: $_oxygenCharges' 
          : 'SYS: Bơm nạp Oxy dự phòng. Oxy tăng +35%. Số bình còn lại: $_oxygenCharges');
    });
  }

  void _repairHull() {
    if (!_gameActive || _gameOver || _hullCharges <= 0 || _hull >= 0.9) return;
    _soundService.playCreatureSound("static_crackle.mp3"); // weld sound
    final isEn = AppStrings.of(context).languageCode == 'en';
    setState(() {
      _hullCharges--;
      _hull = (_hull + 0.3).clamp(0.0, 1.0);
      _addLog(isEn
          ? 'SYS: Welding drones dispatched to reinforce hull. Armor +30%. Nano-drones left: $_hullCharges'
          : 'SYS: Triển khai robot hàn vỏ tàu. Vỏ tàu tăng +30%. Robot còn lại: $_hullCharges');
    });
  }

  void _activateShield() {
    if (!_gameActive || _gameOver || _shieldActive || _energy < 0.3) return;
    _soundService.playCreatureSound("static_crackle.mp3");
    final isEn = AppStrings.of(context).languageCode == 'en';
    setState(() {
      _energy -= 0.3;
      _shieldActive = true;
      _shieldSecondsLeft = 4;
      _addLog(isEn ? 'SYS: ELECTROMAGNETIC ENERGY DEFLECTOR ENGAGED (4 SECONDS)' : 'SYS: KÍCH HOẠT LÁ CHẮN NĂNG LƯỢNG ĐIỆN TỪ (4 GIÂY)');
    });

    _shieldTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final isEnShield = AppStrings.of(context).languageCode == 'en';
      setState(() {
        _shieldSecondsLeft--;
        if (_shieldSecondsLeft <= 0) {
          _shieldActive = false;
          timer.cancel();
          _addLog(isEnShield ? 'SYS: Energy shield depleted - DISENGAGED' : 'SYS: Lá chắn năng lượng quá tải - TẮT');
        }
      });
    });
  }

  void _endGame(String reason) {
    _gameTimer?.cancel();
    _shieldTimer?.cancel();

    // Stop all audio players when simulator game ends
    _soundService.stopAmbient();
    _soundService.stopSecondaryAmbient();
    _soundService.stopCreatureSound();

    if (!mounted) return;

    final isEn = AppStrings.of(context).languageCode == 'en';
    setState(() {
      _gameOver = true;
      _gameActive = false;
      _oxygenWarningActive = false;
    });

    _addLog(isEn ? 'SYS: CRITICAL SUBMERSIBLE FAILURE: $reason' : 'SYS: TÀU NGẦM GẶP SỰ CỐ NGHIÊM TRỌNG: $reason');
    _addLog(isEn ? 'SYS: BROADCASTING S.O.S. BEACON... MAX DEPTH RECORDED: ${_depth}m' : 'SYS: PHÁT TÍN HIỆU CỨU HỘ S.O.S... ĐỘ SÂU ĐẠT ĐƯỢC: ${_depth}m');

    // Update high score in DataService
    Provider.of<DataService>(context, listen: false).updateHighScoreDepth(_depth);
  }

  @override
  void dispose() {
    _hudAnimationController.dispose();
    _gameTimer?.cancel();
    _shieldTimer?.cancel();
    _logScrollController.dispose();
    // Stop all audio players when simulator is exited/closed
    _soundService.stopAmbient();
    _soundService.stopSecondaryAmbient();
    _soundService.stopCreatureSound();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<DataService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF020813),
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
                  child: _buildHeader(context),
                ),

                // Main Cockpit Simulator Screen (Maximized vertical height for video)
                Expanded(
                  child: _gameOver 
                      ? _buildGameOverPanel(dataService) 
                      : _buildSimulationPanel(dataService),
                ),

                // Action HUD Control buttons
                if (_gameActive && !_gameOver) ...[
                  Container(
                    width: double.infinity,
                    height: 1.0,
                    color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                  ),
                  _buildControlsPanel(),
                ],

                if (!_gameOver) ...[
                  Container(
                    width: double.infinity,
                    height: 1.0,
                    color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                  ),

                  // Text Log console (Compact single-line ticker when collapsed to maximize video height)
                  SizedBox(
                    height: _isLogExpanded ? 88 : 28,
                    child: _buildLogConsole(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final strings = AppStrings.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00F0FF)),
          onPressed: () {
            if (_gameActive && !_gameOver) {
              // Ask for confirmation
              showCupertinoDialog(
                context: context,
                builder: (context) => CupertinoAlertDialog(
                  title: Text(
                    strings.languageCode == 'vi' ? 'Hủy nhiệm vụ lặn?' : 'Abort dive mission?',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  content: Text(
                    strings.languageCode == 'vi'
                        ? 'Tiến trình lặn hiện tại sẽ bị mất. Bạn có chắc chắn muốn thoát?'
                        : 'Current dive progress will be lost. Are you sure you want to exit?',
                  ),
                  actions: [
                    CupertinoDialogAction(
                      child: Text(
                        strings.languageCode == 'vi' ? 'Tiếp tục lặn' : 'Continue Dive',
                        style: const TextStyle(color: Color(0xFF007AFF)), // Standard iOS blue
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CupertinoDialogAction(
                      isDestructiveAction: true,
                      child: Text(
                        strings.languageCode == 'vi' ? 'Thoát' : 'Exit',
                      ),
                      onPressed: () {
                        Navigator.pop(context); // close dialog
                        Navigator.pop(context); // pop screen
                      },
                    ),
                  ],
                ),
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
        Column(
          children: [
            Text(
              strings.simulatorTitle,
              style: const TextStyle(
                color: Color(0xFF00F0FF),
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
            Text(
              strings.languageCode == 'vi' ? 'MÔ PHỎNG LẶN AN TOÀN VỎ TÀU' : 'SAFE DESCENT SIMULATION',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 8,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildVolumeButton(context),
            buildSettingsButton(context),
          ],
        ),
      ],
    );
  }

  Widget _buildSimulationPanel(DataService dataService) {
    if (!_gameActive) {
      return _buildOnboardingPanel(dataService);
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1F3D).withValues(alpha: 0.15),
        border: Border(
          top: BorderSide(
            color: _shieldActive ? const Color(0xFFFF3366) : const Color(0xFF00F0FF).withValues(alpha: 0.25),
            width: _shieldActive ? 2.5 : 1.5,
          ),
        ),
      ),
      child: Transform.translate(
        offset: Offset(_shakeX, _shakeY),
        child: _buildAbyssViewport(),
      ),
    );
  }

  Widget _buildOnboardingPanel(DataService dataService) {
    final strings = AppStrings.of(context);
    final isEn = strings.languageCode == 'en';
    final selectedVessel = _vessels[_selectedVesselIndex];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1F3D).withValues(alpha: 0.2),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF00F0FF).withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header icon and title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/icon/cruise.png',
                  width: 38,
                  height: 38,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEn ? 'ABYSS SURVIVAL MISSION' : 'NHIỆM VỤ SINH TỒN VỰC THẲM',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      isEn
                          ? 'CUSTOMIZE SUBMARINE LOADOUT & DESCEND DEEP'
                          : 'TÙY CHỈNH TÀU NGẦM & KHÁM PHÁ VỰC MARIANA',
                      style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 8, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 1. SECTION: CHỌN MẪU TÀU NGẦM (Vessel Selection)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                isEn ? '1. SELECT SUBMARINE CLASS:' : '1. CHỌN MẪU TÀU NGẦM CHÍNH:',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            // Vessels Horizontal Showcase (Big photorealistic cards)
            SizedBox(
              height: 175,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _vessels.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final vessel = _vessels[index];
                  final isSelected = _selectedVesselIndex == index;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedVesselIndex = index;
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 155,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? vessel.themeColor : Colors.white24,
                          width: isSelected ? 2.5 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: vessel.themeColor.withValues(alpha: 0.45),
                                  blurRadius: 12,
                                  spreadRadius: 1.5,
                                )
                              ]
                            : [],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          // 1. Large photorealistic submarine image background
                          Positioned.fill(
                            child: Image.asset(
                              vessel.imageAsset,
                              fit: BoxFit.cover,
                            ),
                          ),

                          // 2. Dark gradient overlay from bottom to top
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.1),
                                    Colors.black.withValues(alpha: 0.85),
                                  ],
                                  stops: const [0.3, 1.0],
                                ),
                              ),
                            ),
                          ),

                          // 3. Selection status badge (Top-Right)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? vessel.themeColor 
                                    : Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? Colors.white : vessel.themeColor,
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isSelected ? Icons.check_circle : vessel.iconData,
                                    size: 11,
                                    color: isSelected ? Colors.black : vessel.themeColor,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    isSelected
                                        ? (isEn ? 'SELECTED' : 'ĐÃ CHỌN')
                                        : (isEn ? 'SELECT' : 'CHỌN'),
                                    style: TextStyle(
                                      color: isSelected ? Colors.black : Colors.white,
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // 4. Submarine Name & Specs (Bottom)
                          Positioned(
                            bottom: 8,
                            left: 8,
                            right: 8,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEn ? vessel.nameEn : vessel.nameVi,
                                  style: TextStyle(
                                    color: isSelected ? vessel.themeColor : Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                    shadows: const [
                                      Shadow(color: Colors.black, blurRadius: 4),
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isEn ? vessel.descEn : vessel.descVi,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 7.5,
                                    height: 1.15,
                                    shadows: [
                                      Shadow(color: Colors.black, blurRadius: 4),
                                    ],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // 2. SECTION: MẠCH NÂNG CẤP TECH PERKS (Select up to 2)
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEn ? '2. TECH PERKS (PICK UP TO 2):' : '2. MẠCH NÂNG CẤP (CHỌN TỐI ĐA 2):',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    '${_selectedPerkIndices.length}/2',
                    style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Perks Grid (2x2 Big Artwork Cards)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _perks.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.55,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final perk = _perks[index];
                final isSelected = _selectedPerkIndices.contains(index);
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedPerkIndices.remove(index);
                      } else {
                        if (_selectedPerkIndices.length >= 2) {
                          // Remove first item if already selected 2
                          _selectedPerkIndices.remove(_selectedPerkIndices.first);
                        }
                        _selectedPerkIndices.add(index);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? perk.color : Colors.white24,
                        width: isSelected ? 2.0 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: perk.color.withValues(alpha: 0.35),
                                blurRadius: 8,
                                spreadRadius: 1,
                              )
                            ]
                          : [],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        // 1. Full-cover artwork background
                        Positioned.fill(
                          child: Image.asset(
                            perk.imageAsset,
                            fit: BoxFit.cover,
                          ),
                        ),

                        // 2. Dark bottom gradient overlay
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.1),
                                  Colors.black.withValues(alpha: 0.85),
                                ],
                                stops: const [0.2, 1.0],
                              ),
                            ),
                          ),
                        ),

                        // 3. Status Checkbox Badge (Top-Right)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? perk.color 
                                  : Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 0.8),
                            ),
                            child: Icon(
                              isSelected ? Icons.check : perk.icon,
                              size: 10,
                              color: isSelected ? Colors.black : Colors.white,
                            ),
                          ),
                        ),

                        // 4. Perk Name & Effect Description (Bottom)
                        Positioned(
                          bottom: 6,
                          left: 6,
                          right: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEn ? perk.nameEn : perk.nameVi,
                                style: TextStyle(
                                  color: isSelected ? perk.color : Colors.white,
                                  fontSize: 9.0,
                                  fontWeight: FontWeight.w900,
                                  shadows: const [
                                    Shadow(color: Colors.black, blurRadius: 4),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 1),
                              Text(
                                isEn ? perk.descEn : perk.descVi,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 7.0,
                                  height: 1.1,
                                  shadows: [
                                    Shadow(color: Colors.black, blurRadius: 4),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // High score status
            if (dataService.highScoreDepth > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00F0FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.amber, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      isEn
                          ? 'DEEPEST DIVE RECORD: ${dataService.highScoreDepth} METERS'
                          : 'KỶ LỤC LẶN SÂU NHẤT: ${dataService.highScoreDepth} MÉT',
                      style: const TextStyle(color: Colors.amber, fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ],
                ),
              ),

            // Start Button
            Container(
              width: double.infinity,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.zero,
                boxShadow: [
                  BoxShadow(
                    color: selectedVessel.themeColor.withValues(alpha: 0.4),
                    blurRadius: 10,
                    spreadRadius: 1,
                  )
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _startGame,
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 22),
                label: Text(
                  isEn 
                      ? 'DEPART WITH ${selectedVessel.nameEn.toUpperCase()}' 
                      : 'KHỞI HÀNH VỚI ${selectedVessel.nameVi.toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.2, color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedVessel.themeColor,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Onboarding panel ends here

  Widget _buildAbyssViewport() {
    // Determine gradient background based on depth
    Color topColor;
    Color bottomColor;
    if (_depth < 1000) {
      topColor = const Color(0xFF0F2B46);
      bottomColor = const Color(0xFF07182E);
    } else if (_depth < 4000) {
      topColor = const Color(0xFF07182E);
      bottomColor = const Color(0xFF030A18);
    } else if (_depth < 8000) {
      topColor = const Color(0xFF030A18);
      bottomColor = const Color(0xFF01040A);
    } else {
      topColor = const Color(0xFF01040A);
      bottomColor = Colors.black;
    }

    // Determine threat text
    String threatText = 'NONE';
    Color threatColor = Colors.greenAccent;
    if (_activeThreat != null) {
      threatText = _activeThreat!.toUpperCase();
      threatColor = const Color(0xFFFF3366);
    }

    // Calculate digital readouts
    double temp = 25.0 - (_depth / 400);
    if (temp < 1.5) temp = 1.5;
    if (_activeThreat == 'vent') temp = 80.0 + _random.nextInt(35); // hot vent!
    
    double pressure = (_depth * 0.0101); // 1 atm per 10m approximately, 0.1 MPa per 10m

    // Monster image asset mapping
    String? monsterAsset;
    if (_activeThreat == 'shark') {
      monsterAsset = 'assets/images/creatures/great_white_shark.png';
    } else if (_activeThreat == 'kraken') {
      monsterAsset = 'assets/images/creatures/kraken.png';
    } else if (_activeThreat == 'bloop') {
      monsterAsset = 'assets/images/creatures/the_bloop.png';
    } else if (_activeThreat == 'cthulhu') {
      monsterAsset = 'assets/images/creatures/Cthulhu.png';
    }

    final strings = AppStrings.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.zero,
        border: Border.all(
          color: _activeThreat != null && !_shieldActive
              ? const Color(0xFFFF3366)
              : const Color(0xFF00F0FF).withValues(alpha: 0.4),
          width: 3.0,
        ),
        boxShadow: [
          BoxShadow(
            color: _activeThreat != null && !_shieldActive
                ? const Color(0xFFFF3366).withValues(alpha: 0.3)
                : const Color(0xFF00F0FF).withValues(alpha: 0.15),
            blurRadius: 15,
            spreadRadius: 1,
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 1. Dynamic depth gradient background
          AnimatedContainer(
            duration: const Duration(seconds: 1),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [topColor, bottomColor],
              ),
            ),
          ),

          // 2. Animated bubbles/marine snow painter
          AnimatedBuilder(
            animation: _hudAnimationController,
            builder: (context, child) {
              return CustomPaint(
                painter: SinkingBubblesPainter(
                  animationValue: _hudAnimationController.value,
                  depth: _depth,
                  activeThreat: _activeThreat,
                ),
                size: Size.infinite,
              );
            },
          ),

          // 3. Radar scanlines and grids painter
          AnimatedBuilder(
            animation: _hudAnimationController,
            builder: (context, child) {
              return CustomPaint(
                painter: RadarViewportPainter(
                  scanProgress: _hudAnimationController.value,
                  isShieldActive: _shieldActive,
                  isThreatActive: _activeThreat != null,
                ),
                size: Size.infinite,
              );
            },
          ),

          // 4. Creature / Ambient Ocean Video Overlay
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: _activeThreat != null ? 0.85 : 0.45,
              duration: const Duration(milliseconds: 400),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  _activeThreat != null
                      ? (_shieldActive
                          ? const Color(0xFF00F0FF).withValues(alpha: 0.25)
                          : const Color(0xFFFF3366).withValues(alpha: 0.3))
                      : const Color(0xFF00F0FF).withValues(alpha: 0.15),
                  BlendMode.srcATop,
                ),
                child: CachedCreatureVideoPlayer(
                  key: ValueKey(_currentVideoUrl),
                  videoUrl: _currentVideoUrl,
                  disableMask: true,
                  fit: BoxFit.cover,
                  placeholder: monsterAsset != null
                      ? Center(
                          child: Image.asset(
                            monsterAsset,
                            fit: BoxFit.contain,
                            width: 250,
                            height: 140,
                            color: const Color(0xFFFF3366).withValues(alpha: 0.8),
                            colorBlendMode: BlendMode.srcATop,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ),

          // 5. Red alert flash overlay (if threat active and no shield)
          if (_activeThreat != null && !_shieldActive)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFFFF3366).withValues(alpha: math.sin(_hudAnimationController.value * math.pi * 4).abs() * 0.4 + 0.1),
                    width: 8,
                  ),
                ),
              ),
            ),

          // 6. Shield activated barrier overlay (pulsing hexagon glow)
          AnimatedOpacity(
            opacity: _shieldTriggeredFlash ? 0.85 : (_shieldActive ? 0.25 : 0.0),
            duration: const Duration(milliseconds: 200),
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00F0FF).withValues(alpha: 0.0),
                    const Color(0xFF00F0FF).withValues(alpha: 0.4),
                  ],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.shield_outlined,
                  size: 90,
                  color: const Color(0xFF00F0FF).withValues(alpha: 0.6),
                ),
              ),
            ),
          ),

          // 7. Tactical Digital overlays
          Positioned(
            top: 10,
            left: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.videocam, size: 10, color: Color(0xFF00F0FF)),
                    SizedBox(width: 4),
                    Text(
                      'CAM-01: HADAL FEED',
                      style: TextStyle(
                        color: Color(0xFF00F0FF),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'PRES: ${pressure.toStringAsFixed(1)} MPa',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 8,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  'TEMP: ${temp.toStringAsFixed(1)} °C',
                  style: TextStyle(
                    color: _activeThreat == 'vent' ? const Color(0xFFFF3366) : Colors.white70,
                    fontSize: 8,
                    fontFamily: 'monospace',
                    fontWeight: _activeThreat == 'vent' ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            top: 10,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _activeThreat != null ? const Color(0xFFFF3366) : Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'THREAT: $threatText',
                      style: TextStyle(
                        color: threatColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'DEPTH: ${_depth}m',
                  style: const TextStyle(
                    color: Color(0xFF00F0FF),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),

          // Threat warning alert text in center
          if (_activeThreat != null)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: threatColor, width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _activeThreat == 'vent' ? 'WARNING: THERMAL ERUPTION' : 'WARNING: COLLISION IMMINENT',
                      style: TextStyle(
                        color: threatColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _shieldActive ? 'SHIELD ABSORBING IMPACT' : 'IMPACT IMMINENT - ENGAGE SHIELD',
                      style: TextStyle(
                        color: _shieldActive ? const Color(0xFF00F0FF) : Colors.white70,
                        fontSize: 8,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Circular lens glass sheen
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.05),
                      Colors.white.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: 0.15),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // 8. Docked Bottom Telemetry Gauges Panel (Dính liền viền Simulator)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF020914).withValues(alpha: 0.85),
                border: Border(
                  top: BorderSide(
                    color: _activeThreat != null && !_shieldActive
                        ? const Color(0xFFFF3366)
                        : const Color(0xFF00F0FF).withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_shieldActive) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                      margin: const EdgeInsets.only(top: 4, bottom: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3366).withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFF3366)),
                      ),
                      child: Text(
                        strings.languageCode == 'vi'
                            ? 'LÁ CHẮN NĂNG LƯỢNG: KÍCH HOẠT (${_shieldSecondsLeft}s)'
                            : 'ENERGY SHIELD: ACTIVE (${_shieldSecondsLeft}s)',
                        style: const TextStyle(color: Color(0xFFFF3366), fontSize: 9.0, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ),
                  ],
                  Row(
                    children: [
                      _buildGauge(
                        strings.languageCode == 'vi' ? 'OXY (O2)' : 'OXYGEN',
                        _oxygen,
                        Colors.green,
                        'x$_oxygenCharges',
                        Icons.air_rounded,
                        showRightDivider: true,
                      ),
                      _buildGauge(
                        strings.languageCode == 'vi' ? 'GIÁP TÀU' : 'HULL',
                        _hull,
                        const Color(0xFFFF3366),
                        'x$_hullCharges',
                        Icons.shield_outlined,
                        showRightDivider: true,
                      ),
                      _buildGauge(
                        strings.languageCode == 'vi' ? 'NĂNG LƯỢNG' : 'ENERGY',
                        _energy,
                        const Color(0xFF00F0FF),
                        '',
                        Icons.bolt_rounded,
                        showRightDivider: false,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGauge(
    String label, 
    double value, 
    Color color, 
    String charges, 
    IconData icon, {
    bool showRightDivider = true,
  }) {
    bool isLow = value < 0.25;
    Color statusColor = isLow ? const Color(0xFFFF3366) : color;
    int filledSegments = (value * 10).clamp(0, 10).round();

    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 6.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.zero,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isLow 
                ? [const Color(0xFFFF3366).withValues(alpha: 0.35), const Color(0xFF1B0309)]
                : [color.withValues(alpha: 0.20), const Color(0xFF020B16)],
          ),
          border: showRightDivider
              ? Border(
                  right: BorderSide(
                    color: const Color(0xFF00F0FF).withValues(alpha: 0.25),
                    width: 1.0,
                  ),
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Header (Icon + Label) and % Value Readout
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 10, color: isLow ? const Color(0xFFFF3366) : statusColor),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: TextStyle(
                        color: isLow ? const Color(0xFFFF3366) : Colors.white70,
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
                AnimatedBuilder(
                  animation: _hudAnimationController,
                  builder: (context, child) {
                    double opacity = 1.0;
                    if (isLow) {
                      opacity = 0.35 + math.sin(_hudAnimationController.value * math.pi * 4).abs() * 0.65;
                    }
                    return Opacity(
                      opacity: opacity,
                      child: Text(
                        '${(value * 100).toInt()}%',
                        style: TextStyle(
                          color: isLow ? const Color(0xFFFF3366) : Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          shadows: [
                            Shadow(color: statusColor, blurRadius: 6),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 5),

            // Row 2: Sleek 10-Segmented LED Progress Bar
            Row(
              children: List.generate(10, (index) {
                bool isActive = index < filledSegments;
                return Expanded(
                  child: Container(
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 0.8),
                    decoration: BoxDecoration(
                      color: isActive ? statusColor : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(1.5),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: statusColor.withValues(alpha: 0.5),
                                blurRadius: 3,
                              )
                            ]
                          : [],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 5),

            // Row 3: Bottom Status Tag
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.4),
                      width: 0.6,
                    ),
                  ),
                  child: Text(
                    charges.isNotEmpty ? charges : 'ON-GRID',
                    style: TextStyle(
                      color: isLow ? const Color(0xFFFF3366) : statusColor,
                      fontSize: 7.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                Text(
                  isLow ? 'CRITICAL' : 'NOMINAL',
                  style: TextStyle(
                    color: isLow ? const Color(0xFFFF3366) : Colors.white30,
                    fontSize: 6.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsPanel() {
    final strings = AppStrings.of(context);
    final isEn = strings.languageCode == 'en';
    final isO2Available = _oxygenCharges > 0 && _oxygen < 0.9;
    final isShieldAvailable = _energy >= 0.3 && !_shieldActive;
    final isHullAvailable = _hullCharges > 0 && _hull < 0.9;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF020712),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF00F0FF).withValues(alpha: 0.2),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          // Oxygen Action Button
          Expanded(
            child: _buildActionButton(
              onPressed: isO2Available ? _refillOxygen : null,
              imageAsset: 'assets/images/creatures/perk_o2_xl.jpg',
              title: isEn ? 'REFUEL O2' : 'BƠM OXY',
              subtitle: isO2Available ? '+35% O2' : (_oxygenCharges <= 0 ? (isEn ? 'EMPTY' : 'HẾT BÌNH') : (isEn ? 'FULL O2' : 'OXY ĐẦY')),
              badgeText: 'x$_oxygenCharges',
              color: Colors.green,
              icon: Icons.air_rounded,
              isEnabled: isO2Available,
            ),
          ),
          const SizedBox(width: 6),

          // Shield Action Button
          Expanded(
            child: _buildActionButton(
              onPressed: isShieldAvailable ? _activateShield : null,
              imageAsset: 'assets/images/creatures/perk_capacitor.jpg',
              title: isEn ? 'DEFLECTOR' : 'LÁ CHẮN',
              subtitle: _shieldActive 
                  ? '${_shieldSecondsLeft}s ACTIVE' 
                  : (isShieldAvailable ? '-30% ENER' : (isEn ? 'LOW ENER' : 'N.LƯỢNG THẤP')),
              badgeText: _shieldActive ? '${_shieldSecondsLeft}s' : '-30%',
              color: const Color(0xFFFF3366),
              icon: Icons.shield_rounded,
              isEnabled: isShieldAvailable || _shieldActive,
              isPulsing: _shieldActive,
            ),
          ),
          const SizedBox(width: 6),

          // Repair Action Button
          Expanded(
            child: _buildActionButton(
              onPressed: isHullAvailable ? _repairHull : null,
              imageAsset: 'assets/images/creatures/perk_auto_drone.jpg',
              title: isEn ? 'WELD HULL' : 'HÀN VỎ TÀU',
              subtitle: isHullAvailable ? '+30% GIÁP' : (_hullCharges <= 0 ? (isEn ? 'EMPTY' : 'HẾT ROBOT') : (isEn ? 'FULL HULL' : 'GIÁP ĐẦY')),
              badgeText: 'x$_hullCharges',
              color: const Color(0xFFFFCC00),
              icon: Icons.handyman_rounded,
              isEnabled: isHullAvailable,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required String imageAsset,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color color,
    required IconData icon,
    required bool isEnabled,
    bool isPulsing = false,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 62,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isPulsing
                ? const Color(0xFFFF3366)
                : (isEnabled ? color.withValues(alpha: 0.85) : Colors.white12),
            width: isPulsing ? 2.0 : (isEnabled ? 1.5 : 1.0),
          ),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: isPulsing ? 0.55 : 0.25),
                    blurRadius: isPulsing ? 10 : 6,
                    spreadRadius: isPulsing ? 1.0 : 0.5,
                  ),
                ]
              : [],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Full-cover Artwork Background Image
            Opacity(
              opacity: isEnabled ? 0.75 : 0.20,
              child: Image.asset(
                imageAsset,
                fit: BoxFit.cover,
              ),
            ),

            // 2. Cyberpunk Dark + Theme Tint Gradient Overlays
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isEnabled
                      ? [
                          Colors.black.withValues(alpha: 0.65),
                          color.withValues(alpha: 0.15),
                          Colors.black.withValues(alpha: 0.88),
                        ]
                      : [
                          Colors.black.withValues(alpha: 0.85),
                          Colors.black.withValues(alpha: 0.88),
                          Colors.black.withValues(alpha: 0.92),
                        ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),

            // 3. Top-Right Badge Pill
            if (badgeText.isNotEmpty)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: isEnabled ? color : Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isEnabled ? Colors.white.withValues(alpha: 0.8) : Colors.white24,
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.8),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      color: isEnabled ? Colors.black : Colors.white54,
                      fontSize: 8.0,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),

            // 4. Action Content (Icon + Title + Subtitle at bottom)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 3.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top-left Icon
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      color: isEnabled ? color.withValues(alpha: 0.3) : Colors.white10,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isEnabled ? color : Colors.white24,
                        width: 0.8,
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 9.5,
                      color: isEnabled ? Colors.white : Colors.white38,
                    ),
                  ),

                  // Bottom Title & Stat Pill
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isEnabled ? Colors.white : Colors.white38,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          shadows: const [
                            Shadow(color: Colors.black, blurRadius: 6),
                            Shadow(color: Colors.black, blurRadius: 3),
                          ],
                        ),
                      ),
                      const SizedBox(height: 1),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.0),
                        decoration: BoxDecoration(
                          color: isEnabled 
                              ? color.withValues(alpha: 0.35) 
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: isEnabled ? color : Colors.white12,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isEnabled ? (color == Colors.green ? Colors.greenAccent : color) : Colors.white38,
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                            shadows: const [
                              Shadow(color: Colors.black, blurRadius: 4),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOverPanel(DataService dataService) {
    final strings = AppStrings.of(context);
    final isEn = strings.languageCode == 'en';
    bool isNewRecord = _depth >= dataService.highScoreDepth;
    final selectedVessel = _vessels[_selectedVesselIndex];

    String depthZoneName;
    if (_depth < 1000) {
      depthZoneName = isEn ? 'TWILIGHT ZONE (MESOPELAGIC)' : 'VÙNG HOÀNG HÔN (DƯỚI 1.000m)';
    } else if (_depth < 4000) {
      depthZoneName = isEn ? 'MIDNIGHT ZONE (BATHYPELAGIC)' : 'VÙNG NỬA ĐÊM (1.000m - 4.000m)';
    } else if (_depth < 6000) {
      depthZoneName = isEn ? 'ABYSSAL ZONE (ABYSSOPELAGIC)' : 'VÙNG ĐÁY VỰC THẲM (4.000m - 6.000m)';
    } else {
      depthZoneName = isEn ? 'HADAL ZONE (MARIANA TRENCH)' : 'VỰC SIÊU SÂU MARIANA (>6.000m)';
    }

    double pressureAtm = _depth * 0.0101;
    double bottomTemp = (25.0 - (_depth / 400)).clamp(1.5, 25.0);

    String deathReport = '';
    if (_oxygen <= 0.0) {
      deathReport = isEn
          ? 'OXYGEN LEVEL CRITICAL: Life support depleted. The cockpit displays died in the freezing dark. The crew lost consciousness in the abyss at $_depth meters.'
          : 'DƯỠNG KHÍ O2 CẠN KIỆT: Hệ thống duy trì sự sống ngừng hoạt động. Màn hình buồng lái tắt lịm trong bóng tối băng giá. Thủy thủ đoàn lịm dần ở độ sâu $_depth mét.';
    } else {
      deathReport = isEn
          ? 'CATASTROPHIC HULL IMPLOSION: Hydrostatic pressure crushed the titanium hull in a millisecond. Immediate compression annihilated all signs of life at $_depth meters.'
          : 'ÁP SUẤT ÉP SẬP VỎ TÀU: Áp lực nước khổng lồ ép nát lớp vỏ titan kiên cố trong tích tắc. Sự cố nén gây nổ tung tức thời ở độ sâu $_depth mét.';
    }

    List<String> unlockedAchievements = [];
    if (_depth >= 4000) unlockedAchievements.add(isEn ? 'Midnight Explorer (4,000m)' : 'Thám Hiểm Vùng Tối (4.000m)');
    if (_depth >= 11000) unlockedAchievements.add(isEn ? 'Mariana Conqueror (11,000m)' : 'Chinh Phục Đáy Mariana (11.000m)');

    return Container(
      width: double.infinity,
      color: const Color(0xFF020712),
      child: Stack(
        children: [
          // 1. Crisp Ocean Background Image
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

          // 2. Abyssal Vignette Gradient (Edges darken smoothly)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF020712).withValues(alpha: 0.45),
                    const Color(0xFF01040A).withValues(alpha: 0.85),
                    const Color(0xFF01040A).withValues(alpha: 0.96),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // 3. Main Debriefing Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Emergency Top Title Bar
                          AnimatedBuilder(
                            animation: _hudAnimationController,
                            builder: (context, child) {
                              double pulse = 0.5 + math.sin(_hudAnimationController.value * math.pi * 4).abs() * 0.5;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF3366).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFFF3366).withValues(alpha: pulse),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF3366).withValues(alpha: pulse * 0.35),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.report_problem_rounded, color: const Color(0xFFFF3366), size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      isEn ? 'MISSION TERMINATED // VESSEL LOST' : 'NHIỆM VỤ KẾT THÚC // MẤT TÀU NGẦM',
                                      style: const TextStyle(
                                        color: Color(0xFFFF3366),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.5,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 10),

                          // Unified Tactical Mission Summary Card
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFF030A18).withValues(alpha: 0.88),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF00F0FF).withValues(alpha: 0.25),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  blurRadius: 18,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Submarine Artwork Banner (Large Cinematic View)
                                SizedBox(
                                  height: 160,
                                  width: double.infinity,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.asset(
                                        selectedVessel.imageAsset,
                                        fit: BoxFit.cover,
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              const Color(0xFF030A18).withValues(alpha: 0.92),
                                            ],
                                            stops: const [0.45, 1.0],
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 10,
                                        left: 14,
                                        right: 14,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  isEn ? selectedVessel.nameEn.toUpperCase() : selectedVessel.nameVi.toUpperCase(),
                                                  style: TextStyle(
                                                    color: selectedVessel.themeColor,
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w900,
                                                    letterSpacing: 1.0,
                                                    shadows: const [
                                                      Shadow(color: Colors.black, blurRadius: 10),
                                                      Shadow(color: Colors.black, blurRadius: 5),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  isEn ? 'TACTICAL SUBMARINE LOADOUT' : 'THÔNG SỐ TÀU LẶN ĐÃ CHỌN',
                                                  style: const TextStyle(
                                                    color: Colors.white60,
                                                    fontSize: 9.0,
                                                    letterSpacing: 0.5,
                                                    shadows: [
                                                      Shadow(color: Colors.black, blurRadius: 6),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFF3366).withValues(alpha: 0.25),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: const Color(0xFFFF3366), width: 0.8),
                                              ),
                                              child: Text(
                                                isEn ? 'DESTROYED' : 'BỊ PHÁ HỦY',
                                                style: const TextStyle(
                                                  color: Color(0xFFFF3366),
                                                  fontSize: 8.5,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Depth Centerpiece Section
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                                  child: Column(
                                    children: [
                                      // Main Depth Display
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF010610).withValues(alpha: 0.8),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: const Color(0xFF00F0FF).withValues(alpha: 0.3),
                                            width: 1.0,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              isEn ? 'MAXIMUM DEPTH ACHIEVED' : 'ĐỘ SÂU ĐẠT ĐƯỢC CUỐI CÙNG',
                                              style: const TextStyle(
                                                color: Colors.white60,
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.baseline,
                                              textBaseline: TextBaseline.alphabetic,
                                              children: [
                                                Text(
                                                  '$_depth',
                                                  style: const TextStyle(
                                                    color: Color(0xFF00F0FF),
                                                    fontSize: 32,
                                                    fontWeight: FontWeight.w900,
                                                    fontFamily: 'monospace',
                                                    shadows: [
                                                      Shadow(color: Color(0xFF00F0FF), blurRadius: 12),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                const Text(
                                                  'M',
                                                  style: TextStyle(
                                                    color: Color(0xFF00F0FF),
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              depthZoneName,
                                              style: TextStyle(
                                                color: selectedVessel.themeColor.withValues(alpha: 0.9),
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.6,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // New Record Banner if applicable
                                      if (isNewRecord) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.amber.withValues(alpha: 0.3),
                                                const Color(0xFFFF8800).withValues(alpha: 0.3),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.amber, width: 1.2),
                                            boxShadow: const [
                                              BoxShadow(color: Colors.amber, blurRadius: 8),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 16),
                                              const SizedBox(width: 6),
                                              Text(
                                                isEn ? '🏆 NEW DEEP-DIVE RECORD!' : '🏆 THIẾT LẬP KỶ LỤC LẶN MỚI!',
                                                style: const TextStyle(
                                                  color: Colors.amber,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 1.0,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],

                                      const SizedBox(height: 8),

                                      // Telemetry 3-Col Badges
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildTelemetryStatPill(
                                              isEn ? 'PRESSURE' : 'ÁP SUẤT',
                                              '${pressureAtm.toStringAsFixed(1)} ATM',
                                              const Color(0xFFFF3366),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: _buildTelemetryStatPill(
                                              isEn ? 'WATER TEMP' : 'NHIỆT ĐỘ',
                                              '${bottomTemp.toStringAsFixed(1)}°C',
                                              const Color(0xFF00F0FF),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: _buildTelemetryStatPill(
                                              isEn ? 'STATUS' : 'TÌNH TRẠNG',
                                              _oxygen <= 0.0 ? (isEn ? 'NO O2' : 'HẾT OXY') : (isEn ? 'CRUSHED' : 'VỠ VỎ'),
                                              Colors.amber,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 8),

                                      // Black Box Narrative Box
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.6),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: const Color(0xFFFF3366).withValues(alpha: 0.3),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  width: 5,
                                                  height: 5,
                                                  decoration: const BoxDecoration(
                                                    color: Color(0xFFFF3366),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  isEn ? 'BLACK BOX VOICE RECORDER // CH-04' : 'TRÍCH XUẤT HỘP ĐEN TÀU NGẦM // SỰ CỐ',
                                                  style: const TextStyle(
                                                    color: Color(0xFFFF3366),
                                                    fontSize: 8.5,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 0.8,
                                                    fontFamily: 'monospace',
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              deathReport,
                                              style: const TextStyle(
                                                color: Color(0xDDFFFFFF),
                                                fontSize: 9.5,
                                                height: 1.4,
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Unlocked Achievements List
                                      if (unlockedAchievements.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.greenAccent.withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.35)),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.military_tech_rounded, color: Colors.greenAccent, size: 16),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  unlockedAchievements.join('  •  '),
                                                  style: const TextStyle(
                                                    color: Colors.greenAccent,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: 'monospace',
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Action Buttons
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Row(
                      children: [
                        // Try Again Button
                        Expanded(
                          flex: 3,
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00F0FF), Color(0xFF0088FF)],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00F0FF).withValues(alpha: 0.35),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: _startGame,
                              icon: const Icon(Icons.restart_alt_rounded, color: Colors.black, size: 18),
                              label: Text(
                                isEn ? 'TRY AGAIN' : 'THỬ LẠI CHUYẾN LẶN',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Exit Button
                        Expanded(
                          flex: 2,
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              color: const Color(0xFF08101E).withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFF00F0FF).withValues(alpha: 0.4),
                                width: 1.0,
                              ),
                            ),
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.home_outlined, color: Color(0xFF00F0FF), size: 16),
                              label: Text(
                                isEn ? 'EXIT' : 'CĂN CỨ',
                                style: const TextStyle(
                                  color: Color(0xFF00F0FF),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
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
    );
  }

  Widget _buildTelemetryStatPill(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Column(
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 7.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogConsole() {
    if (!_isLogExpanded) {
      String latestLog = _logs.isNotEmpty ? _logs.last : 'LOG: SYSTEM OPERATIONAL';
      Color logColor = Colors.greenAccent;
      if (latestLog.contains('BÁO ĐỘNG') || latestLog.contains('SỰ CỐ') || latestLog.contains('ALERT') || latestLog.contains('HAZARD')) {
        logColor = const Color(0xFFFF3366);
      } else if (latestLog.contains('CẢNH BÁO') || latestLog.contains('WARNING')) {
        logColor = const Color(0xFFFFCC00);
      } else if (latestLog.contains('KÝ HIỆU') || latestLog.contains('SHIELD')) {
        logColor = const Color(0xFF00F0FF);
      }

      return ClipRect(
        child: GestureDetector(
          onTap: () {
            setState(() {
              _isLogExpanded = true;
            });
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF010307),
              border: Border(
                top: BorderSide(color: const Color(0xFF00F0FF).withValues(alpha: 0.15), width: 1.0),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: logColor,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: logColor, blurRadius: 4)],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    latestLog,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: logColor,
                      fontFamily: 'monospace',
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_up,
                  size: 14,
                  color: const Color(0xFF00F0FF).withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ClipRect(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF010307),
          border: Border(
            top: BorderSide(color: const Color(0xFF00F0FF).withValues(alpha: 0.15), width: 1.0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'LOG TELEMETRY CONSOLE',
                  style: TextStyle(color: const Color(0xFF00F0FF).withValues(alpha: 0.5), fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isLogExpanded = false;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 14,
                      color: const Color(0xFF00F0FF).withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Expanded(
              child: ListView.builder(
                controller: _logScrollController,
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  String logText = _logs[index];
                  Color logColor = Colors.greenAccent;
                  if (logText.contains('BÁO ĐỘNG') || logText.contains('SỰ CỐ') || logText.contains('ALERT') || logText.contains('HAZARD')) {
                    logColor = const Color(0xFFFF3366);
                  } else if (logText.contains('CẢNH BÁO') || logText.contains('WARNING')) {
                    logColor = const Color(0xFFFFCC00);
                  } else if (logText.contains('KÝ HIỆU') || logText.contains('SHIELD')) {
                    logColor = const Color(0xFF00F0FF);
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2.0),
                    child: Text(
                      logText,
                      style: TextStyle(
                        color: logColor,
                        fontFamily: 'monospace',
                        fontSize: 8.5,
                        height: 1.2,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painters for cockpit window visual layers
class RadarViewportPainter extends CustomPainter {
  final double scanProgress; // 0.0 to 1.0
  final bool isShieldActive;
  final bool isThreatActive;

  RadarViewportPainter({
    required this.scanProgress,
    required this.isShieldActive,
    required this.isThreatActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    final paintLine = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.1)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw coordinate grids
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paintLine);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintLine);
    }

    // Concentric sonar overlay rings
    canvas.drawCircle(center, radius * 0.35, paintLine);
    canvas.drawCircle(center, radius * 0.7, paintLine);
    canvas.drawCircle(center, radius * 1.0, paintLine);

    // Crosshairs lines
    canvas.drawLine(Offset(center.dx - radius, center.dy), Offset(center.dx + radius, center.dy), paintLine);
    canvas.drawLine(Offset(center.dx, center.dy - radius), Offset(center.dx, center.dy + radius), paintLine);

    // Dynamic sweeping radar scanline
    final scanY = size.height * scanProgress;
    final scanPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF00F0FF).withValues(alpha: 0.0),
          const Color(0xFF00F0FF).withValues(alpha: 0.15),
          const Color(0xFF00F0FF).withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, scanY - 20, size.width, 40))
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(Rect.fromLTWH(0, scanY - 20, size.width, 40), scanPaint);

    final scanEdgePaint = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.35)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, scanY), Offset(size.width, scanY), scanEdgePaint);
  }

  @override
  bool shouldRepaint(covariant RadarViewportPainter oldDelegate) {
    return oldDelegate.scanProgress != scanProgress ||
        oldDelegate.isShieldActive != isShieldActive ||
        oldDelegate.isThreatActive != isThreatActive;
  }
}

class SinkingBubblesPainter extends CustomPainter {
  final double animationValue; // 0.0 to 1.0 from controller
  final int depth;
  final String? activeThreat;

  SinkingBubblesPainter({
    required this.animationValue,
    required this.depth,
    this.activeThreat,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bubblePaint = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    final ventPaint = Paint()
      ..color = const Color(0xFFFF6600).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final int bubbleCount = activeThreat == 'vent' ? 40 : 20;

    for (int i = 0; i < bubbleCount; i++) {
      // Deterministic positioning
      final double x = ((i * 113) % size.width);
      
      // Speed multiplier for parallax depth effect
      final double speedFactor = 0.4 + ((i * 13) % 10) / 10.0;
      
      // Bubbles rise upwards as sub sinks downwards
      final double scrollOffset = (depth * 0.6 + animationValue * size.height) * speedFactor;
      final double y = (size.height - (scrollOffset + i * 43) % size.height);

      // Slight sinusoidal horizontal drift
      final double driftX = math.sin(animationValue * math.pi * 2 + i) * 6;
      final Offset position = Offset((x + driftX) % size.width, y);

      final double radius = 1.0 + ((i * 7) % 3);

      if (activeThreat == 'vent') {
        canvas.drawCircle(position, radius * 1.5, ventPaint);
        canvas.drawCircle(position, radius * 3.0, Paint()
          ..color = const Color(0xFFFF3300).withValues(alpha: 0.1)
          ..style = PaintingStyle.fill);
      } else {
        canvas.drawCircle(position, radius, bubblePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SinkingBubblesPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.depth != depth ||
        oldDelegate.activeThreat != activeThreat;
  }
}
