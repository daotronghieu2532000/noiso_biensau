import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/creature.dart';
import '../models/ocean.dart';

class DataService extends ChangeNotifier {
  List<Creature> _creatures = [];
  List<Ocean> _oceans = [];
  bool _isLoading = true;
  int _highScoreDepth = 0;
  bool _isPremiumUnlocked = false;

  List<Creature> get creatures => _creatures;
  List<Ocean> get oceans => _oceans;
  bool get isLoading => _isLoading;
  int get highScoreDepth => _highScoreDepth;
  bool get isPremiumUnlocked => _isPremiumUnlocked;

  DataService() {
    loadData();
  }

  Future<void> loadData() async {
    try {
      _isLoading = true;
      notifyListeners();

      // 1. Try loading creatures from API first
      try {
        final response = await http
            .get(Uri.parse('https://codego.io.vn/api/get_creatures.php'))
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final List<dynamic> creatureData = json.decode(response.body);
          _creatures = creatureData.map((jsonItem) => Creature.fromJson(jsonItem)).toList();
          if (kDebugMode) {
            print("Successfully loaded ${_creatures.length} creatures from API.");
          }
        } else {
          throw Exception("API returned status code ${response.statusCode}");
        }
      } catch (apiError) {
        if (kDebugMode) {
          print("API load failed, falling back to local asset: $apiError");
        }
        // Fallback to local asset JSON
        final String creatureResponse = await rootBundle.loadString('assets/data/creatures.json');
        final List<dynamic> creatureData = json.decode(creatureResponse);
        _creatures = creatureData.map((jsonItem) => Creature.fromJson(jsonItem)).toList();
      }

      _creatures.sort((a, b) => a.minDepth.compareTo(b.minDepth));

      // Load oceans
      final String oceanResponse = await rootBundle.loadString('assets/data/oceans.json');
      final List<dynamic> oceanData = json.decode(oceanResponse);
      _oceans = oceanData.map((jsonItem) => Ocean.fromJson(jsonItem)).toList();
      
      // Load persistent data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _highScoreDepth = prefs.getInt('high_score_depth') ?? 0;
      _isPremiumUnlocked = prefs.getBool('is_premium_unlocked') ?? false;
      
      for (var creature in _creatures) {
        if (_isPremiumUnlocked) {
          creature.isLocked = false;
        } else {
          final isUnlocked = prefs.getBool('unlocked_${creature.id}');
          if (isUnlocked != null) {
            creature.isLocked = !isUnlocked;
          } else {
            // If not in prefs, initialize prefs based on initial state from json
            if (!creature.isLocked) {
              await prefs.setBool('unlocked_${creature.id}', true);
            }
          }
        }
      }
      
    } catch (e) {
      if (kDebugMode) {
        print("Error loading data: $e");
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get creatures by type ('real' or 'myth')
  List<Creature> getCreaturesByType(String type) {
    return _creatures.where((c) => c.type == type).toList();
  }

  // Unlock a creature permanently
  Future<void> unlockCreature(String id) async {
    final index = _creatures.indexWhere((c) => c.id == id);
    if (index != -1) {
      _creatures[index].isLocked = false;
      notifyListeners();
      
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('unlocked_$id', true);
      } catch (e) {
        if (kDebugMode) {
          print("Error saving unlock state: $e");
        }
      }
    }
  }

  // Update high score lặn sinh tồn
  Future<void> updateHighScoreDepth(int depth) async {
    if (depth > _highScoreDepth) {
      _highScoreDepth = depth;
      notifyListeners();
      
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('high_score_depth', depth);
      } catch (e) {
        if (kDebugMode) {
          print("Error saving high score depth: $e");
        }
      }
    }
  }

  // Unlock lifetime premium package
  Future<void> unlockPremium() async {
    _isPremiumUnlocked = true;
    for (var creature in _creatures) {
      creature.isLocked = false;
    }
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_premium_unlocked', true);
      
      // Save unlock state for all creatures to SharedPreferences too
      for (var creature in _creatures) {
        await prefs.setBool('unlocked_${creature.id}', true);
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error saving premium unlock: $e");
      }
    }
  }
}
