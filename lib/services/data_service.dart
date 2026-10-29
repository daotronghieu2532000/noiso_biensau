import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import '../models/creature.dart';
import '../models/ocean.dart';
import '../models/battle_video.dart';
import '../models/sailor_story.dart';

class DataService extends ChangeNotifier {
  List<Creature> _creatures = [];
  List<Ocean> _oceans = [];
  List<BattleVideo> _videos = [];
  List<SailorStory> _stories = [];
  bool _isLoading = true;
  int _highScoreDepth = 0;
  bool _isPremiumUnlocked = false;
  bool _isPremiumMonthly = false; // gói hàng tháng

  // Product IDs
  static const String premiumProductId =
      'vn.io.codego.noisobiensau.premium_lifetimem';

  // Trên Android Play Console là premium_month, trên iOS là premium_monthly
  static String get monthlyProductId => Platform.isAndroid
      ? 'vn.io.codego.noisobiensau.premium_month'
      : 'vn.io.codego.noisobiensau.premium_monthly';

  static Set<String> get allProductIds => {
        premiumProductId,
        'vn.io.codego.noisobiensau.premium_month',
        'vn.io.codego.noisobiensau.premium_monthly',
      };

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isPurchaseLoading = false;

  // Cache ProductDetails fetched from Store
  ProductDetails? _lifetimeProduct;
  ProductDetails? _monthlyProduct;

  ProductDetails? get lifetimeProduct => _lifetimeProduct;
  ProductDetails? get monthlyProduct => _monthlyProduct;

  String get lifetimePriceText => _lifetimeProduct?.price ?? r'$3.99';
  String get monthlyPriceText => _monthlyProduct?.price ?? r'$0.99';

  List<Creature> get creatures => _creatures;
  List<Ocean> get oceans => _oceans;
  List<BattleVideo> get videos => _videos;
  List<SailorStory> get stories => _stories;
  bool get isLoading => _isLoading;
  int get highScoreDepth => _highScoreDepth;
  bool get isPremiumUnlocked => _isPremiumUnlocked;
  bool get isPremiumMonthly => _isPremiumMonthly;
  // Cả 2 gói đều có quyền lợi VIP như nhau
  bool get hasAnyPremium => _isPremiumUnlocked || _isPremiumMonthly;
  bool get isPurchaseLoading => _isPurchaseLoading;

  DataService() {
    loadData();
    _initializeIap();
  }

