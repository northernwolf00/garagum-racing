import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game_progress_service.dart';
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
/// The ad unit ids below are the app's **production** AdMob ids. While
/// developing, add your device to [RequestConfiguration.testDeviceIds] (in
/// [init]) so you only ever see Google test ads — clicking live ads on your
/// own device can get the AdMob account suspended.
class AdService {
  static AdService? _instance;
  static AdService get instance {
    _instance ??= AdService._();
    return _instance!;
  }

  AdService._();

  // Debug builds always use Google's official **test** ad units — they serve
  // immediately regardless of AdMob account/app approval status and never risk
  // an invalid-traffic strike. Release builds use the app's real console ids.
  static bool get _useTestAds => kDebugMode;

  static String get bannerUnitId => _useTestAds
      ? (Platform.isIOS
            ? 'ca-app-pub-3940256099942544/2934735716'
            : 'ca-app-pub-3940256099942544/6300978111')
      : (Platform.isIOS
            ? 'ca-app-pub-9512095597042833/8075871458'
            : 'ca-app-pub-9512095597042833/9878134214');

  static String get _interstitialUnitId => _useTestAds
      ? (Platform.isIOS
            ? 'ca-app-pub-3940256099942544/4411468910'
            : 'ca-app-pub-3940256099942544/1033173712')
      : (Platform.isIOS
            ? 'ca-app-pub-9512095597042833/1640551547'
            : 'ca-app-pub-9512095597042833/4006483132');

  static String get _rewardedUnitId => _useTestAds
      ? (Platform.isIOS
            ? 'ca-app-pub-3940256099942544/1712485313'
            : 'ca-app-pub-3940256099942544/5224354917')
      : (Platform.isIOS
            ? 'ca-app-pub-9512095597042833/9111847457'
            : 'ca-app-pub-9512095597042833/3206688158');

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

  /// The run count for which an interstitial has already been shown, so
  /// leaving via two different buttons in one run can't show two ads.
  int _lastInterstitialRun = -1;

  bool get _adsSuppressed =>
      PurchaseService.instance.noAds ||
      GameProgressService.instance.starterNoAdsActive;

  /// True while a bottom banner is actually on screen. Screens listen to this
  /// to reserve matching bottom padding so their buttons stay above the banner
  /// instead of being covered by it.
  final ValueNotifier<bool> bannerVisible = ValueNotifier(false);

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    _prefs = await SharedPreferences.getInstance();
    try {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          testDeviceIds: ['5078FBCB70B6D336AA8E0D8A6981730B'],
        ),
      );
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

  /// Records that a run just ended (crash / finish / out of fuel). Counting is
  /// kept separate from showing so the ad only ever appears once the player
  /// dismisses the result overlay, never on top of it.
  Future<void> recordRunEnded() async {
    final runCount = (_prefs?.getInt(_keyRunCount) ?? 0) + 1;
    await _prefs?.setInt(_keyRunCount, runCount);
  }

  /// Shows an interstitial if one is due, subject to the grace period, the
  /// every-Nth-run cadence and the no-ads entitlement. Call this when the
  /// player leaves a result overlay to the menu / levels — never mid-game.
  Future<void> maybeShowInterstitial() async {
    if (_adsSuppressed) return;
    final runCount = _prefs?.getInt(_keyRunCount) ?? 0;
    if (runCount <= _interstitialGracePeriod) return;
    if ((runCount - _interstitialGracePeriod) % _interstitialEveryNRuns != 0) {
      return;
    }
    if (runCount == _lastInterstitialRun) return; // already shown this run
    _lastInterstitialRun = runCount;

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

  /// Loads a rewarded ad on demand and completes with it (or null on
  /// failure/timeout). Used when the user taps "watch ad" but nothing was
  /// preloaded yet — e.g. right after launch or after a failed preload.
  Future<RewardedAd?> _loadRewardedNow() {
    final completer = Completer<RewardedAd?>();
    _loadingRewarded = true;
    RewardedAd.load(
      adUnitId: _rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingRewarded = false;
          if (!completer.isCompleted) completer.complete(ad);
        },
        onAdFailedToLoad: (error) {
          debugPrint('[ads] rewarded on-demand load failed: $error');
          _loadingRewarded = false;
          if (!completer.isCompleted) completer.complete(null);
        },
      ),
    );
    // Don't leave the user waiting forever if the network stalls.
    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => null,
    );
  }

  /// True if a rewarded ad is loaded and ready to show right now.
  bool get isRewardedReady => _rewarded != null;

  /// Shows a rewarded ad. [onReward] fires only if the user earns the reward
  /// (watches long enough). Returns true if an ad was actually shown.
  /// Rewarded ads are available even to no-ads / VIP users — they're opt-in.
  Future<bool> showRewarded({required VoidCallback onReward}) async {
    // Use the preloaded ad if we have one; otherwise try to load one right now
    // (the preload may have failed or not finished yet). Only give up — and let
    // the caller show "not ready" — when even an on-demand load can't produce
    // an ad (e.g. AdMob returns no-fill / 403).
    var ad = _rewarded;
    _rewarded = null;
    ad ??= await _loadRewardedNow();
    if (ad == null) {
      _loadRewarded(); // keep trying in the background for next time
      return false;
    }
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
    await ad.show(onUserEarnedReward: (ad, reward) => earned = true);
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
