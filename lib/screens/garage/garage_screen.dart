import 'package:flutter/material.dart';

import '../../models/vehicle_config.dart';
import '../../services/game_progress_service.dart';

class GarageScreen extends StatefulWidget {
  const GarageScreen({super.key});

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  int _selectedVehicle = 0;
  final List<VehicleConfig> _vehicles = VehicleConfig.allVehicles;

  @override
  void initState() {
    super.initState();
    final savedId = GameProgressService.instance.getSelectedVehicle();
    final idx = _vehicles.indexWhere((v) => v.id == savedId);
    if (idx >= 0) {
      _selectedVehicle = idx;
    }

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic));
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = _vehicles[_selectedVehicle];

    return Scaffold(
      backgroundColor: const Color(0xFF0F0905),
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0B0704), Color(0xFF1C1008), Color(0xFF0F0905)],
                ),
              ),
            ),
          ),

          // Grid pattern
          Positioned.fill(child: _GridPattern()),

          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0x33E8A33D),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0x55E8A33D)),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Color(0xFFE8A33D),
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'GARAJ',
                            style: TextStyle(
                              color: Color(0xFFFFD98C),
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 5,
                            ),
                          ),
                          const Spacer(),
                          _CoinDisplay(coins: 0),
                        ],
                      ),
                    ),

                    // Vehicle selector
                    SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _vehicles.length,
                        itemBuilder: (_, i) {
                          final v = _vehicles[i];
                          final selected = i == _selectedVehicle;
                          return GestureDetector(
                            onTap: () async {
                              setState(() => _selectedVehicle = i);
                              await GameProgressService.instance
                                  .setSelectedVehicle(_vehicles[i].id);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: selected
                                    ? const LinearGradient(colors: [
                                        Color(0xFFFF8C1A),
                                        Color(0xFFE85A00),
                                      ])
                                    : null,
                                color: selected
                                    ? null
                                    : const Color(0x22E8A33D),
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFFFFAA44)
                                      : const Color(0x33E8A33D),
                                ),
                              ),
                              child: Row(
                                children: [
                                  if (!v.unlocked)
                                    const Icon(Icons.lock, size: 14,
                                        color: Color(0xFFE8A33D)),
                                  if (!v.unlocked)
                                    const SizedBox(width: 4),
                                  Text(
                                    v.name,
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : const Color(0xFFE8A33D),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Vehicle display area
                    Expanded(
                      flex: 4,
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Glow behind car
                            Container(
                              width: 250,
                              height: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(120),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFE8601A)
                                        .withOpacity(0.2),
                                    blurRadius: 60,
                                    spreadRadius: 20,
                                  ),
                                ],
                              ),
                            ),
                            // Shadow under car
                            Container(
                              width: 200,
                              height: 20,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(100),
                                color: Colors.black.withOpacity(0.4),
                              ),
                            ),
                            // Car image (body + both wheels composited,
                            // matching the in-race rig)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _VehiclePreview(
                                bodyAsset: vehicle.fullBodyAsset,
                                wheelAsset: vehicle.fullWheelAsset,
                                width: 280,
                              ),
                            ),
                            // Lock overlay
                            if (!vehicle.unlocked)
                              Container(
                                width: 280,
                                height: 140,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.lock_rounded,
                                        color: Color(0xFFE8A33D), size: 36),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/images/ui/coin.png',
                                          width: 18,
                                          height: 18,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(Icons.monetization_on,
                                                  color: Color(0xFFFFD98C),
                                                  size: 18),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${vehicle.unlockCost}',
                                          style: const TextStyle(
                                            color: Color(0xFFFFD98C),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Stats card
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0x22E8A33D),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0x33E8A33D)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                vehicle.name.toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFFFFD98C),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 3,
                                ),
                              ),
                              const Spacer(),
                              if (vehicle.unlocked)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0x33FF8C1A),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: const Color(0x66FF8C1A)),
                                  ),
                                  child: const Text(
                                    'SAÝLANAN',
                                    style: TextStyle(
                                      color: Color(0xFFFF8C1A),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _StatBar(label: 'MOTOR', value: vehicle.engine,
                              icon: Icons.bolt),
                          const SizedBox(height: 10),
                          _StatBar(label: 'ASMA', value: vehicle.suspension,
                              icon: Icons.compress),
                          const SizedBox(height: 10),
                          _StatBar(label: 'TEKERLEKLER', value: vehicle.tires,
                              icon: Icons.circle_outlined),
                          const SizedBox(height: 10),
                          _StatBar(label: 'ÝANGYÇ TANKY', value: vehicle.fuel,
                              icon: Icons.local_gas_station),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Action button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: vehicle.unlocked
                          ? _ActionButton(
                              label: 'SAÝLA WE OÝNA',
                              icon: Icons.check_circle_rounded,
                              primary: true,
                              onTap: () async {
                                await GameProgressService.instance
                                    .setSelectedVehicle(vehicle.id);
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                            )
                          : _ActionButton(
                              label: 'SAT AL — ${vehicle.unlockCost} teňňe',
                              icon: Icons.lock_open_rounded,
                              primary: false,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Ýeterlik teňňe ýok!'),
                                    backgroundColor: Color(0xFF3D1A06),
                                  ),
                                );
                              },
                            ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Grid Pattern ──────────────────────────────────────────────────────────────

class _GridPattern extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GridPainter());
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x0AE8A33D)
      ..strokeWidth = 0.5;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Stat Bar ─────────────────────────────────────────────────────────────────