  void _initializeIap() {
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _listenToPurchaseUpdated,
      onDone: () => _subscription?.cancel(),
      onError: (error) {
        _isPurchaseLoading = false;
        notifyListeners();
      },
    );
    // Tự động fetch giá sản phẩm từ Google Play / App Store ngay khi mở app
    fetchProducts();
  }

  /// Tải thông tin sản phẩm và giá động từ Google Play / App Store
  Future<void> fetchProducts() async {
    try {
      final bool isAvailable = await _inAppPurchase.isAvailable();
      if (!isAvailable) return;

      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails(allProductIds);

      for (final product in response.productDetails) {
        if (product.id == premiumProductId) {
          _lifetimeProduct = product;
        } else if (product.id == monthlyProductId ||
            product.id == 'vn.io.codego.noisobiensau.premium_month' ||
            product.id == 'vn.io.codego.noisobiensau.premium_monthly') {
          _monthlyProduct = product;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching product details: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _listenToPurchaseUpdated(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        _isPurchaseLoading = true;
        notifyListeners();
      } else {
        if (purchaseDetails.status == PurchaseStatus.error ||
            purchaseDetails.status == PurchaseStatus.canceled) {
          _isPurchaseLoading = false;
          notifyListeners();
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          // Kiểm tra loại gói để xác định đây là lifetime hay monthly
          final productId = purchaseDetails.productID;
          if (productId == monthlyProductId ||
              productId == 'vn.io.codego.noisobiensau.premium_month' ||
              productId == 'vn.io.codego.noisobiensau.premium_monthly') {
            await unlockMonthlyPremium();
          } else {
            // lifetime hoặc bất kỳ gói nào khác
            await unlockPremium();
          }
          _isPurchaseLoading = false;
          notifyListeners();
        }

        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  /// Mua gói Trọn đời (Non-consumable)
  Future<String?> buyPremium() async {
    try {
      final bool isAvailable = await _inAppPurchase.isAvailable();
      if (!isAvailable) {
        return 'Cửa hàng thanh toán hiện không khả dụng trên thiết bị này.';
      }

      _isPurchaseLoading = true;
      notifyListeners();

      ProductDetails? product = _lifetimeProduct;
      if (product == null) {
        final ProductDetailsResponse response =
            await _inAppPurchase.queryProductDetails({premiumProductId});
        if (response.productDetails.isNotEmpty) {
          product = response.productDetails.first;
          _lifetimeProduct = product;
        }
      }

      if (product == null) {
        _isPurchaseLoading = false;
        notifyListeners();
        return 'Không thể kết nối thông tin gói từ cửa hàng. Vui lòng thử lại sau.';
      }

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      return null;
    } catch (e) {
      _isPurchaseLoading = false;
      notifyListeners();
      return 'Lỗi xử lý thanh toán: $e';
    }
  }

  /// Mua gói Hàng tháng (Auto-renewable subscription)
  Future<String?> buyMonthly() async {
    try {
      final bool isAvailable = await _inAppPurchase.isAvailable();
      if (!isAvailable) {
        return 'Cửa hàng thanh toán hiện không khả dụng trên thiết bị này.';
      }

      _isPurchaseLoading = true;
      notifyListeners();

      ProductDetails? product = _monthlyProduct;
      if (product == null) {
        final ProductDetailsResponse response =
            await _inAppPurchase.queryProductDetails({
          monthlyProductId,
          'vn.io.codego.noisobiensau.premium_month',
          'vn.io.codego.noisobiensau.premium_monthly',
        });
        if (response.productDetails.isNotEmpty) {
          product = response.productDetails.first;
          _monthlyProduct = product;
        }
      }

      if (product == null) {
        _isPurchaseLoading = false;
        notifyListeners();
        return 'Không thể kết nối thông tin gói thuê bao từ cửa hàng. Vui lòng thử lại sau.';
      }

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );
      // Subscription dùng buyNonConsumable cho iOS & Android
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      return null;
    } catch (e) {
      _isPurchaseLoading = false;
      notifyListeners();
      return 'Lỗi xử lý thanh toán: $e';
    }
  }

  Future<String?> restorePurchases() async {
    try {
      final bool isAvailable = await _inAppPurchase.isAvailable();
      if (!isAvailable) {
        return 'Cửa hàng thanh toán hiện không khả dụng.';
      }
      _isPurchaseLoading = true;
      notifyListeners();
      await _inAppPurchase.restorePurchases();
      return null;
    } catch (e) {
      return 'Không thể khôi phục giao dịch: $e';
    } finally {
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
          _creatures = creatureData
              .map((jsonItem) => Creature.fromJson(jsonItem))
              .toList();
        } else {
          throw Exception("API returned status code ${response.statusCode}");
        }
      } catch (apiError) {
        // Fallback to local asset JSON
        final String creatureResponse = await rootBundle.loadString(
          'assets/data/creatures.json',
        );
        final List<dynamic> creatureData = json.decode(creatureResponse);
        _creatures = creatureData
            .map((jsonItem) => Creature.fromJson(jsonItem))
            .toList();
      }

      // Chuẩn hoá và sắp xếp mốc độ sâu, tự động chống trùng lặp
      _normalizeAndSortCreatures();

      // Load oceans
      final String oceanResponse = await rootBundle.loadString(
        'assets/data/oceans.json',
      );
      final List<dynamic> oceanData = json.decode(oceanResponse);
      _oceans = oceanData.map((jsonItem) => Ocean.fromJson(jsonItem)).toList();

      // Load videos from API (with local fallback)
      try {
        final response = await http
            .get(Uri.parse('https://codego.io.vn/api/get_videos.php'))
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final List<dynamic> videoData = json.decode(response.body);
          _videos = videoData
              .map((jsonItem) => BattleVideo.fromJson(jsonItem))
              .toList();
        } else {
          throw Exception("API returned status code ${response.statusCode}");
        }
      } catch (apiError) {
        // Fallback to local asset JSON
        final String videoResponse = await rootBundle.loadString(
          'assets/data/videos.json',
        );
        final List<dynamic> videoData = json.decode(videoResponse);
        _videos = videoData
            .map((jsonItem) => BattleVideo.fromJson(jsonItem))
            .toList();
      }

      // Load stories from API (with local fallback)
      try {
        final response = await http
            .get(Uri.parse('https://codego.io.vn/api/get_stories.php'))
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200 && response.body.trim().isNotEmpty) {
          final dynamic decoded = json.decode(response.body);
          if (decoded is List) {
            _stories = decoded
                .map((jsonItem) => SailorStory.fromJson(jsonItem))
                .toList();
          } else {
            throw Exception("API response is not a JSON list");
          }
        } else {
          throw Exception("API returned status code ${response.statusCode} or empty body");
        }
      } catch (apiError) {
        // Fallback to local asset JSON
        final String storyResponse = await rootBundle.loadString(
          'assets/data/stories.json',
        );
        final List<dynamic> storyData = json.decode(storyResponse);
        _stories = storyData
            .map((jsonItem) => SailorStory.fromJson(jsonItem))
            .toList();
      }

      // Load persistent data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _highScoreDepth = prefs.getInt('high_score_depth') ?? 0;
      _isPremiumUnlocked = prefs.getBool('is_premium_unlocked') ?? false;
      _isPremiumMonthly = prefs.getBool('is_premium_monthly') ?? false;

      for (var creature in _creatures) {
        if (_isPremiumUnlocked || _isPremiumMonthly) {
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
    } catch (_) {
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
      } catch (_) {
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
      } catch (_) {
      }
    }
  }

  /// Mở khóa gói Trọn đời (lưu vĩnh viễn)
  Future<void> unlockPremium() async {
    _isPremiumUnlocked = true;
    _isPremiumMonthly = false; // lifetime bao gồm cả monthly
    for (var creature in _creatures) {
      creature.isLocked = false;
    }
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_premium_unlocked', true);
      await prefs.setBool('is_premium_monthly', false);
      for (var creature in _creatures) {
        await prefs.setBool('unlocked_${creature.id}', true);
      }
    } catch (_) {
    }
  }

  /// Mở khóa gói Hàng tháng (lưu tạm, có thể hết hạn)
  Future<void> unlockMonthlyPremium() async {
    _isPremiumMonthly = true;
    for (var creature in _creatures) {
      creature.isLocked = false;
    }
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_premium_monthly', true);
      for (var creature in _creatures) {
        await prefs.setBool('unlocked_${creature.id}', true);
      }
    } catch (_) {
    }
  }

  /// Huỷ gói monthly (khi subscription hết hạn hoặc bị huỷ)
  Future<void> revokeMonthlyPremium() async {
    _isPremiumMonthly = false;
    // Chỉ revoke quái thú nếu không có lifetime
    if (!_isPremiumUnlocked) {
      for (var creature in _creatures) {
        if (creature.type == 'myth') creature.isLocked = true;
      }
    }
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_premium_monthly', false);
    } catch (_) {
    }
  }

  /// Bảng độ sâu chuẩn hóa khuyến nghị cho 24 sinh vật hiện tại
  static const Map<String, (int, int)> _knownStandardDepths = {
    'clownfish': (0, 50),
    'humpback_whale': (15, 500),
    'great_white_shark': (35, 1200),
    'orca': (60, 1000),
    'blue_whale': (100, 500),
    'megalodon': (150, 1500),
    'lagiacrus': (200, 1200),
    'giant_isopod': (300, 2140),
    'oarfish': (450, 1000),
    'reaper_leviathan': (600, 1500),
    'sperm_whale': (750, 3000),
    'giant_squid': (900, 1500),
    'vampire_squid': (1000, 1800),
    'anglerfish': (1400, 4000),
    'black_dragonfish': (1800, 3000),
    'greenland_shark': (2200, 3200),
    'ghost_leviathan': (2800, 8000),
    'kraken': (3500, 6000),
    'godzilla': (4200, 9000),
    'sea_serpent': (5000, 8000),
    'the_bloop': (5800, 9000),
    'jormungandr': (7000, 10500),
    'leviathan': (9000, 11000),
    'cthulhu': (11000, 11000),
  };

  /// Chuẩn hoá mốc độ sâu và tự động phân giải trùng mốc (Anti-collision Depth Progression)
  void _normalizeAndSortCreatures() {
    if (_creatures.isEmpty) return;

    // 1. Áp dụng chuẩn hoá mốc cho các loài đã biết (nếu API cũ chưa cập nhật hoặc bị gán nhầm 0m)
    for (int i = 0; i < _creatures.length; i++) {
      final c = _creatures[i];
      if (_knownStandardDepths.containsKey(c.id)) {
        final std = _knownStandardDepths[c.id]!;
        if (c.minDepth != std.$1) {
          _creatures[i] = c.copyWith(
            minDepth: std.$1,
            maxDepth: std.$2,
          );
        }
      }
    }

    // 2. Sắp xếp thứ tự ưu tiên: minDepth -> maxDepth -> id
    _creatures.sort((a, b) {
      int cmp = a.minDepth.compareTo(b.minDepth);
      if (cmp != 0) return cmp;
      int cmpMax = a.maxDepth.compareTo(b.maxDepth);
      if (cmpMax != 0) return cmpMax;
      return a.id.compareTo(b.id);
    });

    // 3. Cơ chế tự động giãn cách mốc (Anti-Collision Staggering):
    // Đảm bảo khi lặn xuống biển, mỗi sinh vật luôn có mốc tăng dần nghiêm ngặt (Strictly Increasing)
    int lastDepth = -1;
    for (int i = 0; i < _creatures.length; i++) {
      var c = _creatures[i];
      if (c.minDepth <= lastDepth) {
        // Tự động phân bổ bước nhảy phù hợp theo từng đới biển
        int step = 20;
        if (lastDepth >= 200 && lastDepth < 1000) {
          step = 50;
        } else if (lastDepth >= 1000 && lastDepth < 4000) {
          step = 100;
        } else if (lastDepth >= 4000) {
          step = 200;
        }

        int nextDepth = lastDepth + step;
        if (nextDepth > 11000) nextDepth = 11000;

        _creatures[i] = c.copyWith(
          minDepth: nextDepth,
          maxDepth: c.maxDepth < nextDepth ? nextDepth + 500 : c.maxDepth,
        );
      }
      lastDepth = _creatures[i].minDepth;
    }
  }
}
