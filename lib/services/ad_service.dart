import 'dart:async';
import 'package:flutter/foundation.dart';

class AdService extends ChangeNotifier {
  bool get areAdsDisabled => true;
  DateTime? get adsDisabledUntil => null;
  bool get isRewardedAdLoading => false;
  bool get showBannerAd => false;
  bool get isInitialized => true;

  String get bannerAdUnitId => '';
  String get interstitialAdUnitId => '';
  String get nativeAdUnitId => '';
  String get rewardedAdUnitId => '';
  String get remainingAdFreeTime => '';

  Future<void> initAdService() async {}
  void enableBannerDisplay() {}
  Future<void> disableAdsFor(Duration duration) async {}
  void loadInterstitialAd() {}
  
  void showInterstitialAd({
    VoidCallback? onComplete,
    bool ignoreCooldown = false,
  }) {
    onComplete?.call();
  }

  void showRewardedAd(
    Duration duration, {
    required VoidCallback onSuccess,
    required VoidCallback onFailure,
  }) {
    onSuccess();
  }
}
