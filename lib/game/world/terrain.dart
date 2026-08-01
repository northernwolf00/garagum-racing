import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/flame.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;

/// Procedural sand-dune ground built from a chain of static line segments.
///
/// The height function combines a few sine waves at different frequencies,
/// which gives the same rolling-dune silhouette as the reference art
/// without needing hand-authored terrain data yet. Collision uses the
/// invisible [ChainShape] fixture; the visible surface is drawn separately
/// with the `terrain_fill`/`terrain_top` textures tiled along the same
/// point list.
class Terrain extends BodyComponent {
  Terrain({
    this.segmentWidth = 2.0,
    this.segmentCount = 400,
  }) : super(renderBody: false);

  final double segmentWidth;
  final int segmentCount;

  /// How many meters of world-space one tile of each texture covers.
  static const double _fillTileMeters = 6.0;
  static const double _topStripHeightMeters = 1.0;

  /// How far below the lowest ground point the fill texture extends, so it
  /// still covers the screen when the camera looks at a dip in the dunes.
  static const double _fillDepthMeters = 40.0;

  late final List<Vector2> groundPoints;
  late final ui.Path _fillPath;
  late final ui.Path _topPath;
  late final ui.Paint _fillPaint;
  late final ui.Paint _topPaint;

  double heightAt(double x) {
    return sin(x * 0.09) * 3.0 +
        sin(x * 0.03) * 6.0 +
        sin(x * 0.005 + 1.7) * 2.5 +
        6.0;
  }

  @override
  Body createBody() {
    groundPoints = List.generate(segmentCount, (i) {
      final x = i * segmentWidth;
      return Vector2(x, -heightAt(x));
    });

    final shape = ChainShape()..createChain(groundPoints);

    final bodyDef = BodyDef(
      position: Vector2.zero(),
      type: BodyType.static,
    );

    final body = world.createBody(bodyDef);
    final fixtureDef = FixtureDef(
      shape,
      friction: 0.9,
      restitution: 0.05,
    );
    body.createFixture(fixtureDef);
    return body;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final fillImage = await Flame.images.load('terrain/terrain_fill.png');
    final topImage = await Flame.images.load('terrain/terrain_top.png');

    final fillScale = _fillTileMeters / fillImage.width;
    _fillPaint = ui.Paint()
      ..shader = ui.ImageShader(
        fillImage,
        ui.TileMode.repeated,
        ui.TileMode.repeated,
        (Matrix4.identity()..scaleByDouble(fillScale, fillScale, 1, 1)).storage,
      );

    final topScaleX = _fillTileMeters / topImage.width;
    final topScaleY = _topStripHeightMeters / topImage.height;
    _topPaint = ui.Paint()
      ..shader = ui.ImageShader(
        topImage,
        ui.TileMode.repeated,
        ui.TileMode.repeated,
        (Matrix4.identity()..scaleByDouble(topScaleX, topScaleY, 1, 1)).storage,
      )
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = _topStripHeightMeters
      ..strokeJoin = ui.StrokeJoin.round
      ..strokeCap = ui.StrokeCap.round;

    final lowestY = groundPoints.map((p) => p.y).reduce(max);
    final deepY = lowestY + _fillDepthMeters;

    _fillPath = ui.Path()..moveTo(groundPoints.first.x, groundPoints.first.y);
    for (final point in groundPoints.skip(1)) {
      _fillPath.lineTo(point.x, point.y);
    }
    _fillPath
      ..lineTo(groundPoints.last.x, deepY)
      ..lineTo(groundPoints.first.x, deepY)
      ..close();

    _topPath = ui.Path()..moveTo(groundPoints.first.x, groundPoints.first.y);
    for (final point in groundPoints.skip(1)) {
      _topPath.lineTo(point.x, point.y);
    }
  }

  @override
  void render(ui.Canvas canvas) {
    canvas.drawPath(_fillPath, _fillPaint);
    canvas.drawPath(_topPath, _topPaint);
  }
}
