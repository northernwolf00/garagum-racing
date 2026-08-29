import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../models/gate_config.dart';
import '../../models/map_theme.dart';
import '../../models/round_config.dart';
import '../../services/app_settings.dart';
import '../../services/game_progress_service.dart';
import '../../services/purchase_service.dart';
import '../../widgets/coin_store_sheet.dart';
import '../menu/menu_screen.dart';
import '../race_screen.dart';

/// Theme-agnostic round-selection grid. Shown after picking a map from the
/// menu — displays every round for that map with lock/unlock state, coin
/// requirements, and distance goals. [GaragumLevelsScreen] and
/// [AshgabatLevelsScreen] are thin wrappers around this that just supply
/// the map-specific data.
class LevelsScreen extends StatefulWidget {
  const LevelsScreen({
    super.key,
    required this.theme,
    required this.headerTitle,
    required this.rounds,
    required this.gradientForRound,
  });

  final MapTheme theme;
  final String headerTitle;
  final List<RoundConfig> rounds;
  final List<Color> Function(int roundIndex) gradientForRound;

  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen>
    with TickerProviderStateMixin {
  final _progress = GameProgressService.instance;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // RaceScreen reaches this screen via pushAndRemoveUntil (it clears the
  // whole stack when going "TURLAR" after a crash/finish), so this can end
  // up as the only route in the Navigator. A plain pop() in that case empties
  // the stack entirely and leaves a black screen — fall back to pushing the
  // menu instead.
  void _onBack() {
    try {
      if (AppSettings.instance.sfx.value) {
        FlameAudio.play('sfx/button_back.wav', volume: 0.7);
      }
    } catch (_) {}
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    navigator.pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, _) => const MenuScreen(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  /// Whether the round can be played right now (progression unlocked and any
  /// coin gate already paid).
  bool _isPlayable(RoundConfig round) {
    final r = round.roundIndex;
    final progressionUnlocked = _progress.isRoundUnlocked(widget.theme, r);
    if (!GateConfig.isGate(widget.theme, r)) return progressionUnlocked;
    return progressionUnlocked && _progress.isGatePaid(widget.theme, r);
  }

  /// Whether an unpaid coin gate on this round is reachable (so it should be
  /// shown as a "pay to unlock" card rather than a plain "finish previous" one).
  /// Map-entry gates (round 1) are always reachable; in-map gates need the
  /// previous round completed.
  bool _isGatePayable(RoundConfig round) {
    final r = round.roundIndex;
    if (!GateConfig.isGate(widget.theme, r)) return false;
    if (_progress.isGatePaid(widget.theme, r)) return false;
    return r == 1 || _progress.isRoundCompleted(widget.theme, r - 1);
  }

  void _playSelectSound() {
    try {
      if (AppSettings.instance.sfx.value) {
        FlameAudio.play('sfx/button_select.wav', volume: 0.8);
      }
    } catch (_) {}
  }

  void _playLockedSound() {
    try {
      if (AppSettings.instance.sfx.value) {
        FlameAudio.play('sfx/button_locked.wav', volume: 0.8);
      }
    } catch (_) {}
  }

  void _onRoundTap(RoundConfig round) {
    if (_isPlayable(round)) {
      _playSelectSound();
      _openRace(round);
      return;
    }
    if (_isGatePayable(round)) {
      _playSelectSound();
      _showGateSheet(round);
      return;
    }
    // Plain progression lock — previous round not finished yet.
    _playLockedSound();
  }

  void _openRace(RoundConfig round) {
    Navigator.of(context)
        .push(
          PageRouteBuilder(
            pageBuilder: (_, animation, _) => RaceScreen(roundConfig: round),
            transitionsBuilder: (_, animation, _, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 400),
          ),
        )
        .then((_) => setState(() {})); // refresh on return
  }

  Future<void> _payGate(RoundConfig round, int cost) async {
    final ok = await _progress.spendCoins(cost);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'not_enough_coins_detail'.trParams({
              'cost': '$cost',
              'have': '${_progress.getTotalCoins()}',
            }),
          ),
          backgroundColor: const Color(0xFF3D1A06),
        ),
      );
      // Offer the store as a way to progress faster (no-op until RevenueCat
      // keys are configured).
      PurchaseService.instance.presentPaywall();
      return;
    }
    await _progress.markGatePaid(widget.theme, round.roundIndex);
    await _progress.unlockRound(widget.theme, round.roundIndex);
    if (!mounted) return;
    setState(() {});
    _openRace(round);
  }

  void _showGateSheet(RoundConfig round) {
    final cost = GateConfig.costFor(widget.theme, round.roundIndex) ?? 0;
    final isMap = GateConfig.isMapGate(widget.theme, round.roundIndex);
    final balance = _progress.getTotalCoins();
    final enough = balance >= cost;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1C1207),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
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
              const SizedBox(height: 20),
              Icon(
                isMap ? Icons.map_rounded : Icons.lock_open_rounded,
                color: const Color(0xFFFFD98C),
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                isMap
                    ? 'unlock_map_named'.trParams({'name': widget.headerTitle})
                    : 'unlock_lap'.trParams({'lap': '${round.roundIndex}'}),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFFD98C),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
                  const SizedBox(width: 8),
                  Text(
                    '$cost',
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'balance_coins'.trParams({'n': '$balance'}),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF8A6A3F),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _payGate(round, cost);
                },
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: enough
                        ? const LinearGradient(
                            colors: [Color(0xFFFF8C1A), Color(0xFFE85A00)],
                          )
                        : null,
                    color: enough ? null : const Color(0x33E8A33D),
                    border: Border.all(
                      color: enough
                          ? const Color(0xFFFFAA44)
                          : const Color(0x55E8A33D),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      enough ? 'unlock_and_play'.tr : 'get_coins'.tr,
                      style: TextStyle(
                        color: enough ? Colors.white : const Color(0xFFE8A33D),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalCoins = _progress.getTotalCoins();
    final completedCount = widget.rounds
        .where((r) => _progress.isRoundCompleted(widget.theme, r.roundIndex))
        .length;

    final minFreq = widget.rounds.first.obstacleFrequency;
    final maxFreq = widget.rounds.last.obstacleFrequency;

    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final screenWidth = mediaQuery.size.width;

    final int crossAxisCount = isLandscape
        ? (screenWidth > 900 ? 5 : 4)
        : (screenWidth > 600 ? 3 : 2);
    final double childAspectRatio = isLandscape ? 1.25 : 1.1;
    final double expandedHeight = isLandscape ? 70.0 : 120.0;

    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1A0E06),
        body: FadeTransition(
          opacity: _fade,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: const Color(0xFF1A0E06),
                pinned: true,
                expandedHeight: expandedHeight,
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Color(0xFFFFD98C),
                  ),
                  onPressed: _onBack,
                ),
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: EdgeInsets.only(
                    left: 60,
                    bottom: isLandscape ? 10 : 16,
                  ),
                  title: Text(
                    widget.headerTitle,
                    style: TextStyle(
                      color: const Color(0xFFFFD98C),
                      fontSize: isLandscape ? 15 : 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF0B1829), Color(0xFF1A0E06)],
                      ),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(
                      right: 16,
                      top: 8,
                      bottom: 8,
                    ),
                    child: GestureDetector(
                      onTap: () async {
                        await showCoinStore(context);
                        if (mounted) setState(() {});
                      },
                      child: _CoinBadge(coins: totalCoins),
                    ),
                  ),
                ],
              ),

              // Progress summary
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    isLandscape ? 6 : 12,
                    16,
                    isLandscape ? 2 : 4,
                  ),
                  child: _ProgressSummary(
                    completed: completedCount,
                    total: widget.rounds.length,
                  ),
                ),
              ),

              // Round grid
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final round = widget.rounds[index];
                    final playable = _isPlayable(round);
                    final gatePayable = _isGatePayable(round);
                    final completed = _progress.isRoundCompleted(
                      widget.theme,
                      round.roundIndex,
                    );
                    return _StaggerIn(
                      index: index,
                      child: _RoundCard(
                        round: round,
                        isUnlocked: playable,
                        isCompleted: completed,
                        stars: _progress.getStars(
                          widget.theme,
                          round.roundIndex,
                        ),
                        gateCost: gatePayable
                            ? GateConfig.costFor(widget.theme, round.roundIndex)
                            : null,
                        isMapGate: gatePayable &&
                            GateConfig.isMapGate(
                                widget.theme, round.roundIndex),
                        gradientColors: widget.gradientForRound(
                          round.roundIndex,
                        ),
                        minFreq: minFreq,
                        maxFreq: maxFreq,
                        onTap: () => _onRoundTap(round),
                      ),
                    );
                  }, childCount: widget.rounds.length),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: isLandscape ? 8 : 12,
                    crossAxisSpacing: isLandscape ? 8 : 12,
                    childAspectRatio: childAspectRatio,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Coin Badge ──────────────────────────────────────────────────────────────

