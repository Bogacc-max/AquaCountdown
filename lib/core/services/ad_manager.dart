import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdManager {
  static AdManager? _instance;
  static AdManager get instance => _instance ??= AdManager._();
  AdManager._();

  static const _bannerTestId = 'ca-app-pub-3940256099942544/6300978111';
  static const _interstitialTestId = 'ca-app-pub-3940256099942544/1033173712';

  InterstitialAd? _interstitialAd;
  int _waterAddCount = 0;
  int _interstitialsShownToday = 0;
  DateTime _lastAdDate = DateTime(2000);
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      _loadInterstitial();
    } catch (e) {
      debugPrint('AdManager init failed: $e');
    }
  }

  BannerAd createBannerAd({BannerAdListener? listener}) {
    return BannerAd(
      adUnitId: _bannerTestId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: listener ?? BannerAdListener(
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    )..load();
  }

  void onWaterAdded() {
    if (!_initialized) return;
    _resetDailyCounterIfNeeded();
    _waterAddCount++;
    if (_waterAddCount % 5 == 0 && _interstitialsShownToday < 2) {
      _showInterstitial();
    }
  }

  void _showInterstitial() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null;
      _interstitialsShownToday++;
      _loadInterstitial();
    }
  }

  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: _interstitialTestId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) => ad.dispose(),
            onAdFailedToShowFullScreenContent: (ad, error) => ad.dispose(),
          );
        },
        onAdFailedToLoad: (_) {},
      ),
    );
  }

  void _resetDailyCounterIfNeeded() {
    final today = DateTime.now();
    if (today.day != _lastAdDate.day ||
        today.month != _lastAdDate.month ||
        today.year != _lastAdDate.year) {
      _interstitialsShownToday = 0;
      _waterAddCount = 0;
      _lastAdDate = today;
    }
  }
}