class _StatBar extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;

  const _StatBar({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF886633)),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF886633),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0x22E8A33D),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: value,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFF8C1A),
                        Color.lerp(const Color(0xFFFF8C1A),
                            const Color(0xFF44FF88), value)!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF8C1A).withOpacity(0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(value * 10).toInt()}/10',
          style: const TextStyle(
            color: Color(0xFF886633),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Action Button ────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool primary;
  final VoidCallback onTap;

  const _ActionButton({
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
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
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
          boxShadow: primary
              ? [
                  BoxShadow(
                    color: const Color(0xFFE85A00).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: primary ? Colors.white : const Color(0xFFE8A33D),
                size: 22),
            const SizedBox(width: 10),
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

// ─── Coin Display ─────────────────────────────────────────────────────────────

class _CoinDisplay extends StatelessWidget {
  final int coins;
  const _CoinDisplay({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x33000000),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x44E8A33D)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/ui/coin.png',
            width: 18,
            height: 18,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.monetization_on,
              color: Color(0xFFFFD98C),
              size: 18,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$coins',
            style: const TextStyle(
              color: Color(0xFFFFD98C),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Vehicle Preview (body + wheels composited) ────────────────────────────

/// Draws a vehicle's body sprite with both wheel sprites overlaid at their
/// wheel-arch positions, so the garage shows the same complete car (body +
/// tires) the race screen does instead of just the bare body art.
///
/// Mirrors [Car]'s rig: every body sprite is a 1024x512 image with
/// front/rear wheel-arch centers at (252,400)/(772,400) and a wheel
/// diameter of ~203.5px (derived from `Car.wheelRadius * 2 /
/// (Car.wheelOffsetX / 260)`), scaled here to the on-screen display width.
class _VehiclePreview extends StatelessWidget {
  const _VehiclePreview({
    required this.bodyAsset,
    required this.wheelAsset,
    required this.width,
  });

  final String bodyAsset;
  final String wheelAsset;
  final double width;

  static const double _artWidthPx = 1024;
  static const double _artHeightPx = 512;
  static const Offset _frontWheelPx = Offset(252, 400);
  static const Offset _rearWheelPx = Offset(772, 400);
  static const double _wheelDiameterPx = 203.5;

  @override
  Widget build(BuildContext context) {
    final scale = width / _artWidthPx;
    final height = _artHeightPx * scale;
    final wheelSize = _wheelDiameterPx * scale;

    Widget wheelAt(Offset px) => Positioned(
          left: px.dx * scale - wheelSize / 2,
          top: px.dy * scale - wheelSize / 2,
          width: wheelSize,
          height: wheelSize,
          child: Image.asset(
            wheelAsset,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        );

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          wheelAt(_rearWheelPx),
          wheelAt(_frontWheelPx),
          Image.asset(
            bodyAsset,
            width: width,
            height: height,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.directions_car,
              size: 100,
              color: Color(0xFFE8A33D),
            ),
          ),
        ],
      ),
    );
  }
}
