import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/garagum_racing_game.dart';
import '../game/input/pedal_button.dart';
import 'menu/menu_screen.dart';

/// Race screen: full physics game + HUD overlay (pedals, pause, fuel gauge,
/// distance counter). Landscape mode.
class RaceScreen extends StatefulWidget {
  const RaceScreen({super.key});

  @override
  State<RaceScreen> createState() => _RaceScreenState();
}

class _RaceScreenState extends State<RaceScreen> with TickerProviderStateMixin {
  late final GaragumRacingGame _game;

  bool _gasPressed = false;
  bool _brakePressed = false;
  bool _paused = false;

  // HUD animation
  late final AnimationController _hudCtrl;
  late final Animation<double> _hudFade;

  @override
  void initState() {
    super.initState();

    // Lock to landscape mode when game starts
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _game = GaragumRacingGame();

    _hudCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _hudFade = CurvedAnimation(parent: _hudCtrl, curve: Curves.easeOut);
    _hudCtrl.forward();
  }

  @override
  void dispose() {
    // Switch back to portrait when exiting race
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    _game.audio.dispose();
    _hudCtrl.dispose();
    super.dispose();
  }

  void _updateThrottle() {
    if (_gasPressed == _brakePressed) {
      _game.setThrottle(0);
    } else if (_gasPressed) {
      _game.setThrottle(1);
    } else {
      _game.setThrottle(-1);
    }
  }

  void _togglePause() {
    setState(() => _paused = !_paused);
    if (_paused) {
      _game.pauseEngine();
    } else {
      _game.resumeEngine();
    }
  }

  void _goToMenu() {
    _game.pauseEngine();
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const MenuScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (route) => false,
    );
  }

  void _restart() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const RaceScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Game canvas ──────────────────────────────────────────────
          Positioned.fill(child: GameWidget(game: _game)),

          // ── HUD fade-in ──────────────────────────────────────────────
          FadeTransition(
            opacity: _hudFade,
            child: Stack(
              children: [
                // Top bar: pause button + distance
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        // Pause button
                        _HudButton(
                          assetPath: 'assets/images/ui/btn_pause.png',
                          fallbackIcon: Icons.pause_rounded,
                          onTap: _togglePause,
                        ),
                        const SizedBox(width: 10),
                        // Distance badge
                        _DistanceBadge(game: _game),
                        const Spacer(),
                        // Coin counter
                        _HudCoinBadge(coins: 0),
                      ],
                    ),
                  ),
                ),

                // Fuel gauge — bottom center
                Positioned(
                  bottom: 48,
                  left: 0,
                  right: 0,
                  child: Center(child: _FuelGauge(level: 1.0)),
                ),

                // ── Brake pedal (LEFT) ──────────────────────────────────
                Positioned(
                  left: 16,
                  bottom: 28,
                  child: PedalButton(
                    assetPath: 'assets/images/ui/pedal_brake.png',
                    pressedAssetPath: 'assets/images/ui/pedal_brake_pressed.png',
                    onPressedChanged: (pressed) {
                      _brakePressed = pressed;
                      _updateThrottle();
                      if (pressed) _game.audio.playButtonClick();
                    },
                  ),
                ),

                // ── Gas pedal (RIGHT) ───────────────────────────────────
                Positioned(
                  right: 16,
                  bottom: 28,
                  child: PedalButton(
                    assetPath: 'assets/images/ui/pedal_gas.png',
                    pressedAssetPath: 'assets/images/ui/pedal_gas_pressed.png',
                    onPressedChanged: (pressed) {
                      _gasPressed = pressed;
                      _updateThrottle();
                      if (pressed) _game.audio.playButtonClick();
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── Pause overlay ────────────────────────────────────────────
          if (_paused)
            _PauseOverlay(
              onResume: _togglePause,
              onRestart: _restart,
              onMenu: _goToMenu,
            ),
        ],
      ),
    );
  }
}

// ─── HUD Button ───────────────────────────────────────────────────────────────

class _HudButton extends StatefulWidget {
  final String assetPath;
  final IconData fallbackIcon;
  final VoidCallback onTap;

