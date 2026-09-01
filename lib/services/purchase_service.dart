import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import 'analytics_service.dart';
import 'game_progress_service.dart';

/// Wraps RevenueCat (purchases_flutter) for in-app purchases, subscriptions
/// and entitlement state.
///
/// Follows the same singleton shape as [GameProgressService] and
/// `AudioManager`: a private constructor, a static [instance] getter, and an
/// [init] awaited once from `main()` before the first frame.
///
/// Entitlements (configured on the RevenueCat dashboard):
/// - `garagumracing_pro` → the master "Pro" subscription. Granting it implies
///   every perk below (no ads + all maps + VIP), so the Pro paywall is the one
///   place a player upgrades. Backed by the `lifetime` / `yearly` / `monthly`
///   products in the "pro" offering.
/// - `no_ads`         → removes banner + interstitial ads (rewarded stays)
/// - `unlock_all_maps`→ unlocks every map
/// - `vip`            → Garagum VIP (no ads + daily coins + 2x)
///
/// The exposed [ValueNotifier]s let widgets rebuild live when an entitlement
/// changes (e.g. the banner disappears the moment Pro is purchased) without any
/// extra state-management package.
class PurchaseService {
  // ── Entitlement identifiers (must match the RevenueCat dashboard) ─────────
  /// Master subscription entitlement. Implies [entitlementNoAds],
  /// [entitlementAllMaps] and [entitlementVip].
  static const String entitlementPro = 'garagumracing_pro';
  static const String entitlementNoAds = 'no_ads';
  static const String entitlementAllMaps = 'unlock_all_maps';
  static const String entitlementVip = 'vip';

  /// Identifier of the Offering that holds the Pro plans on the dashboard.
  /// Kept as a single constant (not per-product) so plans stay fully dynamic —
  /// the app never hardcodes individual product ids; it reads whatever packages
  /// this offering serves. Falls back to the project's *current* offering when
  /// no offering with this id exists.
  static const String proOfferingId = 'pro';

  // ── Product identifiers ───────────────────────────────────────────────────
  // Consumable coin packs → how many coins each grants when purchased.
  static const Map<String, int> coinPackAmounts = {
    'coins_10000': 10000,
    'coins_50000': 50000,
    'coins_200000': 200000,
  };

  /// One-time bundle: 25 000 coins + UAZ + 3-day ad-free window.
  static const String starterPackProductId = 'starter_pack';

  /// RevenueCat *public* SDK keys (Project → API keys on the dashboard).
  ///
  /// [_testStoreApiKey] is a cross-platform **Test Store** key (`test_…`): it
  /// lets purchases and paywalls be exercised on any device before the App
  /// Store / Play Store products are live. When it's set it takes precedence on
  /// both platforms. Swap in the real `appl_…` / `goog_…` keys for production.
  ///
  /// While every key is a placeholder the service runs in a safe no-op mode:
  /// nothing is configured, every entitlement reads `false`, and the app never
  /// crashes.
  static const String _testStoreApiKey = 'test_LVJwiszEYglNEtIBREtvFCmSmab';
  static const String _androidApiKey = 'goog_REPLACE_ME';
  static const String _iosApiKey = 'appl_REPLACE_ME';

  /// The key actually handed to [Purchases.configure]. Prefers the Test Store
  /// key (works on both platforms), then falls back to the platform-specific
  /// production key.
  static String get _apiKey {
    if (_testStoreApiKey.startsWith('test_')) return _testStoreApiKey;
    return Platform.isIOS ? _iosApiKey : _androidApiKey;
  }

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

  /// Master Pro subscription. Implies no-ads + all-maps + VIP.
  final ValueNotifier<bool> proNotifier = ValueNotifier(false);
  final ValueNotifier<bool> noAdsNotifier = ValueNotifier(false);
  final ValueNotifier<bool> allMapsNotifier = ValueNotifier(false);
  final ValueNotifier<bool> vipNotifier = ValueNotifier(false);

  bool get isPro => proNotifier.value;
  // Pro is a superset — it unlocks each individual perk too.
  bool get noAds => proNotifier.value || noAdsNotifier.value || vipNotifier.value;
  bool get allMapsUnlocked => proNotifier.value || allMapsNotifier.value;
  bool get isVip => proNotifier.value || vipNotifier.value;

  Future<void> init() async {
    final apiKey = _apiKey;
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
    proNotifier.value = active.containsKey(entitlementPro);
    noAdsNotifier.value = active.containsKey(entitlementNoAds);
    allMapsNotifier.value = active.containsKey(entitlementAllMaps);
    vipNotifier.value = active.containsKey(entitlementVip);
  }

  /// The customer's raw RevenueCat info (subscription dates, management URL,
  /// active entitlements). Returns null if RevenueCat isn't configured.
  Future<CustomerInfo?> getCustomerInfo() async {
    if (!_configured) return null;
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      debugPrint('[purchase] getCustomerInfo failed: $e');
      return null;
    }
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
      AnalyticsService.instance.logPurchase(package.storeProduct.identifier);
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

