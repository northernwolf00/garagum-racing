import 'package:flutter/material.dart';

import '../levels/garagum_levels_screen.dart';
import '../menu/menu_screen.dart';

class GameOverScreen extends StatefulWidget {
  final double distanceMeters;
  final int coinsCollected;

  const GameOverScreen({
    super.key,
    this.distanceMeters = 0,
    this.coinsCollected = 0,
  });

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen>
    with TickerProviderStateMixin {
  late final AnimationController _panelCtrl;
  late final AnimationController _statsCtrl;
  late final Animation<double> _panelFade;
  late final Animation<Offset> _panelSlide;
  late final Animation<double> _statsFade;

  @override
  void initState() {
    super.initState();

    _panelCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _statsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _panelFade = CurvedAnimation(parent: _panelCtrl, curve: Curves.easeOut);
    _panelSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _panelCtrl, curve: Curves.easeOutCubic));
    _statsFade = CurvedAnimation(parent: _statsCtrl, curve: Curves.easeOut);

    _panelCtrl.forward();
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _statsCtrl.forward();
    });
  }

  @override
  void dispose() {
    _panelCtrl.dispose();
    _statsCtrl.dispose();
    super.dispose();
  }

  void _restart() {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, animation, _) => const GaragumLevelsScreen(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (route) => false,
    );
  }

  void _goMenu() {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, animation, _) => const MenuScreen(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Dark desert background gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [Color(0xFF2A1006), Color(0xFF0A0402)],
                ),
              ),
            ),
          ),

          // Dust particles effect (static decorative dots)
          Positioned.fill(child: CustomPaint(painter: _DustPainter())),

          // Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),

                // GAME OVER title
                FadeTransition(
                  opacity: _panelFade,
                  child: SlideTransition(
                    position: _panelSlide,
                    child: Column(
                      children: [
                        Text(
                          'OÝUN',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 10,
                            foreground: Paint()
                              ..shader = const LinearGradient(
                                colors: [Color(0xFFFF4500), Color(0xFFFF8C1A)],
                              ).createShader(
                                  const Rect.fromLTWH(0, 0, 200, 60)),
                            shadows: const [
                              Shadow(
                                color: Color(0xAAFF4500),
                                blurRadius: 30,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'GUTARDY',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 12,
                            foreground: Paint()
                              ..shader = const LinearGradient(
                                colors: [Color(0xFFFF8C1A), Color(0xFFFFD98C)],
                              ).createShader(
                                  const Rect.fromLTWH(0, 0, 200, 45)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Stats panel
                FadeTransition(
                  opacity: _statsFade,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0x22E8A33D),
                      borderRadius: BorderRadius.circular(24),
                      border:
                          Border.all(color: const Color(0x44E8A33D), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE8601A).withValues(alpha: 0.08),
                          blurRadius: 40,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'NETIJELERIŇ',
                          style: TextStyle(
                            color: Color(0xFF886633),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _StatRow(
                          icon: 'assets/images/ui/icon_distance.png',
                          fallbackIcon: Icons.straighten,
                          label: 'ARALYGY',
                          value:
                              '${widget.distanceMeters.toStringAsFixed(0)} m',
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: Color(0x22E8A33D), height: 1),
                        ),
                        _StatRow(
                          icon: 'assets/images/ui/coin.png',
                          fallbackIcon: Icons.monetization_on,
                          label: 'TEŇŇELER',
                          value: '${widget.coinsCollected}',
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Buttons
                FadeTransition(
                  opacity: _statsFade,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        _GameOverButton(
                          label: 'TÄZEDEN OÝNA',
                          icon: Icons.replay_rounded,
                          primary: true,
                          onTap: _restart,
                        ),
                        const SizedBox(height: 14),
                        _GameOverButton(
                          label: 'BAŞ MENÝU',
                          icon: Icons.home_rounded,
                          primary: false,
                          onTap: _goMenu,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dust Painter ─────────────────────────────────────────────────────────────

class _DustPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (int i = 0; i < 80; i++) {
      final x = ((i * 173.1) % 100) / 100 * size.width;
      final y = ((i * 89.7) % 100) / 100 * size.height;
      final r = 0.5 + (i % 4) * 0.7;
      final opacity = 0.04 + (i % 6) * 0.025;
      paint.color = const Color(0xFFFF8C1A).withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Stat Row ─────────────────────────────────────────────────────────────────

class _StatRow extends StatelessWidget {
  final String icon;
  final IconData fallbackIcon;
  final String label;
  final String value;

  const _StatRow({
    required this.icon,
    required this.fallbackIcon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          icon,
          width: 28,
          height: 28,
          errorBuilder: (_, _, _) => Icon(
            fallbackIcon,
            color: const Color(0xFFE8A33D),
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF886633),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFFFD98C),
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

// ─── Game Over Button ─────────────────────────────────────────────────────────

class _GameOverButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool primary;
  final VoidCallback onTap;

  const _GameOverButton({
    required this.label,
    required this.icon,
    required this.primary,
    required this.onTap,
  });

  @override
  State<_GameOverButton> createState() => _GameOverButtonState();
}

class _GameOverButtonState extends State<_GameOverButton>
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
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
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
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: widget.primary
                ? const LinearGradient(
                    colors: [Color(0xFFFF8C1A), Color(0xFFE85A00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: widget.primary ? null : const Color(0x22E8A33D),
            border: Border.all(
              color: widget.primary
                  ? const Color(0xFFFFAA44)
                  : const Color(0x44E8A33D),
              width: 1.5,
            ),
            boxShadow: widget.primary
                ? [
                    BoxShadow(
                      color: const Color(0xFFE85A00).withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                color: widget.primary ? Colors.white : const Color(0xFFE8A33D),
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: widget.primary
                      ? Colors.white
                      : const Color(0xFFE8A33D),
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
