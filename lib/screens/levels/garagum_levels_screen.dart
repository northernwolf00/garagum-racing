import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/round_config.dart';
import '../../services/game_progress_service.dart';
import '../race_screen.dart';

/// Shown after selecting the Garagum map. Displays all 10 rounds with
/// lock/unlock state, coin requirements, and distance goals.
class GaragumLevelsScreen extends StatefulWidget {
  const GaragumLevelsScreen({super.key});

  @override
  State<GaragumLevelsScreen> createState() => _GaragumLevelsScreenState();
}

class _GaragumLevelsScreenState extends State<GaragumLevelsScreen>
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

  void _onRoundTap(RoundConfig round) {
    if (!_progress.isRoundUnlocked(round.roundIndex)) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => RaceScreen(roundConfig: round),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    ).then((_) => setState(() {})); // refresh on return
  }

  @override
  Widget build(BuildContext context) {
    final totalCoins = _progress.getTotalCoins();

    return Scaffold(
      backgroundColor: const Color(0xFF1A0E06),
      body: FadeTransition(
        opacity: _fade,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: const Color(0xFF1A0E06),
              pinned: true,
              expandedHeight: 120,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Color(0xFFFFD98C)),
                onPressed: () => Navigator.of(context).pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding:
                    const EdgeInsets.only(left: 60, bottom: 16),
                title: const Text(
                  'GARAGUM ÇÖLI',
                  style: TextStyle(
                    color: Color(0xFFFFD98C),
                    fontSize: 18,
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
                  padding:
                      const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                  child: _CoinBadge(coins: totalCoins),
                ),
              ],
            ),

            // Round grid
            SliverPadding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final round = RoundConfig.all[index];
                    final unlocked =
                        _progress.isRoundUnlocked(round.roundIndex);
                    final completed =
                        _progress.isRoundCompleted(round.roundIndex);
                    return _RoundCard(
                      round: round,
                      isUnlocked: unlocked,
                      isCompleted: completed,
                      onTap: () => _onRoundTap(round),
                    );
                  },
                  childCount: RoundConfig.all.length,
                ),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
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
            errorBuilder: (_, __, ___) => const Icon(
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

// ─── Round Card ──────────────────────────────────────────────────────────────

class _RoundCard extends StatefulWidget {
  const _RoundCard({
    required this.round,
    required this.isUnlocked,
    required this.isCompleted,
    required this.onTap,
  });

  final RoundConfig round;
  final bool isUnlocked;
  final bool isCompleted;
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
    _scale = Tween<double>(begin: 1.0, end: 0.93)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
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

    // Color theme per round difficulty
    final List<Color> gradientColors = _gradientForRound(round.roundIndex);

    return GestureDetector(
      onTapDown: (_) {
        if (unlocked) _ctrl.forward();
      },
      onTapUp: (_) {
        _ctrl.reverse();
        if (unlocked) widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
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
                    )
                  ]
                : null,
          ),
          child: Stack(
            children: [
              // Main content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Round number
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
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
                                fontSize: 17,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (!unlocked)
                          const Icon(Icons.lock_rounded,
                              color: Color(0xFF4A3320), size: 20),
                        if (completed)
                          const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF76FF03), size: 22),
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
                            fontSize: 15,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
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
                      ],
                    ),
                  ],
                ),
              ),

              // Locked overlay
              if (!unlocked)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: Colors.black.withValues(alpha: 0.3),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _gradientForRound(int idx) {
    const palettes = [
      [Color(0xFFE8A33D), Color(0xFF8B4A1A)],  // 1
      [Color(0xFFD4A017), Color(0xFF7A5500)],  // 2
      [Color(0xFFD35400), Color(0xFF6E2C00)],  // 3
      [Color(0xFFC0392B), Color(0xFF641E16)],  // 4
      [Color(0xFF8E44AD), Color(0xFF4A235A)],  // 5
      [Color(0xFF2980B9), Color(0xFF1A4A6B)],  // 6
      [Color(0xFF27AE60), Color(0xFF145A32)],  // 7
      [Color(0xFF16A085), Color(0xFF0A4D43)],  // 8
      [Color(0xFF2C3E50), Color(0xFF1A252F)],  // 9
      [Color(0xFFE74C3C), Color(0xFFC0392B)],  // 10
    ];
    final i = (idx - 1).clamp(0, palettes.length - 1);
    return palettes[i].cast<Color>();
  }
}
