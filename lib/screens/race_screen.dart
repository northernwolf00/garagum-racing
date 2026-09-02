import 'dart:math' as math;
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../game/garagum_racing_game.dart';
import '../game/input/pedal_button.dart';
import '../models/gate_config.dart';
import '../models/map_theme.dart';
import '../models/round_config.dart';
import '../services/ad_service.dart';
import '../services/analytics_service.dart';
import '../services/game_progress_service.dart';
import '../services/sfx.dart';
import 'levels/ashgabat_levels_screen.dart';
import 'levels/derweze_levels_screen.dart';
import 'levels/garagum_levels_screen.dart';
import 'levels/yangykala_levels_screen.dart';
import 'menu/menu_screen.dart';

/// Race screen. Receives [roundConfig] which controls distance, coin count
/// and obstacle difficulty for this particular round.
class RaceScreen extends StatefulWidget {
  const RaceScreen({super.key, required this.roundConfig});

  final RoundConfig roundConfig;

  @override
  State<RaceScreen> createState() => _RaceScreenState();
}

class _RaceScreenState extends State<RaceScreen> with TickerProviderStateMixin {
  late final GaragumRacingGame _game;

  bool _gasPressed = false;
  bool _brakePressed = false;
  bool _paused = false;
  bool _crashed = false;
  bool _finished = false;
  bool _outOfFuel = false;
  bool _roundSaved = false;

  /// How many of this run's collected coins have already been persisted to the
  /// player's total. [_saveCoins] only ever banks the *unsaved* delta, so it's
  /// safe to call on every run-ending path — and, crucially, coins collected
  /// after a "watch an ad to continue" refuel still get saved at the real end.
  int _savedCoinCount = 0;

  /// One rewarded refuel per run (the out-of-fuel "continue" offer).
  bool _fuelAdUsed = false;

  /// Set once the finish-screen "2x coins" reward has been granted.
  bool _coinsDoubled = false;

  /// Stars earned on this run (1–3) and any one-time star coin bonus paid,
  /// computed at the finish line and shown on the finish overlay.
  int _earnedStars = 0;
  int _starBonusCoins = 0;

  /// Guards _restart/_goToMenu/_goToLevels against being triggered more
  /// than once. Without this, mashing an overlay button (e.g. "restart"
  /// right after a crash) fires several overlapping Navigator transitions,
  /// each spinning up its own GaragumRacingGame — and their unordered,
  /// un-awaited SystemChrome.setPreferredOrientations() calls can resolve
  /// out of order, leaving the app stuck in landscape after backing out to
  /// the menu. It also avoids briefly rendering several heavy game
  /// instances at once, which is the likely cause of the blank/white
  /// screen after rapid repeated taps.
  bool _isNavigatingAway = false;

  // HUD animation
  late final AnimationController _hudCtrl;
  late final Animation<double> _hudFade;

  // Short camera-shake played on crash for extra impact.
  late final AnimationController _shakeCtrl;

  RoundConfig get _round => widget.roundConfig;

  /// Stable analytics id for this round, e.g. `garagum_3`.
  String get _levelId => '${_round.theme.name}_${_round.roundIndex}';

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Stop menu background music when game starts
    FlameAudio.bgm.stop();