  const _HudButton({
    required this.assetPath,
    required this.fallbackIcon,
    required this.onTap,
  });

  @override
  State<_HudButton> createState() => _HudButtonState();
}

class _HudButtonState extends State<_HudButton>
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
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
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
            color: const Color(0x88000000),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x55E8A33D), width: 1.5),
          ),
          child: Center(
            child: Image.asset(
              widget.assetPath,
              width: 24,
              height: 24,
              errorBuilder: (_, __, ___) => Icon(
                widget.fallbackIcon,
                color: const Color(0xFFE8A33D),
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Distance Badge ───────────────────────────────────────────────────────────

class _DistanceBadge extends StatefulWidget {
  final GaragumRacingGame game;
  const _DistanceBadge({required this.game});

  @override
  State<_DistanceBadge> createState() => _DistanceBadgeState();
}

class _DistanceBadgeState extends State<_DistanceBadge> {
  // Distance tracking will be wired up when the game exposes it.
  // For now shows 0 m.
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x88000000),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x44E8A33D), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/ui/icon_distance.png',
            width: 16,
            height: 16,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.straighten,
              color: Color(0xFFE8A33D),
              size: 16,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            '0 m',
            style: TextStyle(
              color: Color(0xFFFFD98C),
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── HUD Coin Badge ───────────────────────────────────────────────────────────

class _HudCoinBadge extends StatelessWidget {
  final int coins;
  const _HudCoinBadge({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x88000000),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x44E8A33D), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/ui/coin.png',
            width: 16,
            height: 16,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.monetization_on,
              color: Color(0xFFFFD98C),
              size: 16,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$coins',
            style: const TextStyle(
              color: Color(0xFFFFD98C),
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Fuel Gauge ───────────────────────────────────────────────────────────────

class _FuelGauge extends StatelessWidget {
  final double level; // 0.0 – 1.0
  const _FuelGauge({required this.level});

  @override
  Widget build(BuildContext context) {
    final color = level > 0.3
        ? Color.lerp(const Color(0xFFFFD700), const Color(0xFF44FF88), level)!
        : const Color(0xFFFF3300);

    return Container(
      width: 140,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0x88000000),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x55E8A33D), width: 1),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(5),
            child: Image.asset(
              'assets/images/ui/icon_fuel.png',
              width: 18,
              height: 18,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.local_gas_station,
                color: Color(0xFFE8A33D),
                size: 16,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0x33FFFFFF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: level.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(color: color.withOpacity(0.5), blurRadius: 6),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
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
      color: Colors.black.withOpacity(0.75),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF1C0E06),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0x55E8A33D), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE8601A).withOpacity(0.15),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0x55E8A33D),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'DURALDY',
                style: TextStyle(
                  color: Color(0xFFFFD98C),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(height: 28),
              _PauseBtn(
                label: 'DOWAM ET',
                icon: Icons.play_arrow_rounded,
                primary: true,
                onTap: onResume,
              ),
              const SizedBox(height: 12),
              _PauseBtn(
                label: 'TÄZEDEN',
                icon: Icons.replay_rounded,
                primary: false,
                onTap: onRestart,
              ),
              const SizedBox(height: 12),
              _PauseBtn(
                label: 'BAŞ MENÝU',
                icon: Icons.home_rounded,
                primary: false,
                onTap: onMenu,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PauseBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool primary;
  final VoidCallback onTap;

  const _PauseBtn({
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
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: primary
              ? const LinearGradient(
                  colors: [Color(0xFFFF8C1A), Color(0xFFE85A00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: primary ? null : const Color(0x22E8A33D),
          border: Border.all(
            color: primary
                ? const Color(0xFFFFAA44)
                : const Color(0x44E8A33D),
            width: 1.5,
          ),
          boxShadow: primary
              ? [
                  BoxShadow(
                    color: const Color(0xFFE85A00).withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: primary ? Colors.white : const Color(0xFFE8A33D),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: primary ? Colors.white : const Color(0xFFE8A33D),
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
