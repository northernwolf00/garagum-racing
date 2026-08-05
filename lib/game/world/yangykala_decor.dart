import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'terrain.dart';

enum _YangykalaDecorType { pillar, arch, yurt, camel, sheep, sazak }

class _DecorPlacement {
  const _DecorPlacement({
    required this.type,
    required this.x,
    required this.groundY,
    required this.scale,
    required this.flip,
  });

  final _YangykalaDecorType type;
  final double x;
  final double groundY;
  final double scale;
  final bool flip;
}

/// Canyon cliffs and desert scenery for Ýaňňykala.
class YangykalaDecorComponent extends Component {
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

      final groundY = -terrain.heightAt(curX);
      final scale = 0.8 + _rand.nextDouble() * 0.4;
      final flip = _rand.nextBool();

      _placements.add(
        _DecorPlacement(
          type: type,
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
