import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../garagum_racing_game.dart';
import 'terrain.dart';

enum _YangykalaDecorType { pillar, arch, yurt, camel, sheep, sazak }

class _DecorPlacement {
  const _DecorPlacement({
    required this.type,
    required this.x,
    required this.groundY,
    required this.angle,
    required this.scale,
    required this.flip,
  });

  final _YangykalaDecorType type;
  final double x;
  final double groundY;
  final double angle;
  final double scale;
  final bool flip;
}

/// Canyon cliffs and desert scenery for Ýaňňykala.
class YangykalaDecorComponent extends Component
    with HasGameReference<GaragumRacingGame> {
  YangykalaDecorComponent({required this.terrain, required int seed})
      : _rand = math.Random(seed);

  final Terrain terrain;
  final math.Random _rand;

  static const double _minSpacing = 35.0;
  static const double _maxSpacing = 75.0;

  late final Sprite _pillarSprite;
  late final Sprite _archSprite;
  late final Sprite _yurtSprite;
  late final Sprite _camelSprite;
  late final Sprite _sheepSprite;
  late final Sprite _sazakSprite;

  final List<_DecorPlacement> _placements = [];

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _pillarSprite = await Sprite.load('images_yangykala/cliffs/rock_pillar.png');
    _archSprite = await Sprite.load('images_yangykala/cliffs/rock_arch.png');
    _yurtSprite = await Sprite.load('images_yangykala/props/ak_oy.png');
    _camelSprite = await Sprite.load('images_yangykala/props/duye.png');
    _sheepSprite = await Sprite.load('images_yangykala/props/goyun.png');
    _sazakSprite = await Sprite.load('images_yangykala/props/sazak.png');
    _generatePlacements();
  }

  void _generatePlacements() {
    final maxX = terrain.segmentCount * terrain.segmentWidth;
    double curX = 30.0;

    while (curX < maxX - 20.0) {
      curX += _minSpacing + _rand.nextDouble() * (_maxSpacing - _minSpacing);
      if (terrain.isInsideBridgeSpan(curX, extraMargin: 8.0)) continue;

      final roll = _rand.nextDouble();
      _YangykalaDecorType type;
      if (roll < 0.25) {
        type = _YangykalaDecorType.pillar;
      } else if (roll < 0.40) {
        type = _YangykalaDecorType.arch;
      } else if (roll < 0.60) {
        type = _YangykalaDecorType.camel;
      } else if (roll < 0.75) {
        type = _YangykalaDecorType.sheep;
      } else if (roll < 0.90) {
        type = _YangykalaDecorType.sazak;
      } else {
        type = _YangykalaDecorType.yurt;
      }

      double decorX = curX;
      double groundAngle = terrain.getGroundAngle(decorX);

      // Prefer flatter ground for wide structures like yurts or arches so they sit flush
      if ((type == _YangykalaDecorType.yurt || type == _YangykalaDecorType.arch) &&
          groundAngle.abs() > 0.18) {
        double bestX = decorX;
        double minAngle = groundAngle.abs();
        for (double dx = -5.0; dx <= 5.0; dx += 1.0) {
          final candX = curX + dx;
          if (terrain.isInsideBridgeSpan(candX, extraMargin: 8.0)) continue;
          final candAngle = terrain.getGroundAngle(candX).abs();
          if (candAngle < minAngle) {
            minAngle = candAngle;
            bestX = candX;
          }
        }
        decorX = bestX;
        groundAngle = terrain.getGroundAngle(decorX);
      }

      final groundY = -terrain.heightAt(decorX);
      final scale = 0.8 + _rand.nextDouble() * 0.4;
      final flip = _rand.nextBool();

      _placements.add(
        _DecorPlacement(
          type: type,
          x: decorX,
          groundY: groundY,
          angle: groundAngle,
          scale: scale,
          flip: flip,
        ),
      );
    }
  }

  @override
  void render(Canvas canvas) {
    for (final p in _placements) {
      // Off-screen decor is skipped (margin covers the widest sprite).
      if (p.x < game.visibleWorldLeft - 6 || p.x > game.visibleWorldRight + 6) {
        continue;
      }
      Sprite sprite;
      Vector2 size;

      switch (p.type) {
        case _YangykalaDecorType.pillar:
          sprite = _pillarSprite;
          size = Vector2(2.5, 6.0) * p.scale;
          break;
        case _YangykalaDecorType.arch:
          sprite = _archSprite;
          size = Vector2(5.0, 5.5) * p.scale;
          break;
        case _YangykalaDecorType.yurt:
          sprite = _yurtSprite;
          size = Vector2(4.0, 3.5) * p.scale;
          break;
        case _YangykalaDecorType.camel:
          sprite = _camelSprite;
          size = Vector2(3.2, 3.2) * p.scale;
          break;
        case _YangykalaDecorType.sheep:
          sprite = _sheepSprite;
          size = Vector2(1.8, 1.5) * p.scale;
          break;
        case _YangykalaDecorType.sazak:
          sprite = _sazakSprite;
          size = Vector2(2.2, 2.5) * p.scale;
          break;
      }

      canvas.save();
      canvas.translate(p.x, p.groundY);
      canvas.rotate(p.angle);
      if (p.flip) canvas.scale(-1, 1);
      sprite.render(
        canvas,
        anchor: Anchor.bottomCenter,
        size: size,
      );
      canvas.restore();
    }
  }
}
