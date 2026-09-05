import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../services/purchase_service.dart';

/// A custom, in-app "Go Pro" plan-selection screen.
///
/// Everything shown is **dynamic**, per RevenueCat's best practices: the plans,
/// their order, prices and trial text all come from whatever the dashboard
/// serves in the [PurchaseService.proOfferingId] offering — no product ids or
/// prices are hardcoded. If plans can't be fetched, it offers the fully
/// dashboard-driven RevenueCat paywall as a fallback.
class ProPaywallScreen extends StatefulWidget {
  const ProPaywallScreen({super.key});

  /// Pushes the paywall. Returns true if the user became Pro during the visit.
  static Future<bool> open(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ProPaywallScreen()),
    );
    return result ?? false;
  }

  @override
  State<ProPaywallScreen> createState() => _ProPaywallScreenState();
}

enum _Status { loading, ready, empty, pro }

class _ProPaywallScreenState extends State<ProPaywallScreen> {
  final _purchases = PurchaseService.instance;

  _Status _status = _Status.loading;
  List<Package> _packages = const [];
  Package? _selected;
  bool _busy = false;

  // Preferred display order — longer commitments (better value) first.
  static const List<PackageType> _order = [
    PackageType.lifetime,
    PackageType.annual,
    PackageType.sixMonth,
    PackageType.threeMonth,
    PackageType.twoMonth,
    PackageType.monthly,
    PackageType.weekly,
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _status = _Status.loading);

    if (_purchases.isPro) {
      setState(() => _status = _Status.pro);
      return;
    }

    final offering = await _purchases.getProOffering();
    final packages = [...?offering?.availablePackages]
      ..sort((a, b) => _rank(a.packageType).compareTo(_rank(b.packageType)));

