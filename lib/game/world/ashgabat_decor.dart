import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../garagum_racing_game.dart';
import 'terrain.dart';

enum _DecorType { building, streetProp }

class _DecorPlacement {
  const _DecorPlacement({
    required this.type,
    required this.spriteIndex,
    required this.x,
    required this.groundY,
    required this.angle,
    required this.scale,
    required this.flip,
  });

  final _DecorType type;
  final int spriteIndex;
  final double x;
  final double groundY;
  final double angle;
  final double scale;
  final bool flip;
}

/// Sparse, purely-visual Aşgabat street scenery — landmark buildings and
/// street furniture (lamps, benches, fountains, flags, traffic lights)
/// scattered along the route so the city road feels inhabited. No Forge2D
/// bodies: it just draws sprites at precomputed ground positions, so it
/// can't interfere with car physics or collisions.
///
/// Mirrors [DesertDecorComponent]'s placement approach: added to the world
/// after [Terrain] but before obstacles/coins/car, so it renders on top of
/// the road texture and behind everything the player can actually interact
/// with.
class AshgabatDecorComponent extends Component
    with HasGameReference<GaragumRacingGame> {
  AshgabatDecorComponent({required this.terrain, required int seed})
      : _rand = math.Random(seed);

  final Terrain terrain;
  final math.Random _rand;

  static const double _minSpacing = 22.0;
  static const double _maxSpacing = 48.0;

  static const double _streetPropSizeM = 2.6;
  static const double _buildingSizeM = 9.0;

  /// Fraction of placements that are a landmark building rather than a
  /// small street prop.
  static const double _buildingChance = 0.16;

  static const List<String> _streetPropAssets = [
    'images_ashgabat/deco/street_lamp.png',
    'images_ashgabat/deco/skamya.png',
    'images_ashgabat/deco/cuwdurim.png',
    'images_ashgabat/deco/baydak.png',
    'images_ashgabat/deco/svetofor.png',
  ];

  static const List<String> _buildingAssets = [
    'images_ashgabat/buildings/yyldyz_hotel.png',
    'images_ashgabat/buildings/olimpiya_stadiony.png',
    'images_ashgabat/buildings/arkadag_stadiony.png',
    'images_ashgabat/buildings/bitaraplyk_binasy.png',
    'images_ashgabat/buildings/garassyzlyk_binasy.png',
    'images_ashgabat/buildings/tw_dini.png',
    'images_ashgabat/buildings/bagt_kosgi.png',
    'images_ashgabat/buildings/alem_carkyfelek.png',
    'images_ashgabat/buildings/dis_ministrligi.png',
    'images_ashgabat/buildings/jay_1.png',
    'images_ashgabat/buildings/jay_2.png',
    'images_ashgabat/buildings/jay_3.png',
  ];

  late final List<Sprite> _streetPropSprites;
  late final List<Sprite> _buildingSprites;
  final List<_DecorPlacement> _placements = [];

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _streetPropSprites =
        await Future.wait(_streetPropAssets.map(Sprite.load));
    _buildingSprites = await Future.wait(_buildingAssets.map(Sprite.load));
    _generatePlacements();
  }

  void _generatePlacements() {
    final maxX = terrain.segmentCount * terrain.segmentWidth;
    double curX = 20.0;

    while (curX < maxX - 20.0) {
      curX += _minSpacing + _rand.nextDouble() * (_maxSpacing - _minSpacing);
      if (terrain.isInsideBridgeSpan(curX, extraMargin: 8.0)) continue;

      final isBuilding = _rand.nextDouble() < _buildingChance;
      final spriteIndex = isBuilding
          ? _rand.nextInt(_buildingAssets.length)
          : _rand.nextInt(_streetPropAssets.length);

      double decorX = curX;
      double groundAngle = terrain.getGroundAngle(decorX);

      // Prefer flatter ground for large buildings so they sit flush
      if (isBuilding && groundAngle.abs() > 0.18) {
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
      final scale = isBuilding
          ? 0.85 + _rand.nextDouble() * 0.4
          : 0.9 + _rand.nextDouble() * 0.25;
      final flip = _rand.nextBool();

      _placements.add(
        _DecorPlacement(
          type: isBuilding ? _DecorType.building : _DecorType.streetProp,
          spriteIndex: spriteIndex,
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
      // Off-screen decor is skipped (wide margin — buildings are large).
      if (p.x < game.visibleWorldLeft - 12 ||
          p.x > game.visibleWorldRight + 12) {
        continue;
      }
      final isBuilding = p.type == _DecorType.building;
      final sprite = isBuilding
          ? _buildingSprites[p.spriteIndex]
          : _streetPropSprites[p.spriteIndex];

      // Buildings/props vary in aspect ratio (unlike the desert set's
      // uniform 256x256 art), so scale by target height and derive width
      // from the sprite's own aspect ratio instead of forcing it square.
      final heightM = (isBuilding ? _buildingSizeM : _streetPropSizeM) * p.scale;
      final aspect = sprite.srcSize.x / sprite.srcSize.y;
      final tileSize = Vector2(heightM * aspect, heightM);

      canvas.save();
      canvas.translate(p.x, p.groundY);
      canvas.rotate(p.angle);
      if (p.flip) canvas.scale(-1, 1);
      sprite.render(
        canvas,
        anchor: Anchor.bottomCenter,
        size: tileSize,
      );
      canvas.restore();
    }
  }
}
