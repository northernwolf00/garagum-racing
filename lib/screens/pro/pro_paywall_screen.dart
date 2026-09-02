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
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
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
        const SizedBox(height: 8),
        Container(
          width: 68,
          height: 68,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFFFFC15A), Color(0xFFE8791A)],
            ),
          ),
          child: const Icon(Icons.workspace_premium_rounded,
              color: Colors.white, size: 38),
        ),
        const SizedBox(height: 14),
        Text(
          'pro_title'.tr,
          style: const TextStyle(
            color: Color(0xFFFFD98C),
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'pro_subtitle'.tr,
          style: const TextStyle(
            color: Color(0xFF8A6A3F),
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 18),
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
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF76FF03), size: 20),
              const SizedBox(width: 12),
              Text(
                key.tr,
                style: const TextStyle(
                  color: Color(0xFFEAD9C3),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
    ];
  }

  // ── Plan selection ──────────────────────────────────────────────────────────
  Widget _buildPlans() {
    // The single best-value badge goes on lifetime, else annual.
    final badgeType = _packages.any((p) => p.packageType == PackageType.lifetime)
        ? PackageType.lifetime
        : PackageType.annual;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                for (final pkg in _packages) ...[
                  _PlanCard(
                    label: _planLabel(pkg),
                    price: pkg.storeProduct.priceString,
                    subPrice: _subPrice(pkg),
                    trial: _trialText(pkg),
                    bestValue: pkg.packageType == badgeType,
                    selected: identical(pkg, _selected),
                    onTap: _busy ? null : () => setState(() => _selected = pkg),
                  ),
                  const SizedBox(height: 10),
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
        const SizedBox(height: 8),
        TextButton(
          onPressed: _busy ? null : _restore,
          child: Text(
            'restore_purchases'.tr,
            style: const TextStyle(
              color: Color(0xFF8A6A3F),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _planLabel(Package pkg) {
    return switch (pkg.packageType) {
      PackageType.lifetime => 'plan_lifetime'.tr,
      PackageType.annual => 'plan_yearly'.tr,
      PackageType.monthly => 'plan_monthly'.tr,
      PackageType.weekly => 'plan_weekly'.tr,
      // Any non-standard duration: fall back to the store's own title.
      _ => pkg.storeProduct.title,
    };
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
  });

  final String label;
  final String price;
  final String? subPrice;
  final String? trial;
  final bool bestValue;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0x33E8A33D) : const Color(0x14E8A33D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFFE8A33D) : const Color(0x33E8A33D),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? const Color(0xFFE8A33D) : const Color(0xFF8A6A3F),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Color(0xFFFFD98C),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (bestValue) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF8C1A), Color(0xFFE85A00)],
                            ),
                          ),
                          child: Text(
                            'best_value'.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
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
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (subPrice != null)
                  Text(
                    subPrice!,
                    style: const TextStyle(
                      color: Color(0xFF8A6A3F),
                      fontSize: 11,
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
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
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                )
              : Text(
                  'continue_btn'.tr,
                  style: TextStyle(
                    color: enabled ? Colors.white : const Color(0xFF8A6A3F),
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}
