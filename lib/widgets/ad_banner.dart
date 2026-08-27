import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_service.dart';
import '../services/purchase_service.dart';

/// A self-managing AdMob banner for the menu / garage screens.
///
/// - Renders nothing until the ad has actually loaded (so no blank gap).
/// - Renders nothing when the no-ads / VIP entitlement is active, and reacts
///   live: the moment "remove ads" is purchased the banner disappears.
/// - Owns the [BannerAd]'s lifecycle and disposes it with the widget.
///
/// Drop it at the bottom of a screen; it sizes itself to the standard banner.
class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  /// Bottom spacer that reserves room for the banner only while one is showing,
  /// so a screen's bottom buttons stay tappable above it. Put it at the end of
  /// the screen's scroll/column content.
  static Widget bottomReservedSpace(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return ValueListenableBuilder<bool>(
      valueListenable: AdService.instance.bannerVisible,
      builder: (_, visible, __) => SizedBox(
        height: visible ? AdSize.banner.height.toDouble() + safeBottom + 8 : 0,
      ),
    );
  }

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _banner;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    PurchaseService.instance.noAdsNotifier.addListener(_onEntitlementChanged);
    PurchaseService.instance.vipNotifier.addListener(_onEntitlementChanged);
    _createBanner();
  }

  void _createBanner() {
    _disposeBanner();
    _loaded = false;
    // Returns null when ads are suppressed (no-ads / VIP).
    _banner = AdService.instance.createBanner(
      onLoaded: () {
        if (mounted) {
          setState(() => _loaded = true);
          AdService.instance.bannerVisible.value = true;
        }
      },
    );
  }

  void _onEntitlementChanged() {
    if (!mounted) return;
    setState(_createBanner);
  }

  void _disposeBanner() {
    _banner?.dispose();
    _banner = null;
    AdService.instance.bannerVisible.value = false;
  }

  @override
  void dispose() {
    PurchaseService.instance.noAdsNotifier.removeListener(_onEntitlementChanged);
    PurchaseService.instance.vipNotifier.removeListener(_onEntitlementChanged);
    _disposeBanner();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = _banner;
    if (banner == null || !_loaded) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: banner.size.width.toDouble(),
          height: banner.size.height.toDouble(),
          child: AdWidget(ad: banner),
        ),
      ),
    );
  }
}
