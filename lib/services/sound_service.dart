import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundService extends ChangeNotifier {
  late final AudioPlayer _ambientPlayer;
  late final AudioPlayer _secondaryAmbientPlayer;
  late final AudioPlayer _creaturePlayer;

  bool _isMuted = false;
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
  }

  // Toggles the global mute state
  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    if (_isMuted) {
      await _ambientPlayer.setVolume(0.0);
      await _secondaryAmbientPlayer.setVolume(0.0);
      await _creaturePlayer.setVolume(0.0);
    } else {
      await _ambientPlayer.setVolume(0.5);
      await _secondaryAmbientPlayer.setVolume(0.5);
      await _creaturePlayer.setVolume(0.8);
    }
    notifyListeners();
  }

  // Plays deep ocean ambient sound
  Future<void> playAmbient(String soundFileName) async {
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
    } catch (e) {
      if (kDebugMode) {
        print("Ambient audio playback failed (sound file 'assets/sounds/$soundFileName' might be missing): $e");
      }
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
    } catch (e) {
      if (kDebugMode) {
        print("Error stopping ambient: $e");
      }
    }
    notifyListeners();
  }

  // Plays secondary looping ambient track (e.g. sonar echo combined with deep hum)
  Future<void> playSecondaryAmbient(String soundFileName) async {
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
    } catch (e) {
      if (kDebugMode) {
        print("Secondary ambient audio playback failed (sound file 'assets/sounds/$soundFileName' might be missing): $e");
      }
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
    } catch (e) {
      if (kDebugMode) {
        print("Error stopping secondary ambient: $e");
      }
    }
    notifyListeners();
  }

  // Plays a specific creature sound effect
  Future<void> playCreatureSound(String soundFileName) async {
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
    } catch (e) {
      if (kDebugMode) {
        print("Creature audio playback failed (sound file '$soundFileName' might be missing or unreachable): $e");
      }
    }
  }

  Future<void> stopCreatureSound() async {
    try {
      await _creaturePlayer.stop();
    } catch (e) {
      if (kDebugMode) {
        print("Error stopping creature sound: $e");
      }
    }
  }

  @override
  void dispose() {
    _ambientPlayer.dispose();
    _secondaryAmbientPlayer.dispose();
    _creaturePlayer.dispose();
    super.dispose();
  }
}