  /// Buys a coin pack by its product id (e.g. `coins_10000`) from the current
  /// offering. Falls back to showing the full paywall when RevenueCat isn't
  /// configured or the package can't be found. Returns true on a completed
  /// purchase.
  Future<bool> purchaseCoinPackById(String productId) async {
    if (!_configured) {
      await presentPaywall();
      return false;
    }
    final offerings = await getOfferings();
    final packages = offerings?.current?.availablePackages ?? const [];
    for (final pkg in packages) {
      if (pkg.storeProduct.identifier.contains(productId)) {
        return purchasePackage(pkg);
      }
    }
    // Product not found in the current offering — show the paywall instead.
    await presentPaywall();
    return false;
  }

  Future<void> _creditConsumableIfNeeded(String productId) async {
    // Store product ids often carry a platform suffix; match by prefix key.
    if (productId.contains(starterPackProductId)) {
      await GameProgressService.instance.grantStarterPack();
      return;
    }
    for (final entry in coinPackAmounts.entries) {
      if (productId.contains(entry.key)) {
        await GameProgressService.instance.addCoins(entry.value);
        return;
      }
    }
  }

  /// Presents the RevenueCat paywall (Paywalls v2 — designed on the
  /// dashboard, no code changes needed to restyle it). Refreshes entitlements
  /// afterwards. Returns true if the user purchased or restored. No-op (false)
  /// when RevenueCat isn't configured.
  Future<bool> presentPaywall() async {
    if (!_configured) return false;
    try {
      final result =
          await RevenueCatUI.presentPaywall(displayCloseButton: true);
      await refresh();
      final bought = result == PaywallResult.purchased ||
          result == PaywallResult.restored;
      if (bought) AnalyticsService.instance.logPurchase('paywall');
      return bought;
    } catch (e) {
      debugPrint('[purchase] presentPaywall failed: $e');
      return false;
    }
  }

  /// Presents the paywall only if [entitlementId] isn't already active (e.g.
  /// don't nag a player who already bought "remove ads").
  Future<bool> presentPaywallIfNeeded(String entitlementId) async {
    if (!_configured) return false;
    try {
      final result = await RevenueCatUI.presentPaywallIfNeeded(
        entitlementId,
        displayCloseButton: true,
      );
      await refresh();
      final bought = result == PaywallResult.purchased ||
          result == PaywallResult.restored;
      if (bought) AnalyticsService.instance.logPurchase('paywall');
      return bought;
    } catch (e) {
      debugPrint('[purchase] presentPaywallIfNeeded failed: $e');
      return false;
    }
  }

  // ── Pro subscription (garagumracing_pro) ──────────────────────────────────

  /// Shows the Pro paywall, but only if the player isn't already Pro. Use this
  /// from every "Go Pro / Unlock everything" button. Returns true if they
  /// upgraded (or restored) during this presentation.
  Future<bool> presentProPaywall() => presentPaywallIfNeeded(entitlementPro);

  /// The Offering that holds the Pro plans: the dedicated [proOfferingId]
  /// offering if it exists, otherwise the project's current (default) offering.
  /// Returns null when RevenueCat isn't configured or offerings can't be
  /// fetched. Use this to render a custom "choose your plan" UI dynamically —
  /// read [Offering.availablePackages] rather than assuming a fixed set.
  Future<Offering?> getProOffering() async {
    final offerings = await getOfferings();
    return offerings?.getOffering(proOfferingId) ?? offerings?.current;
  }

  /// Same as [getProOffering] but resolved through a RevenueCat *Placement*, so
  /// the dashboard can serve a different offering per in-app location without
  /// an app update. Returns null if the placement has no offering configured.
  Future<Offering?> getProOfferingForPlacement(String placement) async {
    if (!_configured) return null;
    try {
      return await Purchases.getCurrentOfferingForPlacement(placement);
    } catch (e) {
      debugPrint('[purchase] placement offering failed: $e');
      return null;
    }
  }

  /// Buys a Pro plan directly (skipping the paywall UI) by its **default
  /// package type** — [PackageType.lifetime], [PackageType.annual] or
  /// [PackageType.monthly]. This reads whatever product the dashboard mapped to
  /// that package, so no product ids are hardcoded. Falls back to the paywall
  /// when the requested plan isn't in the offering. Returns true on a completed
  /// purchase.
  Future<bool> purchasePro(PackageType type) async {
    if (!_configured) {
      await presentProPaywall();
      return false;
    }
    final offering = await getProOffering();
    final package = switch (type) {
      PackageType.lifetime => offering?.lifetime,
      PackageType.annual => offering?.annual,
      PackageType.monthly => offering?.monthly,
      PackageType.weekly => offering?.weekly,
      PackageType.sixMonth => offering?.sixMonth,
      PackageType.threeMonth => offering?.threeMonth,
      PackageType.twoMonth => offering?.twoMonth,
      _ => null,
    };
    if (package != null) return purchasePackage(package);
    // Requested plan not offered right now — let the player pick from the
    // paywall (which always reflects the live dashboard configuration).
    await presentProPaywall();
    return false;
  }

  /// Presents RevenueCat's Customer Center — the drop-in screen where users
  /// manage/cancel their subscription, restore purchases and request refunds.
  /// Entitlements are refreshed afterwards in case anything changed there.
  Future<void> presentCustomerCenter() async {
    if (!_configured) return;
    try {
      await RevenueCatUI.presentCustomerCenter();
      await refresh();
    } catch (e) {
      debugPrint('[purchase] presentCustomerCenter failed: $e');
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
