import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'terrain.dart';

enum _DerwezeDecorType { yurt, camel, sheep, dog, ojak, sazak, sign, crater }

class _DerwezePlacement {
  const _DerwezePlacement({
    required this.type,
    required this.x,
    required this.groundY,
    required this.scale,
    required this.flip,
  });

  final _DerwezeDecorType type;
  final double x;
  final double groundY;
  final double scale;
  final bool flip;
}

/// Scenery and animated Derweze Gas Crater for Derweze map.
class DerwezeDecorComponent extends Component {
  DerwezeDecorComponent({required this.terrain, required int seed})
      : _rand = math.Random(seed);

  final Terrain terrain;
  final math.Random _rand;

  static const double _minSpacing = 40.0;
  static const double _maxSpacing = 85.0;

  late final Sprite _yurtSprite;
  late final Sprite _camelSprite;
  late final Sprite _sheepSprite;
  late final Sprite _dogSprite;
  late final Sprite _ojakSprite;
  late final Sprite _sazakSprite;
  late final Sprite _signSprite;
  late final Sprite _craterPitSprite;
  late final List<Sprite> _craterFireSprites;
  late final Sprite _craterGlowSprite;

  final List<_DerwezePlacement> _placements = [];

  double _fireTimer = 0.0;
  int _fireFrame = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _yurtSprite = await Sprite.load('images_derweze/props/ak_oy.png');
    _camelSprite = await Sprite.load('images_derweze/props/duye.png');
    _sheepSprite = await Sprite.load('images_derweze/props/goyun.png');
    _dogSprite = await Sprite.load('images_derweze/props/copan_it.png');
    _ojakSprite = await Sprite.load('images_derweze/props/ojak_gazan.png');
    _sazakSprite = await Sprite.load('images_derweze/props/sazak.png');
    _signSprite = await Sprite.load('images_derweze/props/derweze_belgi.png');

    _craterPitSprite = await Sprite.load('images_derweze/crater/crater_pit.png');
    _craterFireSprites = [
      await Sprite.load('images_derweze/crater/crater_fire_1.png'),
      await Sprite.load('images_derweze/crater/crater_fire_2.png'),
      await Sprite.load('images_derweze/crater/crater_fire_3.png'),
    ];
    _craterGlowSprite = await Sprite.load('images_derweze/crater/crater_glow.png');

    _generatePlacements();
  }

  void _generatePlacements() {
    final maxX = terrain.segmentCount * terrain.segmentWidth;
    double curX = 35.0;

    // Place a sign at the start
    _placements.add(_DerwezePlacement(
      type: _DerwezeDecorType.sign,
      x: 18.0,
      groundY: -terrain.heightAt(18.0),
      scale: 1.0,
      flip: false,
    ));

    // Place gas crater at ~180m intervals
    double nextCraterX = 180.0;

    while (curX < maxX - 20.0) {
      if ((curX - nextCraterX).abs() < 20.0) {
        _placements.add(_DerwezePlacement(
          type: _DerwezeDecorType.crater,
          x: nextCraterX,
          groundY: -terrain.heightAt(nextCraterX),
          scale: 1.0,
          flip: false,
        ));
        nextCraterX += 220.0;
        curX += 45.0;
        continue;
      }

      curX += _minSpacing + _rand.nextDouble() * (_maxSpacing - _minSpacing);
      if (terrain.isInsideBridgeSpan(curX, extraMargin: 8.0)) continue;

      final roll = _rand.nextDouble();
      _DerwezeDecorType type;
      if (roll < 0.25) {
        type = _DerwezeDecorType.yurt;
      } else if (roll < 0.45) {
        type = _DerwezeDecorType.camel;
      } else if (roll < 0.65) {
        type = _DerwezeDecorType.sheep;
      } else if (roll < 0.80) {
        type = _DerwezeDecorType.sazak;
      } else if (roll < 0.90) {
        type = _DerwezeDecorType.ojak;
      } else {
        type = _DerwezeDecorType.dog;
      }

      final groundY = -terrain.heightAt(curX);
      final scale = 0.85 + _rand.nextDouble() * 0.35;
      final flip = _rand.nextBool();

      _placements.add(
        _DerwezePlacement(
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
  void update(double dt) {
    super.update(dt);
    _fireTimer += dt;
    if (_fireTimer >= 0.12) {
      _fireTimer = 0.0;
      _fireFrame = (_fireFrame + 1) % _craterFireSprites.length;
    }
  }

  @override
  void render(Canvas canvas) {
    for (final p in _placements) {
      if (p.type == _DerwezeDecorType.crater) {
        _renderCrater(canvas, p.x, p.groundY);
        continue;
      }

      Sprite sprite;
      Vector2 size;

      switch (p.type) {
        case _DerwezeDecorType.yurt:
          sprite = _yurtSprite;
          size = Vector2(4.0, 3.5) * p.scale;
          break;
        case _DerwezeDecorType.camel:
          sprite = _camelSprite;
          size = Vector2(3.2, 3.2) * p.scale;
          break;
        case _DerwezeDecorType.sheep:
          sprite = _sheepSprite;
          size = Vector2(1.8, 1.4) * p.scale;
          break;
        case _DerwezeDecorType.dog:
          sprite = _dogSprite;
          size = Vector2(1.5, 1.4) * p.scale;
          break;
        case _DerwezeDecorType.ojak:
          sprite = _ojakSprite;
          size = Vector2(1.6, 1.6) * p.scale;
          break;
        case _DerwezeDecorType.sazak:
          sprite = _sazakSprite;
          size = Vector2(2.2, 2.5) * p.scale;
          break;
        case _DerwezeDecorType.sign:
          sprite = _signSprite;
          size = Vector2(2.2, 3.2) * p.scale;
          break;
        case _DerwezeDecorType.crater:
          continue;
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

  void _renderCrater(Canvas canvas, double x, double groundY) {
    // 1. Crater glow (additive orange blend)
    canvas.save();
    canvas.translate(x, groundY + 1.0);
    final glowPaint = Paint()..blendMode = BlendMode.plus;
    _craterGlowSprite.render(
      canvas,
      anchor: Anchor.center,
      size: Vector2(14.0, 7.0),
      overridePaint: glowPaint,
    );
    canvas.restore();

    // 2. Crater pit base
    canvas.save();
    canvas.translate(x, groundY + 0.5);
    _craterPitSprite.render(
      canvas,
      anchor: Anchor.bottomCenter,
      size: Vector2(12.0, 4.0),
    );
    canvas.restore();

    // 3. Crater animated fire frame
    canvas.save();
    canvas.translate(x, groundY - 0.2);
    _craterFireSprites[_fireFrame].render(
      canvas,
      anchor: Anchor.bottomCenter,
      size: Vector2(10.0, 3.0),
    );
    canvas.restore();
  }
}
