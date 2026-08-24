import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'game_progress_service.dart';

/// Wraps RevenueCat (purchases_flutter) for in-app purchases, subscriptions
/// and entitlement state.
///
/// Follows the same singleton shape as [GameProgressService] and
/// `AudioManager`: a private constructor, a static [instance] getter, and an
/// [init] awaited once from `main()` before the first frame.
///
/// Entitlements (configured on the RevenueCat dashboard):
/// - `no_ads`         → removes banner + interstitial ads (rewarded stays)
/// - `unlock_all_maps`→ unlocks every map
/// - `vip`            → Garagum VIP subscription (no ads + daily coins + 2x)
///
/// The three exposed [ValueNotifier]s let widgets rebuild live when an
/// entitlement changes (e.g. the banner disappears the moment "remove ads"
/// is purchased) without any extra state-management package.
class PurchaseService {
  // ── Entitlement identifiers (must match the RevenueCat dashboard) ─────────
  static const String entitlementNoAds = 'no_ads';
  static const String entitlementAllMaps = 'unlock_all_maps';
  static const String entitlementVip = 'vip';

  // ── Product identifiers ───────────────────────────────────────────────────
  // Consumable coin packs → how many coins each grants when purchased.
  static const Map<String, int> coinPackAmounts = {
    'coins_10000': 10000,
    'coins_50000': 50000,
    'coins_200000': 200000,
  };

  /// RevenueCat *public* SDK keys. Replace the placeholders with the real
  /// keys from the RevenueCat dashboard (Project → API keys). While they are
  /// left as placeholders the service runs in a safe no-op mode: nothing is
  /// configured, every entitlement reads `false`, and the app never crashes.
  static const String _androidApiKey = 'goog_REPLACE_ME';
  static const String _iosApiKey = 'appl_REPLACE_ME';

  static PurchaseService? _instance;
  static PurchaseService get instance {
    _instance ??= PurchaseService._();
    return _instance!;
  }

  PurchaseService._();

  /// Whether [Purchases.configure] actually ran. When false (placeholder keys
  /// or a configure failure) every call degrades to a safe default so the game
  /// keeps working with no store connection.
  bool _configured = false;
  bool get isConfigured => _configured;

  final ValueNotifier<bool> noAdsNotifier = ValueNotifier(false);
  final ValueNotifier<bool> allMapsNotifier = ValueNotifier(false);
  final ValueNotifier<bool> vipNotifier = ValueNotifier(false);

  bool get noAds => noAdsNotifier.value || vipNotifier.value;
  bool get allMapsUnlocked => allMapsNotifier.value;
  bool get isVip => vipNotifier.value;

  Future<void> init() async {
    final apiKey = Platform.isIOS ? _iosApiKey : _androidApiKey;
    if (apiKey.contains('REPLACE_ME')) {
      debugPrint(
        '[purchase] RevenueCat API key not set — running in no-op mode. '
        'Set the real key in PurchaseService before release.',
      );
      return;
    }

    try {
      await Purchases.setLogLevel(
        kDebugMode ? LogLevel.debug : LogLevel.info,
      );
      await Purchases.configure(PurchasesConfiguration(apiKey));
      _configured = true;

      // Keep entitlement notifiers in sync whenever RevenueCat pushes an
      // update (restore, renewal, expiry, purchase from another device).
      Purchases.addCustomerInfoUpdateListener(_applyCustomerInfo);
      await refresh();
    } catch (e) {
      debugPrint('[purchase] configure failed: $e');
      _configured = false;
    }
  }

  /// Re-reads the current entitlement state from RevenueCat.
  Future<void> refresh() async {
    if (!_configured) return;
    try {
      final info = await Purchases.getCustomerInfo();
      _applyCustomerInfo(info);
    } catch (e) {
      debugPrint('[purchase] refresh failed: $e');
    }
  }

  void _applyCustomerInfo(CustomerInfo info) {
    final active = info.entitlements.active;
    noAdsNotifier.value = active.containsKey(entitlementNoAds);
    allMapsNotifier.value = active.containsKey(entitlementAllMaps);
    vipNotifier.value = active.containsKey(entitlementVip);
  }

  /// Returns the current RevenueCat offerings, or null if unavailable.
  Future<Offerings?> getOfferings() async {
    if (!_configured) return null;
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('[purchase] getOfferings failed: $e');
      return null;
    }
  }

  /// Purchases a package. On success, refreshes entitlements and credits any
  /// consumable coin pack to the local coin balance. Returns true on success.
  Future<bool> purchasePackage(Package package) async {
    if (!_configured) return false;
    try {
      final result =
          await Purchases.purchase(PurchaseParams.package(package));
      _applyCustomerInfo(result.customerInfo);
      await _creditConsumableIfNeeded(package.storeProduct.identifier);
      return true;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code != PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('[purchase] purchase failed: $code');
      }
      return false;
    } catch (e) {
      debugPrint('[purchase] purchase failed: $e');
      return false;
    }
  }

  Future<void> _creditConsumableIfNeeded(String productId) async {
    // Store product ids often carry a platform suffix; match by prefix key.
    for (final entry in coinPackAmounts.entries) {
      if (productId.contains(entry.key)) {
        await GameProgressService.instance.addCoins(entry.value);
        return;
      }
    }
  }

  /// Restores previously bought non-consumables / subscriptions.
  Future<bool> restorePurchases() async {
    if (!_configured) return false;
    try {
      final info = await Purchases.restorePurchases();
      _applyCustomerInfo(info);
      return true;
    } catch (e) {
      debugPrint('[purchase] restore failed: $e');
      return false;
    }
  }
}
