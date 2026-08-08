import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/creature.dart';
import '../widgets/cached_video_player.dart';
import '../services/data_service.dart';
import '../services/sound_service.dart';
import '../l10n/app_strings.dart';

enum CombatEffectType {
  slash,      // Kiếm
  fire,       // Lửa đốt
  lightning,  // Sét đánh
  claw,       // Vuốt cào
  bite        // Hàm cắn
}

class BattleScreen extends StatefulWidget {
  const BattleScreen({super.key});

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> with TickerProviderStateMixin {
  final math.Random _random = math.Random();
  final ScrollController _logScrollController = ScrollController();
  late SoundService _soundService;

  List<Creature> _selectableCreatures = [];
  Creature? _leftCreature;
  Creature? _rightCreature;

  // Combat Stats
  double _leftMaxHP = 100;
  double _leftHP = 100;
  double _leftAttack = 0;
  double _leftDefense = 0;
  double _leftSpeed = 0;

  double _rightMaxHP = 100;
  double _rightHP = 100;
  double _rightAttack = 0;
  double _rightDefense = 0;
  double _rightSpeed = 0;

  // Interactive Buffs/Skills (1 charge per battle)
  bool _leftHasHeal = true;
  bool _leftHasShield = true;
  bool _leftHasRage = true;
  bool _leftShieldActive = false;
  bool _leftRageActive = false;

  bool _rightHasHeal = true;
  bool _rightHasShield = true;
  bool _rightHasRage = true;
  bool _rightShieldActive = false;
  bool _rightRageActive = false;

  // Battle status
  bool _isBattleActive = false;
  bool _isBattleOver = false;
  int _roundCount = 0;
  Timer? _battleTimer;
  final List<String> _battleLogs = [];

  // Hit Shake Animations
  double _leftShakeX = 0.0;
  double _rightShakeX = 0.0;
  bool _leftFlashRed = false;
  bool _rightFlashRed = false;
  final List<Map<String, dynamic>> _damagePopups = [];
  final List<Map<String, dynamic>> _activeEffects = [];

  @override
  void initState() {
    super.initState();
    
    // Schedule load after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dataService = Provider.of<DataService>(context, listen: false);
      setState(() {
        // Filter creatures to only mythic or bosses (danger level >= 4 or type == myth)
        _selectableCreatures = dataService.creatures
            .where((c) => c.type == 'myth' || c.dangerLevel >= 4)
            .toList();
        
        // Auto pick default random pair
        _randomizePair();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _soundService = Provider.of<SoundService>(context, listen: false);
  }

  @override
  void dispose() {
    _battleTimer?.cancel();
    _soundService.stopCreatureSound();
    _logScrollController.dispose();
    super.dispose();
  }

  void _randomizePair() {
    if (_selectableCreatures.isEmpty) return;
    _battleTimer?.cancel();
    setState(() {
      _isBattleActive = false;
      _isBattleOver = false;
      _roundCount = 0;
      _battleLogs.clear();
      _damagePopups.clear();
      _activeEffects.clear();
      
      // Select left
      _leftCreature = _selectableCreatures[_random.nextInt(_selectableCreatures.length)];
      
      // Select right (make sure it's different if possible)
      if (_selectableCreatures.length > 1) {
        do {
          _rightCreature = _selectableCreatures[_random.nextInt(_selectableCreatures.length)];
        } while (_rightCreature!.id == _leftCreature!.id);
      } else {
        _rightCreature = _leftCreature;
      }

      _initializeStats();
      _addLog('--- ĐẤU TRƯỜNG SẴN SÀNG / ARENA READY ---');
    });
  }

  void _initializeStats() {
    if (_leftCreature == null || _rightCreature == null) return;

    // Left Creature Stats
    _leftMaxHP = (_leftCreature!.dangerLevel * 150.0 + _leftCreature!.creatureSizeMeters * 0.5 + 300.0).roundToDouble();
    _leftHP = _leftMaxHP;
    _leftAttack = (_leftCreature!.dangerLevel * 30.0 + 40.0).roundToDouble();
    _leftDefense = (_leftCreature!.dangerLevel * 12.0 + 20.0).roundToDouble();
    _leftSpeed = (300.0 / (_leftCreature!.creatureSizeMeters.clamp(1.0, 300.0)) + _leftCreature!.dangerLevel * 10.0).roundToDouble();

    // Right Creature Stats
    _rightMaxHP = (_rightCreature!.dangerLevel * 150.0 + _rightCreature!.creatureSizeMeters * 0.5 + 300.0).roundToDouble();
    _rightHP = _rightMaxHP;
    _rightAttack = (_rightCreature!.dangerLevel * 30.0 + 40.0).roundToDouble();
    _rightDefense = (_rightCreature!.dangerLevel * 12.0 + 20.0).roundToDouble();
    _rightSpeed = (300.0 / (_rightCreature!.creatureSizeMeters.clamp(1.0, 300.0)) + _rightCreature!.dangerLevel * 10.0).roundToDouble();

    // Reset buffs
    _leftHasHeal = true;
    _leftHasShield = true;
    _leftHasRage = true;
    _leftShieldActive = false;
    _leftRageActive = false;

    _rightHasHeal = true;
    _rightHasShield = true;
    _rightHasRage = true;
    _rightShieldActive = false;
    _rightRageActive = false;
  }

  void _addLog(String text) {
    if (!mounted) return;
    setState(() {
      _battleLogs.add(text);
    });
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

  // Support Skills Left
  void _useLeftHeal() {
    if (!_isBattleActive || _isBattleOver || !_leftHasHeal) return;
    final strings = AppStrings.of(context);
    final isVi = strings.languageCode == 'vi';
    
    setState(() {
      _leftHasHeal = false;
      double healAmount = (_leftMaxHP * 0.25).roundToDouble();
      _leftHP = (_leftHP + healAmount).clamp(0.0, _leftMaxHP);
      _soundService.playCreatureSound("static_crackle.mp3");
      _addLog(isVi 
          ? '💚 HỖ TRỢ TRÁI: Kích hoạt HỒI PHỤC cho ${_leftCreature!.getName("vi")} (+${healAmount.toInt()} HP)!'
          : '💚 LEFT SUPPORT: Activated HEAL for ${_leftCreature!.getName("en")} (+${healAmount.toInt()} HP)!');
    });
  }

  void _useLeftShield() {
    if (!_isBattleActive || _isBattleOver || !_leftHasShield) return;
    final strings = AppStrings.of(context);
    final isVi = strings.languageCode == 'vi';

    setState(() {
      _leftHasShield = false;
      _leftShieldActive = true;
      _soundService.playCreatureSound("static_crackle.mp3");
      _addLog(isVi
          ? '🛡️ HỖ TRỢ TRÁI: Tạo LÁ CHẮN bảo vệ cho ${_leftCreature!.getName("vi")}!'
          : '🛡️ LEFT SUPPORT: Deployed SHIELD for ${_leftCreature!.getName("en")}!');
    });
  }

  void _useLeftRage() {
    if (!_isBattleActive || _isBattleOver || !_leftHasRage) return;
    final strings = AppStrings.of(context);
    final isVi = strings.languageCode == 'vi';

    setState(() {
      _leftHasRage = false;
      _leftRageActive = true;
      _soundService.playCreatureSound("static_crackle.mp3");
      _addLog(isVi
          ? '⚡ HỖ TRỢ TRÁI: Kích hoạt NỔI GIẬN cho ${_leftCreature!.getName("vi")} (X1.8 Sát thương đòn sau)!'
          : '⚡ LEFT SUPPORT: Activated RAGE for ${_leftCreature!.getName("en")} (1.8x damage next turn)!');
    });
  }

  // Support Skills Right
  void _useRightHeal() {
    if (!_isBattleActive || _isBattleOver || !_rightHasHeal) return;
    final strings = AppStrings.of(context);
    final isVi = strings.languageCode == 'vi';

    setState(() {
      _rightHasHeal = false;
      double healAmount = (_rightMaxHP * 0.25).roundToDouble();
      _rightHP = (_rightHP + healAmount).clamp(0.0, _rightMaxHP);
      _soundService.playCreatureSound("static_crackle.mp3");
      _addLog(isVi
          ? '💚 HỖ TRỢ PHẢI: Kích hoạt HỒI PHỤC cho ${_rightCreature!.getName("vi")} (+${healAmount.toInt()} HP)!'
          : '💚 RIGHT SUPPORT: Activated HEAL for ${_rightCreature!.getName("en")} (+${healAmount.toInt()} HP)!');
    });
  }

  void _useRightShield() {
    if (!_isBattleActive || _isBattleOver || !_rightHasShield) return;
    final strings = AppStrings.of(context);
    final isVi = strings.languageCode == 'vi';

    setState(() {
      _rightHasShield = false;
      _rightShieldActive = true;
      _soundService.playCreatureSound("static_crackle.mp3");
      _addLog(isVi
          ? '🛡️ HỖ TRỢ PHẢI: Tạo LÁ CHẮN bảo vệ cho ${_rightCreature!.getName("vi")}!'
          : '🛡️ RIGHT SUPPORT: Deployed SHIELD for ${_rightCreature!.getName("en")}!');
    });
  }

  void _useRightRage() {
    if (!_isBattleActive || _isBattleOver || !_rightHasRage) return;
    final strings = AppStrings.of(context);
    final isVi = strings.languageCode == 'vi';

    setState(() {
      _rightHasRage = false;
      _rightRageActive = true;
      _soundService.playCreatureSound("static_crackle.mp3");
      _addLog(isVi
          ? '⚡ HỖ TRỢ PHẢI: Kích hoạt NỔI GIẬN cho ${_rightCreature!.getName("vi")} (X1.8 Sát thương đòn sau)!'
          : '⚡ RIGHT SUPPORT: Activated RAGE for ${_rightCreature!.getName("en")} (1.8x damage next turn)!');
    });
  }

  void _startBattle() {
    if (_leftCreature == null || _rightCreature == null || _isBattleActive || _isBattleOver) return;

    final strings = AppStrings.of(context);
    final isVi = strings.languageCode == 'vi';

    setState(() {
      _isBattleActive = true;
      _isBattleOver = false;
    });

    _addLog(isVi ? '🔥 CUỘC CHIẾN BẮT ĐẦU! 🔥' : '🔥 BATTLE COMMENCED! 🔥');

    // Run combat rounds every 2800ms
    _battleTimer = Timer.periodic(const Duration(milliseconds: 2800), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_leftHP <= 0 || _rightHP <= 0) {
        _endBattle();
        return;
      }

      _executeRound();
    });
  }

  void _executeRound() {
    _roundCount++;
    final strings = AppStrings.of(context);
    final isVi = strings.languageCode == 'vi';

    _addLog(isVi ? '\n[VÒNG $_roundCount]' : '\n[ROUND $_roundCount]');

    // Check speed to see who attacks first
    bool leftAttacksFirst = _leftSpeed >= _rightSpeed;
    if (_leftSpeed == _rightSpeed) {
      leftAttacksFirst = _random.nextBool();
    }

    if (leftAttacksFirst) {
      // Left attacks
      _performAttack(isLeftAttacking: true);
      // Right retaliates if still alive
      if (_rightHP > 0) {
        Future.delayed(const Duration(milliseconds: 1300), () {
          if (mounted && _isBattleActive && !_isBattleOver) {
            _performAttack(isLeftAttacking: false);
          }
        });
      }
    } else {
      // Right attacks
      _performAttack(isLeftAttacking: false);
      // Left retaliates if still alive
      if (_leftHP > 0) {
        Future.delayed(const Duration(milliseconds: 1300), () {
          if (mounted && _isBattleActive && !_isBattleOver) {
            _performAttack(isLeftAttacking: true);
          }
        });
      }
    }
  }

  CombatEffectType _getCreatureEffectType(String creatureId) {
    switch (creatureId) {
      case 'godzilla':
        return CombatEffectType.fire;
      case 'lagiacrus':
        return CombatEffectType.lightning;
      case 'megalodon':
      case 'reaper_leviathan':
        return CombatEffectType.bite;
      case 'kraken':
      case 'giant_isopod':
      case 'black_dragonfish':
        return CombatEffectType.claw;
      case 'cthulhu':
      case 'ghost_leviathan':
      case 'jormungandr':
      case 'sea_serpent':
      default:
        return CombatEffectType.slash;
    }
  }

  void _performAttack({required bool isLeftAttacking}) {
    final strings = AppStrings.of(context);
    final isVi = strings.languageCode == 'vi';

    final attacker = isLeftAttacking ? _leftCreature! : _rightCreature!;
    final defender = isLeftAttacking ? _rightCreature! : _leftCreature!;

    // Play attacker sound
    if (attacker.ambientSound.isNotEmpty) {
      _soundService.playCreatureSound(attacker.ambientSound);
    }

    // Damage calculations
    double rawDmg = isLeftAttacking ? _leftAttack : _rightAttack;
    double defenseValue = isLeftAttacking ? _rightDefense : _leftDefense;
    
    // Scale damage with randomized factor
    double damageFactor = 0.85 + _random.nextDouble() * 0.3; // 85% to 115%
    double dmg = (rawDmg * damageFactor - defenseValue * 0.4).roundToDouble();
    if (dmg < 20) dmg = 20;

    // Apply Rage
    bool rageTriggered = isLeftAttacking ? _leftRageActive : _rightRageActive;
    if (rageTriggered) {
      dmg = (dmg * 1.8).roundToDouble();
      if (isLeftAttacking) {
        _leftRageActive = false;
      } else {
        _rightRageActive = false;
      }
    }

    // Check Shield
    bool shieldTriggered = isLeftAttacking ? _rightShieldActive : _leftShieldActive;
    if (shieldTriggered) {
      dmg = 0;
      if (isLeftAttacking) {
        _rightShieldActive = false;
      } else {
        _leftShieldActive = false;
      }
    }

    // Shake and Flash
    setState(() {
      if (isLeftAttacking) {
        _rightShakeX = 12.0;
        _rightFlashRed = true;
        _rightHP = (_rightHP - dmg).clamp(0.0, _rightMaxHP);
      } else {
        _leftShakeX = 12.0;
        _leftFlashRed = true;
        _leftHP = (_leftHP - dmg).clamp(0.0, _leftMaxHP);
      }
    });

    final String popupId = DateTime.now().millisecondsSinceEpoch.toString() + _random.nextInt(100).toString();
    final effect = _getCreatureEffectType(attacker.id);
    setState(() {
      _damagePopups.add({
        'id': popupId,
        'damage': dmg.toInt(),
        'isLeft': !isLeftAttacking,
      });
      _activeEffects.add({
        'id': popupId,
        'type': effect,
        'isLeft': !isLeftAttacking,
      });
    });

    // Reset shake and flash after delay
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _leftShakeX = 0.0;
          _rightShakeX = 0.0;
          _leftFlashRed = false;
          _rightFlashRed = false;
        });
      }
    });

    // Logging attack outcome
    String attName = attacker.getName(strings.languageCode);
    String defName = defender.getName(strings.languageCode);

    if (shieldTriggered) {
      _addLog(isVi
          ? '🛡️ Lá chắn của $defName hấp thụ hoàn toàn đòn tấn công từ $attName!'
          : '🛡️ $defName\'s shield fully absorbed the attack from $attName!');
    } else {
      String ragePrefix = rageTriggered ? (isVi ? '💥 CHẤN ĐỘNG! ' : '💥 RAGE IMPACT! ') : '';
      _addLog(isVi
          ? '$ragePrefix$attName tấn công $defName gây ${dmg.toInt()} sát thương.'
          : '$ragePrefix$attName attacks $defName dealing ${dmg.toInt()} damage.');
    }
  }

  void _endBattle() {
    _battleTimer?.cancel();
    final strings = AppStrings.of(context);
    final isVi = strings.languageCode == 'vi';

    setState(() {
      _isBattleActive = false;
      _isBattleOver = true;
    });

    if (_leftHP <= 0 && _rightHP <= 0) {
      _addLog(isVi 
          ? '\n💀 LƯỠNG BẠI CÂU THƯƠNG! Cả hai quái thú đều gục ngã.' 
          : '\n💀 DOUBLE KNOCKOUT! Both monsters collapsed.');
    } else if (_leftHP <= 0) {
      _addLog(isVi 
          ? '\n🏆 CHIẾN THẮNG THUỘC VỀ: ${_rightCreature!.getName("vi").toUpperCase()}!' 
          : '\n🏆 VICTOR: ${_rightCreature!.getName("en").toUpperCase()}!');
      if (_rightCreature!.ambientSound.isNotEmpty) {
        _soundService.playCreatureSound(_rightCreature!.ambientSound);
      }
    } else {
      _addLog(isVi 
          ? '\n🏆 CHIẾN THẮNG THUỘC VỀ: ${_leftCreature!.getName("vi").toUpperCase()}!' 
          : '\n🏆 VICTOR: ${_leftCreature!.getName("en").toUpperCase()}!');
      if (_leftCreature!.ambientSound.isNotEmpty) {
        _soundService.playCreatureSound(_leftCreature!.ambientSound);
      }
    }
  }

  void _resetBattle() {
    _battleTimer?.cancel();
    setState(() {
      _isBattleActive = false;
      _isBattleOver = false;
      _roundCount = 0;
      _battleLogs.clear();
      _damagePopups.clear();
      _activeEffects.clear();
      _initializeStats();
      _addLog('--- ĐÃ THIẾT LẬP LẠI TRẬN ĐẤU / ARENA RESET ---');
    });
  }

  void _showCreatureSelectDialog({required bool isLeft}) {
    if (_isBattleActive) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF030A18),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.of(context).languageCode == 'vi'
                    ? 'CHỌN QUÁI THÚ CHIẾN ĐẤU'
                    : 'SELECT COMBAT MONSTER',
                style: const TextStyle(
                  color: Color(0xFF00F0FF),
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _selectableCreatures.length,
                  itemBuilder: (context, index) {
                    final creature = _selectableCreatures[index];
                    final String name = creature.getName(AppStrings.of(context).languageCode);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: creature.imageProvider,
                        backgroundColor: const Color(0xFF010610),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Danger Lvl: ${creature.dangerLevel} | Depth: ${creature.minDepth}m',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          if (isLeft) {
                            _leftCreature = creature;
                          } else {
                            _rightCreature = creature;
                          }
                          _initializeStats();
                          _resetBattle();
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.listen(context);

    return Scaffold(
      backgroundColor: const Color(0xFF020813),
      appBar: AppBar(
        title: Text(
          strings.languageCode == 'vi' ? 'ĐẤU TRƯỜNG BIỂN SÂU' : 'ABYSSAL ARENA',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF030B1C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _leftCreature == null || _rightCreature == null
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00F0FF),
              ),
            )
          : SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double W = constraints.maxWidth;
                  final double H = constraints.maxHeight;

                  return Stack(
                    children: [
                      // 1. Left Fighter Card (Top, full-width, zero border radius, Cover fit video)
                      Positioned(
                        left: 0,
                        top: 0,
                        width: W,
                        height: H * 0.44,
                        child: _buildCombatantCard(
                          creature: _leftCreature!,
                          isLeft: true,
                          currentHP: _leftHP,
                          maxHP: _leftMaxHP,
                          shakeX: _leftShakeX,
                          flashRed: _leftFlashRed,
                          shieldActive: _leftShieldActive,
                          rageActive: _leftRageActive,
                        ),
                      ),

                      // 2. Control Bar (Middle, centered - Apple Minimalist Style)
                      Positioned(
                        left: 12,
                        right: 12,
                        top: H * 0.44 + 8,
                        height: 48,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // COMBAT button (Apple Prominent Blue)
                            SizedBox(
                              width: W * 0.35,
                              height: 38,
                              child: ElevatedButton(
                                onPressed: (_isBattleActive || _isBattleOver) ? null : _startBattle,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0A84FF), // iOS Dark Mode Blue
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.white.withValues(alpha: 0.05),
                                  disabledForegroundColor: Colors.white24,
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                                    const SizedBox(width: 4),
                                    Text(
                                      strings.languageCode == 'vi' ? 'Quyết Đấu' : 'Combat',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            // Center: VS Badge
                            Container(
                              width: 34,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white24,
                                  width: 1.0,
                                ),
                              ),
                              child: const Text(
                                'VS',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.0,
                                ),
                              ),
                            ),
                            
                            // RANDOM button (Apple Tinted Translucent Grey)
                            SizedBox(
                              width: W * 0.35,
                              height: 38,
                              child: ElevatedButton(
                                onPressed: _isBattleActive ? null : _randomizePair,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.white.withValues(alpha: 0.03),
                                  disabledForegroundColor: Colors.white12,
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.shuffle_rounded, color: Colors.white, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      strings.languageCode == 'vi' ? 'Đổi Cặp' : 'Random',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            // RESET button
                            SizedBox(
                              width: 38,
                              height: 38,
                              child: IconButton(
                                onPressed: _isBattleActive ? null : _resetBattle,
                                icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 18),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 3. Right Fighter Card (Below Control Bar, full-width, zero border radius, Cover fit video)
                      Positioned(
                        left: 0,
                        top: H * 0.44 + 8 + 48 + 8,
                        width: W,
                        height: H * 0.44,
                        child: _buildCombatantCard(
                          creature: _rightCreature!,
                          isLeft: false,
                          currentHP: _rightHP,
                          maxHP: _rightMaxHP,
                          shakeX: _rightShakeX,
                          flashRed: _rightFlashRed,
                          shieldActive: _rightShieldActive,
                          rageActive: _rightRageActive,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }

  Widget _buildCombatantCard({
    required Creature creature,
    required bool isLeft,
    required double currentHP,
    required double maxHP,
    required double shakeX,
    required bool flashRed,
    required bool shieldActive,
    required bool rageActive,
  }) {
    final strings = AppStrings.of(context);
    final String name = creature.getName(strings.languageCode);
    final double hpPercent = (currentHP / maxHP).clamp(0.0, 1.0);
    
    final Color sideColor = isLeft ? const Color(0xFF00F0FF) : const Color(0xFFFF3366);

    // Winner/Loser status logic
    final bool isWinner = _isBattleOver && ((isLeft && _leftHP > 0) || (!isLeft && _rightHP > 0));
    final bool isLoser = _isBattleOver && ((isLeft && _leftHP <= 0 && _rightHP > 0) || (!isLeft && _rightHP <= 0 && _leftHP > 0));
    final bool isDraw = _isBattleOver && _leftHP <= 0 && _rightHP <= 0;
    final bool useGrayscale = isLoser || isDraw;

    final Widget cardBody = Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Selector/Profile Header
            GestureDetector(
              onTap: () => _showCreatureSelectDialog(isLeft: isLeft),
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
                padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: sideColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.0,
                        ),
                      ),
                    ),
                    if (!_isBattleActive)
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white60,
                        size: 16,
                      ),
                  ],
                ),
              ),
            ),

            // 2. Avatar Area
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Transform.scale(
                    scale: isLeft ? 1.35 : 1.0,
                    child: creature.videoUrl.isNotEmpty
                        ? CachedCreatureVideoPlayer(
                            key: ValueKey(creature.id),
                            videoUrl: creature.videoUrl,
                            disableMask: true,
                            fit: BoxFit.cover,
                            placeholder: creature.buildImage(
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.black,
                                  child: const Icon(Icons.broken_image, color: Colors.white38),
                                );
                              },
                            ),
                          )
                        : creature.buildImage(
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.black,
                                child: const Icon(Icons.broken_image, color: Colors.white38),
                              );
                            },
                          ),
                  ),
                  
                  // Red Flash overlay when hit
                  if (flashRed)
                    Container(
                      color: Colors.red.withValues(alpha: 0.4),
                    ),
                  
                  // Active combat effect animations
                  ..._activeEffects
                      .where((e) => e['isLeft'] == isLeft)
                      .map((e) => CombatEffectOverlay(
                            key: ValueKey(e['id']),
                            type: e['type'],
                            onComplete: () {
                              setState(() {
                                _activeEffects.removeWhere((item) => item['id'] == e['id']);
                              });
                            },
                          )),

                  // Shield Overlay Indicator
                  if (shieldActive)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF00F0FF),
                            width: 4.0,
                          ),
                          color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/images/icon/shield.png',
                            width: 40.0,
                            height: 40.0,
                          ),
                        ),
                      ),
                    ),

                  // Rage Overlay Indicator (Moved to left: 8)
                  if (rageActive)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Image.asset(
                          'assets/images/icon/battery.png',
                          width: 16.0,
                          height: 16.0,
                        ),
                      ),
                    ),

                  // Floating Skill Buttons Column (Action Strip overlayed on the right side of the video)
                  Positioned(
                    top: 0,
                    bottom: 0,
                    right: 0,
                    width: 48,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5), // Glass dark background
                        border: const Border(
                          left: BorderSide(color: Colors.white10, width: 1.0),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // HEAL
                          _buildSkillButton(
                            icon: Opacity(
                              opacity: (isLeft ? _leftHasHeal : _rightHasHeal) ? 1.0 : 0.35,
                              child: Image.asset(
                                'assets/images/icon/heal.png',
                                width: 20,
                                height: 20,
                              ),
                            ),
                            color: Colors.green,
                            isActive: isLeft ? _leftHasHeal : _rightHasHeal,
                            onTap: isLeft ? _useLeftHeal : _useRightHeal,
                            tooltip: 'HEAL',
                          ),
                          // SHIELD
                          _buildSkillButton(
                            icon: Opacity(
                              opacity: (isLeft ? _leftHasShield : _rightHasShield) ? 1.0 : 0.35,
                              child: Image.asset(
                                'assets/images/icon/shield.png',
                                width: 20,
                                height: 20,
                              ),
                            ),
                            color: const Color(0xFF00F0FF),
                            isActive: isLeft ? _leftHasShield : _rightHasShield,
                            onTap: isLeft ? _useLeftShield : _useRightShield,
                            tooltip: 'SHIELD',
                          ),
                          // RAGE
                          _buildSkillButton(
                            icon: Opacity(
                              opacity: (isLeft ? _leftHasRage : _rightHasRage) ? 1.0 : 0.35,
                              child: Image.asset(
                                'assets/images/icon/battery.png',
                                width: 20,
                                height: 20,
                              ),
                            ),
                            color: Colors.orange,
                            isActive: isLeft ? _leftHasRage : _rightHasRage,
                            onTap: isLeft ? _useLeftRage : _useRightRage,
                            tooltip: 'RAGE',
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Floating Damage Texts
                  ..._damagePopups
                      .where((p) => p['isLeft'] == isLeft)
                      .map((p) => Positioned(
                            top: 60.0,
                            child: FloatingDamageText(
                              key: ValueKey(p['id']),
                              damage: p['damage'],
                              isLeft: isLeft,
                              onComplete: () {
                                setState(() {
                                  _damagePopups.removeWhere((item) => item['id'] == p['id']);
                                });
                              },
                            ),
                          )),
                ],
              ),
            ),

            // 3. Health bar & Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'HP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${currentHP.toInt()}/${maxHP.toInt()}',
                        style: TextStyle(
                          color: currentHP <= (maxHP * 0.25) ? Colors.red : Colors.green,
                          fontSize: 10.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2.0),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.0),
                    child: LinearProgressIndicator(
                      value: hpPercent,
                      minHeight: 6.0,
                      backgroundColor: Colors.white24,
                      color: hpPercent <= 0.25 ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            // 5. Miniature numerical stats list
            Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatIndicator(
                    icon: Icons.flash_on,
                    value: isLeft ? _leftAttack.toInt() : _rightAttack.toInt(),
                    color: Colors.orange,
                  ),
                  _buildStatIndicator(
                    icon: Icons.shield_outlined,
                    value: isLeft ? _leftDefense.toInt() : _rightDefense.toInt(),
                    color: Colors.blue,
                  ),
                  _buildStatIndicator(
                    icon: Icons.speed,
                    value: isLeft ? _leftSpeed.toInt() : _rightSpeed.toInt(),
                    color: Colors.purple,
                  ),
                ],
              ),
            ),
          ],
        ),

        // ── VICTORY/DEFEAT/DRAW OVERLAY FILTERS ───────────────────────────
        if (isWinner)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.18),
                border: Border.all(color: Colors.amber, width: 2.5),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF030A18).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.amber, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🏆', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        strings.languageCode == 'vi' ? 'CHIẾN THẮNG' : 'VICTOR',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        if (isLoser)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.55),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(6.0),
                    border: Border.all(color: Colors.white24, width: 1.0),
                  ),
                  child: Text(
                    strings.languageCode == 'vi' ? 'BẠI TRẬN' : 'DEFEATED',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ),

        if (isDraw)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.45),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(6.0),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5), width: 1.0),
                  ),
                  child: Text(
                    strings.languageCode == 'vi' ? 'HÒA NHAU' : 'MUTUAL KO',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    return Transform.translate(
      offset: Offset(shakeX, 0.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          color: const Color(0xFF030B1C),
          borderRadius: BorderRadius.zero,
          border: Border(
            top: BorderSide(
              color: flashRed 
                  ? Colors.red 
                  : sideColor.withValues(alpha: _isBattleActive ? 0.8 : 0.3),
              width: 1.5,
            ),
            bottom: BorderSide(
              color: flashRed 
                  ? Colors.red 
                  : sideColor.withValues(alpha: _isBattleActive ? 0.8 : 0.3),
              width: 1.5,
            ),
          ),
          boxShadow: [
            if (_isBattleActive)
              BoxShadow(
                color: sideColor.withValues(alpha: 0.15),
                blurRadius: 8.0,
                spreadRadius: 1.0,
              ),
          ],
        ),
        child: useGrayscale
            ? ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0,      0,      0,      1, 0,
                ]),
                child: cardBody,
              )
            : cardBody,
      ),
    );
  }

  Widget _buildSkillButton({
    required Widget icon,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return GestureDetector(
      onTap: isActive ? onTap : null,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? color.withValues(alpha: 0.15) : Colors.white10,
          border: Border.all(
            color: isActive ? color.withValues(alpha: 0.4) : Colors.white12,
            width: 1.0,
          ),
        ),
        child: icon,
      ),
    );
  }

  Widget _buildStatIndicator({
    required IconData icon,
    required int value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color.withValues(alpha: 0.7),
          size: 10.0,
        ),
        const SizedBox(width: 2.0),
        Text(
          value.toString(),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 9.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// Floating Damage Text effect that moves upwards and fades out
class FloatingDamageText extends StatefulWidget {
  final int damage;
  final bool isLeft;
  final VoidCallback onComplete;

  const FloatingDamageText({
    super.key,
    required this.damage,
    required this.isLeft,
    required this.onComplete,
  });

  @override
  State<FloatingDamageText> createState() => _FloatingDamageTextState();
}

class _FloatingDamageTextState extends State<FloatingDamageText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _yOffset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_controller);

    _yOffset = Tween<double>(begin: 0.0, end: -90.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.damage == 0 ? const Color(0xFF00F0FF) : Colors.redAccent;
    final text = widget.damage == 0 ? 'SHIELDED' : '-${widget.damage} HP';
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: Offset(0, _yOffset.value),
            child: child,
          ),
        );
      },
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 22.0,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.9),
              offset: const Offset(2.0, 2.0),
              blurRadius: 4.0,
            ),
            Shadow(
              color: color.withValues(alpha: 0.8),
              blurRadius: 12.0,
            ),
          ],
        ),
      ),
    );
  }
}

