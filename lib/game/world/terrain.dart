import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/flame.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;

import '../../models/round_config.dart';

/// Struct representing a bridge span along the x-axis.
class BridgeSpan {
  const BridgeSpan({
    required this.startX,
    required this.endX,
  });

  final double startX;
  final double endX;

  double get width => endX - startX;
}

/// Procedural sand-dune ground built from a chain of static line segments,
/// incorporating periodic canal dips where bridges span across.
class Terrain extends BodyComponent {
  Terrain({
    this.segmentWidth = 0.35,
    RoundConfig? roundConfig,
  })  : segmentCount = roundConfig != null
            ? ((roundConfig.distanceMeters + 60.0) / 0.35).ceil().clamp(500, 8000)
            : 3000,
        super(renderBody: false) {
    _generateBridgeSpans();
  }

  final double segmentWidth;
  final int segmentCount;

  static const double canalDepth = 6.5;
  static const double canalBankMargin = 3.5;

  /// List of procedurally generated bridge spans.
  final List<BridgeSpan> bridgeSpans = [];

  /// How many meters of world-space one tile of each texture covers.
  static const double _fillTileMeters = 6.0;
  static const double _topStripHeightMeters = 0.8;

  /// How far below the lowest ground point the fill texture extends.
  static const double _fillDepthMeters = 60.0;

  late final List<Vector2> groundPoints;
  late final ui.Path _fillPath;
  late final ui.Path _topPath;
  late final ui.Paint _fillPaint;
  late final ui.Paint _topPaint;

  void _generateBridgeSpans() {
    // Generate bridges every ~180-220 meters starting after x = 120m
    double curX = 130.0;
    final maxWorldX = segmentCount * segmentWidth;

    while (curX < maxWorldX - 40.0) {
      final spanWidth = 22.0;
      bridgeSpans.add(BridgeSpan(startX: curX, endX: curX + spanWidth));
      curX += 190.0;
    }
  }

  double baseHeightAt(double x) {
    return sin(x * 0.09) * 3.0 +
        sin(x * 0.03) * 6.0 +
        sin(x * 0.005 + 1.7) * 2.5 +
        6.0;
  }

  /// Returns the elevation (height) of the ground surface at x.
  /// Higher return value means higher ground level (world Y = -heightAt(x)).
  double heightAt(double x) {
    final baseH = baseHeightAt(x);

    for (final span in bridgeSpans) {
      final bStart = span.startX;
      final bEnd = span.endX;

      if (x >= bStart - canalBankMargin && x <= bEnd + canalBankMargin) {
        // Target canal bottom height
        final bridgeDeckH = baseHeightAt(bStart);
        final canalBedH = bridgeDeckH - canalDepth;

        if (x >= bStart && x <= bEnd) {
          return canalBedH;
        } else if (x < bStart) {
          // Left bank slope down
          final t = (x - (bStart - canalBankMargin)) / canalBankMargin;
          final smoothT = (1 - cos(t * pi)) / 2;
          return baseH + (canalBedH - baseH) * smoothT;
        } else {
          // Right bank slope up
          final t = (x - bEnd) / canalBankMargin;
          final smoothT = (1 - cos(t * pi)) / 2;
          return canalBedH + (baseH - canalBedH) * smoothT;
        }
      }
    }

    return baseH;
  }

  /// Checks if x falls within any bridge deck span or its canal embankment.
  bool isInsideBridgeSpan(double x, {double extraMargin = 2.0}) {
    for (final span in bridgeSpans) {
      if (x >= span.startX - extraMargin && x <= span.endX + extraMargin) {
        return true;
      }
    }
    return false;
  }

  /// Computes ground slope angle (radians) at position x.
  double getGroundAngle(double x) {
    final dx = 0.4;
    final h1 = heightAt(x - dx);
    final h2 = heightAt(x + dx);
    // Note: Y in world space is -height, so dy = -(h2 - h1)
    return atan2(-(h2 - h1), dx * 2);
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