    _game = GaragumRacingGame(roundConfig: _round);
    _game.onCrash = _onCarCrashed;
    _game.onFinish = _onRoundFinished;
    _game.onOutOfFuel = () {
      _gasPressed = false;
      _brakePressed = false;
      _saveCoins();
      AdService.instance.recordRunEnded();
      AnalyticsService.instance.logRaceEnd(
        _levelId,
        'out_of_fuel',
        coins: _game.coinNotifier.value,
      );
      // Use addPostFrameCallback so setState fires after the current build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _outOfFuel = true);
      });
    };

    _hudCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _hudFade = CurvedAnimation(parent: _hudCtrl, curve: Curves.easeOut);
    _hudCtrl.forward();

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    AnalyticsService.instance.logRaceStart(
      _levelId,
      GameProgressService.instance.getSelectedVehicle(),
    );
  }

  @override
  void dispose() {
    _game.audio.dispose();
    _hudCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _updateThrottle() {
    if (_crashed || _finished || _outOfFuel || _paused || _isNavigatingAway) {
      _game.setThrottle(0);
      return;
    }
    if (_gasPressed == _brakePressed) {
      _game.setThrottle(0);
    } else if (_gasPressed) {
      _game.setThrottle(1);
    } else {
      _game.setThrottle(-1);
    }
  }

  void _onCarCrashed() {
    _gasPressed = false;
    _brakePressed = false;
    _saveCoins();
    AdService.instance.recordRunEnded();
    AnalyticsService.instance.logRaceEnd(
      _levelId,
      'crash',
      coins: _game.coinNotifier.value,
    );
    // Crash feedback: sound + heavy haptic + a quick camera shake.
    Sfx.crash();
    _shakeCtrl.forward(from: 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _crashed = true);
    });
  }

  Future<void> _onRoundFinished() async {
    _gasPressed = false;
    _brakePressed = false;
    if (_roundSaved) return;
    _roundSaved = true;
    _earnedStars = _computeStars();
    // Await so the star bonus + updated balance are ready before the finish
    // overlay (which reads them) is shown. The await also defers setState off
    // the current game render frame.
    await _saveProgress();
    AdService.instance.recordRunEnded();
    AnalyticsService.instance.logRaceEnd(
      _levelId,
      'finish',
      coins: _game.coinNotifier.value,
    );
    Sfx.levelComplete();
    if (mounted) setState(() => _finished = true);
  }

  /// Persists whatever coins were collected this run to the player's total,
  /// no matter how the run ends. Every coin/crash/fuel path (crash, out of
  /// fuel, or a genuine finish) calls this exactly once via [_coinsSaved] —
  /// previously only a full finish saved coins, so a crash or running out
  /// of fuel silently discarded every coin collected that run.
  Future<void> _saveCoins() async {
    final collected = _game.coinNotifier.value;
    final delta = collected - _savedCoinCount;
    if (delta <= 0) return;
    _savedCoinCount = collected;
    await GameProgressService.instance.addCoins(delta);
  }

  /// Stars for a finished run: ⭐ reach the finish, ⭐⭐ collect the required
  /// coins (a genuine pass), ⭐⭐⭐ collect ≥90% of the road's coins (mastery).
  int _computeStars() {
    final collected = _game.coinNotifier.value;
    var stars = 1;
    if (collected >= _round.requiredCoins) stars = 2;
    if (collected >= (_round.totalCoins * 0.9).floor()) stars = 3;
    return stars;
  }

  /// Only reaching the actual finish line can mark a round completed and
  /// unlock the next one — matching [_round.requiredCoins] alone is not
  /// enough, the player still has to finish the road.
  Future<void> _saveProgress() async {
    await _saveCoins();
    final collected = _game.coinNotifier.value;
    if (collected >= _round.requiredCoins) {
      await GameProgressService.instance.completeRound(
        _round.theme,
        _round.roundIndex,
      );
    }
    // Award stars (best kept) and any one-time star coin bonus.
    _starBonusCoins = await GameProgressService.instance.recordStars(
      _round.theme,
      _round.roundIndex,
      _earnedStars,
      _round.totalCoins,
    );
  }

  void _togglePause() {
    setState(() => _paused = !_paused);
    if (_paused) {
      _game.setThrottle(0);
      _game.audio.stopEngine();
      _game.pauseEngine();
    } else {
      _game.resumeEngine();
    }
  }

  Future<void> _goToMenu() async {
    if (_isNavigatingAway) return;
    _isNavigatingAway = true;
    _game.setThrottle(0);
    _game.pauseEngine();
    await _game.audio.dispose();
    await AdService.instance.maybeShowInterstitial();
    if (!mounted) return;
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const MenuScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
      (route) => false,
    );
  }

  Future<void> _goToLevels() async {
    if (_isNavigatingAway) return;
    _isNavigatingAway = true;
    _game.setThrottle(0);
    _game.pauseEngine();
    await _game.audio.dispose();
    await AdService.instance.maybeShowInterstitial();
    if (!mounted) return;
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    if (!mounted) return;

    Widget levelsScreen;
    switch (_round.theme) {
      case MapTheme.garagum:
        levelsScreen = const GaragumLevelsScreen();
        break;
      case MapTheme.ashgabat:
        levelsScreen = const AshgabatLevelsScreen();
        break;
      case MapTheme.yangykala:
        levelsScreen = const YangykalaLevelsScreen();
        break;
      case MapTheme.derweze:
        levelsScreen = const DerwezeLevelsScreen();
        break;
    }

    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => levelsScreen,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
      (route) => false,
    );
  }

  Future<void> _restart() async {
    if (_isNavigatingAway) return;
    _isNavigatingAway = true;
    _game.setThrottle(0);
    _game.pauseEngine();
    await _game.audio.dispose();
    if (!mounted) return;
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => RaceScreen(roundConfig: _round),
        transitionDuration: Duration.zero,
      ),
    );
  }

  Future<void> _goToNextRound() async {
    final nextRound = RoundConfig.getRound(_round.theme, _round.roundIndex + 1);
    if (nextRound == null) {
      _goToLevels();
      return;
    }
    final unlocked = GameProgressService.instance.isRoundUnlocked(_round.theme, nextRound.roundIndex);
    if (!unlocked) {
      _goToLevels();
      return;
    }

    if (_isNavigatingAway) return;
    _isNavigatingAway = true;
    _game.setThrottle(0);
    _game.pauseEngine();
    await _game.audio.dispose();
    if (!mounted) return;
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => RaceScreen(roundConfig: nextRound),
        transitionDuration: Duration.zero,
      ),
    );
  }

  /// Out-of-fuel "watch an ad to keep driving" offer. On a completed reward it
  /// refuels the car and dismisses the overlay so the run continues from where
  /// it stalled. Allowed once per run.
  Future<void> _watchAdToContinue() async {
    if (_fuelAdUsed) return;
    final shown = await AdService.instance.showRewarded(
      onReward: () async {
        _fuelAdUsed = true;
        await _game.refuelAndResume();
        if (mounted) setState(() => _outOfFuel = false);
      },
    );
    if (!shown && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ad_not_ready'.tr),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Finish-screen "double your coins" offer. On a completed reward it banks a
  /// second copy of this run's coins to the player's total. Allowed once.
  Future<void> _watchAdToDoubleCoins() async {
    if (_coinsDoubled) return;
    final bonus = _game.coinNotifier.value;
    if (bonus <= 0) return;
    final shown = await AdService.instance.showRewarded(
      onReward: () async {
        _coinsDoubled = true;
        await GameProgressService.instance.addCoins(bonus);
        if (mounted) setState(() {});
      },
    );
    if (!shown && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ad_not_ready'.tr),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double currentThrottle = _game.throttleInput;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goToMenu();
      },
      child: Scaffold(
        body: Stack(
          children: [
            // ── Game canvas ──────────────────────────────────────────────
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _shakeCtrl,
                builder: (context, child) {
                  // Decaying shake: strong at impact, settles to zero. When the
                  // controller sits at 0 the offset is 0, so there is no cost.
                  final t = _shakeCtrl.value;
                  if (t == 0) return child!;
                  final damp = 1 - t;
                  final dx = math.sin(t * math.pi * 8) * 12 * damp;
                  final dy = math.cos(t * math.pi * 7) * 8 * damp;
                  return Transform.translate(
                    offset: Offset(dx, dy),
                    child: child,
                  );
                },
                child: GameWidget<GaragumRacingGame>(
                  game: _game,
                loadingBuilder: (context) => Container(
                  color: const Color(0xFF140A03),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 44,
                          height: 44,
                          child: CircularProgressIndicator(
                            strokeWidth: 3.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFFFF8C00),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'loading'.tr,
                          style: const TextStyle(
                            color: Color(0xFFFFD98C),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ),
              ),
            ),

            // ── HUD fade-in ──────────────────────────────────────────────
            FadeTransition(
              opacity: _hudFade,
              child: Stack(
                children: [
                  // ── Top Left Stack (Fuel, Coins, Distance) ─────────────
                  Positioned(
                    top: 12,
                    left: 16,
                    child: SafeArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Fuel bar — driven by ValueNotifier, no setState
                          ValueListenableBuilder<double>(
                            valueListenable: _game.fuelNotifier,
                            builder: (_, level, __) => _FuelBar(level: level),
                          ),
                          const SizedBox(height: 6),
                          // Coin counter — driven by ValueNotifier
                          ValueListenableBuilder<int>(
                            valueListenable: _game.coinNotifier,
                            builder: (_, count, __) => _CoinCounter(
                              collected: count,
                              required: _round.requiredCoins,
                              total: _round.totalCoins,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Distance progress (rebuilt only with setState on crash/finish)
                          _DistanceCounter(
                            current: _game.distance,
                            goal: _round.distanceMeters,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Top Right (Pause Button + Round Label) ─────────────
                  Positioned(
                    top: 12,
                    right: 16,
                    child: SafeArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _PauseButton(onTap: _togglePause),
                          const SizedBox(height: 6),
                          _RoundLabel(
                            roundIndex: _round.roundIndex,
                            totalRounds: RoundConfig.totalRoundsFor(
                              _round.theme,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Bottom Center (RPM & Boost Gauges) ─────────────────
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _DashboardGauges(
                        throttle: currentThrottle,
                        brakePressed: _brakePressed,
                        gasPressed: _gasPressed,
                      ),
                    ),
                  ),

                  // ── Bottom Left (Brake Pedal) ──────────────────────────
                  Positioned(
                    left: 20,
                    bottom: 12,
                    child: PedalButton(
                      width: 90,
                      assetPath: 'assets/images/ui/pedal_brake.png',
                      pressedAssetPath:
                          'assets/images/ui/pedal_brake_pressed.png',
                      onPressedChanged: (pressed) {
                        if (_crashed || _finished || _outOfFuel || _paused || _isNavigatingAway) return;
                        setState(() => _brakePressed = pressed);
                        _updateThrottle();
                        if (pressed) _game.audio.playButtonClick();
                      },
                    ),
                  ),

                  // ── Bottom Right (Gas Pedal) ───────────────────────────
                  Positioned(
                    right: 20,
                    bottom: 12,
                    child: PedalButton(
                      width: 90,
                      assetPath: 'assets/images/ui/pedal_gas.png',
                      pressedAssetPath:
                          'assets/images/ui/pedal_gas_pressed.png',
                      onPressedChanged: (pressed) {
                        if (_crashed || _finished || _outOfFuel || _paused || _isNavigatingAway) return;
                        setState(() => _gasPressed = pressed);
                        _updateThrottle();
                        if (pressed) _game.audio.playButtonClick();
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ── Out-of-Fuel overlay ──────────────────────────────────────
            if (_outOfFuel && !_crashed && !_finished)
              _OutOfFuelOverlay(
                onWatchAd: _fuelAdUsed ? null : _watchAdToContinue,
                onRestart: _restart,
                onLevels: _goToLevels,
                onMenu: _goToMenu,
              ),

            // ── Pause overlay ────────────────────────────────────────────
            if (_paused)
              _PauseOverlay(
                onResume: _togglePause,
                onRestart: _restart,
                onMenu: _goToMenu,
              ),

            // ── Crash overlay ─────────────────────────────────────────────
            if (_crashed && !_finished)
              _CrashOverlay(
                distanceMeters: _game.distance,
                coinsCollected: _game.coinNotifier.value,
                onRestart: _restart,
                onLevels: _goToLevels,
                onMenu: _goToMenu,
              ),

            // ── Finish overlay ─────────────────────────────────────────────
            if (_finished)
              _FinishOverlay(
                round: _round,
                coinsCollected: _game.coinNotifier.value,
                coinsDoubled: _coinsDoubled,
                stars: _earnedStars,
                starBonus: _starBonusCoins,
                onDoubleCoins: _watchAdToDoubleCoins,
                onNextLevel: _goToNextRound,
                onLevels: _goToLevels,
                onRestart: _restart,
                onMenu: _goToMenu,
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Round Label ──────────────────────────────────────────────────────────────

class _RoundLabel extends StatelessWidget {
  const _RoundLabel({required this.roundIndex, required this.totalRounds});
  final int roundIndex;
  final int totalRounds;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white30, width: 1),
      ),
      child: Text(
        'lap_progress'.trParams({
          'current': '$roundIndex',
          'total': '$totalRounds',
        }),
        style: const TextStyle(
          color: Color(0xFFFFD98C),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

// ─── Coin Counter ─────────────────────────────────────────────────────────────

class _CoinCounter extends StatelessWidget {
  const _CoinCounter({
    required this.collected,
    required this.required,
    required this.total,
  });

  final int collected;
  final int required;
  final int total;

  @override
  Widget build(BuildContext context) {
    final enough = collected >= required;
    return Row(
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
          '$collected / $required',
          style: TextStyle(
            color: enough ? const Color(0xFF76FF03) : const Color(0xFFFFD700),
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            shadows: const [
              Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Distance Counter ────────────────────────────────────────────────────────

class _DistanceCounter extends StatelessWidget {
  const _DistanceCounter({required this.current, required this.goal});
  final double current;
  final double goal;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          'assets/images/ui/icon_distance.png',
          width: 20,
          height: 20,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.straighten, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 8),
        Text(
          '${current.floor()} / ${goal.toInt()} m',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            shadows: [
              Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Fuel Bar ─────────────────────────────────────────────────────────────────

class _FuelBar extends StatelessWidget {
  final double level;

  const _FuelBar({required this.level});

  @override
  Widget build(BuildContext context) {
    // Color changes: green > yellow > red as fuel drops
    final List<Color> fillColors = level > 0.5
        ? [const Color(0xFF76FF03), const Color(0xFFC6FF00)]
        : level > 0.25
        ? [const Color(0xFFFFD700), const Color(0xFFFFA000)]
        : [const Color(0xFFFF3300), const Color(0xFFFF6600)];

    return Row(
      children: [
        Image.asset(
          'assets/images/ui/icon_fuel.png',
          width: 22,
          height: 22,
          errorBuilder: (_, __, ___) => Icon(
            Icons.local_gas_station,
            color: level > 0.25 ? const Color(0xFFFF3333) : Colors.red,
            size: 22,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          width: 110,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: level <= 0.2 ? Colors.red : Colors.white70,
              width: level <= 0.2 ? 2.0 : 1.5,
            ),
          ),
          padding: const EdgeInsets.all(2),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: level.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(colors: fillColors),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Pause Button ─────────────────────────────────────────────────────────────

class _PauseButton extends StatefulWidget {
  final VoidCallback onTap;
  const _PauseButton({required this.onTap});

  @override
  State<_PauseButton> createState() => _PauseButtonState();
}

class _PauseButtonState extends State<_PauseButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.88,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white60, width: 1.5),
          ),
          child: Center(
            child: Image.asset(
              'assets/images/ui/btn_pause.png',
              width: 26,
              height: 26,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.pause_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Dashboard Gauges ─────────────────────────────────────────────────────────

class _DashboardGauges extends StatelessWidget {
  final double throttle;
  final bool brakePressed;
  final bool gasPressed;

  const _DashboardGauges({
    required this.throttle,
    required this.brakePressed,
    required this.gasPressed,
  });

  @override
  Widget build(BuildContext context) {
    final rpmFactor =
        (throttle.abs() * 0.85 + (gasPressed || brakePressed ? 0.15 : 0.0))
            .clamp(0.0, 1.0);
    final rpmAngle = (-120 + rpmFactor * 240) * (math.pi / 180);

    final boostFactor = (gasPressed ? 0.9 : (brakePressed ? 0.4 : 0.0)).clamp(
      0.0,
      1.0,
    );
    final boostAngle = (-120 + boostFactor * 240) * (math.pi / 180);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _GaugeWidget(
          gaugeAsset: 'assets/images/ui/gauge_rpm.png',
          needleAsset: 'assets/images/ui/gauge_needle.png',
          needleAngle: rpmAngle,
          size: 72,
        ),
        const SizedBox(width: 12),
        _GaugeWidget(
          gaugeAsset: 'assets/images/ui/gauge_boost.png',
          needleAsset: 'assets/images/ui/gauge_needle.png',
          needleAngle: boostAngle,
          size: 72,
        ),
      ],
    );
  }
}

class _GaugeWidget extends StatelessWidget {
  final String gaugeAsset;
  final String needleAsset;
  final double needleAngle;
  final double size;

  const _GaugeWidget({
    required this.gaugeAsset,
    required this.needleAsset,
    required this.needleAngle,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            gaugeAsset,
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black54,
                border: Border.all(color: Colors.white30, width: 2),
              ),
            ),
          ),
          Transform.rotate(
            angle: needleAngle,
            child: Image.asset(
              needleAsset,
              width: size * 0.75,
              height: size * 0.75,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  Container(width: 2, height: size * 0.35, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Out-of-Fuel Overlay ──────────────────────────────────────────────────────

class _OutOfFuelOverlay extends StatelessWidget {
  /// Null once the free refuel has already been used this run — the ad button
  /// is then hidden.
  final VoidCallback? onWatchAd;
  final VoidCallback onRestart;
  final VoidCallback onLevels;
  final VoidCallback onMenu;

  const _OutOfFuelOverlay({
    required this.onWatchAd,
    required this.onRestart,
    required this.onLevels,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.82),
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0A00),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFF8C00), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF8C00).withValues(alpha: 0.25),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0x33FF8C00),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFF8C00),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/ui/icon_fuel.png',
                      width: 30,
                      height: 30,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.local_gas_station,
                        color: Color(0xFFFF8C00),
                        size: 30,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFFF8C00), Color(0xFFFFD700)],
                  ).createShader(bounds),
                  child: Text(
                    'out_of_fuel'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'fuel_hint'.tr,
                  style: const TextStyle(color: Color(0xFFFFD98C), fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Rewarded "watch an ad to keep driving" — the highest-value
                // placement, shown once per run.
                if (onWatchAd != null) ...[
                  _RewardedAdButton(
                    label: 'watch_ad_continue'.tr,
                    icon: Icons.local_gas_station_rounded,
                    onTap: onWatchAd!,
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    Expanded(
                      child: _OverlayBtn(
                        label: 'retry'.tr,
                        icon: Icons.replay_rounded,
                        primary: true,
                        onTap: onRestart,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _OverlayBtn(
                        label: 'laps'.tr,
                        icon: Icons.list_rounded,
                        primary: false,
                        onTap: onLevels,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _OverlayBtn(
                        label: 'menu'.tr,
                        icon: Icons.home_rounded,
                        primary: false,
                        onTap: onMenu,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Pause Overlay ────────────────────────────────────────────────────────────

class _PauseOverlay extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onMenu;

  const _PauseOverlay({
    required this.onResume,
    required this.onRestart,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1C0E06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x55E8A33D), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE8601A).withValues(alpha: 0.15),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0x55E8A33D),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'paused'.tr,
                  style: const TextStyle(
                    color: Color(0xFFFFD98C),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _OverlayBtn(
                        label: 'resume'.tr,
                        icon: Icons.play_arrow_rounded,
                        primary: true,
                        onTap: onResume,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _OverlayBtn(
                        label: 'retry'.tr,
                        icon: Icons.replay_rounded,
                        primary: false,
                        onTap: onRestart,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _OverlayBtn(
                        label: 'menu'.tr,
                        icon: Icons.home_rounded,
                        primary: false,
                        onTap: onMenu,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Crash Overlay ────────────────────────────────────────────────────────────

class _CrashOverlay extends StatelessWidget {
  final double distanceMeters;
  final int coinsCollected;
  final VoidCallback onRestart;
  final VoidCallback onLevels;
  final VoidCallback onMenu;

  const _CrashOverlay({
    required this.distanceMeters,
    required this.coinsCollected,
    required this.onRestart,
    required this.onLevels,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.82),
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1F0C05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFF5500), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF4500).withValues(alpha: 0.25),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0x33FF4500),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFF5500),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFFF5500),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 8),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFFF4500), Color(0xFFFF8C1A)],
                  ).createShader(bounds),
                  child: Text(
                    'you_flipped'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'your_distance'.trParams({'m': '${distanceMeters.floor()}'}),
                      style: const TextStyle(
                        color: Color(0xFFFFD98C),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Image.asset(
                      'assets/images/ui/coin.png',
                      width: 16,
                      height: 16,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.monetization_on,
                        color: Color(0xFFFFD700),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'collected'.trParams({'n': '$coinsCollected'}),
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _OverlayBtn(
                        label: 'retry'.tr,
                        icon: Icons.replay_rounded,
                        primary: true,
                        onTap: onRestart,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _OverlayBtn(
                        label: 'laps'.tr,
                        icon: Icons.list_rounded,
                        primary: false,
                        onTap: onLevels,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _OverlayBtn(
                        label: 'menu'.tr,
                        icon: Icons.home_rounded,
                        primary: false,
                        onTap: onMenu,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Finish Overlay ──────────────────────────────────────────────────────────

class _FinishOverlay extends StatefulWidget {
  const _FinishOverlay({
    required this.round,
    required this.coinsCollected,
    required this.coinsDoubled,
    required this.stars,
    required this.starBonus,
    required this.onDoubleCoins,
    required this.onLevels,
    required this.onRestart,
    required this.onMenu,
    this.onNextLevel,
  });

  final RoundConfig round;
  final int coinsCollected;
  final bool coinsDoubled;

  /// Stars earned this run (1–3) and the one-time coin bonus they paid.
  final int stars;
  final int starBonus;
  final VoidCallback onDoubleCoins;
  final VoidCallback onLevels;
  final VoidCallback onRestart;
  final VoidCallback onMenu;
  final VoidCallback? onNextLevel;

  @override
  State<_FinishOverlay> createState() => _FinishOverlayState();
}

class _FinishOverlayState extends State<_FinishOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final AnimationController _coinCtrl;
  late final Animation<double> _scale;
  late final Animation<double> _coinCount;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _coinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scale = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);
    _coinCount = Tween<double>(
      begin: 0,
      end: widget.coinsCollected.toDouble(),
    ).animate(CurvedAnimation(parent: _coinCtrl, curve: Curves.easeOut));

    _scaleCtrl.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _coinCtrl.forward();
    });
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _coinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final passed = widget.coinsCollected >= widget.round.requiredCoins;
    final nextUnlocked =
        passed &&
        widget.round.roundIndex <
            RoundConfig.totalRoundsFor(widget.round.theme);
    final nextGate = GameProgressService.instance.nextUnpaidGate();
    final balance = GameProgressService.instance.getTotalCoins();

    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: ScaleTransition(
            scale: _scale,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1F0D),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: passed
                      ? const Color(0xFF76FF03)
                      : const Color(0xFFFF8C1A),
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        (passed
                                ? const Color(0xFF76FF03)
                                : const Color(0xFFFF8C1A))
                            .withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon + Title Row (compact landscape design)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: passed
                              ? const Color(0x2276FF03)
                              : const Color(0x22FF8C1A),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          passed
                              ? Icons.emoji_events_rounded
                              : Icons.sports_score_rounded,
                          color: passed
                              ? const Color(0xFFFFD700)
                              : const Color(0xFFFF8C1A),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: passed
                                  ? [
                                      const Color(0xFF76FF03),
                                      const Color(0xFFCCFF00),
                                    ]
                                  : [
                                      const Color(0xFFFF8C1A),
                                      const Color(0xFFFFD700),
                                    ],
                            ).createShader(bounds),
                            child: Text(
                              passed ? 'completed'.tr : 'lap_over'.tr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3,
                              ),
                            ),
                          ),
                          Text(
                            widget.round.title,
                            style: const TextStyle(
                              color: Color(0xFFFFD98C),
                              fontSize: 12,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Coin count animated & status row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _coinCount,
                        builder: (_, __) => Row(
                          children: [
                            Image.asset(
                              'assets/images/ui/coin.png',
                              width: 28,
                              height: 28,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.monetization_on,
                                color: Color(0xFFFFD700),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '+${_coinCount.value.toInt()}',
                              style: const TextStyle(
                                color: Color(0xFFFFD700),
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              passed
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              color: passed
                                  ? const Color(0xFF76FF03)
                                  : const Color(0xFFFF4500),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              (passed ? 'coins_passed' : 'coins_not_enough')
                                  .trParams({
                                'collected': '${widget.coinsCollected}',
                                'required': '${widget.round.requiredCoins}',
                              }),
                              style: TextStyle(
                                color: passed
                                    ? const Color(0xFF76FF03)
                                    : const Color(0xFFFF6B35),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Stars earned this run (best is kept across replays)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 1; i <= 3; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Icon(
                            i <= widget.stars
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: i <= widget.stars
                                ? const Color(0xFFFFD700)
                                : const Color(0xFF4A3320),
                            size: 32,
                          ),
                        ),
                      if (widget.starBonus > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x33FFD700),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+${widget.starBonus}',
                            style: const TextStyle(
                              color: Color(0xFFFFD700),
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // "Az galdy" — progress toward the next coin gate
                  if (nextGate != null) ...[
                    const SizedBox(height: 10),
                    _NextGateBar(gate: nextGate, balance: balance),
                  ],

                  // Next round unlocked notice
                  if (nextUnlocked) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x3376FF03),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF76FF03),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.lock_open_rounded,
                            color: Color(0xFF76FF03),
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'lap_unlocked'.trParams(
                                {'lap': '${widget.round.roundIndex + 1}'}),
                            style: const TextStyle(
                              color: Color(0xFF76FF03),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Rewarded "double your coins" — offered once, only when
                  // there are coins to double.
                  if (widget.coinsCollected > 0) ...[
                    const SizedBox(height: 12),
                    if (widget.coinsDoubled)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x3376FF03),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF76FF03)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: Color(0xFF76FF03), size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'coins_doubled'.tr,
                              style: const TextStyle(
                                color: Color(0xFF76FF03),
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      _RewardedAdButton(
                        label: 'watch_ad_double'.tr,
                        icon: Icons.monetization_on_rounded,
                        onTap: widget.onDoubleCoins,
                      ),
                  ],

                  const SizedBox(height: 16),

                  // Action Buttons Row (Responsive & Compact)
                  Row(
                    children: [
                      if (nextUnlocked && widget.onNextLevel != null) ...[
                        Expanded(
                          flex: 5,
                          child: _OverlayBtn(
                            label: 'next_lap'.tr,
                            icon: Icons.play_arrow_rounded,
                            primary: true,
                            onTap: widget.onNextLevel!,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        flex: 4,
                        child: _OverlayBtn(
                          label: 'laps'.tr,
                          icon: Icons.list_rounded,
                          primary: !nextUnlocked,
                          onTap: widget.onLevels,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 4,
                        child: _OverlayBtn(
                          label: 'retry'.tr,
                          icon: Icons.replay_rounded,
                          primary: false,
                          onTap: widget.onRestart,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 4,
                        child: _OverlayBtn(
                          label: 'menu'.tr,
                          icon: Icons.home_rounded,
                          primary: false,
                          onTap: widget.onMenu,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Rewarded Ad Button ───────────────────────────────────────────────────────

/// Full-width call-to-action for opt-in rewarded ads, with a small "AD" badge
/// so players always know a video is coming. Visually distinct (green→gold)
/// from the regular navigation buttons.
class _RewardedAdButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _RewardedAdButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0xFF4CAF14), Color(0xFF9CCC00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: const Color(0xFFCCFF33), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF76FF03).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'AD',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.8,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared Button ───────────────────────────────────────────────────────────

class _OverlayBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool primary;
  final VoidCallback onTap;

  const _OverlayBtn({
    required this.label,
    required this.icon,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: primary
              ? const LinearGradient(
                  colors: [Color(0xFFFF8C1A), Color(0xFFE85A00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: primary ? null : const Color(0x22E8A33D),
          border: Border.all(
            color: primary ? const Color(0xFFFFAA44) : const Color(0x44E8A33D),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: primary ? Colors.white : const Color(0xFFE8A33D),
              size: 18,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: primary ? Colors.white : const Color(0xFFE8A33D),
                  letterSpacing: 1.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Next-gate "az galdy" progress bar ──────────────────────────────────────

/// Shows how close the player is to affording the next coin gate — the
/// near-miss nudge from the monetisation plan ("14 300 / 20 000 — ýene azajyk").
class _NextGateBar extends StatelessWidget {
  const _NextGateBar({required this.gate, required this.balance});

  final GateInfo gate;
  final int balance;

  String get _label {
    if (gate.isMapGate) {
      switch (gate.theme) {
        case MapTheme.garagum:
          return 'map_garagum_short'.tr;
        case MapTheme.ashgabat:
          return 'map_ashgabat_short'.tr;
        case MapTheme.yangykala:
          return 'map_yangykala_short'.tr;
        case MapTheme.derweze:
          return 'map_derweze_short'.tr;
      }
    }
    return 'gate_lap'.trParams({'round': '${gate.round}'});
  }

  @override
  Widget build(BuildContext context) {
    final frac = (balance / gate.cost).clamp(0.0, 1.0);
    final remaining = (gate.cost - balance).clamp(0, gate.cost);
    final ready = balance >= gate.cost;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x33E8A33D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  ready
                      ? 'gate_ready'.trParams({'label': _label})
                      : 'gate_to_unlock'.trParams({'label': _label}),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFFFD98C),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$balance / ${gate.cost}',
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 6, color: const Color(0x22FFFFFF)),
                FractionallySizedBox(
                  widthFactor: frac,
                  child: Container(
                    height: 6,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF8C1A), Color(0xFFFFD700)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!ready) ...[
            const SizedBox(height: 4),
            Text(
              'more_coins'.trParams({'n': '$remaining'}),
              style: const TextStyle(
                color: Color(0xFF8A6A3F),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