// Combat Effect Widget that renders custom animations on top of the fighter
class CombatEffectOverlay extends StatefulWidget {
  final CombatEffectType type;
  final VoidCallback onComplete;

  const CombatEffectOverlay({
    super.key,
    required this.type,
    required this.onComplete,
  });

  @override
  State<CombatEffectOverlay> createState() => _CombatEffectOverlayState();
}

class _CombatEffectOverlayState extends State<CombatEffectOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 550),
      vsync: this,
    );
    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned.fill(
          child: CustomPaint(
            painter: CombatEffectPainter(
              type: widget.type,
              progress: _controller.value,
            ),
          ),
        );
      },
    );
  }
}

// Custom Painter to draw each of the 5 different combat effects
class CombatEffectPainter extends CustomPainter {
  final CombatEffectType type;
  final double progress;

  CombatEffectPainter({required this.type, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double centerX = w / 2;
    final double centerY = h / 2;
    
    // Opacity fades out towards the end of progress
    final double opacity = progress < 0.65 ? 1.0 : (1.0 - (progress - 0.65) / 0.35);

    switch (type) {
      case CombatEffectType.claw:
        // Claw Slashes: 3 parallel diagonal slashes
        final Paint glowPaint = Paint()
          ..color = Colors.orangeAccent.withOpacity(opacity * 0.5)
          ..strokeWidth = 9.0
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);

        final Paint clawPaint = Paint()
          ..color = Colors.red.withOpacity(opacity)
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

        final double currentProgress = progress.clamp(0.0, 1.0);

        void drawSlash(double startX, double startY, double endX, double endY) {
          final double curEndX = startX + (endX - startX) * currentProgress;
          final double curEndY = startY + (endY - startY) * currentProgress;
          canvas.drawLine(Offset(startX, startY), Offset(curEndX, curEndY), glowPaint);
          canvas.drawLine(Offset(startX, startY), Offset(curEndX, curEndY), clawPaint);
        }

        drawSlash(w * 0.8, h * 0.25, w * 0.2, h * 0.75);
        drawSlash(w * 0.65, h * 0.2, w * 0.1, h * 0.65);
        drawSlash(w * 0.9, h * 0.3, w * 0.35, h * 0.8);
        break;

      case CombatEffectType.slash:
        // Sword/Beam Slash: Glowing cyan diagonal line
        final Paint glowPaint = Paint()
          ..color = const Color(0xFF00F0FF).withOpacity(opacity * 0.65)
          ..strokeWidth = 14.0
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7.0);

        final Paint innerPaint = Paint()
          ..color = Colors.white.withOpacity(opacity)
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

        final double currentProgress = progress.clamp(0.0, 1.0);
        final double startX = w * 0.15;
        final double startY = h * 0.15;
        final double endX = w * 0.85;
        final double endY = h * 0.85;

        final double curEndX = startX + (endX - startX) * currentProgress;
        final double curEndY = startY + (endY - startY) * currentProgress;

        canvas.drawLine(Offset(startX, startY), Offset(curEndX, curEndY), glowPaint);
        canvas.drawLine(Offset(startX, startY), Offset(curEndX, curEndY), innerPaint);
        break;

      case CombatEffectType.fire:
        // Fire Burst: Radial expanding fire/plasma sparks
        final Paint firePaint = Paint()..style = PaintingStyle.fill;
        final double radius = (w * 0.45) * progress;
        
        for (int i = 0; i < 8; i++) {
          final double angle = (i * math.pi / 4);
          final double distance = radius;
          final double sparkX = centerX + math.cos(angle) * distance;
          final double sparkY = centerY + math.sin(angle) * distance;
          
          final double sizeFactor = (1.0 - progress) * 18.0;
          if (sizeFactor > 0) {
            firePaint.color = Colors.redAccent.withOpacity(opacity * 0.45);
            canvas.drawCircle(Offset(sparkX, sparkY), sizeFactor + 4.5, firePaint);
            
            firePaint.color = Colors.orange.withOpacity(opacity);
            canvas.drawCircle(Offset(sparkX, sparkY), sizeFactor, firePaint);
            
            firePaint.color = Colors.yellow.withOpacity(opacity);
            canvas.drawCircle(Offset(sparkX, sparkY), sizeFactor * 0.5, firePaint);
          }
        }
        break;

      case CombatEffectType.lightning:
        // Lightning Bolt: Flickering vertical thunderbolt
        if (progress > 0.8) break;

        final Paint glowPaint = Paint()
          ..color = const Color(0xFF00E5FF).withOpacity(opacity * 0.6)
          ..strokeWidth = 12.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9.0);

