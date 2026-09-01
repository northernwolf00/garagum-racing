import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Thin wrapper around Firebase Analytics.
///
/// Same singleton shape as the other services ([AdService], [PurchaseService]):
/// private constructor, static [instance], [init] awaited once from `main()`.
///
/// Every log method swallows its own errors — analytics must never crash the
/// game or block a gameplay flow. In debug builds collection is disabled so the
/// developer's own play sessions don't pollute the production dashboards.
class AnalyticsService {
  static AnalyticsService? _instance;
  static AnalyticsService get instance {
    _instance ??= AnalyticsService._();
    return _instance!;
  }

  AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  bool _initialized = false;

  /// A [NavigatorObserver] you can pass to `GetMaterialApp`/`MaterialApp` so
  /// screen views are logged automatically on every route change.
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      // Don't count developer test sessions in the production numbers.
      await _analytics.setAnalyticsCollectionEnabled(!kDebugMode);
    } catch (e) {
      debugPrint('[analytics] init failed: $e');
    }
  }

  /// Logs an arbitrary event. Keys/values must satisfy Firebase's limits
  /// (event name ≤ 40 chars, param values are String/num).
  Future<void> logEvent(
    String name, {
    Map<String, Object>? params,
  }) async {
    try {
      await _analytics.logEvent(name: name, parameters: params);
    } catch (e) {
      debugPrint('[analytics] logEvent($name) failed: $e');
    }
  }

  // ── Game-specific convenience events ──────────────────────────────────────

  /// A race/run started on [levelId] with [vehicleId].
  Future<void> logRaceStart(String levelId, String vehicleId) => logEvent(
    'race_start',
    params: {'level_id': levelId, 'vehicle_id': vehicleId},
  );

  /// A run ended. [result] is e.g. 'finish' / 'crash' / 'out_of_fuel'.
  Future<void> logRaceEnd(
    String levelId,
    String result, {
    int? coins,
    double? distance,
  }) => logEvent('race_end', params: {
    'level_id': levelId,
    'result': result,
    'coins': ?coins,
    if (distance != null) 'distance': distance.round(),
  });

  /// The player unlocked a vehicle.
  Future<void> logVehicleUnlocked(String vehicleId) =>
      logEvent('vehicle_unlocked', params: {'vehicle_id': vehicleId});

  /// The player unlocked / opened a level.
  Future<void> logLevelUnlocked(String levelId) =>
      logEvent('level_unlocked', params: {'level_id': levelId});

  /// The player watched a rewarded ad to earn coins.
  Future<void> logRewardedEarned(int coins) =>
      logEvent('rewarded_earned', params: {'coins': coins});

  /// The player changed the UI language ([code] = 'en' / 'ru' / 'tr').
  Future<void> logLanguageChanged(String code) =>
      logEvent('language_changed', params: {'language': code});

  /// A store purchase completed. [productId] is the RevenueCat/store product.
  Future<void> logPurchase(String productId) =>
      logEvent('purchase_completed', params: {'product_id': productId});
}
