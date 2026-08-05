import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/game_progress_service.dart';
import '../levels/ashgabat_levels_screen.dart';
import '../levels/garagum_levels_screen.dart';
import '../garage/garage_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with TickerProviderStateMixin {
  late final AnimationController _titleController;
  late final AnimationController _duneController;
  late final AnimationController _buttonsController;

  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _buttonsFade;
  late final Animation<Offset> _buttonsSlide;

  late final PageController _mapPageController;
  int _selectedMapIndex = 0;
  int _totalCoins = 0;
  bool _soundOn = true;

  final List<_MapItem> _maps = const [
    _MapItem(
      id: 'garagum',
      title: 'Garagum çöli',
      subtitle: 'Geniş çägelikler hem gum gerişleri',
      assetPath: 'assets/images/ui/map_card_garagum.png',
      isUnlocked: true,
      badgeText: 'AÇYK',
      gradientColors: [Color(0xFFE8A33D), Color(0xFF8B4A1A)],
    ),
    _MapItem(
      id: 'ashgabat',
      title: 'Aşgabat',
      subtitle: 'Ak mermer köçeler hem belent binalar',
      assetPath: '',
      isUnlocked: true,
      badgeText: 'AÇYK',
      gradientColors: [Color(0xFF79BEE4), Color(0xFF2C6B8A)],
    ),
    _MapItem(
      id: 'yannykala',
      title: 'Ýaňňykala',
      subtitle: 'Steep cliffs & canyon paths',
      assetPath: '',
      isUnlocked: false,
      badgeText: 'ÝAPYK',
      gradientColors: [Color(0xFFD35400), Color(0xFF6E2C00)],
    ),
    _MapItem(
      id: 'derweze',
      title: 'Derweze (Gaz krateri)',
      subtitle: 'Gije, alaw hem gapanak bökdençler',
      assetPath: '',
      isUnlocked: false,
      badgeText: 'ÝAPYK',
      gradientColors: [Color(0xFFC0392B), Color(0xFF641E16)],
    ),
  ];

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    _totalCoins = GameProgressService.instance.getTotalCoins();

    _mapPageController = PageController(viewportFraction: 0.85);

    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _duneController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _buttonsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _titleFade = CurvedAnimation(parent: _titleController, curve: Curves.easeOut);
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _titleController, curve: Curves.easeOutCubic));

    _buttonsFade = CurvedAnimation(parent: _buttonsController, curve: Curves.easeOut);
    _buttonsSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _buttonsController, curve: Curves.easeOutCubic));

    _titleController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _buttonsController.forward();
    });

    _startMenuMusic();
  }

  @override
  void dispose() {
    // Menu theme is scoped to this screen only — stop it (not dispose the
    // shared FlameAudio.bgm player) so it doesn't keep playing underneath
    // the levels/garage/race screens.
    FlameAudio.bgm.stop();
    _titleController.dispose();
    _duneController.dispose();
    _buttonsController.dispose();
    _mapPageController.dispose();
    super.dispose();
  }

  Future<void> _startMenuMusic() async {
    if (!_soundOn) return;
    await FlameAudio.bgm.initialize();
    await FlameAudio.bgm.play('music/menu_theme.mp3', volume: 0.45);
  }

  void _toggleSound() {
    setState(() => _soundOn = !_soundOn);
    if (_soundOn) {
      _startMenuMusic();
    } else {
      FlameAudio.bgm.stop();
    }
  }

  void _showLockedMessage() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.lock_clock_outlined, color: Color(0xFFFFD98C), size: 20),
            SizedBox(width: 10),
            Text(
              'Entek elýeterli däl',
              style: TextStyle(
                color: Color(0xFFFFD98C),
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2A1406),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0x66E8A33D)),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onPlay() {
    final currentMap = _maps[_selectedMapIndex];
    if (!currentMap.isUnlocked) {
      _showLockedMessage();
      return;
    }

    if (currentMap.id == 'garagum' || currentMap.id == 'ashgabat') {
      // Open the round-selection grid for whichever unlocked map was picked
      FlameAudio.bgm.pause();
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, animation, __) => currentMap.id == 'garagum'
              ? const GaragumLevelsScreen()
              : const AshgabatLevelsScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      ).then((_) {
        if (mounted && _soundOn) FlameAudio.bgm.resume();
      });
    } else {
      // Future maps still open race screen directly (placeholder)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu karta heniz elýeterli däl.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _onGarage() {
    FlameAudio.bgm.pause();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const GarageScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    ).then((_) {
      if (mounted && _soundOn) FlameAudio.bgm.resume();
    });
  }

  void _onSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0E06),
      body: Stack(
        children: [
          // Sky gradient background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.35, 0.65, 1.0],
                  colors: [
                    Color(0xFF0B1829),
                    Color(0xFF1F3B5A),
                    Color(0xFF8B4A1A),
                    Color(0xFF3D1A06),
                  ],
                ),
              ),
            ),
          ),

          // Stars
          const Positioned.fill(child: _StarsLayer()),

          // Animated dunes
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _duneController,
              builder: (_, __) =>
                  _DuneSilhouette(animValue: _duneController.value),
            ),
          ),

          // Menu bg overlay
          Positioned.fill(
            child: Image.asset(
              'assets/images/ui/menu_bg.png',
              fit: BoxFit.cover,
              color: Colors.black.withValues(alpha: 0.40),
              colorBlendMode: BlendMode.darken,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),

          // Content Layout
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      const Spacer(),
                      _CoinBadge(coins: _totalCoins),
                      const SizedBox(width: 8),
                      _IconBtn(
                        assetPath: _soundOn
                            ? 'assets/images/ui/icon_sound_on.png'
                            : 'assets/images/ui/icon_sound_off.png',
                        onTap: _toggleSound,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Title
                FadeTransition(
                  opacity: _titleFade,
                  child: SlideTransition(
                    position: _titleSlide,
                    child: Column(
                      children: [
                        _Divider(),
                        const SizedBox(height: 8),
                        const Text(
                          'GARAGUM',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFFD98C),
                            letterSpacing: 6,
                            shadows: [
                              Shadow(
                                color: Color(0xFFE8601A),
                                blurRadius: 24,
                                offset: Offset(0, 4),
                              ),
                              Shadow(
                                color: Color(0x99FF8C00),
                                blurRadius: 48,
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          'RACING',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFFE8A33D),
                            letterSpacing: 12,
                            shadows: [
                              Shadow(
                                color: Color(0x88E8601A),
                                blurRadius: 16,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        _Divider(),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Map Selection Carousel Section
                FadeTransition(
                  opacity: _buttonsFade,
                  child: SlideTransition(
                    position: _buttonsSlide,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: const [
                              Icon(Icons.map_rounded,
                                  size: 18, color: Color(0xFFE8A33D)),
                              SizedBox(width: 8),
                              Text(
                                'KARTA SAÝLAŇ',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFFFD98C),
                                  letterSpacing: 3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 155,
                          child: PageView.builder(
                            controller: _mapPageController,
                            itemCount: _maps.length,
                            onPageChanged: (index) {
                              setState(() {
                                _selectedMapIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              final map = _maps[index];
                              final isSelected = index == _selectedMapIndex;

                              return GestureDetector(
                                onTap: () {
                                  _mapPageController.animateToPage(
                                    index,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                  if (!map.isUnlocked) {
                                    _showLockedMessage();
                                  }
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    gradient: LinearGradient(
                                      colors: map.gradientColors,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFFFFD98C)
                                          : const Color(0x44E8A33D),
                                      width: isSelected ? 2 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isSelected
                                            ? map.gradientColors.first
                                                .withValues(alpha: 0.5)
                                            : Colors.black.withValues(alpha: 0.3),
                                        blurRadius: isSelected ? 16 : 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      // Card Content
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: map.isUnlocked
                                                      ? const Color(0x44000000)
                                                      : const Color(0xAA000000),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      map.isUnlocked
                                                          ? Icons.check_circle
                                                          : Icons.lock,
                                                      size: 13,
                                                      color: map.isUnlocked
                                                          ? const Color(
                                                              0xFF44FF88)
                                                          : const Color(
                                                              0xFFFF6666),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      map.badgeText,
                                                      style: TextStyle(
                                                        color: map.isUnlocked
                                                            ? const Color(
                                                                0xFF44FF88)
                                                            : const Color(
                                                                0xFFFF6666),
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        letterSpacing: 1,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                '${index + 1}/${_maps.length}',
                                                style: const TextStyle(
                                                  color: Color(0xAAFFFFFF),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Spacer(),
                                          Text(
                                            map.title,
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                              shadows: [
                                                Shadow(
                                                    color: Colors.black54,
                                                    blurRadius: 6),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            map.subtitle,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xDDFFFFFF),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),

                                      // Lock overlay for locked maps
                                      if (!map.isUnlocked)
                                        Positioned.fill(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black
                                                  .withValues(alpha: 0.45),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: const [
                                                  Icon(Icons.lock,
                                                      size: 32,
                                                      color: Color(0xFFFFD98C)),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    'Entek elýeterli däl',
                                                    style: TextStyle(
                                                      color: Color(0xFFFFD98C),
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w700,
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
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Carousel Page Indicators (Dots)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _maps.length,
                            (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: _selectedMapIndex == i ? 20 : 7,
                              height: 7,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: _selectedMapIndex == i
                                    ? const Color(0xFFFFD98C)
                                    : const Color(0x44E8A33D),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Buttons Section
                FadeTransition(
                  opacity: _buttonsFade,
                  child: SlideTransition(
                    position: _buttonsSlide,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _MenuButton(
                            label: 'OYNA',
                            icon: Icons.play_arrow_rounded,
                            isPrimary: true,
                            onTap: _onPlay,
                          ),
                          const SizedBox(height: 12),
                          _MenuButton(
                            label: 'GARAJ',
                            icon: Icons.garage_rounded,
                            isPrimary: false,
                            onTap: _onGarage,
                          ),
                          const SizedBox(height: 12),
                          _MenuButton(
                            label: 'SAZLAMALAR',
                            icon: Icons.settings_rounded,
                            isPrimary: false,
                            onTap: _onSettings,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Version
                const Text(
                  'v1.0.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0x44FFD98C),
                    fontSize: 11,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Map Item Data ────────────────────────────────────────────────────────────

class _MapItem {
  final String id;
  final String title;
  final String subtitle;
  final String assetPath;
  final bool isUnlocked;
  final String badgeText;
  final List<Color> gradientColors;

  const _MapItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.assetPath,
    required this.isUnlocked,
    required this.badgeText,
    required this.gradientColors,
  });
}

// ─── Divider ──────────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 60,
        height: 2,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.transparent, Color(0xFFE8A33D), Colors.transparent],
          ),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}

// ─── Stars Layer ─────────────────────────────────────────────────────────────

class _StarsLayer extends StatelessWidget {
  const _StarsLayer();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _StarsPainter());
  }
}

class _StarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (int i = 0; i < 60; i++) {
      final x = ((i * 137.508) % 100) / 100 * size.width;
      final y = ((i * 97.3) % 60) / 100 * size.height;
      final radius = 0.8 + (i % 3) * 0.6;
      final opacity = 0.25 + (i % 5) * 0.12;
      paint.color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Dune Silhouette ──────────────────────────────────────────────────────────

class _DuneSilhouette extends StatelessWidget {
  final double animValue;
  const _DuneSilhouette({required this.animValue});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(MediaQuery.of(context).size.width, 200),
      painter: _DunePainter(animValue),
    );
  }
}

class _DunePainter extends CustomPainter {
  final double t;
  _DunePainter(this.t);

  double _sin(double x) {
    const pi = 3.14159265358979;
    double v = x % (2 * pi);
    if (v < 0) v += 2 * pi;
    if (v < pi) {
      return (v * (pi - v) * 4) / (pi * pi);
    } else {
      final w = v - pi;
      return -((w * (pi - w) * 4) / (pi * pi));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final shift = t * 30;

    // Back dune
    final backPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0xFF5C3010), Color(0xFF2A1406)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final backPath = Path();
    backPath.moveTo(0, size.height);
    final y0back = size.height * 0.45 + shift * 0.3;
    backPath.lineTo(0, y0back);
    for (double x = 0; x <= size.width; x++) {
      final y = size.height * 0.45 +
          18 * _sin(x / size.width * 2.5 + t * 0.5) +
          9 * _sin(x / size.width * 5 - t * 0.3) +
          shift * 0.3;
      backPath.lineTo(x, y);
    }
    backPath.lineTo(size.width, size.height);
    backPath.close();
    canvas.drawPath(backPath, backPaint);

    // Front dune
    final frontPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0xFF3D1A06), Color(0xFF120802)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final frontPath = Path();
    frontPath.moveTo(0, size.height);
    final y0front = size.height * 0.62 - shift * 0.2;
    frontPath.lineTo(0, y0front);
    for (double x = 0; x <= size.width; x++) {
      final y = size.height * 0.62 +
          12 * _sin(x / size.width * 3 - t * 0.4) +
          7 * _sin(x / size.width * 7 + t * 0.6) -
          shift * 0.2;
      frontPath.lineTo(x, y);
    }
    frontPath.lineTo(size.width, size.height);
    frontPath.close();
    canvas.drawPath(frontPath, frontPaint);
  }

  @override
  bool shouldRepaint(covariant _DunePainter old) => old.t != t;
}

// ─── Menu Button ─────────────────────────────────────────────────────────────

class _MenuButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  const _MenuButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton>
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
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: widget.isPrimary
                ? const LinearGradient(
                    colors: [Color(0xFFFF8C1A), Color(0xFFE85A00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: widget.isPrimary ? null : const Color(0x2BE8A33D),
            border: Border.all(
              color: widget.isPrimary
                  ? const Color(0xFFFFAA44)
                  : const Color(0x55E8A33D),
              width: 1.5,
            ),
            boxShadow: widget.isPrimary
                ? [
                    BoxShadow(
                      color: const Color(0xFFE85A00).withValues(alpha: 0.45),
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
                color: widget.isPrimary ? Colors.white : const Color(0xFFE8A33D),
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: widget.isPrimary
                      ? Colors.white
                      : const Color(0xFFE8A33D),
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Coin Badge ───────────────────────────────────────────────────────────────

class _CoinBadge extends StatelessWidget {
  final int coins;
  const _CoinBadge({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x44000000),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x55E8A33D), width: 1),
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
              color: Color(0xFFFFD98C),
              size: 20,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$coins',
            style: const TextStyle(
              color: Color(0xFFFFD98C),
              fontWeight: FontWeight.w700,
              fontSize: 15,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Icon Btn ─────────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final String assetPath;
  final VoidCallback onTap;
  const _IconBtn({required this.assetPath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0x44000000),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x44E8A33D)),
        ),
        child: Center(
          child: Image.asset(
            assetPath,
            width: 22,
            height: 22,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.volume_up,
              color: Color(0xFFE8A33D),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Settings Sheet ──────────────────────────────────────────────────────────

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet();

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  bool _music = true;
  bool _sfx = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C0E06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x44E8A33D)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0x66E8A33D),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'SAZLAMALAR',
            style: TextStyle(
              color: Color(0xFFFFD98C),
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 24),
          _SettingRow(
            label: 'Saz',
            value: _music,
            onChanged: (v) => setState(() => _music = v),
          ),
          const SizedBox(height: 16),
          _SettingRow(
            label: 'Ses efektleri',
            value: _sfx,
            onChanged: (v) => setState(() => _sfx = v),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFE8A33D),
            fontSize: 16,
            letterSpacing: 1,
          ),
        ),
        const Spacer(),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFFFF8C1A),
          trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? const Color(0x55FF8C1A)
                : const Color(0x33FFFFFF),
          ),
        ),
      ],
    );
  }
}
