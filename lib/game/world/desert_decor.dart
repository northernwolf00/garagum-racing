import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'terrain.dart';

enum _DecorType { camel, yurt }

class _DecorPlacement {
  const _DecorPlacement({
    required this.type,
    required this.x,
    required this.groundY,
    required this.scale,
    required this.flip,
  });

  final _DecorType type;
  final double x;
  final double groundY;
  final double scale;
  final bool flip;
}

/// Sparse, purely-visual desert scenery (camels — "düýe" — and yurts —
/// "ak öý") scattered along the route so the dunes feel inhabited instead
/// of empty. No Forge2D bodies: it just draws sprites at precomputed ground
/// positions, so it can't interfere with car physics or collisions.
///
/// Added to the world after [Terrain] but before obstacles/coins/car, so it
/// renders on top of the sand texture and behind everything the player can
/// actually interact with.
class DesertDecorComponent extends Component {
  DesertDecorComponent({required this.terrain, required int seed})
      : _rand = math.Random(seed);

  final Terrain terrain;
  final math.Random _rand;

  static const double _minSpacing = 45.0;
  static const double _maxSpacing = 95.0;

  /// World-space tile size (both source images are square 256x256 with
  /// their own ground shadow baked in, so a uniform width==height keeps
  /// the art undistorted).
  static const double _camelSizeM = 3.2;
  static const double _yurtSizeM = 4.0;

  /// Fraction of placements that are a yurt rather than a camel.
  static const double _yurtChance = 0.3;

  late final Sprite _camelSprite;
  late final Sprite _yurtSprite;
  final List<_DecorPlacement> _placements = [];

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _camelSprite = await Sprite.load('parallax/deco_duye.png');
    _yurtSprite = await Sprite.load('parallax/deco_ak_oy.png');
    _generatePlacements();
  }

  void _generatePlacements() {
    final maxX = terrain.segmentCount * terrain.segmentWidth;
    double curX = 25.0;

    while (curX < maxX - 20.0) {
      curX += _minSpacing + _rand.nextDouble() * (_maxSpacing - _minSpacing);
      if (terrain.isInsideBridgeSpan(curX, extraMargin: 8.0)) continue;

      final isYurt = _rand.nextDouble() < _yurtChance;
      final groundY = -terrain.heightAt(curX);
      final scale = 0.85 + _rand.nextDouble() * 0.35;
      final flip = _rand.nextBool();

      _placements.add(
        _DecorPlacement(
          type: isYurt ? _DecorType.yurt : _DecorType.camel,
          x: curX,
          groundY: groundY,
          scale: scale,
          flip: flip,
        ),
      );
    }
  }

  @override
  void render(Canvas canvas) {
    for (final p in _placements) {
      final isYurt = p.type == _DecorType.yurt;
      final sprite = isYurt ? _yurtSprite : _camelSprite;
      final tileSize = (isYurt ? _yurtSizeM : _camelSizeM) * p.scale;

      canvas.save();
      canvas.translate(p.x, p.groundY);
      if (p.flip) canvas.scale(-1, 1);
      sprite.render(
        canvas,
        anchor: Anchor.bottomCenter,
        size: Vector2.all(tileSize),
      );
      canvas.restore();
    }
  }
}