class _CoinBadge extends StatelessWidget {
  const _CoinBadge({required this.coins});
  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x33E8A33D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8A33D), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/ui/coin.png',
            width: 20,
            height: 20,
            errorBuilder: (_, _, _) => const Icon(
              Icons.monetization_on,
              color: Color(0xFFFFD700),
              size: 20,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$coins',
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Progress Summary ───────────────────────────────────────────────────────

class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({required this.completed, required this.total});

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : completed / total;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x33E8A33D), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'progress'.tr,
                style: const TextStyle(
                  color: Color(0xFFFFD98C),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              Text(
                'laps_completed'.trParams({
                  'completed': '$completed',
                  'total': '$total',
                }),
                style: const TextStyle(
                  color: Color(0xFFE8A33D),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(height: 8, color: const Color(0x33FFFFFF)),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: fraction.clamp(0.0, 1.0)),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => FractionallySizedBox(
                    widthFactor: value,
                    child: Container(
                      height: 8,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF8C1A), Color(0xFFFFD700)],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Staggered entrance wrapper ────────────────────────────────────────────

class _StaggerIn extends StatefulWidget {
  const _StaggerIn({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<_StaggerIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: 40 * widget.index), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ─── Difficulty Dots ────────────────────────────────────────────────────────

/// Small 1-5 dot indicator translating [RoundConfig.obstacleFrequency]
/// (scaled against this map's own min..max range) into an at-a-glance
/// difficulty rating.
class _DifficultyDots extends StatelessWidget {
  const _DifficultyDots({
    required this.frequency,
    required this.unlocked,
    required this.minFreq,
    required this.maxFreq,
  });

  final double frequency;
  final bool unlocked;
  final double minFreq;
  final double maxFreq;

  @override
  Widget build(BuildContext context) {
    final range = maxFreq - minFreq;
    final filled = range <= 0
        ? 5
        : (((frequency - minFreq) / range) * 5).round().clamp(1, 5);

    return Row(
      children: List.generate(5, (i) {
        final isFilled = i < filled;
        return Padding(
          padding: const EdgeInsets.only(right: 3),
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: !unlocked
                  ? const Color(0xFF3A2515)
                  : isFilled
                  ? const Color(0xFFFFD98C)
                  : Colors.white.withValues(alpha: 0.25),
            ),
          ),
        );
      }),
    );
  }
}

// ─── Round Card ──────────────────────────────────────────────────────────────

class _RoundCard extends StatefulWidget {
  const _RoundCard({
    required this.round,
    required this.isUnlocked,
    required this.isCompleted,
    required this.gradientColors,
    required this.minFreq,
    required this.maxFreq,
    required this.onTap,
    this.stars = 0,
    this.gateCost,
    this.isMapGate = false,
  });

  final RoundConfig round;
  final bool isUnlocked;
  final bool isCompleted;

  /// Best stars (0–3) earned on this round, shown on the card.
  final int stars;

  /// When non-null this round is behind a payable coin gate; the card shows a
  /// price + "AÇ" affordance instead of the plain "finish previous" lock.
  final int? gateCost;
  final bool isMapGate;
  final List<Color> gradientColors;
  final double minFreq;
  final double maxFreq;
  final VoidCallback onTap;

  @override
  State<_RoundCard> createState() => _RoundCardState();
}

class _RoundCardState extends State<_RoundCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.93,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final round = widget.round;
    final unlocked = widget.isUnlocked;
    final completed = widget.isCompleted;
    final gradientColors = widget.gradientColors;

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final padding = isLandscape ? 8.0 : 12.0;
    final circleSize = isLandscape ? 28.0 : 36.0;
    final circleFontSize = isLandscape ? 14.0 : 17.0;
    final titleFontSize = isLandscape ? 13.0 : 15.0;
    final checkIconSize = isLandscape ? 18.0 : 22.0;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isLandscape ? 14 : 18),
            gradient: unlocked
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  )
                : null,
            color: unlocked ? null : const Color(0xFF1C1207),
            border: Border.all(
              color: unlocked
                  ? gradientColors.last.withValues(alpha: 0.7)
                  : const Color(0xFF3A2A15),
              width: 1.5,
            ),
            boxShadow: unlocked
                ? [
                    BoxShadow(
                      color: gradientColors.first.withValues(alpha: 0.3),
                      blurRadius: 16,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              // Main content
              Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Round number
                    Row(
                      children: [
                        Container(
                          width: circleSize,
                          height: circleSize,
                          decoration: BoxDecoration(
                            color: unlocked
                                ? Colors.white.withValues(alpha: 0.2)
                                : const Color(0xFF2A1A0A),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${round.roundIndex}',
                              style: TextStyle(
                                color: unlocked
                                    ? Colors.white
                                    : const Color(0xFF4A3320),
                                fontWeight: FontWeight.w900,
                                fontSize: circleFontSize,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (widget.stars > 0)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (int i = 1; i <= 3; i++)
                                Icon(
                                  i <= widget.stars
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  color: i <= widget.stars
                                      ? const Color(0xFFFFD700)
                                      : Colors.white.withValues(alpha: 0.35),
                                  size: isLandscape ? 12 : 14,
                                ),
                            ],
                          )
                        else if (completed)
                          Icon(
                            Icons.check_circle_rounded,
                            color: const Color(0xFF76FF03),
                            size: checkIconSize,
                          ),
                      ],
                    ),

                    // Stats
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          round.title,
                          style: TextStyle(
                            color: unlocked
                                ? Colors.white
                                : const Color(0xFF4A3320),
                            fontWeight: FontWeight.w800,
                            fontSize: titleFontSize,
                            letterSpacing: isLandscape ? 1.0 : 1.5,
                          ),
                        ),
                        SizedBox(height: isLandscape ? 2 : 4),
                        Row(
                          children: [
                            Icon(
                              Icons.straight_rounded,
                              color: unlocked
                                  ? Colors.white70
                                  : const Color(0xFF3A2515),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${round.distanceMeters.toInt()} m',
                              style: TextStyle(
                                color: unlocked
                                    ? Colors.white70
                                    : const Color(0xFF3A2515),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.monetization_on_rounded,
                              color: unlocked
                                  ? const Color(0xFFFFD700)
                                  : const Color(0xFF3A2515),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${round.requiredCoins} / ${round.totalCoins}',
                              style: TextStyle(
                                color: unlocked
                                    ? const Color(0xFFFFD700)
                                    : const Color(0xFF3A2515),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _DifficultyDots(
                          frequency: round.obstacleFrequency,
                          unlocked: unlocked,
                          minFreq: widget.minFreq,
                          maxFreq: widget.maxFreq,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Play affordance for unlocked-but-not-yet-completed rounds
              if (unlocked && !completed)
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),

              // Locked overlay — either a payable coin gate (price + "AÇ") or a
              // plain progression lock ("finish previous round").
              if (!unlocked)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: Colors.black.withValues(
                        alpha: widget.gateCost != null ? 0.5 : 0.35,
                      ),
                    ),
                    child: Center(
                      child: widget.gateCost != null
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.isMapGate
                                      ? Icons.map_rounded
                                      : Icons.lock_open_rounded,
                                  color: const Color(0xFFFFD98C),
                                  size: 24,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      'assets/images/ui/coin.png',
                                      width: 14,
                                      height: 14,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.monetization_on,
                                        color: Color(0xFFFFD700),
                                        size: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${widget.gateCost}',
                                      style: const TextStyle(
                                        color: Color(0xFFFFD700),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.isMapGate
                                      ? 'unlock_map'.tr
                                      : 'unlock_short'.tr,
                                  style: const TextStyle(
                                    color: Color(0xFFFFD98C),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.lock_rounded,
                                  color: Color(0xFF8A6A3F),
                                  size: 26,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'complete_lap'.trParams({
                                    'lap': '${round.roundIndex - 1}',
                                  }),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF8A6A3F),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
