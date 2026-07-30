import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import '../models/creature.dart';
import '../models/ocean.dart';
import '../models/battle_video.dart';

class DataService extends ChangeNotifier {
  List<Creature> _creatures = [];
  List<Ocean> _oceans = [];
  List<BattleVideo> _videos = [];
  bool _isLoading = true;
  int _highScoreDepth = 0;
  bool _isPremiumUnlocked = false;

  static const String premiumProductId = 'vn.io.codego.noisobiensau.premium_lifetime';
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isPurchaseLoading = false;

  List<Creature> get creatures => _creatures;
  List<Ocean> get oceans => _oceans;
  List<BattleVideo> get videos => _videos;
  bool get isLoading => _isLoading;
  int get highScoreDepth => _highScoreDepth;
  bool get isPremiumUnlocked => _isPremiumUnlocked;
  bool get isPurchaseLoading => _isPurchaseLoading;

  DataService() {
    loadData();
    _initializeIap();
  }

  void _initializeIap() {
    final Stream<List<PurchaseDetails>> purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _listenToPurchaseUpdated,
      onDone: () => _subscription?.cancel(),
      onError: (error) {
        if (kDebugMode) {
          print("IAP Stream Error: $error");
        }
        _isPurchaseLoading = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        _isPurchaseLoading = true;
        notifyListeners();
      } else {
        if (purchaseDetails.status == PurchaseStatus.error ||
            purchaseDetails.status == PurchaseStatus.canceled) {
          _isPurchaseLoading = false;
          notifyListeners();
          if (kDebugMode) {
            print("Purchase failed or canceled: ${purchaseDetails.error}");
          }
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          await unlockPremium();
          _isPremiumUnlocked = true;
          _isPurchaseLoading = false;
          notifyListeners();
        }
        
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  Future<void> buyPremium() async {
    try {
      final bool isAvailable = await _inAppPurchase.isAvailable();
      if (!isAvailable) {
        if (kDebugMode) {
          print("Store is not available");
        }
        return;
      }

      _isPurchaseLoading = true;
      notifyListeners();

      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails({premiumProductId});
      if (response.notFoundIDs.contains(premiumProductId) || response.productDetails.isEmpty) {
        if (kDebugMode) {
          print("Product ID not found in store: $premiumProductId");
        }
        _isPurchaseLoading = false;
        notifyListeners();
        return;
      }

      final ProductDetails productDetails = response.productDetails.first;
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      if (kDebugMode) {
        print("Error launching purchase: $e");
      }
      _isPurchaseLoading = false;
      notifyListeners();
    }
  }

  Future<void> restorePurchases() async {
    try {
      _isPurchaseLoading = true;
      notifyListeners();
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      if (kDebugMode) {
        print("Error restoring purchases: $e");
      }
      _isPurchaseLoading = false;
      notifyListeners();
    }
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

      // Load videos from API (with local fallback)
      try {
        final response = await http
            .get(Uri.parse('https://codego.io.vn/api/get_videos.php'))
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final List<dynamic> videoData = json.decode(response.body);
          _videos = videoData.map((jsonItem) => BattleVideo.fromJson(jsonItem)).toList();
          if (kDebugMode) {
            print("Successfully loaded ${_videos.length} videos from API.");
          }
        } else {
          throw Exception("API returned status code ${response.statusCode}");
        }
      } catch (apiError) {
        if (kDebugMode) {
          print("API load failed for videos, falling back to local asset: $apiError");
        }
        // Fallback to local asset JSON
        final String videoResponse = await rootBundle.loadString('assets/data/videos.json');
        final List<dynamic> videoData = json.decode(videoResponse);
        _videos = videoData.map((jsonItem) => BattleVideo.fromJson(jsonItem)).toList();
      }
      
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