        final Paint boltPaint = Paint()
          ..color = Colors.white.withOpacity(opacity)
          ..strokeWidth = 3.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        final int segmentCount = 6;
        final double segmentHeight = h / segmentCount;
        final List<Offset> points = [Offset(centerX, 0)];
        final double randSeed = (progress * 150).toInt().toDouble();
        
        for (int i = 1; i < segmentCount; i++) {
          final double offsetX = math.sin(randSeed + i) * (w * 0.22);
          points.add(Offset(centerX + offsetX, i * segmentHeight));
        }
        points.add(Offset(centerX, h));

        for (int i = 0; i < points.length - 1; i++) {
          canvas.drawLine(points[i], points[i + 1], glowPaint);
          canvas.drawLine(points[i], points[i + 1], boltPaint);
        }
        break;

      case CombatEffectType.bite:
        // Jaw Bite: Metallic jaws clamping shut from top and bottom
        final double biteProgress = progress < 0.4 ? (progress / 0.4) : 1.0;
        final double topJawY = centerY * biteProgress;
        final double bottomJawY = h - (h - centerY) * biteProgress;

        final Paint metalPaint = Paint()
          ..color = Colors.blueGrey.withOpacity(opacity)
          ..style = PaintingStyle.fill;

        final Paint borderPaint = Paint()
          ..color = Colors.redAccent.withOpacity(opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        // Top jaw teeth path
        final Path topPath = Path();
        topPath.moveTo(0, 0);
        topPath.lineTo(w, 0);
        topPath.lineTo(w, topJawY - 18);
        for (int i = 0; i < 4; i++) {
          final double x1 = i * (w / 4);
          final double x2 = (i + 1) * (w / 4);
          final double midX = (x1 + x2) / 2;
          topPath.lineTo(x1, topJawY - 18);
          topPath.lineTo(midX, topJawY + 12);
          topPath.lineTo(x2, topJawY - 18);
        }
        topPath.lineTo(w, 0);
        topPath.close();

        // Bottom jaw teeth path
        final Path bottomPath = Path();
        bottomPath.moveTo(0, h);
        bottomPath.lineTo(w, h);
        bottomPath.lineTo(w, bottomJawY + 18);
        for (int i = 0; i < 4; i++) {
          final double x1 = i * (w / 4);
          final double x2 = (i + 1) * (w / 4);
          final double midX = (x1 + x2) / 2;
          bottomPath.lineTo(x1, bottomJawY + 18);
          bottomPath.lineTo(midX, bottomJawY - 12);
          bottomPath.lineTo(x2, bottomJawY + 18);
        }
        bottomPath.lineTo(w, h);
        bottomPath.close();

        canvas.drawPath(topPath, metalPaint);
        canvas.drawPath(topPath, borderPaint);

        canvas.drawPath(bottomPath, metalPaint);
        canvas.drawPath(bottomPath, borderPaint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
