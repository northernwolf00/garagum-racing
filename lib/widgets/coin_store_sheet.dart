import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/ad_service.dart';
import '../services/game_progress_service.dart';
import '../services/purchase_service.dart';

/// Opens the shared coin store as a bottom sheet. Reachable by tapping the coin
/// badge from the menu, garage and levels screens.
///
/// Offers two ways to get coins side by side (per the monetisation plan):
/// - **Watch an ad → +[GameProgressService.rewardAdCoins]** coins, capped at
///   [GameProgressService.rewardAdDailyCap] per day so it complements playing
///   rather than replacing it.
/// - **Buy a coin pack** (or remove ads) via RevenueCat.
Future<void> showCoinStore(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _CoinStoreSheet(),
  );
}

class _CoinStoreSheet extends StatefulWidget {
  const _CoinStoreSheet();

  @override
  State<_CoinStoreSheet> createState() => _CoinStoreSheetState();
}

class _CoinStoreSheetState extends State<_CoinStoreSheet> {
  final _progress = GameProgressService.instance;
  bool _busy = false;
  int _justEarned = 0;

  // Coin packs: (product id, coin amount, display price). Prices are the plan's
  // placeholders — the real localized price comes from RevenueCat once
  // configured; the purchase itself always goes through purchaseCoinPackById.
  static const List<(String, int, String)> _packs = [
    ('coins_10000', 10000, '\$0.99'),
    ('coins_50000', 50000, '\$3.99'),
    ('coins_200000', 200000, '\$9.99'),
  ];

  Future<void> _watchAd() async {
    if (_busy || !_progress.canWatchRewardForCoins) return;
    setState(() => _busy = true);
    final shown = await AdService.instance.showRewarded(onReward: () {
      _progress.claimRewardAdCoins().then((amt) {
        if (mounted && amt > 0) setState(() => _justEarned = amt);
      });
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (!shown) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ad_not_ready'.tr),
          backgroundColor: const Color(0xFF3D1A06),
        ),
      );
    }
  }

  Future<void> _buyPack(String productId) async {
    if (_busy) return;
    setState(() => _busy = true);
    await PurchaseService.instance.purchaseCoinPackById(productId);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _removeAds() async {
    if (_busy) return;
    setState(() => _busy = true);
    await PurchaseService.instance
        .presentPaywallIfNeeded(PurchaseService.entitlementNoAds);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _progress.rewardAdsRemainingToday;
    final canWatch = _progress.canWatchRewardForCoins && !_busy;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C0E06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x44E8A33D)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0x33FFD98C),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/ui/coin.png',
                width: 26,
                height: 26,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.monetization_on,
                  color: Color(0xFFFFD700),
                  size: 26,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'get_coins'.tr,
                style: const TextStyle(
                  color: Color(0xFFFFD98C),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'balance_coins'.trParams({'n': '${_progress.getTotalCoins()}'}),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF8A6A3F),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),

          // ── Watch ad for coins ──────────────────────────────────────────
          GestureDetector(
            onTap: canWatch ? _watchAd : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: canWatch
                    ? const LinearGradient(
                        colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                      )
                    : null,
                color: canWatch ? null : const Color(0x22E8A33D),
                border: Border.all(
                  color: canWatch
                      ? const Color(0xFF66FF88)
                      : const Color(0x44E8A33D),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.play_circle_fill_rounded,
                    color: canWatch
                        ? const Color(0xFFB9FFC9)
                        : const Color(0xFF8A6A3F),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'watch_ad_plus'.trParams(
                              {'n': '${GameProgressService.rewardAdCoins}'}),
                          style: TextStyle(
                            color: canWatch
                                ? Colors.white
                                : const Color(0xFF8A6A3F),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          remaining > 0
                              ? 'ads_left_today'.trParams({
                                  'remaining': '$remaining',
                                  'cap':
                                      '${GameProgressService.rewardAdDailyCap}',
                                })
                              : 'ads_done_today'.tr,
                          style: const TextStyle(
                            color: Color(0xFF8A6A3F),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_busy)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFB9FFC9),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_justEarned > 0) ...[
            const SizedBox(height: 8),
            Text(
              'coins_claimed'.trParams({'n': '$_justEarned'}),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF44FF88),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],

          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(child: Divider(color: Color(0x33E8A33D))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'or_buy'.tr,
                  style: const TextStyle(
                    color: Color(0xFF8A6A3F),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: Color(0x33E8A33D))),
            ],
          ),
          const SizedBox(height: 12),

          // ── Coin packs ──────────────────────────────────────────────────
          for (final pack in _packs) ...[
            _CoinPackRow(
              amount: pack.$2,
              price: pack.$3,
              onTap: _busy ? null : () => _buyPack(pack.$1),
            ),
            const SizedBox(height: 8),
          ],

          const SizedBox(height: 6),

          // ── Remove ads (Pro) ────────────────────────────────────────────
          GestureDetector(
            onTap: _busy ? null : _removeAds,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x55FFD700)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.workspace_premium_rounded,
                      color: Color(0xFFFFD700), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'go_ad_free'.tr,
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoinPackRow extends StatelessWidget {
  const _CoinPackRow({
    required this.amount,
    required this.price,
    required this.onTap,
  });

  final int amount;
  final String price;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0x22E8A33D),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x33E8A33D)),
        ),
        child: Row(
          children: [
            Image.asset(
              'assets/images/ui/coin.png',
              width: 22,
              height: 22,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.monetization_on,
                color: Color(0xFFFFD700),
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'amount_coins'.trParams({'n': '$amount'}),
              style: const TextStyle(
                color: Color(0xFFFFD98C),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8C1A), Color(0xFFE85A00)],
                ),
              ),
              child: Text(
                price,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
