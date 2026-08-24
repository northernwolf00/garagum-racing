import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'purchase_service.dart';

/// Wraps AdMob (google_mobile_ads): banner, interstitial and rewarded ads.
///
/// Same singleton shape as [PurchaseService] / `GameProgressService`: private
/// constructor, static [instance], [init] awaited once from `main()`.
///
/// Ad policy (from the monetisation design):
/// - Rewarded  — always available, even for paying users. Opt-in only.
/// - Interstitial — only after a run's result overlay is dismissed, never
///   during the first [_interstitialGracePeriod] runs, then every
///   [_interstitialEveryNRuns]th run. Suppressed when [PurchaseService.noAds].
/// - Banner   — menu + garage screens only. Suppressed when noAds.
///
/// All ad unit ids below are Google's official **test** ids. Swap them for
/// the real ids from the AdMob console before release.
class AdService {
  static AdService? _instance;
  static AdService get instance {
    _instance ??= AdService._();
    return _instance!;
  }

  AdService._();

  // ── Test ad unit ids (replace before release) ─────────────────────────────
  static String get bannerUnitId => Platform.isIOS
      ? 'ca-app-pub-3940256099942544/2934735716'
      : 'ca-app-pub-3940256099942544/6300978111';

  static String get _interstitialUnitId => Platform.isIOS
      ? 'ca-app-pub-3940256099942544/4411468910'
      : 'ca-app-pub-3940256099942544/1033173712';

  static String get _rewardedUnitId => Platform.isIOS
      ? 'ca-app-pub-3940256099942544/1712485313'
      : 'ca-app-pub-3940256099942544/5224354917';

  // ── Interstitial cadence ──────────────────────────────────────────────────
  static const int _interstitialGracePeriod = 5; // no ads for first N runs
  static const int _interstitialEveryNRuns = 3; // then every Nth run
  static const String _keyRunCount = 'ad_run_count';

  bool _initialized = false;
  SharedPreferences? _prefs;

  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  bool _loadingInterstitial = false;
  bool _loadingRewarded = false;

  bool get _adsSuppressed => PurchaseService.instance.noAds;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    _prefs = await SharedPreferences.getInstance();
    try {
      await MobileAds.instance.initialize();
    } catch (e) {
      debugPrint('[ads] initialize failed: $e');
      return;
    }
    // Preload the on-demand formats so they're ready at the result overlay.
    _loadInterstitial();
    _loadRewarded();
  }

  // ── Interstitial ───────────────────────────────────────────────────────────

  void _loadInterstitial() {
    if (_loadingInterstitial || _interstitial != null) return;
    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: _interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _loadingInterstitial = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('[ads] interstitial load failed: $error');
          _interstitial = null;
          _loadingInterstitial = false;
        },
      ),
    );
  }

  /// Records a finished run and, subject to the grace period / cadence and the
  /// no-ads entitlement, shows an interstitial. Call this when the player
  /// leaves a result overlay (menu / levels), never mid-game.
  Future<void> maybeShowInterstitialAfterRun() async {
    final runCount = (_prefs?.getInt(_keyRunCount) ?? 0) + 1;
    await _prefs?.setInt(_keyRunCount, runCount);

    if (_adsSuppressed) return;
    if (runCount <= _interstitialGracePeriod) return;
    if ((runCount - _interstitialGracePeriod) % _interstitialEveryNRuns != 0) {
      return;
    }

    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadInterstitial();
      },
    );
    await ad.show();
  }

  // ── Rewarded ────────────────────────────────────────────────────────────────

  void _loadRewarded() {
    if (_loadingRewarded || _rewarded != null) return;
    _loadingRewarded = true;
    RewardedAd.load(
      adUnitId: _rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          _loadingRewarded = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('[ads] rewarded load failed: $error');
          _rewarded = null;
          _loadingRewarded = false;
        },
      ),
    );
  }

  /// True if a rewarded ad is loaded and ready to show right now.
  bool get isRewardedReady => _rewarded != null;

  /// Shows a rewarded ad. [onReward] fires only if the user earns the reward
  /// (watches long enough). Returns true if an ad was actually shown.
  /// Rewarded ads are available even to no-ads / VIP users — they're opt-in.
  Future<bool> showRewarded({required VoidCallback onReward}) async {
    final ad = _rewarded;
    if (ad == null) {
      _loadRewarded();
      return false;
    }
    _rewarded = null;
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewarded();
        if (earned) onReward();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadRewarded();
      },
    );
    await ad.show(
      onUserEarnedReward: (ad, reward) => earned = true,
    );
    return true;
  }

  /// Builds a fresh banner ad for the menu / garage screens. Returns null when
  /// ads are suppressed (no-ads / VIP). The caller owns disposing the ad.
  BannerAd? createBanner({VoidCallback? onLoaded}) {
    if (_adsSuppressed) return null;
    final banner = BannerAd(
      adUnitId: bannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => onLoaded?.call(),
        onAdFailedToLoad: (ad, error) {
          debugPrint('[ads] banner load failed: $error');
          ad.dispose();
        },
      ),
    );
    banner.load();
    return banner;
  }
}