    if (!mounted) return;
    if (packages.isEmpty) {
      setState(() => _status = _Status.empty);
      return;
    }
    setState(() {
      _packages = packages;
      // Default to the annual plan if present (usually the sweet spot), else
      // the first available plan.
      _selected = packages.firstWhere(
        (p) => p.packageType == PackageType.annual,
        orElse: () => packages.first,
      );
      _status = _Status.ready;
    });
  }

  int _rank(PackageType t) {
    final i = _order.indexOf(t);
    return i < 0 ? _order.length : i;
  }

  Future<void> _buySelected() async {
    final pkg = _selected;
    if (pkg == null || _busy) return;
    setState(() => _busy = true);
    final ok = await _purchases.purchasePackage(pkg);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok && _purchases.isPro) {
      _toast('pro_purchase_success'.tr);
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _restore() async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await _purchases.restorePurchases();
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(ok ? 'purchases_restored'.tr : 'restore_failed'.tr);
    if (_purchases.isPro && mounted) setState(() => _status = _Status.pro);
  }

  /// Fallback to RevenueCat's own dashboard-driven paywall (e.g. when the
  /// custom plan list can't be fetched).
  Future<void> _openHostedPaywall() async {
    if (_busy) return;
    setState(() => _busy = true);
    await _purchases.presentProPaywall();
    if (!mounted) return;
    setState(() => _busy = false);
    if (_purchases.isPro) Navigator.of(context).pop(true);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF3D1A06),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF140A04),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Color(0xFF8A6A3F)),
                onPressed: () => Navigator.of(context).pop(_purchases.isPro),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_status) {
      case _Status.loading:
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFFE8A33D)),
        );
      case _Status.pro:
        return _buildProActive();
      case _Status.empty:
        return _buildEmpty();
      case _Status.ready:
        return _buildPlans();
    }
  }

  // ── Header shared by the plan + empty states ────────────────────────────────
  Widget _buildHeader() {
    return Column(
      children: [
        const SizedBox(height: 4),
        Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFFFFC15A), Color(0xFFE8791A)],
            ),
          ),
          child: const Icon(Icons.workspace_premium_rounded,
              color: Colors.white, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          'pro_title'.tr,
          style: const TextStyle(
            color: Color(0xFFFFD98C),
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'pro_subtitle'.tr,
          style: const TextStyle(
            color: Color(0xFF8A6A3F),
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        ..._benefits(),
      ],
    );
  }

  List<Widget> _benefits() {
    const items = [
      (Icons.block_rounded, 'pro_benefit_no_ads'),
      (Icons.map_rounded, 'pro_benefit_all_maps'),
      (Icons.monetization_on_rounded, 'pro_benefit_vip_coins'),
      (Icons.bolt_rounded, 'pro_benefit_2x'),
    ];
    return [
      for (final (icon, key) in items)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.5),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF76FF03), size: 16),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  key.tr,
                  style: const TextStyle(
                    color: Color(0xFFEAD9C3),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
    ];
  }

  // ── Plan selection ──────────────────────────────────────────────────────────
  Widget _buildPlans() {
    // The single best-value badge goes on lifetime, else annual, else starter pack.
    final hasSubscription = _packages.any((p) =>
        p.packageType == PackageType.lifetime ||
        p.packageType == PackageType.annual);
    final badgeType = _packages.any((p) => p.packageType == PackageType.lifetime)
        ? PackageType.lifetime
        : PackageType.annual;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                for (final pkg in _packages) ...[
                  _PlanCard(
                    label: _planLabel(pkg),
                    price: pkg.storeProduct.priceString,
                    subPrice: _subPrice(pkg),
                    trial: _trialText(pkg),
                    icon: _planIcon(pkg),
                    bestValue: hasSubscription
                        ? pkg.packageType == badgeType
                        : pkg.storeProduct.identifier
                            .toLowerCase()
                            .contains('starter_pack'),
                    selected: identical(pkg, _selected),
                    onTap: _busy ? null : () => setState(() => _selected = pkg),
                  ),
                  const SizedBox(height: 6.5),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        _ContinueButton(
          busy: _busy,
          onTap: _selected == null ? null : _buySelected,
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: _busy ? null : _restore,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'restore_purchases'.tr,
            style: const TextStyle(
              color: Color(0xFF8A6A3F),
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ),
      ],
    );
  }

  String _planLabel(Package pkg) {
    switch (pkg.packageType) {
      case PackageType.lifetime:
        return 'plan_lifetime'.tr;
      case PackageType.annual:
        return 'plan_yearly'.tr;
      case PackageType.monthly:
        return 'plan_monthly'.tr;
      case PackageType.weekly:
        return 'plan_weekly'.tr;
      default:
        break;
    }

    final id = pkg.storeProduct.identifier.toLowerCase();
    if (id.contains('remove_ads')) return 'remove_ads'.tr;
    if (id.contains('unlock_all_maps')) return 'pro_benefit_all_maps'.tr;
    if (id.contains('starter_pack')) return 'Starter Pack';
    if (id.contains('coins_10000') || id == 'coins_10000') return '10,000 Coins';
    if (id.contains('coins_50000') || id == 'coins_50000') return '50,000 Coins';
    if (id.contains('coins_200000') || id == 'coins_200000') return '200,000 Coins';

    final raw = pkg.storeProduct.title;
    return raw.replaceAll(RegExp(r'\s*\([^)]*\)$'), '').trim();
  }

  IconData? _planIcon(Package pkg) {
    final id = pkg.storeProduct.identifier.toLowerCase();
    if (id.contains('coins_200000')) return Icons.diamond_rounded;
    if (id.contains('coins')) return Icons.monetization_on_rounded;
    if (id.contains('starter')) return Icons.card_giftcard_rounded;
    if (id.contains('map')) return Icons.map_rounded;
    if (id.contains('ad')) return Icons.block_rounded;
    return null;
  }

  /// A small "≈ price / month" line for the annual plan, when the store gives
  /// us the derived per-month price. Purely informative, never hardcoded.
  String? _subPrice(Package pkg) {
    if (pkg.packageType == PackageType.annual) {
      return pkg.storeProduct.pricePerMonthString;
    }
    return null;
  }

  String? _trialText(Package pkg) {
    final intro = pkg.storeProduct.introductoryPrice;
    if (intro != null && intro.price == 0) return 'free_trial'.tr;
    return null;
  }

  // ── Already-Pro state ───────────────────────────────────────────────────────
  Widget _buildProActive() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_rounded,
              color: Color(0xFFE8A33D), size: 64),
          const SizedBox(height: 16),
          Text(
            'pro_you_are_pro'.tr,
            style: const TextStyle(
              color: Color(0xFFFFD98C),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed:
                _busy ? null : () => _purchases.presentCustomerCenter(),
            icon: const Icon(Icons.manage_accounts_rounded,
                color: Color(0xFFE8A33D)),
            label: Text(
              'manage_subscription'.tr,
              style: const TextStyle(
                color: Color(0xFFE8A33D),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty / error state ─────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            Text(
              'no_plans_available'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF8A6A3F),
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _busy ? null : _load,
              child: Text('retry'.tr,
                  style: const TextStyle(
                      color: Color(0xFFE8A33D), fontWeight: FontWeight.w700)),
            ),
            TextButton(
              onPressed: _busy ? null : _openHostedPaywall,
              child: Text('go_pro'.tr,
                  style: const TextStyle(
                      color: Color(0xFFE8A33D), fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.label,
    required this.price,
    required this.subPrice,
    required this.trial,
    required this.bestValue,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final String price;
  final String? subPrice;
  final String? trial;
  final bool bestValue;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9.5),
        decoration: BoxDecoration(
          color: selected ? const Color(0x33E8A33D) : const Color(0x14E8A33D),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFFE8A33D) : const Color(0x33E8A33D),
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? const Color(0xFFE8A33D) : const Color(0xFF8A6A3F),
              size: 19,
            ),
            const SizedBox(width: 9),
            if (icon != null) ...[
              Icon(
                icon,
                color: selected ? const Color(0xFFFFD98C) : const Color(0xFF9E7E50),
                size: 17,
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected
                                ? const Color(0xFFFFD98C)
                                : const Color(0xFFE8D7C2),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (bestValue) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF8C1A), Color(0xFFE85A00)],
                            ),
                          ),
                          child: Text(
                            'best_value'.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (trial != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      trial!,
                      style: const TextStyle(
                        color: Color(0xFF76FF03),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subPrice != null)
                  Text(
                    subPrice!,
                    style: const TextStyle(
                      color: Color(0xFF8A6A3F),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !busy;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: enabled
              ? const LinearGradient(
                  colors: [Color(0xFFFFC15A), Color(0xFFE8791A)],
                )
              : null,
          color: enabled ? null : const Color(0x22E8A33D),
        ),
        child: Center(
          child: busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.2, color: Colors.white),
                )
              : Text(
                  'continue_btn'.tr,
                  style: TextStyle(
                    color: enabled ? Colors.white : const Color(0xFF8A6A3F),
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}

