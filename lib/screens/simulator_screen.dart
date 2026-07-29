import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_service.dart';
import '../services/sound_service.dart';
import '../l10n/app_strings.dart';
import 'settings_screen.dart';

class SimulatorScreen extends StatefulWidget {
  const SimulatorScreen({super.key});

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
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
  
  int _oxygenCharges = 3;
  int _hullCharges = 3;
  bool _shieldActive = false;
  int _shieldSecondsLeft = 0;

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

  @override
  void initState() {
    super.initState();
    _backgroundImage = _bgImages[_random.nextInt(_bgImages.length)];
    _hudAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _soundService = Provider.of<SoundService>(context, listen: false);
  }

  void _startGame() {
    setState(() {
      _gameActive = true;
      _gameOver = false;
      _depth = 0;
      _oxygen = 1.0;
      _hull = 1.0;
      _energy = 1.0;
      _oxygenCharges = 3;
      _hullCharges = 3;
      _shieldActive = false;
      _shieldSecondsLeft = 0;
      _activeThreat = null;
      _threatTicks = 0;
      _shakeX = 0.0;
      _shakeY = 0.0;
      _shieldTriggeredFlash = false;
      _oxygenWarningActive = false;
      final isEn = AppStrings.of(context).languageCode == 'en';
      _logs.clear();
      _addLog(isEn ? 'SYS: INITIALIZING DSV-ADVENTURER DIVE SYSTEMS...' : 'SYS: KHỞI ĐỘNG HỆ THỐNG LẶN DSV-ADVENTURER...');
      _addLog(isEn ? 'SYS: HUD TELEMETRY LINK: CONNECTED' : 'SYS: LIÊN KẾT LIÊN LẠC HUD: KẾT NỐI');
      _addLog(isEn ? 'SYS: BEGINNING SUBMERSIBLE DESCENT INTO DEEP BASIN...' : 'SYS: BẮT ĐẦU THẢ TRÔI TÀU NGẦM XUỐNG VỰC SÂU...');
    });

    _ambientSoundForDepth(0);

    // Game loop ticks every 500ms
    _gameTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _tickGame();
    });
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
    if (!_gameActive || _gameOver) return;

    setState(() {
      // 1. Descend depth (approx 50m per half-second = 100m/s)
      _depth += 60 + _random.nextInt(30);

      // 2. Consume oxygen (approx 1.5% per tick, drains faster below 6000m due to stress)
      double o2Drain = 0.012;
      if (_depth > 6000) o2Drain = 0.018;
      if (_depth > 10000) o2Drain = 0.025;
      _oxygen = (_oxygen - o2Drain).clamp(0.0, 1.0);
      _updateOxygenWarningSound();

      // 3. Recharge energy slowly (0.5% per tick, unless shield is active)
      if (!_shieldActive) {
        _energy = (_energy + 0.005).clamp(0.0, 1.0);
      }

      // 4. Random Events based on depth
      _triggerDepthEvents();

      // Decrement active threat ticks
      if (_activeThreat != null) {
        _threatTicks--;
        if (_threatTicks <= 0) {
          _activeThreat = null;
        }
      }

      // 5. Check Game Over
      final isEn = AppStrings.of(context).languageCode == 'en';
      if (_oxygen <= 0.0) {
        _endGame(isEn ? 'OXYGEN DEPLETED - CREW SUFFOCATED' : 'OXY CẠN KIỆT - THỦY THỦ ĐOÀN NGẠT KHÍ');
      } else if (_hull <= 0.0) {
        _endGame(isEn ? 'CRUSH PRESSURE DESTROYED HULL - IMPLOSION' : 'ÁP SUẤT NGHIỀN NÁT VỎ TÀU NGẦM - NỔ TUNG');
      }
    });
  }

  void _triggerDepthEvents() {
    // Occur randomly
    if (_random.nextDouble() > 0.12) return;
    final isEn = AppStrings.of(context).languageCode == 'en';

    if (_depth > 500 && _depth < 1000 && !_logs.any((l) => l.contains('TWILIGHT') || l.contains('Hoàng Hôn'))) {
      _addLog(isEn ? 'WARNING: Entering the Twilight Zone. Sunlight fades away.' : 'CẢNH BÁO: Đi vào vùng Hoàng Hôn (Twilight Zone). Ánh sáng mặt trời tắt dần.');
      _activeThreat = 'twilight';
      _threatTicks = 6;
    }
    else if (_depth > 1000 && _depth < 1500 && !_logs.any((l) => l.contains('MIDNIGHT') || l.contains('Nửa Đêm'))) {
      _addLog(isEn ? 'WARNING: Entering the Midnight Zone. High-power spotlights engaged.' : 'CẢNH BÁO: Đi vào vùng Nửa Đêm (Midnight Zone). Bật đèn pha công suất cao.');
      _soundService.playCreatureSound("low_pressure.m4a");
      _activeThreat = 'midnight';
      _threatTicks = 6;
    }
    else if (_depth > 1500 && _depth < 3000 && _random.nextDouble() < 0.3) {
      _addLog(isEn ? 'HAZARD: Encountered boiling underwater hydrothermal vent plume!' : 'SỰ CỐ: Gặp luồng phun thủy nhiệt ngầm sục sôi!');
      _activeThreat = 'vent';
      _threatTicks = 6;
      _soundService.playCreatureSound("shark_heartbeat.mp3");
      if (_shieldActive) {
        _addLog(isEn ? 'SHIELD: Thermal vent impact absorbed by electromagnetic deflector.' : 'KÝ HIỆU: Lá chắn hấp thụ chấn động thủy nhiệt.');
        _triggerShieldFlash();
      } else {
        double dmg = 0.15 + _random.nextDouble() * 0.1;
        _hull = (_hull - dmg).clamp(0.0, 1.0);
        _addLog(isEn ? 'ALERT: Hull heat fractures detected! Shield integrity decreased by ${(dmg * 100).toInt()}%!' : 'BÁO ĐỘNG: Vỏ tàu bị nứt nhiệt! Độ bền giáp giảm ${(dmg * 100).toInt()}%!');
        _triggerShake(intensity: 8.0);
      }
    }
    else if (_depth > 3000 && _depth < 4500 && _random.nextDouble() < 0.25) {
      _addLog(isEn ? 'DETECTION: Hostile pack of prehistoric sharks surrounding the vessel!' : 'PHÁT HIỆN: Đàn cá mập cổ đại hung tợn vây quanh tàu!');
      _activeThreat = 'shark';
      _threatTicks = 6;
      _soundService.playCreatureSound("shark_heartbeat.mp3");
      if (_shieldActive) {
        _addLog(isEn ? 'SHIELD: Electromagnetic screen repelled the shark pack.' : 'KÝ HIỆU: Lá chắn điện từ đẩy lùi đàn cá mập.');
        _triggerShieldFlash();
      } else {
        double dmg = 0.12;
        _hull = (_hull - dmg).clamp(0.0, 1.0);
        _addLog(isEn ? 'ALERT: Shark rammed into viewing viewport! Structural armor decreased by ${(dmg * 100).toInt()}%!' : 'BÁO ĐỘNG: Cá mập tấn công đâm vào kính ngắm! Giáp giảm ${(dmg * 100).toInt()}%!');
        _triggerShake(intensity: 10.0);
      }
    }
    else if (_depth > 4500 && _depth < 7000 && _random.nextDouble() < 0.3) {
      _addLog(isEn ? 'WARNING: Massive biomass tremor signature. Kraken leviathan approaching!' : 'CẢNH BÁO: Phát hiện chấn động biomass lớn. Thủy quái Kraken đang áp sát!');
      _activeThreat = 'kraken';
      _threatTicks = 6;
      _soundService.playCreatureSound("leviathan_groan.mp3");
      if (_shieldActive) {
        _addLog(isEn ? 'SHIELD: Electromagnetic shield deflected Kraken constricting wrap.' : 'KÝ HIỆU: Lá chắn chặn đứng cú quấn siết của Kraken.');
        _triggerShieldFlash();
      } else {
        double dmg = 0.25;
        _hull = (_hull - dmg).clamp(0.0, 1.0);
        _addLog(isEn ? 'ALERT: Kraken tentacle slammed the hull! Armor integrity decreased by ${(dmg * 100).toInt()}%!' : 'BÁO ĐỘNG: Xúc tu Kraken quất mạnh vào vỏ tàu! Giáp giảm ${(dmg * 100).toInt()}%!');
        _triggerShake(intensity: 14.0);
      }
    }
    else if (_depth > 7000 && _depth < 9500 && _random.nextDouble() < 0.3) {
      _addLog(isEn ? 'WARNING: Ultra-low frequency infrasound "The Bloop" swept through!' : 'CẢNH BÁO: Sóng siêu âm tần số cực thấp "The Bloop" quét qua!');
      _activeThreat = 'bloop';
      _threatTicks = 6;
      _soundService.playCreatureSound("leviathan_groan.mp3");
      _energy = (_energy - 0.25).clamp(0.0, 1.0);
      _addLog(isEn ? 'SYS: Severe electromagnetic interference! Battery cells drained by 25%!' : 'SYS: Nhiễu loạn điện từ cực mạnh! Năng lượng dự trữ giảm 25%!');
      _triggerShake(intensity: 5.0);
    }
    else if (_depth >= 9500 && _random.nextDouble() < 0.35) {
      _addLog(isEn ? 'WARNING: Eerie telepathic feedback from Old God Cthulhu detected!' : 'CẢNH BÁO: Tín hiệu thần giao cách cảm ma quái của Tà Thần Cthulhu!');
      _activeThreat = 'cthulhu';
      _threatTicks = 6;
      _soundService.playCreatureSound("leviathan_groan.mp3");
      if (_shieldActive) {
        _addLog(isEn ? 'SHIELD: Psychic ward blocked Cthulhu mental disturbance.' : 'KÝ HIỆU: Hào quang tâm linh chặn đứng tác động từ Cthulhu.');
        _triggerShieldFlash();
      } else {
        _oxygen = (_oxygen - 0.15).clamp(0.0, 1.0);
        _addLog(isEn ? 'ALERT: Crew sanity collapsing under psychic pressure! Respiration rate increased by 15%!' : 'BÁO ĐỘNG: Thủy thủ đoàn điên loạn hoảng sợ! Lượng Oxy hô hấp hao hụt nhanh chóng 15%!');
        _triggerShake(intensity: 6.0);
      }
    }
  }

  void _triggerShake({double intensity = 8.0}) {
    int ticks = 0;
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted || ticks >= 10 || !_gameActive) {
        setState(() {
          _shakeX = 0;
          _shakeY = 0;
        });
        timer.cancel();
        return;
      }
      setState(() {
        _shakeX = (_random.nextDouble() * 2 - 1) * intensity;
        _shakeY = (_random.nextDouble() * 2 - 1) * intensity;
      });
      ticks++;
    });
  }

  void _triggerShieldFlash() {
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
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 8),

                  // Main Cockpit Simulator Screen
                  Expanded(
                    flex: 7,
                    child: _gameOver 
                        ? _buildGameOverPanel(dataService) 
                        : _buildSimulationPanel(dataService),
                  ),
                  const SizedBox(height: 12),

                  // Action HUD Control buttons
                  if (_gameActive && !_gameOver) ...[
                    _buildControlsPanel(),
                    const SizedBox(height: 12),
                  ],

                  // Text Log console
                  Expanded(
                    flex: 3,
                    child: _buildLogConsole(),
                  ),
                ],
              ),
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
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF0D1F3D),
                  title: Text(
                    strings.languageCode == 'vi' ? 'Hủy nhiệm vụ lặn?' : 'Abort dive mission?',
                    style: const TextStyle(color: Color(0xFFFF3366), fontWeight: FontWeight.bold),
                  ),
                  content: Text(
                    strings.languageCode == 'vi'
                        ? 'Tiến trình lặn hiện tại sẽ bị mất. Bạn có chắc chắn muốn thoát?'
                        : 'Current dive progress will be lost. Are you sure you want to exit?',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      child: Text(
                        strings.languageCode == 'vi' ? 'TIẾP TỤC LẶN' : 'CONTINUE DIVE',
                        style: const TextStyle(color: Color(0xFF00F0FF)),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    TextButton(
                      child: Text(
                        strings.languageCode == 'vi' ? 'THOÁT' : 'EXIT',
                        style: const TextStyle(color: Color(0xFFFF3366)),
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
    final strings = AppStrings.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1F3D).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _shieldActive ? const Color(0xFFFF3366) : const Color(0xFF00F0FF).withValues(alpha: 0.25),
          width: _shieldActive ? 2.5 : 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Cockpit window viewport with screen shake
          Transform.translate(
            offset: Offset(_shakeX, _shakeY),
            child: _buildAbyssViewport(),
          ),

          // Telemetry Gauges (O2, Hull, Shield)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildGauge(strings.languageCode == 'vi' ? 'DƯỠNG KHÍ (O2)' : 'OXYGEN (O2)', _oxygen, Colors.green, 'x$_oxygenCharges'),
                _buildGauge(strings.languageCode == 'vi' ? 'GIÁP VỎ TÀU' : 'HULL SHIELD', _hull, const Color(0xFFFF3366), 'x$_hullCharges'),
                _buildGauge(strings.languageCode == 'vi' ? 'NĂNG LƯỢNG' : 'ENERGY CELL', _energy, const Color(0xFF00F0FF), ''),
              ],
            ),
          ),

          // Shield status text
          if (_shieldActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF3366).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFF3366).withValues(alpha: 0.5)),
              ),
              child: Text(
                strings.languageCode == 'vi'
                    ? 'LÁ CHẮN NĂNG LƯỢNG: KÍCH HOẠT (${_shieldSecondsLeft}s)'
                    : 'ENERGY SHIELD: ACTIVE (${_shieldSecondsLeft}s)',
                style: const TextStyle(color: Color(0xFFFF3366), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            )
          else
            const SizedBox(height: 25),
        ],
      ),
    );
  }

  Widget _buildOnboardingPanel(DataService dataService) {
    final strings = AppStrings.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1F3D).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.25)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header icon and title
            Image.asset(
              'assets/images/icon/cruise.png',
              width: 74,
              height: 74,
            ),
            const SizedBox(height: 8),
            Text(
              strings.languageCode == 'vi' ? 'NHIỆM VỤ SINH TỒN VỰC THẲM' : 'ABYSS SURVIVAL MISSION',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              strings.languageCode == 'vi'
                  ? 'CHỈ HUY TÀU NGẦM LẶN XUỐNG VỰC SÂU MARIANA'
                  : 'COMMAND THE SUBMARINE TO DESCEND INTO MARIANA ABYSS',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 9, letterSpacing: 0.5),
            ),
            const Divider(color: Color(0xFF00F0FF), height: 20, thickness: 0.5),

            // Mechanics Grid
            _buildMechanicRow(
              Image.asset(
                'assets/images/icon/oxygen-mask.png',
                width: 26,
                height: 26,
              ),
              Colors.green,
              strings.languageCode == 'vi' ? 'DƯỠNG KHÍ OXY' : 'OXYGEN SUPPLY',
              strings.languageCode == 'vi'
                  ? 'Oxy cạn dần liên tục. Nhấn [BƠM OXY] khi O2 dưới 30%. Hạn chế tối đa 3 bình nạp lại.'
                  : 'Oxygen drains constantly. Press [REFUEL O2] when O2 is below 30%. Max 3 refills.',
            ),
            const SizedBox(height: 10),
            _buildMechanicRow(
              Image.asset(
                'assets/images/icon/repair-tools.png',
                width: 26,
                height: 26,
              ),
              const Color(0xFFFFCC00),
              strings.languageCode == 'vi' ? 'GIÁP VỎ TÀU (HULL)' : 'HULL INTEGRITY',
              strings.languageCode == 'vi'
                  ? 'Thủy quái tấn công sẽ phá hủy giáp vỏ tàu. Nhấn [HÀN VỎ TÀU] để cử robot sửa chữa vỏ tàu. Tối đa 3 lần.'
                  : 'Monster attacks will damage the hull. Press [WELD HULL] to deploy repair robots. Max 3 repairs.',
            ),
            const SizedBox(height: 10),
            _buildMechanicRow(
              Image.asset(
                'assets/images/icon/shield.png',
                width: 26,
                height: 26,
              ),
              const Color(0xFFFF3366),
              strings.languageCode == 'vi' ? 'LÁ CHẮN ĐIỆN TỪ (SHIELD)' : 'ELECTROMAGNETIC SHIELD',
              strings.languageCode == 'vi'
                  ? 'Kích hoạt lá chắn tốn 30% năng lượng. Hãy căn đúng lúc cảnh báo quái thú tiếp cận để bật lá chắn chặn 100% sát thương.'
                  : 'Shield activation costs 30% energy. Timing the shield right after warning signs blocks 100% damage.',
            ),
            const SizedBox(height: 10),
            _buildMechanicRow(
              Image.asset(
                'assets/images/icon/battery.png',
                width: 26,
                height: 26,
              ),
              const Color(0xFF00F0FF),
              strings.languageCode == 'vi' ? 'NĂNG LƯỢNG (ENERGY)' : 'BATTERY ENERGY',
              strings.languageCode == 'vi'
                  ? 'Năng lượng tự sạc lại chậm. Cần để kích hoạt Lá chắn bảo vệ tàu ngầm khỏi áp suất cực lớn.'
                  : 'Energy recharges slowly. Required to activate the shield to block creature strikes.',
            ),
            
            const SizedBox(height: 16),

            // High score status
            if (dataService.highScoreDepth > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF00F0FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.amber, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      strings.languageCode == 'vi'
                          ? 'KỶ LỤC LẶN SÂU NHẤT: ${dataService.highScoreDepth} MÉT'
                          : 'DEEPEST DIVE RECORD: ${dataService.highScoreDepth} METERS',
                      style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ],
                ),
              ),

            // Start Button
            Container(
              width: double.infinity,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(23),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00F0FF).withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _startGame,
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 24),
                label: Text(
                  strings.languageCode == 'vi' ? 'KHỞI HÀNH XUỐNG VỰC SÂU' : 'DEPART INTO THE DEEP',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5, color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00F0FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMechanicRow(Widget iconWidget, Color color, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          ),
          child: iconWidget,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(color: Colors.white60, fontSize: 9, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

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

    return AspectRatio(
      aspectRatio: 1.8,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
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

            // 4. Creature silhouette overlay
            if (monsterAsset != null)
              Center(
                child: AnimatedOpacity(
                  opacity: _activeThreat != null ? 0.75 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: AnimatedScale(
                    scale: _activeThreat != null ? 1.2 : 0.4,
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutBack,
                    child: Image.asset(
                      monsterAsset,
                      fit: BoxFit.contain,
                      width: 250,
                      height: 140,
                      color: const Color(0xFFFF3366).withValues(alpha: 0.8),
                      colorBlendMode: BlendMode.srcATop,
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
          ],
        ),
      ),
    );
  }

  Widget _buildGauge(String label, double value, Color color, String charges) {
    bool isLow = value < 0.3;
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer neon glow arc
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: isLow ? 0.25 : 0.05),
                    blurRadius: 10,
                    spreadRadius: 1,
                  )
                ],
              ),
            ),
            SizedBox(
              width: 72,
              height: 72,
              child: CircularProgressIndicator(
                value: value,
                backgroundColor: const Color(0xFF071224),
                valueColor: AlwaysStoppedAnimation<Color>(isLow ? const Color(0xFFFF3366) : color),
                strokeWidth: 6,
              ),
            ),
            AnimatedBuilder(
              animation: _hudAnimationController,
              builder: (context, child) {
                double opacity = 1.0;
                if (isLow) {
                  opacity = 0.3 + math.sin(_hudAnimationController.value * math.pi * 4).abs() * 0.7;
                }
                return Opacity(
                  opacity: opacity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(value * 100).toInt()}%',
                        style: TextStyle(
                          color: isLow ? const Color(0xFFFF3366) : Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                      if (charges.isNotEmpty)
                        Text(
                          charges,
                          style: TextStyle(
                            color: isLow ? const Color(0xFFFF3366) : color,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isLow ? const Color(0xFFFF3366) : Colors.white.withValues(alpha: 0.5),
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildControlsPanel() {
    final strings = AppStrings.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1F3D).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Oxygen button
          _buildActionButton(
            onPressed: _oxygenCharges > 0 && _oxygen < 0.9 ? _refillOxygen : null,
            iconWidget: Image.asset(
              'assets/images/icon/oxygen-mask.png',
              width: 36,
              height: 36,
            ),
            label: strings.languageCode == 'en' ? 'REFUEL O2' : 'BƠM OXY',
            color: Colors.green,
            isEnabled: _oxygenCharges > 0 && _oxygen < 0.9,
          ),
          
          // Shield button
          _buildActionButton(
            onPressed: _energy >= 0.3 && !_shieldActive ? _activateShield : null,
            iconWidget: Image.asset(
              'assets/images/icon/shield.png',
              width: 36,
              height: 36,
            ),
            label: strings.languageCode == 'en' ? 'DEFLECTOR' : 'LÁ CHẮN',
            color: const Color(0xFFFF3366),
            isEnabled: _energy >= 0.3 && !_shieldActive,
          ),

          // Repair button
          _buildActionButton(
            onPressed: _hullCharges > 0 && _hull < 0.9 ? _repairHull : null,
            iconWidget: Image.asset(
              'assets/images/icon/repair-tools.png',
              width: 36,
              height: 36,
            ),
            label: strings.languageCode == 'en' ? 'WELD HULL' : 'HÀN VỎ TÀU',
            color: const Color(0xFFFFCC00),
            isEnabled: _hullCharges > 0 && _hull < 0.9,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required Widget iconWidget,
    required String label,
    required Color color,
    required bool isEnabled,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          if (isEnabled)
            BoxShadow(
              color: color.withValues(alpha: 0.25),
              blurRadius: 8,
              spreadRadius: 1,
            )
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled 
              ? const Color(0xFF0D1F3D).withValues(alpha: 0.6) 
              : Colors.black.withValues(alpha: 0.4),
          side: BorderSide(
            color: isEnabled ? color : Colors.white.withValues(alpha: 0.1),
            width: isEnabled ? 2.0 : 1.0,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: isEnabled ? 4 : 0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: isEnabled ? 1.0 : 0.3,
              child: iconWidget,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isEnabled ? Colors.white : Colors.white.withValues(alpha: 0.2),
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
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
    String deathReport = '';
    if (_oxygen <= 0.0) {
      deathReport = isEn
          ? 'OXYGEN LEVEL CRITICAL: O2 DEPLETED. The cockpit displays flickered and died, and life support failed. The crew gradually lost consciousness in the crushing cold and pitch-black void at $_depth meters.'
          : 'DƯỠNG KHÍ O2 CẠN KIỆT HOÀN TOÀN. Màn hình buồng lái tắt lịm, hệ thống điều hòa ngừng hoạt động. Thủy thủ đoàn lịm dần đi trong bóng tối và cái lạnh thấu xương ở độ sâu $_depth mét.';
    } else {
      deathReport = isEn
          ? 'CRITICAL PRESSURE WARNING: HULL FAILURE. The colossal hydrostatic pressure at $_depth meters crushed the reinforced titanium hull in a fraction of a millisecond. Immediate implosion annihilated all signs of life.'
          : 'ÁP SUẤT NGHIỀN NÁT VỎ TÀU NGẦM. Áp lực nước khổng lồ ở độ sâu $_depth mét đã ép sập lớp vỏ titan kiên cố trong một phần triệu giây. Sự cố nén gây nổ tung tức thời, xóa sổ mọi dấu vết sự sống.';
    }

    List<String> unlockedAchievements = [];
    if (_depth >= 4000) unlockedAchievements.add('Midnight Explorer (4,000m)');
    if (_depth >= 11000) unlockedAchievements.add('Mariana Conqueror (11,000m)');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0307),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF3366), width: 2.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF3366).withValues(alpha: 0.25),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Graphic warning backdrop texture
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Image.asset(
                'assets/images/creatures/diver_transparent.png',
                fit: BoxFit.cover,
                color: Colors.red,
                colorBlendMode: BlendMode.srcATop,
              ),
            ),
          ),
          SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                // Blinking emergency icon
                AnimatedBuilder(
                  animation: _hudAnimationController,
                  builder: (context, child) {
                    return Icon(
                      Icons.error_outline_rounded,
                      color: const Color(0xFFFF3366),
                      size: 54,
                      shadows: [
                        Shadow(
                          color: const Color(0xFFFF3366).withValues(alpha: math.sin(_hudAnimationController.value * math.pi * 4).abs()),
                          blurRadius: 15,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  isEn ? 'COMMUNICATION SIGNAL LOST' : 'MẤT TÍN HIỆU LIÊN LẠC',
                  style: const TextStyle(
                    color: Color(0xFFFF3366),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                Text(
                  isEn ? 'FINAL TELEMETRY REPORT' : 'BÁO CÁO TELEMETRY CUỐI CÙNG',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 8,
                    letterSpacing: 1,
                  ),
                ),
                const Divider(color: Color(0xFFFF3366), height: 20, thickness: 0.5),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(isEn ? 'FINAL DIVE DEPTH: ' : 'ĐỘ SÂU CUỐI CÙNG: ', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    Text(
                      '$_depth m',
                      style: const TextStyle(
                        color: Color(0xFF00F0FF),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                
                if (isNewRecord)
                  Container(
                    margin: const EdgeInsets.only(top: 6, bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.amber),
                    ),
                    child: Text(
                      isEn ? 'NEW RECORD ESTABLISHED!' : 'THIẾT LẬP KỶ LỤC MỚI!',
                      style: const TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.w900),
                    ),
                  ),
                
                const SizedBox(height: 6),
                
                // Tragic fate summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFF3366).withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    deathReport,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      height: 1.4,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                
                const SizedBox(height: 14),
                
                if (unlockedAchievements.isNotEmpty) ...[
                  Text(
                    isEn ? 'CREW ACHIEVEMENTS UNLOCKED:' : 'DANH HIỆU THUYỀN VIÊN ĐÃ MỞ KHÓA:',
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  const SizedBox(height: 6),
                  ...unlockedAchievements.map((ach) => Text(
                    '★ $ach',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500, fontFamily: 'monospace'),
                  )),
                  const SizedBox(height: 14),
                ],
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _startGame,
                      icon: const Icon(Icons.refresh, color: Colors.black),
                      label: Text(isEn ? 'TRY AGAIN' : 'THỬ LẠI', style: const TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00F0FF),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.exit_to_app, color: Color(0xFF00F0FF)),
                      label: Text(isEn ? 'EXIT' : 'THOÁT', style: const TextStyle(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF00F0FF)),
                        foregroundColor: const Color(0xFF00F0FF),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogConsole() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF010307),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.15)),
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
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
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
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    logText,
                    style: TextStyle(
                      color: logColor,
                      fontFamily: 'monospace',
                      fontSize: 9,
                      height: 1.3,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
