import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundService extends ChangeNotifier {
  static const String _muteKey = 'sound_is_muted';

  late final AudioPlayer _ambientPlayer;
  late final AudioPlayer _secondaryAmbientPlayer;
  late final AudioPlayer _creaturePlayer;
  final List<AudioPlayer> _pageFlipPool = [];
  int _pageFlipPoolIndex = 0;

  bool _isMuted = false;
  Future<void>? _initFuture;
  bool _isAmbientPlaying = false;
  bool _isSecondaryAmbientPlaying = false;
  String? _currentAmbientSound;
  String? _currentSecondaryAmbientSound;

  bool get isMuted => _isMuted;
  bool get isAmbientPlaying => _isAmbientPlaying;
  bool get isSecondaryAmbientPlaying => _isSecondaryAmbientPlaying;

  SoundService() {
    _ambientPlayer = AudioPlayer();
    _secondaryAmbientPlayer = AudioPlayer();
    _creaturePlayer = AudioPlayer();
    
    // Set ambient players to loop
    _ambientPlayer.setReleaseMode(ReleaseMode.loop);
    _secondaryAmbientPlayer.setReleaseMode(ReleaseMode.loop);

    // Audio pool cho lật trang liên tục không bị ngắt
    for (int i = 0; i < 3; i++) {
      final p = AudioPlayer();
      p.setReleaseMode(ReleaseMode.stop);
      p.setPlayerMode(PlayerMode.lowLatency);
      p.setVolume(0.85);
      _pageFlipPool.add(p);
    }

    _initFuture = _loadMuteState();
  }

  // Đọc trạng thái tắt/bật âm thanh đã lưu từ lần mở app trước
  Future<void> _loadMuteState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isMuted = prefs.getBool(_muteKey) ?? false;
      await _applyVolumeState();
      notifyListeners();
    } catch (_) {
    }
  }

  Future<void> _applyVolumeState() async {
    if (_isMuted) {
      await _ambientPlayer.setVolume(0.0);
      await _secondaryAmbientPlayer.setVolume(0.0);
      await _creaturePlayer.setVolume(0.0);
    } else {
      await _ambientPlayer.setVolume(0.5);
      await _secondaryAmbientPlayer.setVolume(0.5);
      await _creaturePlayer.setVolume(0.8);
    }
  }

  // Toggles the global mute state and saves it to SharedPreferences
  Future<void> toggleMute() async {
    await _initFuture;
    _isMuted = !_isMuted;
    await _applyVolumeState();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_muteKey, _isMuted);
    } catch (_) {
    }
  }

  // Plays deep ocean ambient sound
  Future<void> playAmbient(String soundFileName) async {
    await _initFuture;
    if (_currentAmbientSound == soundFileName && _isAmbientPlaying) return;
    
    _currentAmbientSound = soundFileName;
    
    if (_isMuted) {
      await _ambientPlayer.setVolume(0.0);
    } else {
      await _ambientPlayer.setVolume(0.5); // moderate ambient volume
    }

    try {
      // In Flutter, audioplayers AssetSource points to files inside the 'assets' directory.
      // So 'sounds/shallow_water.mp3' refers to 'assets/sounds/shallow_water.mp3'.
      await _ambientPlayer.stop();
      await _ambientPlayer.play(AssetSource('sounds/$soundFileName'));
      _isAmbientPlaying = true;
    } catch (_) {
      _isAmbientPlaying = false;
    }
    notifyListeners();
  }

  Future<void> stopAmbient() async {
    if (!_isAmbientPlaying && _currentAmbientSound == null) return;
    _currentAmbientSound = null;
    _isAmbientPlaying = false;
    try {
      await _ambientPlayer.stop();
    } catch (_) {
    }
    notifyListeners();
  }

  // Plays secondary looping ambient track (e.g. sonar echo combined with deep hum)
  Future<void> playSecondaryAmbient(String soundFileName) async {
    await _initFuture;
    if (_currentSecondaryAmbientSound == soundFileName && _isSecondaryAmbientPlaying) return;
    
    _currentSecondaryAmbientSound = soundFileName;
    
    if (_isMuted) {
      await _secondaryAmbientPlayer.setVolume(0.0);
    } else {
      await _secondaryAmbientPlayer.setVolume(0.5);
    }

    try {
      await _secondaryAmbientPlayer.stop();
      await _secondaryAmbientPlayer.play(AssetSource('sounds/$soundFileName'));
      _isSecondaryAmbientPlaying = true;
    } catch (_) {
      _isSecondaryAmbientPlaying = false;
    }
    notifyListeners();
  }

  Future<void> stopSecondaryAmbient() async {
    if (!_isSecondaryAmbientPlaying && _currentSecondaryAmbientSound == null) return;
    _currentSecondaryAmbientSound = null;
    _isSecondaryAmbientPlaying = false;
    try {
      await _secondaryAmbientPlayer.stop();
    } catch (_) {
    }
    notifyListeners();
  }

  // Plays a specific creature sound effect
  Future<void> playCreatureSound(String soundFileName) async {
    await _initFuture;
    if (_isMuted) return;
    if (soundFileName.isEmpty) return;

    try {
      await _creaturePlayer.stop();
      await _creaturePlayer.setVolume(0.8);
      if (soundFileName.startsWith('http://') || soundFileName.startsWith('https://')) {
        await _creaturePlayer.play(UrlSource(soundFileName));
      } else {
        await _creaturePlayer.play(AssetSource('sounds/$soundFileName'));
      }
    } catch (_) {
    }
  }

  Future<void> stopCreatureSound() async {
    try {
      await _creaturePlayer.stop();
    } catch (_) {
    }
  }

  // Âm thanh lật trang sách cổ chân thực
  Future<void> playPageFlipSound() async {
    await _initFuture;
    if (_isMuted || _pageFlipPool.isEmpty) return;
    try {
      final player = _pageFlipPool[_pageFlipPoolIndex];
      _pageFlipPoolIndex = (_pageFlipPoolIndex + 1) % _pageFlipPool.length;
      player.stop();
      await player.play(
        AssetSource('sounds/page_flip.mp3'),
        mode: PlayerMode.lowLatency,
      );
    } catch (_) {
    }
  }

  @override
  void dispose() {
    _ambientPlayer.dispose();
    _secondaryAmbientPlayer.dispose();
    _creaturePlayer.dispose();
    for (final p in _pageFlipPool) {
      p.stop();
      p.dispose();
    }
    _pageFlipPool.clear();
    super.dispose();
  }
}
